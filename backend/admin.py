from fastapi import APIRouter, Depends, HTTPException
import logging
import os
import time
from datetime import datetime, timedelta, timezone
from sqlalchemy.orm import Session
from sqlalchemy import String, cast, desc, func, or_, text
from typing import List, Dict, Any

from database import get_db
import models
from auth import get_current_user
from app.services.classifier_service import classifier_service
from app.services.rag_service import rag_service

logger = logging.getLogger(__name__)
router = APIRouter()

def require_admin(current_user: models.User = Depends(get_current_user)):
    if current_user.role != "admin" or not current_user.is_active:
        raise HTTPException(status_code=403, detail="Admin privileges required")
    return current_user

@router.get("/overview")
def get_admin_overview(
    days: int = 30,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin),
):
    if days not in (7, 30, 90):
        raise HTTPException(status_code=422, detail="days must be 7, 30, or 90")

    since = datetime.now(timezone.utc) - timedelta(days=days)
    analysis_query = db.query(models.Analysis).filter(models.Analysis.created_at >= since)
    report_query = db.query(models.CommunityReport).filter(models.CommunityReport.created_at >= since)

    total_analyses = analysis_query.count()
    scams_detected = analysis_query.filter(models.Analysis.classification == "SCAM").count()
    high_risk = analysis_query.filter(models.Analysis.risk_level.in_(["HIGH", "CRITICAL"])).count()
    pending_reviews = db.query(models.ReviewCase).filter(models.ReviewCase.status == "PENDING").count()
    community_reports = report_query.count()
    verified_knowledge = db.query(models.KnowledgeEntry).filter(
        models.KnowledgeEntry.status.in_(["APPROVED", "ACTIVE"])
    ).count()

    risk_dist = analysis_query.with_entities(
        models.Analysis.risk_level, 
        func.count(models.Analysis.id)
    ).group_by(models.Analysis.risk_level).all()

    today = datetime.now(timezone.utc).date()
    activity = {
        (today - timedelta(days=offset)).isoformat(): 0
        for offset in range(days - 1, -1, -1)
    }
    for bucket, count in analysis_query.with_entities(
        func.date(models.Analysis.created_at), func.count(models.Analysis.id)
    ).group_by(func.date(models.Analysis.created_at)).all():
        if bucket is not None:
            bucket_key = bucket.isoformat() if hasattr(bucket, "isoformat") else str(bucket)
            if bucket_key in activity:
                activity[bucket_key] = count

    recent_analyses = analysis_query.order_by(
        desc(models.Analysis.created_at)
    ).limit(5).all()
    recent_reviews = db.query(models.ReviewCase).filter(
        models.ReviewCase.created_at >= since
    ).order_by(
        desc(models.ReviewCase.created_at)
    ).limit(5).all()
    recent_reports = report_query.order_by(
        desc(models.CommunityReport.created_at)
    ).limit(5).all()
    review_statuses = db.query(
        models.ReviewCase.status, func.count(models.ReviewCase.id)
    ).group_by(models.ReviewCase.status).all()
    report_statuses = db.query(
        models.CommunityReport.status, func.count(models.CommunityReport.id)
    ).group_by(models.CommunityReport.status).all()

    return {
        "period_days": days,
        "totalAnalyses": total_analyses,
        "scamsDetected": scams_detected,
        "highRisk": high_risk,
        "pendingReviews": pending_reviews,
        "communityReports": community_reports,
        "verifiedKnowledge": verified_knowledge,
        "riskDistribution": [{"name": r[0] or "UNKNOWN", "value": r[1]} for r in risk_dist],
        "analysisActivity": [{"date": day, "count": count} for day, count in activity.items()],
        "reviewStatusCounts": {status: count for status, count in review_statuses},
        "reportStatusCounts": {status: count for status, count in report_statuses},
        "recentAnalyses": [
            {
                "id": a.id,
                "created_at": a.created_at,
                "input_type": a.input_type,
                "classification": a.classification,
                "risk_level": a.risk_level,
                "category": a.category,
                "user": a.user.email if a.user else "Unknown"
            } for a in recent_analyses
        ],
        "recentReviews": [
            {
                "id": review.id,
                "analysis_id": review.analysis_id,
                "status": review.status,
                "priority": review.priority,
                "created_at": review.created_at,
                "risk_level": review.analysis.risk_level if review.analysis else None,
                "input_type": review.analysis.input_type if review.analysis else None,
                "reporter": review.user.email if review.user else "Unknown",
            } for review in recent_reviews
        ],
        "recentCommunityReports": [
            {
                "id": report.id,
                "category": report.category,
                "content": report.content,
                "status": report.status,
                "created_at": report.created_at,
                "reporter": report.user.email if report.user else "Unknown",
            } for report in recent_reports
        ],
    }

