from sqlalchemy.orm import Session
from models import Analysis, ReviewCase, ReviewCaseEvent, User
import json

class EscalationService:
    def __init__(self, db: Session):
        self.db = db

    def evaluate_analysis(self, analysis: Analysis, user: User) -> dict:
        should_escalate = analysis.risk_level in {"HIGH", "CRITICAL"}
        reasons = [f"{analysis.risk_level}_RISK"] if should_escalate else []
        priority = (
            "URGENT" if analysis.risk_level == "CRITICAL"
            else "HIGH" if analysis.risk_level == "HIGH"
            else "LOW"
        )

        return {
            "should_escalate": should_escalate,
            "priority": priority,
            "reasons": reasons
        }
        
    def request_human_verification(self, analysis_id: int, user_id: int) -> ReviewCase:
        """
        Trigger E: USER REQUEST
        Explicit user request for human verification.
        """
        analysis = self.db.query(Analysis).filter(Analysis.id == analysis_id, Analysis.user_id == user_id).first()
        if not analysis:
            raise ValueError("Analysis not found or not owned by user.")
            
        existing_case = self.db.query(ReviewCase).filter(ReviewCase.analysis_id == analysis_id).first()
        if existing_case:
            analysis.review_case = existing_case
            return existing_case # Already requested
            
        review_case = ReviewCase(
            analysis_id=analysis_id,
            user_id=user_id,
            status="PENDING",
            priority="MEDIUM",
            escalation_reason="USER_REQUEST",
            escalation_reasons_json=json.dumps(["USER_REQUEST"])
        )
        self.db.add(review_case)
        self.db.commit()
        self.db.refresh(review_case)
        analysis.review_case = review_case
        analysis.escalation_status = "USER_REQUESTED"
        self.db.commit()
        
        self.log_event(review_case.id, user_id, "CASE_CREATED", None, "PENDING", "User requested human verification.")
        
        return review_case

    def create_escalated_case(self, analysis: Analysis, evaluation: dict) -> ReviewCase:
        """
        Creates a review case based on backend evaluation.
        """
        existing_case = self.db.query(ReviewCase).filter(ReviewCase.analysis_id == analysis.id).first()
        if existing_case:
            analysis.review_case = existing_case
            return existing_case
            
        review_case = ReviewCase(
            analysis_id=analysis.id,
            user_id=analysis.user_id,
            status="PENDING",
            priority=evaluation["priority"],
            escalation_reason=",".join(evaluation["reasons"]),
            escalation_reasons_json=json.dumps(evaluation["reasons"])
        )
        self.db.add(review_case)
        self.db.commit()
        self.db.refresh(review_case)
        analysis.review_case = review_case
        
        self.log_event(review_case.id, None, "CASE_CREATED", None, "PENDING", f"System escalated due to: {evaluation['reasons']}")
        
        return review_case
        
    def log_event(self, review_case_id: int, actor_id: int, event_type: str, prev_status: str, new_status: str, notes: str):
        event = ReviewCaseEvent(
            review_case_id=review_case_id,
            actor_user_id=actor_id,
            event_type=event_type,
            previous_status=prev_status,
            new_status=new_status,
            notes=notes
        )
        self.db.add(event)
        self.db.commit()
