from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import String, cast, desc, func, or_
from sqlalchemy.orm import Session
from database import get_db
from models import AuditLog, User, ReviewCase, Analysis, KnowledgeEntry, ReviewCaseEvent
from app.services.escalation_service import EscalationService
from app.services.jira_service import JiraService
from app.services.rag_service import rag_service
from auth import get_current_regular_user, get_current_user, get_current_verified_user
import json
from typing import List, Literal
from datetime import datetime

router = APIRouter()

# --- USER ENDPOINTS ---

@router.post("/request/{analysis_id}")
def request_review(analysis_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_verified_user)):
    """User requests human verification for an analysis."""
    escalation_service = EscalationService(db)
    try:
        review_case = escalation_service.request_human_verification(analysis_id, current_user.id)
        return {"success": True, "case_id": review_case.id, "status": review_case.status}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/my")
def get_my_reviews(db: Session = Depends(get_db), current_user: User = Depends(get_current_regular_user)):
    """Get all reviews requested by the user."""
    reviews = db.query(ReviewCase).filter(ReviewCase.user_id == current_user.id).all()
    
    result = []
    for r in reviews:
        result.append({
            "id": r.id,
            "analysis_id": r.analysis_id,
            "status": r.status,
            "created_at": r.created_at,
            "updated_at": r.updated_at
        })
    return result

@router.post("/{case_id}/information")
def provide_additional_information(case_id: int, info: dict, db: Session = Depends(get_db), current_user: User = Depends(get_current_verified_user)):
    """User provides additional information for a case that needs it."""
    review_case = db.query(ReviewCase).filter(ReviewCase.id == case_id, ReviewCase.user_id == current_user.id).first()
    if not review_case:
        raise HTTPException(status_code=404, detail="Review case not found")
        
    if review_case.status != "NEEDS_INFORMATION":
        raise HTTPException(status_code=400, detail="Case is not requesting information")
        
    prev_status = review_case.status
    review_case.status = "IN_REVIEW"
    db.commit()
    
    escalation_service = EscalationService(db)
    escalation_service.log_event(
        review_case.id, 
        current_user.id, 
        "INFORMATION_RECEIVED", 
        prev_status, 
        "IN_REVIEW", 
        f"User provided info: {info.get('notes', '')}"
    )
    
    return {"success": True, "status": review_case.status}

# --- ADMIN ENDPOINTS ---

def require_admin(user: User = Depends(get_current_user)):
    if user.role != "admin" or not user.is_active:
        raise HTTPException(status_code=403, detail="Admin privileges required")
    return user

class ReviewDecisionPayload(BaseModel):
    decision: Literal[
        "CONFIRMED_SCAM",
        "CONFIRMED_GENUINE",
        "UNCERTAIN",
        "INSUFFICIENT_INFORMATION",
    ]
    notes: str = Field(default="", max_length=5000)

@router.get("/admin/list")
def list_all_reviews(
    skip: int = 0,
    limit: int = 20,
    search: str = "",
    review_status: str = "",
    priority: str = "",
    risk_level: str = "",
    input_type: str = "",
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
):
    limit = min(max(limit, 1), 100)
    base_query = db.query(ReviewCase).join(Analysis, Analysis.id == ReviewCase.analysis_id)
    query = base_query.outerjoin(User, User.id == ReviewCase.user_id)
    if review_status:
        query = query.filter(ReviewCase.status == review_status)
    if priority:
        query = query.filter(ReviewCase.priority == priority)
    if risk_level:
        query = query.filter(Analysis.risk_level == risk_level)
    if input_type:
        query = query.filter(Analysis.input_type == input_type)
    if search.strip():
        term = f"%{search.strip()}%"
        query = query.filter(or_(
            cast(ReviewCase.id, String).ilike(term),
            cast(ReviewCase.analysis_id, String).ilike(term),
            Analysis.content.ilike(term),
            Analysis.category.ilike(term),
            User.email.ilike(term),
            User.full_name.ilike(term),
        ))

    total = query.count()
    cases = query.order_by(desc(ReviewCase.created_at)).offset(max(skip, 0)).limit(limit).all()
    counts = db.query(ReviewCase.status, func.count(ReviewCase.id)).group_by(ReviewCase.status).all()
    summary = {status: int(count) for status, count in counts}
    summary["TOTAL"] = sum(summary.values())

    return {
        "items": [
            {
                "id": case.id,
                "analysis_id": case.analysis_id,
                "risk_level": case.analysis.risk_level,
                "classification": case.analysis.classification,
                "category": case.analysis.category,
                "input_type": case.analysis.input_type,
                "content_preview": (case.analysis.original_text or case.analysis.content or "")[:180],
                "reporter": case.user.email if case.user else "Unknown",
                "status": case.status,
                "priority": case.priority,
                "escalation_reason": case.escalation_reason,
                "assigned_reviewer_id": case.assigned_reviewer_id,
                "created_at": case.created_at,
            }
            for case in cases
        ],
        "total": total,
        "page": max(skip, 0) // limit + 1,
        "page_size": limit,
        "total_pages": (total + limit - 1) // limit,
        "summary": summary,
    }

