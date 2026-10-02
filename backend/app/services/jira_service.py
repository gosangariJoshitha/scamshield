import os
import requests
from requests.auth import HTTPBasicAuth
from sqlalchemy.orm import Session
from models import ReviewCase, JiraIntegration, ReviewCaseEvent

class JiraService:
    def __init__(self, db: Session):
        self.db = db
        self.enabled = os.getenv("JIRA_ENABLED", "false").lower() == "true"
        self.base_url = os.getenv("JIRA_BASE_URL")
        self.email = os.getenv("JIRA_EMAIL")
        self.api_token = os.getenv("JIRA_API_TOKEN")
        self.project_key = os.getenv("JIRA_PROJECT_KEY")

    def create_issue_for_review_case(self, review_case_id: int, actor_id: int) -> dict:
        if not self.enabled:
            return {"success": False, "error": "Jira integration is disabled."}
            
        review_case = self.db.query(ReviewCase).filter(ReviewCase.id == review_case_id).first()
        if not review_case:
            return {"success": False, "error": "Review case not found."}
            
        # Check if already linked
        existing = self.db.query(JiraIntegration).filter(JiraIntegration.review_case_id == review_case_id).first()
        if existing:
            return {"success": True, "issue_key": existing.jira_issue_key, "message": "Jira ticket already exists."}
            
        # Prepare Jira API payload safely
        summary = f"[ScamShield] Review Case - RV-{review_case.id}"
        description = f"""ScamShield Review Case: RV-{review_case.id}
Risk Level: {review_case.analysis.risk_level if review_case.analysis else 'N/A'}
Risk Score: {review_case.analysis.risk_score if review_case.analysis else 'N/A'}
Escalation Reason: {review_case.escalation_reason}

ScamShield Review URL: {os.getenv('FRONTEND_URL', 'http://localhost:5173')}/admin/reviews/{review_case.id}
"""

        payload = {
            "fields": {
                "project": {
                    "key": self.project_key
                },
                "summary": summary,
                "description": description,
                "issuetype": {
                    "name": "Task"
                }
            }
        }
        
        try:
            url = f"{self.base_url}/rest/api/2/issue"
            auth = HTTPBasicAuth(self.email, self.api_token)
            headers = {
                "Accept": "application/json",
                "Content-Type": "application/json"
            }
            
            # Since this might run in a mock environment or without real credentials, 
            # we will handle failures gracefully.
            response = requests.post(url, json=payload, auth=auth, headers=headers, timeout=10)
            
            if response.status_code == 201:
                data = response.json()
                issue_key = data.get("key")
                issue_id = data.get("id")
                
                integration = JiraIntegration(
                    review_case_id=review_case_id,
                    jira_issue_id=issue_id,
                    jira_issue_key=issue_key,
                    status="CREATED"
                )
                self.db.add(integration)
                
                # Audit log
                event = ReviewCaseEvent(
                    review_case_id=review_case_id,
                    actor_user_id=actor_id,
                    event_type="JIRA_CREATED",
                    notes=f"Linked to Jira Issue: {issue_key}"
                )
                self.db.add(event)
                
                self.db.commit()
                return {"success": True, "issue_key": issue_key}
            else:
                # Jira API error
                event = ReviewCaseEvent(
                    review_case_id=review_case_id,
                    actor_user_id=actor_id,
                    event_type="JIRA_SYNC_FAILED",
                    notes=f"Failed to create Jira issue. Status: {response.status_code}"
                )
                self.db.add(event)
                self.db.commit()
                return {"success": False, "error": f"Jira API error: {response.text}"}
                
        except Exception as e:
            # Network or other error
            event = ReviewCaseEvent(
                review_case_id=review_case_id,
                actor_user_id=actor_id,
                event_type="JIRA_SYNC_FAILED",
                notes=f"Jira connection error: {str(e)}"
            )
            self.db.add(event)
            self.db.commit()
            return {"success": False, "error": f"Connection error: {str(e)}"}
