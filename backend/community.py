from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from auth import get_current_user, get_current_verified_user
import models
from database import get_db
from schemas import CommunityReportCreate, CommunityReportResponse

router = APIRouter(prefix="/community", tags=["community"])

@router.post("/reports", response_model=CommunityReportResponse)
def create_report(payload: CommunityReportCreate, current_user: models.User = Depends(get_current_verified_user), db: Session = Depends(get_db)):
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
        content=payload.content,
        category=payload.category,
        description=payload.description,
        evidence=payload.evidence,
        status="Pending"
    )
    db.add(report_db)
    db.commit()
    db.refresh(report_db)
    return {
        "id": report_db.id,
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
    # Community reports are visible to authenticated users in either portal.
    reports = (
        db.query(models.CommunityReport, models.User.full_name)
        .outerjoin(models.User, models.CommunityReport.user_id == models.User.id)
        .order_by(models.CommunityReport.created_at.desc())
        .all()
    )
    return [
        {
            "id": report.id,
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
