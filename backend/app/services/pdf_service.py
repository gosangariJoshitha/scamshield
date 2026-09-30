import fitz  # PyMuPDF
import io
import logging

logger = logging.getLogger(__name__)

class PDFService:
    def extract_text(self, file_content: bytes) -> tuple[str, dict]:
        """
        Extracts text from a PDF file byte stream using PyMuPDF.
        Returns a tuple of (extracted_text, metadata).
        """
        try:
            pdf_document = fitz.open(stream=file_content, filetype="pdf")
            extracted_text = ""
            page_count = len(pdf_document)
            
            for page_num in range(page_count):
                page = pdf_document.load_page(page_num)
                extracted_text += page.get_text() + "\n"
            
            pdf_document.close()
            
            extracted_text = extracted_text.strip()
            
            metadata = {
                "page_count": page_count,
                "extraction_engine": "PyMuPDF (fitz)"
            }
            
            return extracted_text, metadata
            
        except Exception as e:
            logger.error(f"PDF extraction failed: {str(e)}")
            raise ValueError(f"Failed to extract text from PDF: {str(e)}")
