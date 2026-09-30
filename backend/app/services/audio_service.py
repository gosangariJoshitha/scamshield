import io
import os
import tempfile
import logging
from faster_whisper import WhisperModel

logger = logging.getLogger(__name__)

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
                
            segments, info = self.model.transcribe(temp_path, beam_size=5)
            
            extracted_text = ""
            for segment in segments:
                extracted_text += segment.text + " "
                
            extracted_text = extracted_text.strip()
            
            metadata = {
                "transcription_engine": "faster-whisper (tiny)",
                "detected_language": info.language,
                "language_probability": round(info.language_probability, 2),
                "duration_seconds": round(info.duration, 2)
            }
            
            return extracted_text, metadata
            
        except Exception as e:
            logger.error(f"Audio transcription failed: {str(e)}")
            raise ValueError(f"Failed to transcribe audio: {str(e)}")
        finally:
            # Clean up temporary file
            try:
                os.remove(temp_path)
            except Exception as e:
                logger.warning(f"Failed to delete temp file {temp_path}: {e}")
