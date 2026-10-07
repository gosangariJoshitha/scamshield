import logging
import os
from pathlib import Path
from fastapi import UploadFile, HTTPException
from schemas import NormalizedAnalysisInput
from app.services.pdf_service import PDFService
from app.services.ocr_service import OCRService
from app.services.audio_service import audio_service
import json

logger = logging.getLogger(__name__)
MAX_UPLOAD_BYTES = int(os.getenv("ANALYSIS_MAX_UPLOAD_BYTES", str(50 * 1024 * 1024)))
MAX_IMAGE_BYTES = int(os.getenv("ANALYSIS_MAX_IMAGE_BYTES", str(10 * 1024 * 1024)))
MAX_PDF_BYTES = int(os.getenv("ANALYSIS_MAX_PDF_BYTES", str(20 * 1024 * 1024)))
MAX_AUDIO_BYTES = int(os.getenv("ANALYSIS_MAX_AUDIO_BYTES", str(25 * 1024 * 1024)))
MAX_TEXT_CHARS = int(os.getenv("ANALYSIS_MAX_TEXT_CHARS", "20000"))
MAX_EMAIL_SUBJECT_CHARS = int(os.getenv("ANALYSIS_MAX_EMAIL_SUBJECT_CHARS", "998"))
MAX_EMAIL_BODY_CHARS = int(os.getenv("ANALYSIS_MAX_EMAIL_BODY_CHARS", "20000"))
MAX_EMAIL_SENDER_CHARS = int(os.getenv("ANALYSIS_MAX_EMAIL_SENDER_CHARS", "320"))
MAX_EXTRACTED_CHARS = int(os.getenv("ANALYSIS_MAX_EXTRACTED_CHARS", "30000"))
MAX_AUDIO_SECONDS = int(os.getenv("ANALYSIS_MAX_AUDIO_SECONDS", "600"))

_IMAGE_TYPES = {
    ".jpg": ({"image/jpeg"}, b"\xff\xd8\xff"),
    ".jpeg": ({"image/jpeg"}, b"\xff\xd8\xff"),
    ".png": ({"image/png"}, b"\x89PNG\r\n\x1a\n"),
    ".webp": ({"image/webp"}, b"RIFF"),
}
_AUDIO_TYPES = {
    ".mp3": ({"audio/mpeg"},),
    ".wav": ({"audio/wav", "audio/x-wav"},),
    ".m4a": ({"audio/mp4", "audio/x-m4a"},),
    ".aac": ({"audio/aac", "audio/aacp"},),
    ".ogg": ({"audio/ogg", "application/ogg"},),
    ".flac": ({"audio/flac", "audio/x-flac"},),
    ".webm": ({"audio/webm"},),
}

# Instantiate services globally so models are loaded once
pdf_service = PDFService()
ocr_service = OCRService()
async def _read_upload(file: UploadFile, max_bytes: int) -> bytes:
    effective_limit = min(MAX_UPLOAD_BYTES, max_bytes)
    file_bytes = await file.read(effective_limit + 1)
    if not file_bytes:
        raise HTTPException(status_code=400, detail="Uploaded file is empty.")
    if len(file_bytes) > effective_limit:
        raise HTTPException(
            status_code=413,
            detail="Uploaded file exceeds the allowed size limit.",
        )
    return file_bytes


def _validate_declared_type(
    file: UploadFile,
    allowed: dict[str, tuple[set[str], bytes]],
    description: str,
) -> tuple[str, bytes]:
    extension = Path(file.filename or "").suffix.lower()
    expected = allowed.get(extension)
    if expected is None:
        raise HTTPException(status_code=415, detail=f"Unsupported {description} format.")
    allowed_mime_types, signature = expected
    declared_mime = (file.content_type or "").strip().lower()
    if declared_mime and declared_mime != "application/octet-stream" and declared_mime not in allowed_mime_types:
        raise HTTPException(status_code=415, detail=f"Unsupported {description} format.")
    return extension, signature


