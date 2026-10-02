import easyocr
import io
import logging
from threading import Lock
from PIL import Image
import numpy as np

logger = logging.getLogger(__name__)

class OCRService:
    def __init__(self):
        logger.info("Initializing EasyOCR model...")
        self.readers = {"en": easyocr.Reader(["en"], gpu=False)}
        self.reader_lock = Lock()

    def _get_reader(self, language: str):
        if language not in {"en", "hi", "te"}:
            raise ValueError(f"Unsupported OCR language: {language}")

        with self.reader_lock:
            if language not in self.readers:
                logger.info("Loading EasyOCR reader for language %s", language)
                self.readers[language] = easyocr.Reader([language, "en"], gpu=False)
            return self.readers[language]

    def extract_text(self, file_content: bytes, language: str = "en") -> tuple[str, dict]:
        """
        Extracts text from an image byte stream using EasyOCR.
        Returns a tuple of (extracted_text, metadata).
        """
        try:
            # Convert bytes to numpy array which EasyOCR expects
            image = Image.open(io.BytesIO(file_content))
            
            # Convert image to RGB if not already
            if image.mode != 'RGB':
                image = image.convert('RGB')
                
            image_np = np.array(image)
            
            # Run OCR
            results = self._get_reader(language).readtext(image_np)
            
            extracted_text = ""
            confidences = []
            
            for (bbox, text, prob) in results:
                extracted_text += text + "\n"
                confidences.append(prob)
                
            extracted_text = extracted_text.strip()
            
            avg_confidence = sum(confidences) / len(confidences) if confidences else None
            
            metadata = {
                "ocr_engine": "EasyOCR",
                "ocr_language": language,
                "average_confidence": round(avg_confidence, 2) if avg_confidence is not None else None,
                "detected_blocks": len(results)
            }
            
            return extracted_text, metadata
            
        except Exception as e:
            logger.error(f"OCR extraction failed: {str(e)}")
            raise ValueError(f"Failed to extract text from image: {str(e)}")
