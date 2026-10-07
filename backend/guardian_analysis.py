import asyncio
import hashlib
import logging
import os
import re
import threading
import time
from collections import OrderedDict, deque
from dataclasses import dataclass, field
from datetime import datetime, timezone
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request, Response

import models
import schemas
from app.pipeline.analysis_pipeline import analyze_text_core
from app.services.rate_limiter import rate_limit_analysis
from app.services.text_service import normalize_text
from auth import get_current_verified_user

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/guardian/analysis", tags=["guardian"])


def _positive_int(name: str, default: int, maximum: int) -> int:
    value = int(os.getenv(name, str(default)))
    if value < 1 or value > maximum:
        raise ValueError(f"{name} must be between 1 and {maximum}.")
    return value


_MAX_SESSIONS = _positive_int("GUARDIAN_AI_MAX_SESSIONS", 128, 1024)
_SESSION_TTL_SECONDS = _positive_int("GUARDIAN_AI_SESSION_TTL_SECONDS", 600, 86_400)
_MAX_WINDOW_CHARS = _positive_int("GUARDIAN_AI_MAX_WINDOW_CHARS", 4000, 20_000)
_MAX_BUFFERED_SEGMENTS = _positive_int("GUARDIAN_AI_MAX_SEGMENTS", 60, 500)
_MIN_NEW_CHARS = _positive_int("GUARDIAN_AI_MIN_NEW_CHARS", 80, 4000)
_MIN_NEW_WORDS = _positive_int("GUARDIAN_AI_MIN_NEW_WORDS", 12, 500)
_MIN_SENTENCE_WORDS = _positive_int("GUARDIAN_AI_MIN_SENTENCE_WORDS", 8, 500)
_MIN_SIGNAL_WORDS = _positive_int("GUARDIAN_AI_MIN_SIGNAL_WORDS", 4, 100)
_ANALYSIS_INTERVAL_SECONDS = _positive_int(
    "GUARDIAN_AI_ANALYSIS_INTERVAL_SECONDS",
    15,
    3600,
)
_MAX_DEDUPLICATION_KEYS = 256
_MAX_CACHED_WINDOWS = 16
_WORD_PATTERN = re.compile(r"[^\W_]+", re.UNICODE)
_SENTENCE_END_PATTERN = re.compile(r"[.!?।]\s*$")
_WB = r"(?<![^\W_])"
_WE = r"(?![^\W_])"
_SECRET_TERMS = (
    r"(?:otp|one[\s-]?time\s+(?:password|code)|verification\s+code|"
    r"pin|password|ओटीपी|पिन|पासवर्ड|ఓటీపీ|పిన్|పాస్‌వర్డ్)"
)
_REQUEST_VERBS = (
    r"(?:send|share|tell|give|read|provide|reveal|forward|"
    r"enter|confirm|reply\s+with|"
    r"भेजें|भेजो|बताएं|बताओ|दीजिए|दो|చెప్పండి|పంపండి|ఇవ్వండి)"
)
_SECRET_REQUEST_PATTERN = re.compile(
    r"(?:" + _WB + _REQUEST_VERBS + _WE + r".{0,100}" + _WB + _SECRET_TERMS + _WE + r"|"
    + _WB + _SECRET_TERMS + _WE + r".{0,100}" + _WB + _REQUEST_VERBS + _WE + r")",
    re.IGNORECASE | re.UNICODE,
)
_NEGATED_REQUEST_PATTERN = re.compile(
    _WB + r"(?:never|don['’]?t|do\s+not|should\s+not|must\s+not|avoid|"
    r"मत|नहीं|కద్దు|వద్దు)" + _WE + r".{0,100}" + _WB + _REQUEST_VERBS + _WE,
    re.IGNORECASE | re.UNICODE,
)
_ACCOUNT_TERMS = (
    r"(?:account|card|bank\s+account|खाता|बैंक\s+खाता|कार्ड|ఖాతా|బ్యాంక్\s+ఖాతా|కార్డు)"
)
_THREAT_TERMS = (
    r"(?:blocked|suspended|frozen|disabled|ब्लॉक|बंद|स्थगित|బ్లాక్|నిలిపివేయబడింది)"
)
_ACCOUNT_THREAT_PATTERN = re.compile(
    r"(?:" + _WB + _ACCOUNT_TERMS + _WE + r".{0,40}" + _WB + _THREAT_TERMS + _WE + r"|"
    + _WB + _THREAT_TERMS + _WE + r".{0,40}" + _WB + _ACCOUNT_TERMS + _WE + r")",
    re.IGNORECASE | re.UNICODE,
)


