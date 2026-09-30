from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Dict, Any

from auth import get_current_user
import models
import schemas
from database import get_db
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form, Body
from app.pipeline.input_router import input_router
from app.pipeline.analysis_pipeline import run_analysis_pipeline
import json

router = APIRouter(prefix="/analysis", tags=["analysis"])

@router.post("/text", response_model=schemas.AnalysisResponse)
async def analyze_text(payload: schemas.AnalysisCreate, current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        input_data = await input_router.route_and_extract(input_type="text", content=payload.content)
        return await run_analysis_pipeline(db=db, input_data=input_data, user_id=current_user.id)
    except Exception as e:
        print(f"Error during analysis: {e}")
        raise HTTPException(status_code=503, detail=str(e))

@router.post("/email", response_model=schemas.AnalysisResponse)
async def analyze_email(payload: Dict[str, Any] = Body(...), current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        input_data = await input_router.route_and_extract(input_type="email", email_data=payload)
        return await run_analysis_pipeline(db=db, input_data=input_data, user_id=current_user.id)
    except Exception as e:
        print(f"Error during analysis: {e}")
        raise HTTPException(status_code=503, detail=str(e))

@router.post("/image", response_model=schemas.AnalysisResponse)
async def analyze_image(file: UploadFile = File(...), current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        input_data = await input_router.route_and_extract(input_type="image", file=file)
        return await run_analysis_pipeline(db=db, input_data=input_data, user_id=current_user.id)
    except Exception as e:
        print(f"Error during analysis: {e}")
        raise HTTPException(status_code=503, detail=str(e))

@router.post("/pdf", response_model=schemas.AnalysisResponse)
async def analyze_pdf(file: UploadFile = File(...), current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        input_data = await input_router.route_and_extract(input_type="pdf", file=file)
        return await run_analysis_pipeline(db=db, input_data=input_data, user_id=current_user.id)
    except Exception as e:
        print(f"Error during analysis: {e}")
        raise HTTPException(status_code=503, detail=str(e))

@router.post("/audio", response_model=schemas.AnalysisResponse)
async def analyze_audio(file: UploadFile = File(...), current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    try:
        input_data = await input_router.route_and_extract(input_type="audio", file=file)
        return await run_analysis_pipeline(db=db, input_data=input_data, user_id=current_user.id)
    except Exception as e:
        print(f"Error during analysis: {e}")
        raise HTTPException(status_code=503, detail=str(e))

@router.get("/history", response_model=List[schemas.AnalysisResponse])
def get_history(current_user: models.User = Depends(get_current_user), db: Session = Depends(get_db)):
    analyses = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id).order_by(models.Analysis.created_at.desc()).all()
    
    # Populate retrieved_evidence_data for each analysis from the database relationship
    for analysis in analyses:
        analysis.retrieved_evidence_data = [
            {
                "knowledge_id": ev.knowledge_id or 0,
                "title": ev.knowledge_entry.title if ev.knowledge_entry else "Known Scam Pattern",
                "category": ev.knowledge_entry.category if ev.knowledge_entry else "Scam",
                "similarity_score": ev.similarity_score,
                "pattern": ev.content,
                "safe_action": ev.knowledge_entry.safe_action if ev.knowledge_entry else "",
                "source": ev.source_reference
            }
            for ev in analysis.retrieved_evidences
        ]
        if analysis.retrieved_evidence_data:
            analysis.evidence_status = "MATCH_FOUND"
        else:
            analysis.evidence_status = "NO_RELEVANT_MATCH"
            
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
