from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from database import get_db
from models import User, ReviewCase, Analysis, KnowledgeEntry, ReviewCaseEvent
from app.services.escalation_service import EscalationService
from app.services.jira_service import JiraService
from app.services.rag_service import rag_service
from auth import get_current_user
import json
from typing import List
from datetime import datetime

router = APIRouter()

# --- USER ENDPOINTS ---

@router.post("/request/{analysis_id}")
def request_review(analysis_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    """User requests human verification for an analysis."""
    escalation_service = EscalationService(db)
    try:
        review_case = escalation_service.request_human_verification(analysis_id, current_user.id)
        return {"success": True, "case_id": review_case.id, "status": review_case.status}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))

@router.get("/my")
def get_my_reviews(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
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
def provide_additional_information(case_id: int, info: dict, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
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
    if user.role != "admin":
        raise HTTPException(status_code=403, detail="Admin privileges required")
    return user

@router.get("/admin/list")
def list_all_reviews(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    """List all review cases for admin."""
    reviews = db.query(ReviewCase).order_by(ReviewCase.created_at.desc()).all()
    result = []
    for r in reviews:
        # Also join analysis data manually
        analysis = db.query(Analysis).filter(Analysis.id == r.analysis_id).first()
        result.append({
            "id": r.id,
            "analysis_id": r.analysis_id,
            "risk_level": analysis.risk_level if analysis else None,
            "classification": analysis.classification if analysis else None,
            "category": analysis.category if analysis else None,
            "status": r.status,
            "priority": r.priority,
            "escalation_reason": r.escalation_reason,
            "assigned_reviewer_id": r.assigned_reviewer_id,
            "created_at": r.created_at
        })
    return result

@router.get("/admin/{case_id}")
def get_review_details(case_id: int, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    """Get full details of a review case."""
    r = db.query(ReviewCase).filter(ReviewCase.id == case_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Case not found")
        
    analysis = db.query(Analysis).filter(Analysis.id == r.analysis_id).first()
    events = db.query(ReviewCaseEvent).filter(ReviewCaseEvent.review_case_id == case_id).order_by(ReviewCaseEvent.created_at.desc()).all()
    
    return {
        "id": r.id,
        "analysis_id": r.analysis_id,
        "status": r.status,
        "priority": r.priority,
        "escalation_reasons": json.loads(r.escalation_reasons_json) if r.escalation_reasons_json else [],
        "review_decision": r.review_decision,
        "reviewer_notes": r.reviewer_notes,
        "assigned_reviewer_id": r.assigned_reviewer_id,
        "created_at": r.created_at,
        "jira": {
            "enabled": r.jira_integration is not None,
            "issue_key": r.jira_integration.jira_issue_key if r.jira_integration else None
        },
        "analysis": {
            "content": analysis.content,
            "risk_score": analysis.risk_score,
            "risk_level": analysis.risk_level,
            "classification": analysis.classification,
            "ml_probability": analysis.ml_probability,
            "llm_confidence": analysis.llm_confidence,
            "category": analysis.category,
            "indicators": analysis.indicators,
            "evidence": analysis.evidence,
            "recommended_action": analysis.recommended_action
        },
        "events": [
            {
                "event_type": e.event_type,
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
    return {"success": True}

@router.post("/admin/{case_id}/start")
def start_review(case_id: int, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    r = db.query(ReviewCase).filter(ReviewCase.id == case_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Case not found")
        
    prev_status = r.status
    r.status = "IN_REVIEW"
    if not r.review_started_at:
        r.review_started_at = datetime.utcnow()
    if not r.assigned_reviewer_id:
        r.assigned_reviewer_id = admin.id
        
    db.commit()
    EscalationService(db).log_event(r.id, admin.id, "CASE_STARTED", prev_status, r.status, "Review started")
    return {"success": True}

@router.post("/admin/{case_id}/decision")
def submit_decision(case_id: int, payload: dict, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    r = db.query(ReviewCase).filter(ReviewCase.id == case_id).first()
    if not r:
        raise HTTPException(status_code=404, detail="Case not found")
        
    decision = payload.get("decision")
    notes = payload.get("notes", "")
    
    valid_decisions = ["CONFIRMED_SCAM", "CONFIRMED_GENUINE", "UNCERTAIN", "INSUFFICIENT_INFORMATION"]
    if decision not in valid_decisions:
        raise HTTPException(status_code=400, detail="Invalid decision")
        
    prev_status = r.status
    r.review_decision = decision
    r.reviewer_notes = notes
    r.reviewed_at = datetime.utcnow()
    
    if decision in ["CONFIRMED_SCAM", "CONFIRMED_GENUINE"]:
        r.status = "VERIFIED"
    elif decision == "UNCERTAIN":
        r.status = "REJECTED" # Or CLOSED depending on policy
    elif decision == "INSUFFICIENT_INFORMATION":
        r.status = "NEEDS_INFORMATION"
        
    db.commit()
    EscalationService(db).log_event(r.id, admin.id, "DECISION_SUBMITTED", prev_status, r.status, f"Decision: {decision}. Notes: {notes}")
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
        status="APPROVED"  # In a full flow this might go to DRAFT first
    )
    db.add(k)
    db.flush()
    rag_service.upsert_knowledge_entry(k)
    db.commit()
    
    EscalationService(db).log_event(r.id, admin.id, "KNOWLEDGE_CREATED", r.status, r.status, "Trusted knowledge entry created and approved")
    
    return {"success": True, "knowledge_id": k.id}
