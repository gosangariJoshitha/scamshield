import logging
from fastapi import UploadFile, HTTPException
from schemas import NormalizedAnalysisInput
from app.services.pdf_service import PDFService
from app.services.ocr_service import OCRService
from app.services.audio_service import AudioService
import json

logger = logging.getLogger(__name__)

# Instantiate services globally so models are loaded once
pdf_service = PDFService()
ocr_service = OCRService()
audio_service = AudioService()

class InputRouter:
    async def route_and_extract(
        self,
        input_type: str,
        content: str | None = None,
        file: UploadFile | None = None,
        email_data: dict | None = None,
        image_language: str = "en",
    ) -> NormalizedAnalysisInput:
        
        extracted_text = ""
        metadata = {}
        original_filename = None
        original_text = None

        if input_type == "text":
            if not content:
                raise HTTPException(status_code=400, detail="Text content is required")
            extracted_text = content.strip()
            original_text = content
            
        elif input_type == "email":
            if not email_data:
                raise HTTPException(status_code=400, detail="Email data is required")
            
            subject = email_data.get("subject", "").strip()
            sender = email_data.get("sender", "").strip()
            body = email_data.get("body", "").strip()
            
            email_parts = []
            if subject: email_parts.append(f"Subject: {subject}")
            if sender: email_parts.append(f"From: {sender}")
            if body: email_parts.append(f"Body:\n{body}")
            
            extracted_text = "\n\n".join(email_parts)
            original_text = json.dumps(email_data)
            metadata = {"has_subject": bool(subject), "has_sender": bool(sender)}
            
        elif input_type == "pdf":
            if not file:
                raise HTTPException(status_code=400, detail="PDF file is required")
            
            original_filename = file.filename
            file_bytes = await file.read()
            
            extracted_text, metadata = pdf_service.extract_text(file_bytes)
            
        elif input_type == "image" or input_type == "screenshot":
            input_type = "image"
            if not file:
                raise HTTPException(status_code=400, detail="Image file is required")
            
            original_filename = file.filename
            file_bytes = await file.read()
            
            extracted_text, metadata = ocr_service.extract_text(file_bytes, image_language)
            
        elif input_type == "audio":
            if not file:
                raise HTTPException(status_code=400, detail="Audio file is required")
            
            original_filename = file.filename
            file_bytes = await file.read()
            audio_extension = {
                "audio/mpeg": ".mp3",
                "audio/wav": ".wav",
                "audio/x-wav": ".wav",
                "audio/mp4": ".m4a",
                "audio/x-m4a": ".m4a",
                "audio/aac": ".aac",
                "audio/ogg": ".ogg",
                "audio/flac": ".flac",
                "audio/webm": ".webm",
            }.get(file.content_type or "", ".wav")
            audio_filename = file.filename or f"audio{audio_extension}"
            extracted_text, metadata = audio_service.extract_text(file_bytes, audio_filename)
            
        else:
            raise HTTPException(status_code=400, detail=f"Unsupported input type: {input_type}")

        if not extracted_text or not extracted_text.strip():
            raise HTTPException(status_code=400, detail="No readable content could be extracted.")

        return NormalizedAnalysisInput(
            input_type=input_type,
            original_filename=original_filename,
            original_text=original_text,
            extracted_text=extracted_text,
            metadata=metadata
        )

input_router = InputRouter()