def _has_audio_signature(extension: str, content: bytes) -> bool:
    if extension == ".wav":
        return content.startswith(b"RIFF") and content[8:12] == b"WAVE"
    if extension == ".mp3":
        return content.startswith(b"ID3") or (
            len(content) >= 2 and content[0] == 0xFF and content[1] & 0xE0 == 0xE0
        )
    if extension == ".m4a":
        return len(content) >= 12 and content[4:8] == b"ftyp"
    if extension == ".aac":
        return len(content) >= 2 and content[0] == 0xFF and content[1] & 0xF6 == 0xF0
    if extension == ".ogg":
        return content.startswith(b"OggS")
    if extension == ".flac":
        return content.startswith(b"fLaC")
    if extension == ".webm":
        return content.startswith(b"\x1a\x45\xdf\xa3")
    return False


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
            if len(content) > MAX_TEXT_CHARS:
                raise HTTPException(status_code=413, detail="Text exceeds the allowed size limit.")
            extracted_text = content.strip()
            original_text = content
            
        elif input_type == "email":
            if not email_data:
                raise HTTPException(status_code=400, detail="Email data is required")
            subject = email_data.get("subject", "")
            sender = email_data.get("sender", "")
            body = email_data.get("body", "")
            if not all(isinstance(value, str) for value in (subject, sender, body)):
                raise HTTPException(status_code=400, detail="Email fields must be text.")
            if (
                len(subject) > MAX_EMAIL_SUBJECT_CHARS
                or len(sender) > MAX_EMAIL_SENDER_CHARS
                or len(body) > MAX_EMAIL_BODY_CHARS
            ):
                raise HTTPException(status_code=413, detail="Email content exceeds the allowed size limit.")
            subject, sender, body = subject.strip(), sender.strip(), body.strip()
            
            email_parts = []
            if subject: email_parts.append(f"Subject: {subject}")
            if sender: email_parts.append(f"From: {sender}")
            if body: email_parts.append(f"Body:\n{body}")
            
            extracted_text = "\n\n".join(email_parts)
            original_text = json.dumps(
                {"subject": subject, "sender": sender, "body": body},
                ensure_ascii=False,
            )
            metadata = {"has_subject": bool(subject), "has_sender": bool(sender)}
            
        elif input_type == "pdf":
            if not file:
                raise HTTPException(status_code=400, detail="PDF file is required")
            
            original_filename = file.filename
            extension = Path(file.filename or "").suffix.lower()
            if extension != ".pdf":
                raise HTTPException(status_code=415, detail="Unsupported PDF format.")
            declared_mime = (file.content_type or "").strip().lower()
            if declared_mime and declared_mime not in {"application/pdf", "application/octet-stream"}:
                raise HTTPException(status_code=415, detail="Unsupported PDF format.")
            file_bytes = await _read_upload(file, MAX_PDF_BYTES)
            if not file_bytes.startswith(b"%PDF-"):
                raise HTTPException(status_code=400, detail="Uploaded file is not a valid PDF.")
            
            extracted_text, metadata = pdf_service.extract_text(file_bytes)
            
        elif input_type == "image" or input_type == "screenshot":
            input_type = "image"
            if not file:
                raise HTTPException(status_code=400, detail="Image file is required")
            
            original_filename = file.filename
            extension, signature = _validate_declared_type(file, _IMAGE_TYPES, "image")
            file_bytes = await _read_upload(file, MAX_IMAGE_BYTES)
            if not file_bytes.startswith(signature):
                raise HTTPException(status_code=400, detail="Uploaded file is not a valid image.")
            if extension == ".webp" and file_bytes[8:12] != b"WEBP":
                raise HTTPException(status_code=400, detail="Uploaded file is not a valid image.")
            
            extracted_text, metadata = ocr_service.extract_text(file_bytes, image_language)
            
        elif input_type == "audio":
            if not file:
                raise HTTPException(status_code=400, detail="Audio file is required")
            
            original_filename = file.filename
            audio_extension = Path(file.filename or "").suffix.lower()
            audio_type = _AUDIO_TYPES.get(audio_extension)
            if audio_type is None:
                raise HTTPException(status_code=415, detail="Unsupported audio format.")
            declared_mime = (file.content_type or "").strip().lower()
            if declared_mime and declared_mime != "application/octet-stream" and declared_mime not in audio_type[0]:
                raise HTTPException(status_code=415, detail="Unsupported audio format.")
            file_bytes = await _read_upload(file, MAX_AUDIO_BYTES)
            if not _has_audio_signature(audio_extension, file_bytes):
                raise HTTPException(status_code=400, detail="Uploaded file is not a valid audio file.")
            audio_filename = file.filename or f"audio{audio_extension}"
            extracted_text, metadata = audio_service.extract_text(file_bytes, audio_filename)
            if metadata.get("duration_seconds", 0) > MAX_AUDIO_SECONDS:
                raise HTTPException(status_code=413, detail="Audio exceeds the allowed duration limit.")
            
        else:
            raise HTTPException(status_code=400, detail=f"Unsupported input type: {input_type}")

        if not extracted_text or not extracted_text.strip():
            raise HTTPException(status_code=400, detail="No readable content could be extracted.")
        if len(extracted_text) > MAX_EXTRACTED_CHARS:
            raise HTTPException(status_code=413, detail="Extracted content exceeds the allowed size limit.")

        return NormalizedAnalysisInput(
            input_type=input_type,
            original_filename=original_filename,
            original_text=original_text,
            extracted_text=extracted_text,
            metadata=metadata
        )

input_router = InputRouter()