@dataclass
class _SessionState:
    lock: asyncio.Lock = field(default_factory=asyncio.Lock)
    segments: deque[schemas.GuardianTranscriptSegmentCreate] = field(
        default_factory=deque
    )
    segment_ids: set[str] = field(default_factory=set)
    segment_id_order: deque[str] = field(default_factory=deque)
    text_fingerprints: set[str] = field(default_factory=set)
    text_fingerprint_order: deque[str] = field(default_factory=deque)
    cached_windows: OrderedDict[str, schemas.GuardianLiveAnalysisResponse] = field(
        default_factory=OrderedDict
    )
    latest_response: schemas.GuardianLiveAnalysisResponse | None = None
    buffered_chars: int = 0
    last_sequence: int = 0
    processed_sequence: int = 0
    last_analysis_at: float | None = None
    updated_at: float = field(default_factory=time.monotonic)


_session_lock = threading.Lock()
_sessions: OrderedDict[tuple[int, UUID], _SessionState] = OrderedDict()


def _get_session_state(user_id: int, session_id: UUID) -> _SessionState:
    key = (user_id, session_id)
    now = time.monotonic()
    with _session_lock:
        expired = [
            session_key
            for session_key, state in _sessions.items()
            if now - state.updated_at > _SESSION_TTL_SECONDS
            and not state.lock.locked()
        ]
        for session_key in expired:
            _sessions.pop(session_key, None)

        state = _sessions.get(key)
        if state is not None:
            state.updated_at = now
            _sessions.move_to_end(key)
            return state

        if len(_sessions) >= _MAX_SESSIONS:
            evictable = next(
                (
                    session_key
                    for session_key, existing in _sessions.items()
                    if not existing.lock.locked()
                ),
                None,
            )
            if evictable is None:
                raise HTTPException(
                    status_code=503,
                    detail="Live AI analysis is temporarily unavailable.",
                )
            _sessions.pop(evictable, None)

        state = _SessionState()
        _sessions[key] = state
        return state


def _remember_bounded(
    value: str,
    values: set[str],
    ordering: deque[str],
) -> None:
    values.add(value)
    ordering.append(value)
    while len(ordering) > _MAX_DEDUPLICATION_KEYS:
        values.discard(ordering.popleft())


def _is_explicit_secret_request(text: str) -> bool:
    sentences = re.split(r"(?<=[.!?।])\s+|\n+", text)
    for sentence in sentences:
        if (
            _SECRET_REQUEST_PATTERN.search(sentence)
            and not _NEGATED_REQUEST_PATTERN.search(sentence)
        ):
            return True
    return False


def _should_analyze(
    new_text: str,
    *,
    last_analysis_at: float | None,
    now: float,
) -> bool:
    if _is_explicit_secret_request(new_text) or _ACCOUNT_THREAT_PATTERN.search(
        new_text
    ):
        return True
    words = _WORD_PATTERN.findall(new_text)
    if len(words) < _MIN_SIGNAL_WORDS:
        return False
    if len(words) >= _MIN_NEW_WORDS and len(new_text) >= _MIN_NEW_CHARS:
        return True
    if len(words) >= _MIN_SENTENCE_WORDS and _SENTENCE_END_PATTERN.search(new_text):
        return True
    return (
        last_analysis_at is not None
        and now - last_analysis_at >= _ANALYSIS_INTERVAL_SECONDS
        and len(words) >= _MIN_SIGNAL_WORDS
    )


def _build_window_id(session_id: UUID, text: str, last_sequence: int) -> str:
    digest = hashlib.sha256(text.casefold().encode("utf-8")).hexdigest()
    return hashlib.sha256(
        f"{session_id}:{last_sequence}:{digest}".encode("utf-8")
    ).hexdigest()


