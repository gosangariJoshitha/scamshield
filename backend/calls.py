from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session

from auth import get_current_user
from database import get_db
import models
from schemas import (
    CallFinalizeRequest,
    CallHistoryDetailResponse,
    CallHistoryItemResponse,
    CallHistoryListResponse,
)

router = APIRouter(prefix="/calls", tags=["calls"])


@router.post("/finalize", response_model=CallHistoryDetailResponse, status_code=status.HTTP_200_OK)
def finalize_call(
    payload: CallFinalizeRequest,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Persist a completed Guardian call.
    Idempotent: If a record with this session_id already exists for this user, return it directly.
    """
    existing = (
        db.query(models.CallHistory)
        .filter(models.CallHistory.session_id == payload.session_id)
        .first()
    )
    if existing:
        if existing.user_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Call session belongs to a different user.",
            )
        return existing

    ended_at = payload.ended_at or datetime.now(timezone.utc)
    duration_seconds = payload.duration_seconds
    if duration_seconds <= 0 and payload.started_at:
        try:
            diff = (ended_at - payload.started_at).total_seconds()
            duration_seconds = max(0, int(diff))
        except Exception:
            duration_seconds = 0

    record = models.CallHistory(
        session_id=payload.session_id,
        user_id=current_user.id,
        started_at=payload.started_at,
        ended_at=ended_at,
        duration_seconds=duration_seconds,
        guardian_enabled=payload.guardian_enabled,
        guardian_status=payload.guardian_status,
        final_risk_score=payload.final_risk_score,
        final_risk_level=payload.final_risk_level,
        classification=payload.classification,
        scam_category=payload.scam_category,
        risk_reasoning=payload.risk_reasoning,
        safe_action=payload.safe_action,
        detected_indicators=payload.detected_indicators,
        supporting_evidence=payload.supporting_evidence,
        protection_actions=payload.protection_actions,
        analysis_status=payload.analysis_status,
        transcription_status=payload.transcription_status,
        audio_status=payload.audio_status,
    )
    db.add(record)
    db.commit()
    db.refresh(record)
    return record


@router.get("/history", response_model=CallHistoryListResponse)
def get_call_history(
    risk_level: Optional[str] = Query(default=None, description="Filter by risk level (LOW, MEDIUM, HIGH, CRITICAL)"),
    page: int = Query(default=1, ge=1),
    limit: int = Query(default=20, ge=1, le=100),
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Return authenticated user's protected-call history.
    """
    query = db.query(models.CallHistory).filter(models.CallHistory.user_id == current_user.id)

    if risk_level and risk_level.strip().upper() not in {"ALL", ""}:
        query = query.filter(models.CallHistory.final_risk_level == risk_level.strip().upper())

    total = query.count()
    offset = (page - 1) * limit
    items = query.order_by(models.CallHistory.ended_at.desc()).offset(offset).limit(limit).all()

    return CallHistoryListResponse(
        items=items,
        total=total,
        page=page,
        limit=limit,
        has_next=(offset + limit) < total,
    )


@router.get("/{session_id}", response_model=CallHistoryDetailResponse)
def get_call_summary(
    session_id: str,
    current_user: models.User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """
    Return one protected call summary by session_id.
    """
    record = (
        db.query(models.CallHistory)
        .filter(
            models.CallHistory.session_id == session_id,
            models.CallHistory.user_id == current_user.id,
        )
        .first()
    )
    if not record:
        # Check if exists for another user to return 403 vs 404
        other = (
            db.query(models.CallHistory)
            .filter(models.CallHistory.session_id == session_id)
            .first()
        )
        if other:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Not authorized to access this call record.",
            )
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Call record not found.",
        )
    return record