@router.get("/analyses")
def get_admin_analyses(
    skip: int = 0,
    limit: int = 50,
    classification: str = None,
    risk_level: str = None,
    status: str = None,
    search: str = None,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin)
):
    query = db.query(models.Analysis)
    
    if classification:
        query = query.filter(models.Analysis.classification == classification)
    if risk_level:
        query = query.filter(models.Analysis.risk_level == risk_level)
    if status:
        if status == "COMPLETED":
            query = query.filter(models.Analysis.processing_status.ilike("COMPLETED%"))
        else:
            query = query.filter(models.Analysis.processing_status == status)
    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.outerjoin(models.User, models.Analysis.user_id == models.User.id).filter(
            or_(
                cast(models.Analysis.id, String).ilike(term),
                models.Analysis.classification.ilike(term),
                models.Analysis.category.ilike(term),
                models.Analysis.input_type.ilike(term),
                models.User.email.ilike(term),
                models.User.full_name.ilike(term),
            )
        )
        
    total = query.count()
    analyses = query.order_by(desc(models.Analysis.created_at)).offset(skip).limit(limit).all()
    
    return {
        "items": [
            {
                "id": a.id,
                "created_at": a.created_at,
                "input_type": a.input_type,
                "classification": a.classification,
                "category": a.category,
                "risk_score": a.risk_score,
                "risk_level": a.risk_level,
                "status": a.processing_status,
                "user": a.user.email if a.user else "Unknown"
            } for a in analyses
        ],
        "total": total,
        "page": (skip // limit) + 1,
        "page_size": limit,
        "total_pages": (total + limit - 1) // limit
    }

@router.get("/analyses/{analysis_id}")
def get_admin_analysis(analysis_id: int, db: Session = Depends(get_db), current_admin: models.User = Depends(require_admin)):
    analysis = db.query(models.Analysis).filter(models.Analysis.id == analysis_id).first()
    if not analysis:
        raise HTTPException(status_code=404, detail="Analysis not found")
        
    perf = db.query(models.AnalysisPerformance).filter(models.AnalysisPerformance.analysis_id == analysis_id).first()
    
    # Do not return sensitive info from user. just id and email/name
    user_info = None
    if analysis.user:
        user_info = {
            "id": analysis.user.id,
            "email": analysis.user.email,
            "full_name": analysis.user.full_name
        }
        
    perf_data = None
    if perf:
        perf_data = {k: v for k, v in perf.__dict__.items() if not k.startswith('_')}
        
    return {
        "analysis": {
            "id": analysis.id,
            "created_at": analysis.created_at,
            "input_type": analysis.input_type,
            "classification": analysis.classification,
            "category": analysis.category,
            "risk_score": analysis.risk_score,
            "risk_level": analysis.risk_level,
            "ml_probability": analysis.ml_probability,
            "llm_confidence": analysis.llm_confidence,
            "indicators": analysis.indicators,
            "processing_status": analysis.processing_status,
            "original_text": analysis.original_text or analysis.content,
            "recommended_action": analysis.recommended_action
        },
        "user": user_info,
        "performance": perf_data,
        "evidence": [
            {
                "id": ev.id,
                "type": ev.evidence_type,
                "content": ev.content,
                "similarity_score": ev.similarity_score
            } for ev in analysis.retrieved_evidences
        ]
    }

@router.get("/community/reports")
def get_admin_community_reports(
    skip: int = 0,
    limit: int = 50,
    report_id: int | None = None,
    status: str = None,
    category: str = None,
    search: str = None,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin)
):
    query = db.query(models.CommunityReport)
    if report_id is not None:
        query = query.filter(models.CommunityReport.id == report_id)
    if status:
        query = query.filter(models.CommunityReport.status == status)
    if category:
        query = query.filter(models.CommunityReport.category.ilike(f"%{category.strip()}%"))
    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.outerjoin(
            models.User, models.CommunityReport.user_id == models.User.id
        ).filter(or_(
            cast(models.CommunityReport.id, String).ilike(term),
            models.CommunityReport.content.ilike(term),
            models.CommunityReport.description.ilike(term),
            models.CommunityReport.category.ilike(term),
            models.User.email.ilike(term),
            models.User.full_name.ilike(term),
        ))
        
    total = query.count()
    reports = query.order_by(desc(models.CommunityReport.created_at)).offset(skip).limit(limit).all()
    
    return {
        "items": [
            {
                "id": r.id,
                "category": r.category,
                "content": r.content,
                "description": r.description,
                "evidence": r.evidence,
                "status": r.status,
                "created_at": r.created_at,
                "reporter": r.user.email if r.user else "Unknown"
            } for r in reports
        ],
        "total": total,
        "page": (skip // limit) + 1,
        "page_size": limit,
        "total_pages": (total + limit - 1) // limit
    }

from pydantic import BaseModel, Field
class CommunityAction(BaseModel):
    action: str
    notes: str = ""
    
@router.post("/community/reports/{report_id}/action")
def action_community_report(
    report_id: int, 
    payload: CommunityAction,
    db: Session = Depends(get_db), 
    current_admin: models.User = Depends(require_admin)
):
    report = db.query(models.CommunityReport).filter(models.CommunityReport.id == report_id).first()
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
        
    if payload.action == "VERIFY":
        report.status = "VERIFIED"
    elif payload.action == "REJECT":
        report.status = "REJECTED"
    elif payload.action == "NEEDS_INFORMATION":
        report.status = "NEEDS_INFORMATION"
    elif payload.action == "CONVERT_TO_KNOWLEDGE":
        if report.status != "VERIFIED":
            raise HTTPException(
                status_code=400,
                detail="Only verified community reports can be converted to knowledge",
            )
        existing_entry = db.query(models.KnowledgeEntry).filter(
            models.KnowledgeEntry.source_type == "VERIFIED_COMMUNITY_REPORT",
            models.KnowledgeEntry.source_reference == str(report.id),
        ).first()
        if existing_entry:
            raise HTTPException(status_code=409, detail="This report is already in the knowledge base")
        k_entry = models.KnowledgeEntry(
            title=f"Community Verified: {report.category or 'Scam pattern'}",
            pattern=report.content,
            category=report.category or "COMMUNITY_REPORT",
            description=report.description,
            indicators=[],
            safe_action="Verify through an official channel before taking action.",
            risk_level="HIGH",
            source="Verified Community Report",
            source_type="VERIFIED_COMMUNITY_REPORT",
            source_reference=str(report.id),
            status="APPROVED"
        )
        db.add(k_entry)
        db.flush()
        rag_service.upsert_knowledge_entry(k_entry)
    else:
        raise HTTPException(status_code=400, detail="Invalid action")

    audit = models.AuditLog(
        actor_id=current_admin.id,
        action=f"COMMUNITY_{payload.action}",
        resource_type="COMMUNITY_REPORT",
        resource_id=str(report.id),
        result="SUCCESS",
        details={"notes": payload.notes}
    )
    db.add(audit)
    db.commit()
    return {
        "status": "success",
        "report_status": report.status,
        "knowledge_id": k_entry.id if payload.action == "CONVERT_TO_KNOWLEDGE" else None,
    }

@router.get("/knowledge")
def get_admin_knowledge(
    skip: int = 0,
    limit: int = 50,
    status: str = None,
    category: str = None,
    search: str = None,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin)
):
    query = db.query(models.KnowledgeEntry)
    if status:
        query = query.filter(models.KnowledgeEntry.status == status)
    if category:
        query = query.filter(models.KnowledgeEntry.category == category)
    if search and search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(or_(
            models.KnowledgeEntry.title.ilike(term),
            models.KnowledgeEntry.pattern.ilike(term),
            models.KnowledgeEntry.category.ilike(term),
            models.KnowledgeEntry.source.ilike(term),
        ))
        
    total = query.count()
    entries = query.order_by(desc(models.KnowledgeEntry.created_at)).offset(skip).limit(limit).all()
    
    return {
        "items": [
            {
                "id": e.id,
                "title": e.title,
                "category": e.category,
                "source": e.source,
                "status": e.status,
                "created_at": e.created_at,
                "updated_at": e.updated_at,
                "risk_level": e.risk_level,
                "pattern": e.pattern,
                "description": e.description,
                "safe_action": e.safe_action,
                "indicators": e.indicators or [],
                "source_type": e.source_type,
                "source_reference": e.source_reference,
            } for e in entries
        ],
        "total": total,
        "page": (skip // limit) + 1,
        "page_size": limit,
        "total_pages": (total + limit - 1) // limit
    }

class KnowledgeCreate(BaseModel):
    title: str
    pattern: str
    category: str
    risk_level: str
    safe_action: str
    indicators: List[str] = Field(default_factory=list)
    description: str = ""
    source: str = "Admin"

@router.post("/knowledge")
def create_knowledge_entry(
    payload: KnowledgeCreate,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin)
):
    entry = models.KnowledgeEntry(
        title=payload.title,
        pattern=payload.pattern,
        category=payload.category,
        risk_level=payload.risk_level,
        safe_action=payload.safe_action,
        indicators=payload.indicators,
        description=payload.description,
        source=payload.source,
        source_type="MANUAL_ENTRY",
        status="APPROVED"
    )
    db.add(entry)
    db.flush()
    rag_service.upsert_knowledge_entry(entry)
    db.commit()
    
    audit = models.AuditLog(
        actor_id=current_admin.id,
        action="KNOWLEDGE_CREATED",
        resource_type="KNOWLEDGE_ENTRY",
        resource_id=str(entry.id),
        result="SUCCESS"
    )
    db.add(audit)
    db.commit()
    return {"status": "success", "id": entry.id}


