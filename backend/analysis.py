import logging
import time
from typing import Any, Dict, List, Literal

from fastapi import APIRouter, BackgroundTasks, Body, Depends, File, Form, HTTPException, UploadFile
from sqlalchemy.orm import Session

from auth import get_current_regular_user
import models
import schemas
from database import get_db
from app.pipeline.input_router import input_router
from app.pipeline.analysis_pipeline import run_analysis_pipeline


logger = logging.getLogger(__name__)
router = APIRouter(prefix="/analysis", tags=["analysis"])


def _raise_analysis_error(error: Exception) -> None:
    if isinstance(error, HTTPException):
        raise error
    if isinstance(error, ValueError):
        logger.warning("Analysis input was rejected.")
        raise HTTPException(
            status_code=400,
            detail="The supplied input could not be processed.",
        ) from error
    logger.exception("Analysis request failed.")
    raise HTTPException(
        status_code=503,
        detail="Analysis is temporarily unavailable.",
    ) from error


def _populate_retrieved_evidence(analysis: models.Analysis) -> None:
    analysis.retrieved_evidence_data = [
        {
            "knowledge_id": ev.knowledge_id or 0,
            "title": ev.knowledge_entry.title if ev.knowledge_entry else "Known Scam Pattern",
            "category": ev.knowledge_entry.category if ev.knowledge_entry else "Scam",
            "similarity_score": ev.similarity_score,
            "pattern": ev.content,
            "safe_action": (
                ev.localized_safe_action
                or (ev.knowledge_entry.safe_action if ev.knowledge_entry else "")
            ),
            "source": ev.source_reference,
            "language": ev.language,
        }
        for ev in analysis.retrieved_evidences
    ]
    analysis.evidence_status = (
        "MATCH_FOUND" if analysis.retrieved_evidence_data else "NO_RELEVANT_MATCH"
    )

@router.post("/text", response_model=schemas.AnalysisResponse)
async def analyze_text(
    background_tasks: BackgroundTasks,
    payload: schemas.AnalysisCreate,
    current_user: models.User = Depends(get_current_regular_user),
    db: Session = Depends(get_db),
):
    try:
        t0 = time.perf_counter()
        input_data = await input_router.route_and_extract(input_type="text", content=payload.content)
        extraction_ms = (time.perf_counter() - t0) * 1000
        return await run_analysis_pipeline(db=db, input_data=input_data, user_id=current_user.id, extraction_ms=extraction_ms, background_tasks=background_tasks)
    except Exception as error:
        _raise_analysis_error(error)

@router.post("/email", response_model=schemas.AnalysisResponse)
async def analyze_email(
    background_tasks: BackgroundTasks,
    payload: Dict[str, Any] = Body(...),
    current_user: models.User = Depends(get_current_regular_user),
    db: Session = Depends(get_db),
):
    try:
        t0 = time.perf_counter()
        input_data = await input_router.route_and_extract(input_type="email", email_data=payload)
        extraction_ms = (time.perf_counter() - t0) * 1000
        return await run_analysis_pipeline(db=db, input_data=input_data, user_id=current_user.id, extraction_ms=extraction_ms, background_tasks=background_tasks)
    except Exception as error:
        _raise_analysis_error(error)

@router.post("/image", response_model=schemas.AnalysisResponse)
async def analyze_image(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    language: Literal["en", "hi", "te"] = Form("en"),
    current_user: models.User = Depends(get_current_regular_user),
    db: Session = Depends(get_db),
):
    try:
        t0 = time.perf_counter()
        input_data = await input_router.route_and_extract(
            input_type="image", file=file, image_language=language
        )
        extraction_ms = (time.perf_counter() - t0) * 1000
        return await run_analysis_pipeline(db=db, input_data=input_data, user_id=current_user.id, extraction_ms=extraction_ms, background_tasks=background_tasks)
    except Exception as error:
        _raise_analysis_error(error)

@router.post("/pdf", response_model=schemas.AnalysisResponse)
async def analyze_pdf(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_regular_user),
    db: Session = Depends(get_db),
):
    try:
        t0 = time.perf_counter()
        input_data = await input_router.route_and_extract(input_type="pdf", file=file)
        extraction_ms = (time.perf_counter() - t0) * 1000
        return await run_analysis_pipeline(db=db, input_data=input_data, user_id=current_user.id, extraction_ms=extraction_ms, background_tasks=background_tasks)
    except Exception as error:
        _raise_analysis_error(error)

@router.post("/audio", response_model=schemas.AnalysisResponse)
async def analyze_audio(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    current_user: models.User = Depends(get_current_regular_user),
    db: Session = Depends(get_db),
):
    try:
        t0 = time.perf_counter()
        input_data = await input_router.route_and_extract(input_type="audio", file=file)
        extraction_ms = (time.perf_counter() - t0) * 1000
        return await run_analysis_pipeline(db=db, input_data=input_data, user_id=current_user.id, extraction_ms=extraction_ms, background_tasks=background_tasks)
    except Exception as error:
        _raise_analysis_error(error)

@router.get("/history", response_model=List[schemas.AnalysisResponse])
def get_history(current_user: models.User = Depends(get_current_regular_user), db: Session = Depends(get_db)):
    analyses = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id).order_by(models.Analysis.created_at.desc()).all()
    
    for analysis in analyses:
        _populate_retrieved_evidence(analysis)
            
    return analyses

@router.get("/dashboard", response_model=schemas.DashboardStats)
def get_dashboard_stats(current_user: models.User = Depends(get_current_regular_user), db: Session = Depends(get_db)):
    total = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id).count()
    scams = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id, models.Analysis.classification == "SCAM").count()
    safe = db.query(models.Analysis).filter(models.Analysis.user_id == current_user.id, models.Analysis.classification == "GENUINE").count()
    high_risk = db.query(models.Analysis).filter(
        models.Analysis.user_id == current_user.id,
        models.Analysis.risk_level.in_(["HIGH", "CRITICAL"]),
    ).count()
    
    return schemas.DashboardStats(
        total_analyses=total,
        scams_detected=scams,
        safe_messages=safe,
        high_risk=high_risk
    )

@router.get("/{analysis_id}", response_model=schemas.AnalysisResponse)
def get_analysis(
    analysis_id: int,
    current_user: models.User = Depends(get_current_regular_user),
    db: Session = Depends(get_db),
):
    analysis = db.query(models.Analysis).filter(
        models.Analysis.id == analysis_id,
        models.Analysis.user_id == current_user.id,
    ).first()
    if analysis is None:
        raise HTTPException(status_code=404, detail="Analysis not found")
    _populate_retrieved_evidence(analysis)
    return analysis
