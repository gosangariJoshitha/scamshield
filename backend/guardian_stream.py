import asyncio
import base64
import json
import logging
import time
from datetime import datetime, timezone
from typing import Optional
from uuid import UUID

from fastapi import APIRouter, WebSocket, WebSocketDisconnect, status
from jose import JWTError, jwt
from sqlalchemy.orm import Session

import database
import models
from app.services.audio_service import audio_service
from auth import ALGORITHM, SECRET_KEY

logger = logging.getLogger(__name__)

router = APIRouter(tags=["guardian"])

WHISPER_CHUNK_SAMPLE_RATE = 16_000
SUPPORTED_SOURCES = {"CALL_AUDIO", "SPEAKERPHONE_AUDIO"}


def _authenticate_ws(token: Optional[str], db: Session) -> Optional[models.User]:
    if not token:
        return None
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            return None
        user = db.query(models.User).filter(models.User.id == int(user_id)).first()
        if user and user.is_active:
            return user
        return None
    except (JWTError, ValueError):
        return None


@router.websocket("/guardian/stream/{session_id}")
async def guardian_stream_endpoint(
    websocket: WebSocket,
    session_id: str,
):
    token = websocket.query_params.get("token")
    if not token:
        sec_protocol = websocket.headers.get("sec-websocket-protocol")
        if sec_protocol:
            token = sec_protocol.split(",")[-1].strip()

    db: Session = next(database.get_db())
    try:
        user = _authenticate_ws(token, db)
        if not user:
            await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
            return

        await websocket.accept()

        accumulated_text: list[str] = []
        call_started_at = time.time()
        last_risk_score = 0
        last_risk_level = "LOW"
        last_classification = "GENUINE"
        last_category = "General"
        detected_indicators: list[str] = []
        safe_action = "Stay vigilant. Do not share personal financial information."
        sequence = 0
        emergency_alert_dispatched = False

        # Send connection confirmation
        await websocket.send_json({
            "type": "connected",
            "session_id": session_id,
            "user_id": user.id,
            "status": "READY",
            "timestamp": time.time(),
        })

        while True:
            try:
                message = await websocket.receive()
            except WebSocketDisconnect:
                break

            pcm_bytes: Optional[bytes] = None
            text_input: Optional[str] = None

            if "bytes" in message and message["bytes"]:
                pcm_bytes = message["bytes"]
            elif "text" in message and message["text"]:
                try:
                    payload = json.loads(message["text"])
                except Exception:
                    payload = {"type": "text", "content": message["text"]}

                msg_type = payload.get("type", "")

                if msg_type == "ping":
                    await websocket.send_json({"type": "pong", "timestamp": time.time()})
                    continue
                elif msg_type == "init":
                    await websocket.send_json({
                        "type": "init_ack",
                        "session_id": session_id,
                        "source": payload.get("source", "SPEAKERPHONE_AUDIO"),
                    })
                    continue
                elif msg_type == "end":
                    break
                elif msg_type in ("audio", "audio_chunk") and "data" in payload:
                    try:
                        pcm_bytes = base64.b64decode(payload["data"])
                    except Exception:
                        await websocket.send_json({"type": "error", "message": "Invalid base64 audio data"})
                        continue
                elif msg_type in ("transcript", "transcript_segment"):
                    text_input = payload.get("text", "").strip()

            new_transcript = ""
            detected_lang = "en"

            if pcm_bytes and len(pcm_bytes) >= 1000:
                sequence += 1
                chunk_id = f"chunk_{sequence}_{int(time.time()*1000)}"
                try:
                    segments = audio_service.transcribe_pcm_chunk(
                        pcm_bytes=pcm_bytes,
                        chunk_id=chunk_id,
                        sequence=sequence,
                        chunk_start_seconds=max(0.0, time.time() - call_started_at),
                    )
                    if segments:
                        new_transcript = " ".join(s.text for s in segments if s.text).strip()
                        detected_lang = segments[0].language
                except Exception as exc:
                    logger.warning("Stream transcription chunk error: %s", exc)

            elif text_input:
                new_transcript = text_input

            if new_transcript:
                accumulated_text.append(new_transcript)
                full_window = " ".join(accumulated_text)

                # Send transcript segment
                await websocket.send_json({
                    "type": "transcript",
                    "session_id": session_id,
                    "text": new_transcript,
                    "language": detected_lang,
                    "is_final": True,
                    "timestamp": time.time(),
                })

                # Incremental AI risk evaluation
                try:
                    from app.pipeline.analysis_pipeline import analyze_text_core
                    analysis_result = await analyze_text_core(
                        full_window,
                        detected_language=detected_lang,
                    )
                    if hasattr(analysis_result, "risk_result") and isinstance(analysis_result.risk_result, dict):
                        last_risk_score = analysis_result.risk_result.get("risk_score", last_risk_score)
                        last_risk_level = analysis_result.risk_result.get("risk_level", last_risk_level)
                    elif isinstance(analysis_result, dict):
                        last_risk_score = analysis_result.get("risk_score", last_risk_score)
                        last_risk_level = analysis_result.get("risk_level", last_risk_level)

                    last_classification = getattr(analysis_result, "classification", None) or (
                        analysis_result.get("classification") if isinstance(analysis_result, dict) else last_classification
                    )
                    last_category = getattr(analysis_result, "category", None) or (
                        analysis_result.get("category") if isinstance(analysis_result, dict) else last_category
                    )
                    detected_indicators = getattr(analysis_result, "final_indicators", None) or (
                        analysis_result.get("indicators") if isinstance(analysis_result, dict) else detected_indicators
                    )
                    safe_action = getattr(analysis_result, "safe_action", None) or (
                        analysis_result.get("recommended_action") if isinstance(analysis_result, dict) else safe_action
                    )
                except Exception as exc:
                    logger.warning("Live stream risk analysis failed: %s", exc)

                is_alert = last_risk_score >= 70

                await websocket.send_json({
                    "type": "risk_update",
                    "session_id": session_id,
                    "risk_score": last_risk_score,
                    "risk_level": last_risk_level,
                    "classification": last_classification,
                    "scam_category": last_category,
                    "detected_indicators": detected_indicators,
                    "safe_action": safe_action,
                    "alert_triggered": is_alert,
                    "timestamp": time.time(),
                })

                if is_alert:
                    if not emergency_alert_dispatched:
                        emergency_alert_dispatched = True
                        try:
                            from emergency_contacts import dispatch_emergency_family_alerts
                            dispatch_emergency_family_alerts(
                                user_id=user.id,
                                db=db,
                                session_id=session_id,
                                risk_score=last_risk_score,
                                detected_category=last_category,
                            )
                        except Exception as alert_exc:
                            logger.error("Failed to trigger emergency alert from stream: %s", alert_exc)

                    await websocket.send_json({
                        "type": "voice_warning",
                        "session_id": session_id,
                        "risk_score": last_risk_score,
                        "message": (
                            "Warning. Potential scam call detected. "
                            "Do not share OTP, passwords, or personal banking details."
                        ),
                    })

        # Finalize and persist summary upon normal completion
        duration = int(time.time() - call_started_at)
        final_summary = {
            "type": "final_summary",
            "session_id": session_id,
            "duration_seconds": duration,
            "final_risk_score": last_risk_score,
            "final_risk_level": last_risk_level,
            "classification": last_classification,
            "scam_category": last_category,
            "safe_action": safe_action,
            "transcript": " ".join(accumulated_text),
            "timestamp": time.time(),
        }

        try:
            await websocket.send_json(final_summary)
            await websocket.close()
        except Exception:
            pass

    finally:
        db.close()