class KnowledgeUpdate(BaseModel):
    title: str | None = None
    pattern: str | None = None
    category: str | None = None
    risk_level: str | None = None
    safe_action: str | None = None
    indicators: List[str] | None = None
    description: str | None = None
    source: str | None = None


@router.patch("/knowledge/{entry_id}")
def update_knowledge_entry(
    entry_id: int,
    payload: KnowledgeUpdate,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin),
):
    entry = db.query(models.KnowledgeEntry).filter(models.KnowledgeEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    for field, value in payload.dict(exclude_unset=True).items():
        setattr(entry, field, value)
    if entry.status in ("APPROVED", "ACTIVE"):
        rag_service.upsert_knowledge_entry(entry)
    db.add(models.AuditLog(
        actor_id=current_admin.id,
        action="KNOWLEDGE_UPDATED",
        resource_type="KNOWLEDGE_ENTRY",
        resource_id=str(entry.id),
        result="SUCCESS",
    ))
    db.commit()
    return {"status": "success"}

@router.patch("/knowledge/{entry_id}/approve")
def approve_knowledge(entry_id: int, db: Session = Depends(get_db), current_admin: models.User = Depends(require_admin)):
    entry = db.query(models.KnowledgeEntry).filter(models.KnowledgeEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    
    entry.status = "APPROVED"
    rag_service.upsert_knowledge_entry(entry)
    
    audit = models.AuditLog(
        actor_id=current_admin.id,
        action="KNOWLEDGE_APPROVED",
        resource_type="KNOWLEDGE_ENTRY",
        resource_id=str(entry.id),
        result="SUCCESS"
    )
    db.add(audit)
    db.commit()
    return {"status": "success"}


@router.patch("/knowledge/{entry_id}/archive")
def archive_knowledge(
    entry_id: int,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin),
):
    entry = db.query(models.KnowledgeEntry).filter(models.KnowledgeEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    rag_service.delete_knowledge_entry(entry.id)
    entry.status = "INACTIVE"
    db.add(models.AuditLog(
        actor_id=current_admin.id,
        action="KNOWLEDGE_ARCHIVED",
        resource_type="KNOWLEDGE_ENTRY",
        resource_id=str(entry.id),
        result="SUCCESS",
    ))
    db.commit()
    return {"status": "success"}


@router.post("/knowledge/{entry_id}/reindex")
def reindex_knowledge(
    entry_id: int,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin),
):
    entry = db.query(models.KnowledgeEntry).filter(models.KnowledgeEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    if entry.status not in ("APPROVED", "ACTIVE"):
        raise HTTPException(status_code=409, detail="Only active knowledge entries can be indexed")
    rag_service.upsert_knowledge_entry(entry)
    db.add(models.AuditLog(
        actor_id=current_admin.id,
        action="KNOWLEDGE_REINDEXED",
        resource_type="KNOWLEDGE_ENTRY",
        resource_id=str(entry.id),
        result="SUCCESS",
    ))
    db.commit()
    return {"status": "success", "indexed": True}

@router.delete("/knowledge/{entry_id}")
def delete_knowledge(entry_id: int, db: Session = Depends(get_db), current_admin: models.User = Depends(require_admin)):
    entry = db.query(models.KnowledgeEntry).filter(models.KnowledgeEntry.id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
        
    rag_service.delete_knowledge_entry(entry.id)
    db.delete(entry)
    
    audit = models.AuditLog(
        actor_id=current_admin.id,
        action="KNOWLEDGE_DELETED",
        resource_type="KNOWLEDGE_ENTRY",
        resource_id=str(entry_id),
        result="SUCCESS"
    )
    db.add(audit)
    db.commit()
    return {"status": "success"}

@router.get("/users/{user_id}")
def get_admin_user(user_id: int, db: Session = Depends(get_db), current_admin: models.User = Depends(require_admin)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    user_analyses = db.query(models.Analysis).filter(models.Analysis.user_id == user_id)
    analysis_count = user_analyses.count()
    recent_analyses = user_analyses.order_by(desc(models.Analysis.created_at)).limit(5).all()
    return {
        "user": {
            "id": user.id,
            "email": user.email,
            "full_name": user.full_name,
            "role": user.role,
            "is_active": user.is_active,
            "created_at": user.created_at,
        },
        "analysis_count": analysis_count,
        "recent_analyses": [
            {
                "id": analysis.id,
                "created_at": analysis.created_at,
                "input_type": analysis.input_type,
                "classification": analysis.classification,
                "risk_level": analysis.risk_level,
                "risk_score": analysis.risk_score,
                "status": analysis.processing_status,
            }
            for analysis in recent_analyses
        ],
    }


@router.get("/users")
def get_admin_users(
    skip: int = 0,
    limit: int = 50,
    role: str = None,
    status: str = None,
    search: str = None,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin)
):
    query = db.query(models.User)
    if role:
        query = query.filter(models.User.role == role)
    if status:
        is_active = True if status == "ACTIVE" else False
        query = query.filter(models.User.is_active == is_active)
    if search and search.strip():
        term = search.strip()
        query = query.filter(or_(
            models.User.full_name.ilike(f"%{term}%"),
            models.User.email.ilike(f"%{term}%"),
            cast(models.User.id, String).ilike(f"%{term}%"),
        ))
        
    total = query.count()
    users = query.order_by(desc(models.User.created_at)).offset(skip).limit(limit).all()
    
    return {
        "items": [
            {
                "id": u.id,
                "email": u.email,
                "full_name": u.full_name,
                "role": u.role,
                "is_active": u.is_active,
                "created_at": u.created_at
            } for u in users
        ],
        "total": total,
        "page": (skip // limit) + 1,
        "page_size": limit,
        "total_pages": (total + limit - 1) // limit,
        "summary": {
            "total": db.query(models.User).count(),
            "active": db.query(models.User).filter(models.User.is_active.is_(True)).count(),
            "inactive": db.query(models.User).filter(models.User.is_active.is_(False)).count(),
            "admins": db.query(models.User).filter(models.User.role == "admin").count(),
        }
    }

class UserRoleUpdate(BaseModel):
    role: str

@router.patch("/users/{user_id}/role")
def update_user_role(user_id: int, payload: UserRoleUpdate, db: Session = Depends(get_db), current_admin: models.User = Depends(require_admin)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    if payload.role not in {"user", "admin"}:
        raise HTTPException(status_code=422, detail="Role must be user or admin")
    if user.id == current_admin.id and payload.role != "admin":
        raise HTTPException(status_code=400, detail="Cannot remove your own admin role")
    if user.role == "admin" and payload.role != "admin" and user.is_active:
        active_admins = db.query(models.User).filter(
            models.User.role == "admin",
            models.User.is_active.is_(True),
        ).count()
        if active_admins <= 1:
            raise HTTPException(status_code=400, detail="Cannot demote the last active administrator")

    old_role = user.role
    user.role = payload.role
    
    audit = models.AuditLog(
        actor_id=current_admin.id,
        action="USER_ROLE_UPDATED",
        resource_type="USER",
        resource_id=str(user.id),
        result="SUCCESS",
        details={"old_role": old_role, "new_role": payload.role}
    )
    db.add(audit)
    db.commit()
    return {"status": "success"}

class UserStatusUpdate(BaseModel):
    is_active: bool
    
@router.patch("/users/{user_id}/status")
def update_user_status(user_id: int, payload: UserStatusUpdate, db: Session = Depends(get_db), current_admin: models.User = Depends(require_admin)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
    if user.id == current_admin.id:
        raise HTTPException(status_code=400, detail="Cannot deactivate yourself")
        
    user.is_active = payload.is_active
    
    audit = models.AuditLog(
        actor_id=current_admin.id,
        action="USER_STATUS_UPDATED",
        resource_type="USER",
        resource_id=str(user.id),
        result="SUCCESS",
        details={"is_active": payload.is_active}
    )
    db.add(audit)
    db.commit()
    return {"status": "success"}

@router.get("/audit")
def get_admin_audit_logs(
    skip: int = 0,
    limit: int = 50,
    action: str = None,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin)
):
    query = db.query(models.AuditLog)
    if action:
        query = query.filter(models.AuditLog.action.ilike(f"%{action}%"))
        
    total = query.count()
    logs = query.order_by(desc(models.AuditLog.created_at)).offset(skip).limit(limit).all()
    
    return {
        "items": [
            {
                "id": l.id,
                "actor": l.actor.email if l.actor else f"Actor {l.actor_id}",
                "action": l.action,
                "resource_type": l.resource_type,
                "resource_id": l.resource_id,
                "result": l.result,
                "created_at": l.created_at
            } for l in logs
        ],
        "total": total,
        "page": (skip // limit) + 1,
        "page_size": limit,
        "total_pages": (total + limit - 1) // limit
    }

@router.get("/health")
def get_admin_system_health(db: Session = Depends(get_db), current_admin: models.User = Depends(require_admin)):
    jira_enabled = (
        os.getenv("JIRA_ENABLED", "false").lower() == "true"
        and bool(os.getenv("JIRA_URL") or os.getenv("JIRA_BASE_URL"))
        and all(
            os.getenv(key)
            for key in ("JIRA_EMAIL", "JIRA_API_TOKEN", "JIRA_PROJECT_KEY")
        )
        and os.getenv("JIRA_PROJECT_KEY") == "SCAM"
    )
    db_started = time.perf_counter()
    health = {
        "database": {"status": "unknown", "latency": None},
        "ml_engine": {"status": "up" if classifier_service.clf is not None and classifier_service.vectorizer is not None else "down", "latency": None},
        "rag_service": {"status": "unknown", "latency": None},
        "jira_integration": {"status": "up" if jira_enabled else "not_configured", "latency": None},
        "system_time": datetime.now(timezone.utc).isoformat()
    }

    try:
        db.execute(text("SELECT 1"))
        health["database"] = {
            "status": "up",
            "latency": f"{(time.perf_counter() - db_started) * 1000:.2f}ms",
        }
    except Exception:
        logger.exception("Admin database health check failed.")
        health["database"]["status"] = "down"

    rag_started = time.perf_counter()
    try:
        rag_service.collection.count()
        health["rag_service"] = {
            "status": "up",
            "latency": f"{(time.perf_counter() - rag_started) * 1000:.2f}ms",
        }
    except Exception:
        logger.exception("Admin RAG health check failed.")
        health["rag_service"]["status"] = "down"

    return health
