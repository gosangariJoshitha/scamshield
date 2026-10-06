import fitz  # PyMuPDF
import io
import logging
import os
from fastapi import HTTPException

logger = logging.getLogger(__name__)
MAX_PDF_PAGES = int(os.getenv("ANALYSIS_MAX_PDF_PAGES", "100"))
MAX_EXTRACTED_CHARS = int(os.getenv("ANALYSIS_MAX_EXTRACTED_CHARS", "30000"))

class PDFService:
    def extract_text(self, file_content: bytes) -> tuple[str, dict]:
        """
        Extracts text from a PDF file byte stream using PyMuPDF.
        Returns a tuple of (extracted_text, metadata).
        """
        try:
            pdf_document = fitz.open(stream=file_content, filetype="pdf")
            page_count = len(pdf_document)
            if page_count > MAX_PDF_PAGES:
                pdf_document.close()
                raise HTTPException(
                    status_code=413,
                    detail="PDF exceeds the allowed page limit.",
                )

            extracted_parts = []
            extracted_length = 0
            for page_num in range(page_count):
                page = pdf_document.load_page(page_num)
                page_text = page.get_text()
                extracted_length += len(page_text) + 1
                if extracted_length > MAX_EXTRACTED_CHARS:
                    pdf_document.close()
                    raise HTTPException(
                        status_code=413,
                        detail="Extracted content exceeds the allowed size limit.",
                    )
                extracted_parts.append(page_text)

            pdf_document.close()
            extracted_text = "\n".join(extracted_parts).strip()
            
            metadata = {
                "page_count": page_count,
                "extraction_engine": "PyMuPDF (fitz)"
            }
            
            return extracted_text, metadata
            
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"PDF extraction failed: {str(e)}")
            raise ValueError(f"Failed to extract text from PDF: {str(e)}")