def _duplicate_response(
    state: _SessionState,
    session_id: UUID,
    window_id: str | None = None,
) -> schemas.GuardianLiveAnalysisResponse:
    if window_id is not None:
        cached = state.cached_windows.get(window_id)
        if cached is not None:
            return cached.model_copy(
                update={
                    "status": "AI_DUPLICATE",
                    "message": "This transcript window was already analyzed.",
                }
            )
    if state.latest_response is not None:
        return state.latest_response.model_copy(
            update={
                "status": "AI_DUPLICATE",
                "message": "This transcript segment was already processed.",
            }
        )
    return schemas.GuardianLiveAnalysisResponse(
        session_id=session_id,
        status="AI_DUPLICATE",
        message="This transcript segment was already processed.",
        processed_sequence=state.processed_sequence,
    )


def _waiting_response(
    state: _SessionState,
    session_id: UUID,
) -> schemas.GuardianLiveAnalysisResponse:
    return schemas.GuardianLiveAnalysisResponse(
        session_id=session_id,
        status="AI_WAITING_FOR_TRANSCRIPT",
        message="Waiting for more conversation before analysis.",
        processed_sequence=state.processed_sequence,
    )


def _trim_segment_buffer(state: _SessionState) -> None:
    while state.segments and (
        len(state.segments) > _MAX_BUFFERED_SEGMENTS
        or state.buffered_chars > _MAX_WINDOW_CHARS
    ):
        removed = state.segments.popleft()
        state.buffered_chars -= len(removed.text) + 1


def _window_text(state: _SessionState) -> tuple[str, str]:
    new_segments = [
        segment
        for segment in state.segments
        if segment.sequence > state.processed_sequence
    ]
    new_text = normalize_text("\n".join(segment.text for segment in new_segments))
    full_text = normalize_text(
        "\n".join(segment.text for segment in state.segments)
    )
    return full_text[-_MAX_WINDOW_CHARS:], new_text


def _result_payload(
    core_result,
    *,
    session_id: UUID,
    window_id: str,
    latest_segment: schemas.GuardianTranscriptSegmentCreate,
) -> schemas.GuardianLiveAnalysisResponse:
    risk = core_result.risk_result
    now = datetime.now(timezone.utc)
    created_at = latest_segment.created_at
    if created_at.tzinfo is None:
        created_at = created_at.replace(tzinfo=timezone.utc)
    transcription_to_analysis_ms = max(
        0.0,
        (now - created_at.astimezone(timezone.utc)).total_seconds() * 1000,
    )
    reasoning = core_result.llm_reasoning or (
        "AI explanation temporarily unavailable."
    )
    result = schemas.GuardianLiveAnalysisResult(
        risk_score=risk["risk_score"],
        risk_level=risk["risk_level"],
        classification=core_result.ml_result["classification"].upper(),
        scam_category=core_result.category,
        detected_indicators=core_result.final_indicators,
        reasoning=reasoning,
        supporting_evidence=core_result.retrieved_evidence,
        ml_probability=core_result.ml_result["ml_probability"],
        llm_confidence=core_result.llm_confidence,
        safe_action=core_result.safe_action,
        safe_actions=core_result.safe_actions,
        timestamp=now,
        session_id=session_id,
        language=core_result.default_language,
        evidence_status=core_result.rag_result.get(
            "evidence_status",
            "NO_RELEVANT_MATCH",
        ),
        processing_status=core_result.processing_status,
        model_version=core_result.model_version,
        rag_version=core_result.rag_version,
        timings_ms={
            "transcription_to_analysis_ms": transcription_to_analysis_ms,
            "preprocessing_ms": core_result.preprocessing_ms,
            "ml_ms": core_result.ml_ms,
            "embedding_ms": core_result.embedding_ms,
            "rag_ms": core_result.rag_ms,
            "llm_ms": core_result.llm_ms,
            "risk_engine_ms": core_result.risk_engine_ms,
            "total_ms": core_result.total_ms,
        },
    )
    if core_result.processing_status == "COMPLETED_WITH_LIMITATIONS":
        message = "AI explanation temporarily unavailable. Showing available risk analysis."
    else:
        message = "Analysis ready."
    return schemas.GuardianLiveAnalysisResponse(
        session_id=session_id,
        status="AI_RESULT_READY",
        message=message,
        processed_sequence=latest_segment.sequence,
        window_id=window_id,
        result=result,
    )


