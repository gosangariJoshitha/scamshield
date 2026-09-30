from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Dict, Any

from auth import get_current_user
import models
import schemas
from database import get_db
from app.pipeline.analysis_pipeline import run_text_analysis_pipeline

router = APIRouter(prefix="/analysis", tags=["analysis"])

@router.post("/text", response_model=schemas.AnalysisResponse)
def run_analysis(payload: schemas.AnalysisCreate, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    """
    Real M3 ML Inference Pipeline.
    Runs preprocessing, ML classifier, and Risk Engine.
    """
    try:
        result_dict = run_text_analysis_pipeline(
            db=db, 
            text=payload.content, 
            user_id=current_user.id
        )
        return result_dict
    except Exception as e:
        print(f"Error during analysis: {e}")
        # If the ML model fails or anything else, return a clear error
        raise HTTPException(status_code=503, detail="ML model is currently unavailable or an error occurred during analysis.")

@router.get("/history", response_model=List[schemas.AnalysisResponse])
def get_history(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    analyses = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id).order_by(models.Analysis.created_at.desc()).all()
    return analyses

@router.get("/dashboard", response_model=schemas.DashboardStats)
def get_dashboard_stats(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    total = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id).count()
    scams = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id, models.Analysis.classification == "SCAM").count()
    safe = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id, models.Analysis.classification == "GENUINE").count()
    high_risk = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id, models.Analysis.risk_level == "HIGH").count()
    
    return schemas.DashboardStats(
        total_analyses=total,
        scams_detected=scams,
        safe_messages=safe,
        high_risk=high_risk
    )