@router.get("/admin/{case_id}")
def get_review_details(case_id: int, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    """Get full details of a review case."""
    r = db.query(ReviewCase).filter(ReviewCase.id == case_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Case not found")
        
    analysis = db.query(Analysis).filter(Analysis.id == r.analysis_id).first()
    events = db.query(ReviewCaseEvent).filter(ReviewCaseEvent.review_case_id == case_id).order_by(ReviewCaseEvent.created_at.desc()).all()
    knowledge_entry_exists = db.query(KnowledgeEntry.id).filter(
        KnowledgeEntry.source_type == "HUMAN_VERIFIED_CASE",
        KnowledgeEntry.source_reference == str(r.id),
    ).first() is not None
    
    return {
        "id": r.id,
        "analysis_id": r.analysis_id,
        "status": r.status,
        "priority": r.priority,
        "escalation_reasons": json.loads(r.escalation_reasons_json) if r.escalation_reasons_json else [],
        "review_decision": r.review_decision,
        "reviewer_notes": r.reviewer_notes,
        "knowledge_entry_exists": knowledge_entry_exists,
        "assigned_reviewer_id": r.assigned_reviewer_id,
        "created_at": r.created_at,
        "jira": {
            "enabled": r.jira_integration is not None,
            "issue_key": r.jira_integration.jira_issue_key if r.jira_integration else None
        },
        "analysis": {
            "content": analysis.content,
            "original_text": analysis.original_text,
            "input_type": analysis.input_type,
            "risk_score": analysis.risk_score,
            "risk_level": analysis.risk_level,
            "classification": analysis.classification,
            "ml_probability": analysis.ml_probability,
            "llm_confidence": analysis.llm_confidence,
            "category": analysis.category,
            "indicators": analysis.indicators,
            "explanation": analysis.explanation,
            "evidence": analysis.evidence,
            "retrieved_evidence": [
                {
                    "content": evidence.content,
                    "similarity_score": evidence.similarity_score,
                    "source": evidence.source_reference,
                    "knowledge_id": evidence.knowledge_id,
                }
                for evidence in analysis.retrieved_evidences
            ],
            "recommended_action": analysis.recommended_action
        },
        "events": [
            {
                "event_type": e.event_type,
                "actor": e.actor.full_name if e.actor else "System",
                "notes": e.notes,
                "created_at": e.created_at
            } for e in events
        ]
    }

@router.post("/admin/{case_id}/assign")
def assign_review(case_id: int, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    r = db.query(ReviewCase).filter(ReviewCase.id == case_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Case not found")
        
    prev_status = r.status
    r.assigned_reviewer_id = admin.id
    r.assigned_at = datetime.utcnow()
    
    if r.status == "PENDING":
        r.status = "ASSIGNED"
        
    db.commit()
    
    EscalationService(db).log_event(r.id, admin.id, "CASE_ASSIGNED", prev_status, r.status, "Assigned to admin")
    db.add(AuditLog(
        actor_id=admin.id,
        action="REVIEW_CASE_ASSIGNED",
        resource_type="REVIEW_CASE",
        resource_id=str(r.id),
        result="SUCCESS",
    ))
    db.commit()
    return {"success": True}

@router.post("/admin/{case_id}/start")
def start_review(case_id: int, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    r = db.query(ReviewCase).filter(ReviewCase.id == case_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Case not found")

    if r.status == "IN_REVIEW":
        return {
            "success": True,
            "status": r.status,
            "assigned_reviewer_id": r.assigned_reviewer_id,
        }
    if r.status not in {"PENDING", "ASSIGNED"}:
        raise HTTPException(
            status_code=409,
            detail=f"Review cannot be started while the case is {r.status}.",
        )
    if r.assigned_reviewer_id and r.assigned_reviewer_id != admin.id:
        raise HTTPException(
            status_code=409,
            detail="This case is assigned to another reviewer.",
        )

    prev_status = r.status
    r.status = "IN_REVIEW"
    if not r.review_started_at:
        r.review_started_at = datetime.utcnow()
    if not r.assigned_reviewer_id:
        r.assigned_reviewer_id = admin.id

    db.commit()
    EscalationService(db).log_event(r.id, admin.id, "CASE_STARTED", prev_status, r.status, "Review started")
    db.add(AuditLog(
        actor_id=admin.id,
        action="REVIEW_CASE_STARTED",
        resource_type="REVIEW_CASE",
        resource_id=str(r.id),
        result="SUCCESS",
    ))
    db.commit()
    return {
        "success": True,
        "status": r.status,
        "assigned_reviewer_id": r.assigned_reviewer_id,
    }

@router.post("/admin/{case_id}/decision")
def submit_decision(case_id: int, payload: ReviewDecisionPayload, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    r = db.query(ReviewCase).filter(ReviewCase.id == case_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Case not found")
        
    if r.status not in {"IN_REVIEW", "NEEDS_INFORMATION"}:
        raise HTTPException(
            status_code=409,
            detail=f"A decision cannot be submitted while the case is {r.status}.",
        )

    decision = payload.decision
    notes = payload.notes.strip()
    if decision in {"UNCERTAIN", "INSUFFICIENT_INFORMATION"} and not notes:
        raise HTTPException(status_code=422, detail="Reviewer notes are required for this decision")
        
    prev_status = r.status
    r.review_decision = decision
    r.reviewer_notes = notes
    r.reviewed_at = datetime.utcnow()
    
    if decision in ["CONFIRMED_SCAM", "CONFIRMED_GENUINE"]:
        r.status = "VERIFIED"
    elif decision == "UNCERTAIN":
        r.status = "CLOSED"
    elif decision == "INSUFFICIENT_INFORMATION":
        r.status = "NEEDS_INFORMATION"
        
    db.commit()
    EscalationService(db).log_event(r.id, admin.id, "DECISION_SUBMITTED", prev_status, r.status, f"Decision: {decision}. Notes: {notes}")
    db.add(AuditLog(
        actor_id=admin.id,
        action="REVIEW_DECISION_SUBMITTED",
        resource_type="REVIEW_CASE",
        resource_id=str(r.id),
        result="SUCCESS",
        details={"decision": decision, "status": r.status},
    ))
    db.commit()
    return {"success": True, "status": r.status}

@router.post("/admin/{case_id}/jira")
def create_jira_ticket(case_id: int, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    jira_service = JiraService(db)
    result = jira_service.create_issue_for_review_case(case_id, admin.id)
    if not result.get("success"):
        raise HTTPException(status_code=500, detail=result.get("error"))
    return result

@router.post("/admin/{case_id}/create-knowledge")
def create_trusted_knowledge(case_id: int, payload: dict, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    r = db.query(ReviewCase).filter(ReviewCase.id == case_id).first()
    if not r or r.status != "VERIFIED" or r.review_decision != "CONFIRMED_SCAM":
        raise HTTPException(status_code=400, detail="Knowledge can only be created from CONFIRMED_SCAM verified cases")
    existing = db.query(KnowledgeEntry).filter(
        KnowledgeEntry.source_type == "HUMAN_VERIFIED_CASE",
        KnowledgeEntry.source_reference == str(r.id),
    ).first()
    if existing:
        raise HTTPException(status_code=409, detail="This review case already has a knowledge entry")
        
    k = KnowledgeEntry(
        title=payload.get("title", f"Scam Pattern RV-{r.id}"),
        pattern=payload.get("pattern"),
        category=payload.get("category"),
        description=payload.get("description"),
        indicators=payload.get("indicators", []),
        safe_action=payload.get("safe_action"),
        risk_level="CRITICAL",
        source="Admin Review Center",
        source_type="HUMAN_VERIFIED_CASE",
        source_reference=str(r.id),
        status="DRAFT"
    )
    db.add(k)
    db.commit()
    
    EscalationService(db).log_event(
        r.id,
        admin.id,
        "KNOWLEDGE_CREATED",
        r.status,
        r.status,
        "Trusted knowledge entry created as a draft pending approval",
    )
    
    return {"success": True, "knowledge_id": k.id}
