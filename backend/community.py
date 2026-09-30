from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List

from auth import get_current_user
import models
import schemas
from database import get_db

router = APIRouter(prefix="/community", tags=["community"])

@router.post("/reports", response_model=schemas.CommunityReportResponse)
def create_report(payload: schemas.CommunityReportCreate, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    report_db = models.CommunityReport(
        user_id=current_user.id,
        content=payload.content,
        category=payload.category,
        description=payload.description,
        evidence=payload.evidence,
        status="Pending"
    )
    db.add(report_db)
    db.commit()
    db.refresh(report_db)
    return report_db

@router.get("/reports", response_model=List[schemas.CommunityReportResponse])
def get_reports(db: Session = Depends(get_db)):
    # Community reports are public for all authenticated users
    reports = db.query(models.CommunityReport).order_by(models.CommunityReport.created_at.desc()).all()
    return reports