async def _process_segment(
    state: _SessionState,
    segment: schemas.GuardianTranscriptSegmentCreate,
    response: Response,
) -> schemas.GuardianLiveAnalysisResponse:
    session_id = segment.session_id
    normalized_text = normalize_text(segment.text).casefold()
    fingerprint = hashlib.sha256(normalized_text.encode("utf-8")).hexdigest()

    async with state.lock:
        state.updated_at = time.monotonic()
        if (
            segment.segment_id in state.segment_ids
            or fingerprint in state.text_fingerprints
            or segment.sequence <= state.last_sequence
        ):
            return _duplicate_response(state, session_id)

        _remember_bounded(
            segment.segment_id,
            state.segment_ids,
            state.segment_id_order,
        )
        _remember_bounded(
            fingerprint,
            state.text_fingerprints,
            state.text_fingerprint_order,
        )
        state.segments.append(segment)
        state.buffered_chars += len(segment.text) + 1
        state.last_sequence = segment.sequence
        _trim_segment_buffer(state)

        window_text, new_text = _window_text(state)
        if not new_text or not _should_analyze(
            new_text,
            last_analysis_at=state.last_analysis_at,
            now=time.monotonic(),
        ):
            state.latest_response = _waiting_response(state, session_id)
            return state.latest_response

        window_id = _build_window_id(
            session_id,
            window_text,
            state.last_sequence,
        )
        cached = state.cached_windows.get(window_id)
        if cached is not None:
            return _duplicate_response(state, session_id, window_id)

        try:
            core_result = await analyze_text_core(
                window_text,
                segment.language if segment.language != "und" else None,
            )
        except Exception as error:
            logger.warning(
                "Guardian analysis failed (%s).",
                type(error).__name__,
            )
            state.processed_sequence = state.last_sequence
            state.last_analysis_at = time.monotonic()
            unavailable = schemas.GuardianLiveAnalysisResponse(
                session_id=session_id,
                status="AI_UNAVAILABLE",
                message="Live AI analysis is temporarily unavailable.",
                processed_sequence=state.processed_sequence,
                window_id=window_id,
            )
            state.latest_response = unavailable
            state.cached_windows[window_id] = unavailable
            response.status_code = 503
            return unavailable

        state.processed_sequence = state.last_sequence
        state.last_analysis_at = time.monotonic()
        analyzed = _result_payload(
            core_result,
            session_id=session_id,
            window_id=window_id,
            latest_segment=segment,
        )
        state.latest_response = analyzed
        state.cached_windows[window_id] = analyzed
        state.cached_windows.move_to_end(window_id)
        while len(state.cached_windows) > _MAX_CACHED_WINDOWS:
            state.cached_windows.popitem(last=False)
        return analyzed


@router.post(
    "/segment",
    response_model=schemas.GuardianLiveAnalysisResponse,
)
async def analyze_guardian_transcript_segment(
    payload: schemas.GuardianTranscriptSegmentCreate,
    response: Response,
    request: Request,
    current_user: models.User = Depends(get_current_verified_user),
):
    rate_limit_analysis(request, current_user=current_user)
    if payload.source != "CALL_AUDIO":
        raise HTTPException(
            status_code=422,
            detail="Live AI analysis is unavailable for this audio source.",
        )
    state = _get_session_state(int(current_user.id), payload.session_id)
    return await _process_segment(state, payload, response)


@router.post(
    "/session/{session_id}/finalize",
    response_model=schemas.GuardianLiveAnalysisResponse,
)
async def finalize_guardian_analysis_session(
    session_id: UUID,
    current_user: models.User = Depends(get_current_verified_user),
):
    key = (int(current_user.id), session_id)
    with _session_lock:
        state = _sessions.get(key)
    if state is not None:
        async with state.lock:
            with _session_lock:
                if _sessions.get(key) is state:
                    _sessions.pop(key, None)
    return schemas.GuardianLiveAnalysisResponse(
        session_id=session_id,
        status="AI_WAITING_FOR_TRANSCRIPT",
        message="Live analysis session finalized.",
    )


def clear_guardian_analysis_sessions() -> None:
    """Clear ephemeral session state; intended for isolated test cleanup."""
    with _session_lock:
        _sessions.clear()
