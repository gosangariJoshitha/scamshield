from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Dict, Any
from pydantic import BaseModel

from auth import get_current_user
import models
import schemas
from database import get_db

router = APIRouter(prefix="/analysis", tags=["analysis"])

@router.post("/run", response_model=schemas.AnalysisResponse)
def run_analysis(payload: schemas.AnalysisCreate, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    # This is the "mock" logic for M1 that now actually creates DB entries
    # so the frontend can treat it as a real endpoint.
    
    mock_risk_score = 87
    mock_risk_level = "HIGH"
    mock_classification = "SCAM"
    mock_ml_prob = 0.91
    mock_category = "Bank KYC Scam"
    mock_indicators = ["Urgency", "Suspicious URL", "KYC request"]
    mock_explanation = "This message is flagged as a high-risk scam. It displays high urgency, asks for sensitive KYC information, and contains a suspicious URL that does not match the official bank domain."
    mock_evidence = ["Similar scam reported 200 times this week.", "Domain registered 2 days ago."]
    mock_recommended = "Do not click the link. Verify directly through the official bank application."

    analysis_db = models.Analysis(
        user_id=current_user.id,
        content=payload.content,
        risk_score=mock_risk_score,
        risk_level=mock_risk_level,
        classification=mock_classification,
        ml_probability=mock_ml_prob,
        category=mock_category,
        indicators=mock_indicators,
        explanation=mock_explanation,
        evidence=mock_evidence,
        recommended_action=mock_recommended
    )
    
    db.add(analysis_db)
    db.commit()
    db.refresh(analysis_db)
    return analysis_db

@router.get("/history", response_model=List[schemas.AnalysisResponse])
def get_history(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    analyses = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id).order_by(models.Analysis.created_at.desc()).all()
    return analyses

@router.get("/dashboard", response_model=schemas.DashboardStats)
def get_dashboard_stats(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    total = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id).count()
    scams = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id, models.Analysis.classification == "SCAM").count()
    safe = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id, models.Analysis.classification == "SAFE").count()
    high_risk = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id, models.Analysis.risk_level == "HIGH").count()
    
    return schemas.DashboardStats(
        total_analyses=total,
        scams_detected=scams,
        safe_messages=safe,
        high_risk=high_risk
    )
