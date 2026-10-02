from sqlalchemy.orm import Session
from models import Analysis, ReviewCase, ReviewCaseEvent, User
import json

class EscalationService:
    def __init__(self, db: Session):
        self.db = db
        # Configurable thresholds
        self.critical_risk_threshold = "CRITICAL"
        self.low_confidence_threshold = 0.60
    
    def evaluate_analysis(self, analysis: Analysis, user: User) -> dict:
        """
        Evaluate if an analysis should be escalated for human review.
        """
        should_escalate = False
        reasons = []
        priority = "LOW"
        
        # Trigger A: CRITICAL RISK
        if analysis.risk_level == self.critical_risk_threshold:
            should_escalate = True
            reasons.append("CRITICAL_RISK")
            priority = "HIGH"
            
        # Trigger B: ML / LLM DISAGREEMENT
        if analysis.classification and analysis.llm_reasoning:
            # We assume llm_reasoning contains some extracted classification if available, 
            # or we rely on a simplified heuristic if LLM confidence is low while ML is high.
            # In a full implementation, LLM output should have a distinct classification field.
            # Here we check if ML confidence is high but LLM confidence is low, indicating disagreement.
            if analysis.ml_probability and analysis.llm_confidence:
                if (analysis.ml_probability > 0.8 and analysis.llm_confidence < 0.5) or \
                   (analysis.ml_probability < 0.2 and analysis.llm_confidence > 0.8):
                    should_escalate = True
                    reasons.append("ML_LLM_DISAGREEMENT")
                    priority = "URGENT" if priority in ["HIGH", "URGENT"] else "MEDIUM"
        
        # Trigger C: INSUFFICIENT RAG
        # If RAG returned no evidence but risk score is somewhat elevated
        if not analysis.retrieved_evidences and (analysis.risk_score or 0) > 40:
            should_escalate = True
            reasons.append("INSUFFICIENT_RAG")
            priority = max_priority(priority, "MEDIUM")
            
        # Trigger D: LOW MODEL CONFIDENCE
        if analysis.ml_probability is not None:
            # If the model is uncertain (e.g. between 0.4 and 0.6)
            if 0.4 <= analysis.ml_probability <= 0.6:
                should_escalate = True
                reasons.append("LOW_MODEL_CONFIDENCE")
                priority = max_priority(priority, "MEDIUM")

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
        
        self.log_event(review_case.id, user_id, "CASE_CREATED", None, "PENDING", "User requested human verification.")
        
        return review_case

    def create_escalated_case(self, analysis: Analysis, evaluation: dict) -> ReviewCase:
        """
        Creates a review case based on backend evaluation.
        """
        existing_case = self.db.query(ReviewCase).filter(ReviewCase.analysis_id == analysis.id).first()
        if existing_case:
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

def max_priority(p1: str, p2: str) -> str:
    levels = {"LOW": 1, "MEDIUM": 2, "HIGH": 3, "URGENT": 4}
    l1 = levels.get(p1, 1)
    l2 = levels.get(p2, 1)
    return p1 if l1 >= l2 else p2
