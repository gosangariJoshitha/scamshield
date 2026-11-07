from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from auth import get_current_user, get_current_verified_user
import models
from database import get_db
from schemas import (
    CommunityReportCreate,
    CommunityReportResponse,
    CommunityReportFlagCreate,
    CommunityReportFlagResponse,
)

router = APIRouter(prefix="/community", tags=["community"])

@router.post("/reports", response_model=CommunityReportResponse)
def create_report(
    payload: CommunityReportCreate,
    current_user: models.User = Depends(get_current_verified_user),
    db: Session = Depends(get_db),
):
    content = payload.content.strip()
    category = payload.category.strip()
    if not content:
        raise HTTPException(status_code=422, detail="Report content cannot be empty.")
    if not category:
        raise HTTPException(status_code=422, detail="Category cannot be empty.")

    if payload.analysis_id is not None:
        analysis = db.query(models.Analysis).filter(
            models.Analysis.id == payload.analysis_id,
            models.Analysis.user_id == current_user.id,
        ).first()
        if analysis is None:
            raise HTTPException(status_code=404, detail="Analysis not found")

    report_db = models.CommunityReport(
        user_id=current_user.id,
        analysis_id=payload.analysis_id,
        content=content,
        category=category,
        description=payload.description.strip() if payload.description else None,
        evidence=payload.evidence.strip() if payload.evidence else None,
        status="Pending"
    )
    db.add(report_db)
    db.commit()
    db.refresh(report_db)
    return {
        "id": report_db.id,
        "user_id": report_db.user_id,
        "content": report_db.content,
        "category": report_db.category,
        "description": report_db.description,
        "evidence": report_db.evidence,
        "analysis_id": report_db.analysis_id,
        "reporter_name": current_user.full_name,
        "status": report_db.status,
        "created_at": report_db.created_at,
    }

@router.get("/reports", response_model=List[CommunityReportResponse])
def get_reports(
    db: Session = Depends(get_db),
    _current_user: models.User = Depends(get_current_user),
):
    # Community reports are visible to authenticated users in either portal,
    # excluding removed/rejected items.
    reports = (
        db.query(models.CommunityReport, models.User.full_name)
        .outerjoin(models.User, models.CommunityReport.user_id == models.User.id)
        .filter(models.CommunityReport.status.notin_(["REMOVED", "REJECTED"]))
        .order_by(models.CommunityReport.created_at.desc())
        .all()
    )
    return [
        {
            "id": report.id,
            "user_id": report.user_id,
            "content": report.content,
            "category": report.category,
            "description": report.description,
            "evidence": report.evidence,
            "analysis_id": report.analysis_id,
            "reporter_name": reporter_name or "Community member",
            "status": report.status,
            "created_at": report.created_at,
        }
        for report, reporter_name in reports
    ]

@router.post(
    "/reports/{report_id}/flag",
    response_model=CommunityReportFlagResponse,
    status_code=status.HTTP_201_CREATED,
)
def flag_report(
    report_id: int,
    payload: CommunityReportFlagCreate,
    current_user: models.User = Depends(get_current_verified_user),
    db: Session = Depends(get_db),
):
    reason = payload.reason.strip()
    if not reason:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="A reason is required to flag content for moderation.",
        )

    report = db.query(models.CommunityReport).filter(models.CommunityReport.id == report_id).first()
    if report is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Community report not found")

    existing_flag = db.query(models.CommunityReportFlag).filter(
        models.CommunityReportFlag.report_id == report_id,
        models.CommunityReportFlag.reporter_user_id == current_user.id,
    ).first()
    if existing_flag is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="You have already flagged this report for moderator review.",
        )

    flag = models.CommunityReportFlag(
        report_id=report_id,
        reporter_user_id=current_user.id,
        reason=reason,
    )
    db.add(flag)
    db.commit()
    db.refresh(flag)
    return flag
