import io
import os
import tempfile
import logging
import av
from fastapi import HTTPException
from faster_whisper import WhisperModel

logger = logging.getLogger(__name__)
MAX_AUDIO_SECONDS = int(os.getenv("ANALYSIS_MAX_AUDIO_SECONDS", "600"))
MAX_EXTRACTED_CHARS = int(os.getenv("ANALYSIS_MAX_EXTRACTED_CHARS", "30000"))
SUPPORTED_AUDIO_CODECS = {
    "aac", "alac", "flac", "mp2", "mp3", "opus", "pcm_f32le",
    "pcm_s16le", "pcm_s24le", "pcm_s32le", "pcm_u8", "vorbis",
}

class AudioService:
    def __init__(self):
        # Initialize WhisperModel
        logger.info("Initializing faster-whisper model (tiny)...")
        # using tiny or base model to save resources
        self.model = WhisperModel("tiny", device="cpu", compute_type="int8")

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

            segments, info = self.model.transcribe(temp_path, beam_size=5)
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
                "transcription_engine": "faster-whisper (tiny)",
                "detected_language": info.language,
                "language_probability": round(info.language_probability, 2),
                "duration_seconds": round(info.duration, 2)
            }
            
            return extracted_text, metadata
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Audio transcription failed: {str(e)}")
            raise ValueError(f"Failed to transcribe audio: {str(e)}")
        finally:
            # Clean up temporary file
            try:
                os.remove(temp_path)
            except Exception as e:
                logger.warning(f"Failed to delete temp file {temp_path}: {e}")
