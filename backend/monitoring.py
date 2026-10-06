import json
import logging
import os
from datetime import date, datetime, timedelta, timezone
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import case, desc, func, text
from sqlalchemy.orm import Session

import models
from app.services.rag_service import rag_service
from auth import get_current_user
from database import get_db

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/admin/monitoring", tags=["monitoring"])
REPOSITORY_ROOT = Path(__file__).resolve().parents[1]


def require_admin(current_user: models.User = Depends(get_current_user)):
    if current_user.role != "admin" or not current_user.is_active:
        raise HTTPException(status_code=403, detail="Admin privileges required")
    return current_user


def _read_report(filename: str):
    path = REPOSITORY_ROOT / "ml" / "reports" / filename
    if not path.is_file():
        return None
    try:
        with path.open(encoding="utf-8") as report_file:
            return json.load(report_file)
    except (OSError, json.JSONDecodeError):
        logger.exception("Unable to read monitoring report %s", path)
        return None


def _active_model_status():
    model_dir = REPOSITORY_ROOT / "ml" / "models" / "classifier"
    metadata_path = model_dir / "model_metadata.json"
    try:
        metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        logger.exception("Unable to read active classifier metadata.")
        return None, False

    artifact_paths = metadata.get("artifact_paths") or {
        "classifier": "scamshield-classifier-v5/scam_classifier.joblib",
        "vectorizer": "scamshield-classifier-v5/tfidf_vectorizer.joblib",
    }
    files = []
    for key in ("classifier", "vectorizer"):
        relative_path = artifact_paths.get(key)
        if not isinstance(relative_path, str):
            return metadata.get("model_version"), False
        candidate = (model_dir / relative_path).resolve()
        try:
            candidate.relative_to(model_dir.resolve())
        except ValueError:
            logger.error("Active classifier metadata contains an invalid artifact path.")
            return metadata.get("model_version"), False
        files.append(candidate.is_file())
    return metadata.get("model_version"), all(files)


@router.get("/overview")
def get_monitoring_overview(
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin),
):
    performance = db.query(
        func.count(models.AnalysisPerformance.id),
        func.avg(models.AnalysisPerformance.total_ms),
        func.avg(models.AnalysisPerformance.llm_ms),
        func.sum(case(
            (models.AnalysisPerformance.status == "SUCCESS", 1),
            else_=0,
        )),
        func.sum(case(
            (models.AnalysisPerformance.status == "FALLBACK", 1),
            else_=0,
        )),
        func.sum(case(
            (models.AnalysisPerformance.status == "ERROR", 1),
            else_=0,
        )),
    ).first()
    total = int(performance[0] or 0)
    success_count = int(performance[3] or 0)
    fallback_count = int(performance[4] or 0)
    failed = int(performance[5] or 0)
    active_users = db.query(models.User).filter(models.User.is_active.is_(True)).count()
    latest_analysis = db.query(func.max(models.Analysis.created_at)).scalar()

    return {
        "period": "All time",
        "model": _read_report("metrics.json"),
        "rag": _read_report("rag_metrics.json"),
        "llm": {
            "success_rate": success_count / total if total else None,
            "fallback_rate": fallback_count / total if total else None,
            "average_latency_ms": float(performance[2]) if performance[2] is not None else None,
            "total_recorded": total,
        },
        "system": {
            "total_analyses": db.query(models.Analysis).count(),
            "recorded_analyses": total,
            "average_analysis_time_ms": float(performance[1]) if performance[1] is not None else None,
            "errors": failed,
            "active_users": active_users,
            "last_analysis_at": latest_analysis,
        },
    }


