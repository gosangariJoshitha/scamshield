import logging
import threading
import time
import asyncio
from collections import OrderedDict
from datetime import datetime
from typing import Literal
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, Request, UploadFile
from pydantic import BaseModel

import models
from app.services.audio_service import (
    WHISPER_CHUNK_MAX_BYTES,
    WHISPER_CHUNK_MAX_SECONDS,
    WHISPER_CHUNK_SAMPLE_RATE,
    audio_service,
)
from app.services.rate_limiter import rate_limit_analysis
from auth import get_current_verified_user

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/guardian/transcription", tags=["guardian"])

_CACHE_TTL_SECONDS = 10 * 60
_CACHE_MAX_CHUNKS = 256
_cache_lock = threading.Lock()
_transcript_cache: OrderedDict[
    tuple[int, str, str], tuple[float, list[dict]]
] = OrderedDict()


class TranscriptSegmentResponse(BaseModel):
    session_id: str
    segment_id: str
    sequence: int
    start_time: float
    end_time: float
    text: str
    is_final: bool
    language: str
    created_at: datetime


class TranscriptionChunkResponse(BaseModel):
    segments: list[TranscriptSegmentResponse]
    language: str


def _canonical_uuid(value: str, field_name: str) -> str:
    try:
        return str(UUID(value))
    except (ValueError, TypeError, AttributeError) as error:
        raise HTTPException(
            status_code=422,
            detail=f"{field_name} must be a valid identifier.",
        ) from error


def _cache_get(key: tuple[int, str, str]) -> list[dict] | None:
    now = time.monotonic()
    with _cache_lock:
        expired = [
            cache_key
            for cache_key, (created_at, _) in _transcript_cache.items()
            if now - created_at > _CACHE_TTL_SECONDS
        ]
        for cache_key in expired:
            _transcript_cache.pop(cache_key, None)
        cached = _transcript_cache.get(key)
        if cached is None:
            return None
        _transcript_cache.move_to_end(key)
        return cached[1]


def _cache_put(key: tuple[int, str, str], segments: list[dict]) -> None:
    now = time.monotonic()
    with _cache_lock:
        expired = [
            cache_key
            for cache_key, (created_at, _) in _transcript_cache.items()
            if now - created_at > _CACHE_TTL_SECONDS
        ]
        for cache_key in expired:
            _transcript_cache.pop(cache_key, None)
        _transcript_cache[key] = (now, segments)
        _transcript_cache.move_to_end(key)
        while len(_transcript_cache) > _CACHE_MAX_CHUNKS:
            _transcript_cache.popitem(last=False)


@router.post("/chunk", response_model=TranscriptionChunkResponse)
async def transcribe_guardian_chunk(
    request: Request,
    session_id: str = Form(..., min_length=1, max_length=64),
    chunk_id: str = Form(..., min_length=1, max_length=64),
    sequence: int = Form(..., ge=1),
    timestamp_ms: int = Form(..., ge=0),
    call_started_at_ms: int = Form(..., ge=0),
    duration_ms: int = Form(..., ge=1, le=WHISPER_CHUNK_MAX_SECONDS * 1000),
    sample_rate_hz: int = Form(...),
    channels: int = Form(...),
    encoding: str = Form(..., max_length=32),
    source: str = Form(..., max_length=40),
    language: Literal["en", "hi", "te"] | None = Form(None),
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_verified_user),
):
    rate_limit_analysis(request, current_user=current_user)
    session_id = _canonical_uuid(session_id, "session_id")
    chunk_id = _canonical_uuid(chunk_id, "chunk_id")

    if source != "CALL_AUDIO":
        raise HTTPException(
            status_code=422,
            detail="Live transcription is unavailable for this audio source.",
        )
    if (
        sample_rate_hz != WHISPER_CHUNK_SAMPLE_RATE
        or channels != 1
        or encoding != "PCM_16BIT"
        or duration_ms != WHISPER_CHUNK_MAX_SECONDS * 1000
    ):
        raise HTTPException(
            status_code=422,
            detail="Audio chunk format is not supported for live transcription.",
        )

    cache_key = (current_user.id, session_id, chunk_id)
    cached_segments = _cache_get(cache_key)
    if cached_segments is not None:
        cached_language = (
            cached_segments[0]["language"] if cached_segments else language or "und"
        )
        return {"segments": cached_segments, "language": cached_language}

    pcm_bytes = await file.read(WHISPER_CHUNK_MAX_BYTES + 1)
    await file.close()
    expected_bytes = (
        WHISPER_CHUNK_SAMPLE_RATE * duration_ms // 1000 * channels * 2
    )
    if len(pcm_bytes) != expected_bytes or len(pcm_bytes) > WHISPER_CHUNK_MAX_BYTES:
        raise HTTPException(
            status_code=422,
            detail="Audio chunk length does not match its declared format.",
        )

    chunk_start_seconds = max(
        0.0,
        (timestamp_ms - duration_ms - call_started_at_ms) / 1000,
    )
    try:
        segments = await asyncio.to_thread(
            audio_service.transcribe_pcm_chunk,
            pcm_bytes=pcm_bytes,
            chunk_id=chunk_id,
            sequence=sequence,
            chunk_start_seconds=chunk_start_seconds,
            language=language,
        )
    except HTTPException:
        raise
    except Exception as error:
        logger.error(
            "Guardian chunk transcription failed (%s).",
            type(error).__name__,
        )
        raise HTTPException(
            status_code=503,
            detail="Transcription is temporarily unavailable.",
        ) from error

    serialized = [segment.as_dict(session_id) for segment in segments]
    _cache_put(cache_key, serialized)
    return {
        "segments": serialized,
        "language": segments[0].language if segments else language or "und",
    }


@router.post("/session/{session_id}/finalize")
def finalize_transcription_session(
    session_id: str,
    current_user: models.User = Depends(get_current_verified_user),
):
    session_id = _canonical_uuid(session_id, "session_id")
    with _cache_lock:
        keys = [
            key
            for key in _transcript_cache
            if key[0] == current_user.id and key[1] == session_id
        ]
        for key in keys:
            _transcript_cache.pop(key, None)
    return {"session_id": session_id, "status": "FINALIZED"}
