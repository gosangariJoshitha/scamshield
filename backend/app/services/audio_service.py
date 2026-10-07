import os
import tempfile
import logging
import av
import threading
from dataclasses import dataclass
from datetime import datetime, timezone

import numpy as np
from fastapi import HTTPException
from faster_whisper import WhisperModel

logger = logging.getLogger(__name__)
MAX_AUDIO_SECONDS = int(os.getenv("ANALYSIS_MAX_AUDIO_SECONDS", "600"))
MAX_EXTRACTED_CHARS = int(os.getenv("ANALYSIS_MAX_EXTRACTED_CHARS", "30000"))
WHISPER_MODEL_NAME = os.getenv("WHISPER_MODEL", "tiny").strip().lower()
WHISPER_SUPPORTED_MODELS = {"tiny", "base", "small"}
WHISPER_CHUNK_SAMPLE_RATE = 16_000
WHISPER_CHUNK_CHANNELS = 1
WHISPER_CHUNK_MAX_SECONDS = 5
WHISPER_CHUNK_MAX_BYTES = (
    WHISPER_CHUNK_SAMPLE_RATE
    * WHISPER_CHUNK_CHANNELS
    * 2
    * WHISPER_CHUNK_MAX_SECONDS
)
SUPPORTED_AUDIO_CODECS = {
    "aac", "alac", "flac", "mp2", "mp3", "opus", "pcm_f32le",
    "pcm_s16le", "pcm_s24le", "pcm_s32le", "pcm_u8", "vorbis",
}


@dataclass(frozen=True)
class TranscriptionSegment:
    segment_id: str
    sequence: int
    start_time: float
    end_time: float
    text: str
    is_final: bool
    language: str
    created_at: datetime

    def as_dict(self, session_id: str) -> dict:
        return {
            "session_id": session_id,
            "segment_id": self.segment_id,
            "sequence": self.sequence,
            "start_time": self.start_time,
            "end_time": self.end_time,
            "text": self.text,
            "is_final": self.is_final,
            "language": self.language,
            "created_at": self.created_at,
        }


class AudioService:
    def __init__(self):
        if WHISPER_MODEL_NAME not in WHISPER_SUPPORTED_MODELS:
            raise ValueError(
                "WHISPER_MODEL must be one of: tiny, base, small."
            )
        self.model_name = WHISPER_MODEL_NAME
        self._model_lock = threading.Lock()
        self.model: WhisperModel | None = None

    def _ensure_model(self) -> WhisperModel:
        if self.model is not None:
            return self.model
        with self._model_lock:
            if self.model is not None:
                return self.model
            logger.info("Initializing faster-whisper model (%s)...", self.model_name)
            try:
                self.model = WhisperModel(
                    self.model_name,
                    device=os.getenv("WHISPER_DEVICE", "cpu"),
                    compute_type=os.getenv("WHISPER_COMPUTE_TYPE", "int8"),
                )
            except Exception as error:
                logger.error(
                    "Faster-Whisper initialization failed (%s).",
                    type(error).__name__,
                )
                raise RuntimeError(
                    "Transcription is temporarily unavailable."
                ) from error
            return self.model

    def transcribe_pcm_chunk(
        self,
        *,
        pcm_bytes: bytes,
        chunk_id: str,
        sequence: int,
        chunk_start_seconds: float,
        language: str | None = None,
    ) -> list[TranscriptionSegment]:
        if not pcm_bytes or len(pcm_bytes) % 2:
            raise ValueError("PCM audio chunk has an invalid byte length.")
        if len(pcm_bytes) > WHISPER_CHUNK_MAX_BYTES:
            raise HTTPException(
                status_code=413,
                detail="Audio chunk exceeds the allowed duration.",
            )

        waveform = np.frombuffer(pcm_bytes, dtype="<i2").astype(np.float32)
        waveform /= 32768.0
        model = self._ensure_model()
        with self._model_lock:
            segments, info = model.transcribe(
                waveform,
                beam_size=1,
                language=language,
                condition_on_previous_text=False,
                vad_filter=False,
            )
            normalized = [
                TranscriptionSegment(
                    segment_id=f"{chunk_id}:{index}",
                    sequence=sequence,
                    start_time=max(0.0, chunk_start_seconds + float(segment.start)),
                    end_time=max(0.0, chunk_start_seconds + float(segment.end)),
                    text=segment.text.strip(),
                    is_final=True,
                    language=info.language or "und",
                    created_at=datetime.now(timezone.utc),
                )
                for index, segment in enumerate(segments)
                if segment.text.strip()
            ]
        return normalized

    def extract_text(self, file_content: bytes, filename: str) -> tuple[str, dict]:
        """
        Extracts transcript from an audio file byte stream.
        faster_whisper requires a file path or a file-like object.
        Returns a tuple of (extracted_text, metadata).
        """
        # Save bytes to a temporary file
        fd, temp_path = tempfile.mkstemp(suffix=os.path.splitext(filename)[1])
        try:
            with os.fdopen(fd, 'wb') as f:
                f.write(file_content)

            with av.open(temp_path) as container:
                audio_streams = container.streams.audio
                if not audio_streams:
                    raise ValueError("Audio stream is missing.")
                duration = (
                    container.duration / av.time_base
                    if container.duration is not None
                    else None
                )
                if duration is None:
                    stream = audio_streams[0]
                    if stream.duration is not None and stream.time_base is not None:
                        duration = float(stream.duration * stream.time_base)
                if duration is None or duration <= 0:
                    raise ValueError("Audio duration could not be verified.")
                if duration > MAX_AUDIO_SECONDS:
                    raise HTTPException(
                        status_code=413,
                        detail="Audio exceeds the allowed duration limit.",
                    )
                if any(
                    stream.codec_context.name not in SUPPORTED_AUDIO_CODECS
                    for stream in audio_streams
                ):
                    raise ValueError("Unsupported audio codec.")

            model = self._ensure_model()
            with self._model_lock:
                segments, info = model.transcribe(temp_path, beam_size=5)
                extracted_parts = []
                extracted_length = 0
                for segment in segments:
                    extracted_length += len(segment.text) + 1
                    if extracted_length > MAX_EXTRACTED_CHARS:
                        raise HTTPException(
                            status_code=413,
                            detail="Extracted content exceeds the allowed size limit.",
                        )
                    extracted_parts.append(segment.text)

            extracted_text = " ".join(extracted_parts).strip()
            
            metadata = {
                "transcription_engine": f"faster-whisper ({self.model_name})",
                "detected_language": info.language,
                "language_probability": round(info.language_probability, 2),
                "duration_seconds": round(info.duration, 2)
            }
            
            return extracted_text, metadata
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(
                "Audio transcription failed (%s).",
                type(e).__name__,
            )
            raise ValueError("Failed to transcribe audio.") from e
        finally:
            # Clean up temporary file
            try:
                os.remove(temp_path)
            except OSError as error:
                logger.warning(
                    "Failed to delete temporary audio file (%s).",
                    type(error).__name__,
                )


audio_service = AudioService()