@router.get("/activity")
def get_analysis_activity(
    days: int = 7,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin),
):
    if days not in (7, 30, 90):
        raise HTTPException(status_code=422, detail="days must be 7, 30, or 90")

    today = datetime.now(timezone.utc).date()
    start_date = today - timedelta(days=days - 1)
    grouped = db.query(
        func.date(models.Analysis.created_at),
        models.Analysis.input_type,
        func.count(models.Analysis.id),
    ).filter(
        models.Analysis.created_at >= datetime.combine(start_date, datetime.min.time(), timezone.utc)
    ).group_by(
        func.date(models.Analysis.created_at),
        models.Analysis.input_type,
    ).all()

    by_day = {}
    channels = set()
    for day, channel, count in grouped:
        if day is None:
            continue
        day_key = day.isoformat() if isinstance(day, date) else str(day)
        channel_name = (channel or "unknown").lower()
        channels.add(channel_name)
        by_day.setdefault(day_key, {})[channel_name] = int(count)

    results = []
    for offset in range(days - 1, -1, -1):
        day_key = (today - timedelta(days=offset)).isoformat()
        counts = by_day.get(day_key, {})
        results.append({
            "date": day_key,
            "total": sum(counts.values()),
            **{channel: counts.get(channel, 0) for channel in sorted(channels)},
        })
    return {"days": days, "channels": sorted(channels), "items": results}


@router.get("/performance")
def get_performance_details(
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin),
):
    fields = (
        "extraction_ms", "preprocessing_ms", "ml_ms", "embedding_ms",
        "rag_ms", "llm_ms",
        "risk_engine_ms", "database_ms", "total_ms",
    )
    averages = db.query(*[
        func.avg(getattr(models.AnalysisPerformance, field)) for field in fields
    ]).first()
    stages = {
        field: float(value) if value is not None else None
        for field, value in zip(fields, averages)
    }
    return {"stages": stages}


@router.get("/channels")
def get_channel_performance(
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin),
):
    rows = db.query(
        models.AnalysisPerformance.input_type,
        func.count(models.AnalysisPerformance.id),
        func.sum(case(
            (models.AnalysisPerformance.status.in_(["SUCCESS", "FALLBACK"]), 1),
            else_=0,
        )),
        func.sum(case(
            (models.AnalysisPerformance.status == "FALLBACK", 1),
            else_=0,
        )),
        func.avg(models.AnalysisPerformance.total_ms),
    ).group_by(models.AnalysisPerformance.input_type).all()
    result = {}
    for channel, count, successes, fallbacks, latency in rows:
        count = int(count or 0)
        success = int(successes or 0)
        fallback = int(fallbacks or 0)
        result[channel or "unknown"] = {
            "count": count,
            "success": success,
            "failure": count - success,
            "fallback": fallback,
            "average_latency_ms": float(latency) if latency is not None else None,
            "success_rate": success / count if count else None,
            "fallback_rate": fallback / count if count else None,
        }
    return result


@router.get("/logs")
def get_monitoring_logs(
    skip: int = 0,
    limit: int = 10,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin),
):
    limit = min(max(limit, 1), 100)
    query = db.query(models.AuditLog)
    total = query.count()
    logs = query.order_by(desc(models.AuditLog.created_at)).offset(max(skip, 0)).limit(limit).all()
    return {
        "items": [
            {
                "id": item.id,
                "actor": item.actor.email if item.actor else f"Actor {item.actor_id}",
                "action": item.action,
                "resource_type": item.resource_type,
                "resource_id": item.resource_id,
                "result": item.result,
                "created_at": item.created_at,
            }
            for item in logs
        ],
        "total": total,
    }


@router.get("/health")
def get_system_health(
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin),
):
    active_model_version, active_model_available = _active_model_status()
    health = {
        "api": "Healthy",
        "database": "Healthy",
        "ml_model": "Healthy" if active_model_available else "Unavailable",
        "model_version": active_model_version,
        "chromadb": "UNAVAILABLE",
        "chromadb_vectors": None,
        "chromadb_expected_minimum": rag_service.get_index_health()["expected_minimum"],
        "embedding": "Configured",
        "llm": "Configured" if os.getenv("GROQ_API_KEY") else "Not Configured",
    }

    try:
        db.execute(text("SELECT 1"))
    except Exception:
        logger.exception("Database health check failed")
        health["database"] = "Unavailable"

    rag_health = rag_service.get_index_health()
    health["chromadb"] = rag_health["status"]
    health["chromadb_vectors"] = rag_health["vector_count"]
    health["chromadb_expected_minimum"] = rag_health["expected_minimum"]

    return health
