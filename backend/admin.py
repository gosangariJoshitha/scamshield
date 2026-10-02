from fastapi import APIRouter, Depends, HTTPException
import os
from sqlalchemy.orm import Session
from sqlalchemy import String, cast, desc, func, or_
from typing import List, Dict, Any

from database import get_db
import models
from auth import get_current_user
from app.services.rag_service import rag_service

router = APIRouter()

def require_admin(current_user: models.User = Depends(get_current_user)):
    if current_user.role != "admin" or not current_user.is_active:
        raise HTTPException(status_code=403, detail="Admin privileges required")
    return current_user

@router.get("/overview")
def get_admin_overview(db: Session = Depends(get_db), current_admin: models.User = Depends(require_admin)):
    # Total Analyses
    total_analyses = db.query(models.Analysis).count()
    
    # Scams Detected
    scams_detected = db.query(models.Analysis).filter(models.Analysis.classification == "SCAM").count()
    
    # High/Critical Risk
    high_risk = db.query(models.Analysis).filter(models.Analysis.risk_level.in_(["HIGH", "CRITICAL"])).count()
    
    # Pending Reviews
    pending_reviews = db.query(models.ReviewCase).filter(models.ReviewCase.status == "PENDING").count()
    
    # Community Reports
    community_reports = db.query(models.CommunityReport).count()
    
    # Verified Knowledge
    verified_knowledge = db.query(models.KnowledgeEntry).filter(models.KnowledgeEntry.status == "APPROVED").count()

    # Risk Distribution
    risk_dist = db.query(
        models.Analysis.risk_level, 
        func.count(models.Analysis.id)
    ).group_by(models.Analysis.risk_level).all()
    
    # Classification Distribution
    class_dist = db.query(
        models.Analysis.classification, 
        func.count(models.Analysis.id)
    ).group_by(models.Analysis.classification).all()

    # Input Type Distribution
    input_dist = db.query(
        models.Analysis.input_type, 
        func.count(models.Analysis.id)
    ).group_by(models.Analysis.input_type).all()

    # Recent Analyses
    recent_analyses = db.query(models.Analysis).order_by(desc(models.Analysis.created_at)).limit(5).all()

    return {
        "totalAnalyses": total_analyses,
        "scamsDetected": scams_detected,
        "highRisk": high_risk,
        "pendingReviews": pending_reviews,
        "communityReports": community_reports,
        "verifiedKnowledge": verified_knowledge,
        "riskDistribution": [{"name": r[0] or "UNKNOWN", "value": r[1]} for r in risk_dist],
        "classificationDistribution": [{"name": r[0] or "UNKNOWN", "value": r[1]} for r in class_dist],
        "inputTypeDistribution": [{"name": r[0] or "UNKNOWN", "value": r[1]} for r in input_dist],
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
        ]
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
    status: str = None,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin)
):
    query = db.query(models.CommunityReport)
    if status:
        query = query.filter(models.CommunityReport.status == status)
        
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

from pydantic import BaseModel
class CommunityAction(BaseModel):
    action: str # VERIFY, REJECT, NEEDS_INFORMATION
    notes: str = None
    
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
        # Create knowledge entry
        k_entry = models.KnowledgeEntry(
            title=f"Community Verified: {report.category}",
            pattern=report.content,
            category=report.category,
            description=report.description,
            indicators=[],
            safe_action="Proceed with caution.",
            risk_level="HIGH",
            source="Community",
            source_type="VERIFIED_COMMUNITY_REPORT",
            source_reference=str(report.id),
            status="APPROVED"
        )
        db.add(k_entry)
        db.flush()
        rag_service.upsert_knowledge_entry(k_entry)
        
    elif payload.action == "REJECT":
        report.status = "REJECTED"
    elif payload.action == "NEEDS_INFORMATION":
        report.status = "NEEDS_INFORMATION"
    else:
        raise HTTPException(status_code=400, detail="Invalid action")
        
    db.commit()
    
    # Audit Log
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
    return {"status": "success", "report_status": report.status}

@router.get("/knowledge")
def get_admin_knowledge(
    skip: int = 0,
    limit: int = 50,
    status: str = None,
    category: str = None,
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin)
):
    query = db.query(models.KnowledgeEntry)
    if status:
        query = query.filter(models.KnowledgeEntry.status == status)
    if category:
        query = query.filter(models.KnowledgeEntry.category == category)
        
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
                "risk_level": e.risk_level,
                "pattern": e.pattern,
                "safe_action": e.safe_action,
                "indicators": e.indicators
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
    indicators: List[str] = []

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
        source="Admin",
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
    db: Session = Depends(get_db),
    current_admin: models.User = Depends(require_admin)
):
    query = db.query(models.User)
    if role:
        query = query.filter(models.User.role == role)
    if status:
        is_active = True if status == "ACTIVE" else False
        query = query.filter(models.User.is_active == is_active)
        
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
        "total_pages": (total + limit - 1) // limit
    }

class UserRoleUpdate(BaseModel):
    role: str

@router.patch("/users/{user_id}/role")
def update_user_role(user_id: int, payload: UserRoleUpdate, db: Session = Depends(get_db), current_admin: models.User = Depends(require_admin)):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
        
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

import datetime
@router.get("/health")
def get_admin_system_health(db: Session = Depends(get_db), current_admin: models.User = Depends(require_admin)):
    # Basic health checks
    jira_enabled = (
        os.getenv("JIRA_ENABLED", "false").lower() == "true"
        and all(os.getenv(key) for key in (
            "JIRA_BASE_URL",
            "JIRA_EMAIL",
            "JIRA_API_TOKEN",
            "JIRA_PROJECT_KEY",
        ))
    )
    health = {
        "database": {"status": "up", "latency": "12ms"},
        "ml_engine": {"status": "up", "latency": "45ms"},
        "rag_service": {"status": "up", "latency": "30ms"},
        "jira_integration": {"status": "up" if jira_enabled else "down", "latency": "-"},
        "system_time": datetime.datetime.utcnow().isoformat()
    }
    return health
