import json
import logging
import os
from urllib.parse import urlsplit

import requests
from requests.auth import HTTPBasicAuth
from sqlalchemy.orm import Session

from models import JiraIntegration, ReviewCase, ReviewCaseEvent


logger = logging.getLogger(__name__)
JIRA_HOST = "joshithagosangari.atlassian.net"
JIRA_PROJECT_KEY = "SCAM"


class JiraService:
    def __init__(self, db: Session):
        self.db = db
        self.enabled = os.getenv("JIRA_ENABLED", "false").lower() == "true"
        self.base_url = (
            os.getenv("JIRA_URL") or os.getenv("JIRA_BASE_URL") or ""
        ).rstrip("/")
        self.email = os.getenv("JIRA_EMAIL")
        self.api_token = os.getenv("JIRA_API_TOKEN")
        self.project_key = os.getenv("JIRA_PROJECT_KEY", "")

    def _configuration_error(self) -> str | None:
        if not self.enabled:
            return "Jira integration is disabled."
        parsed_url = urlsplit(self.base_url)
        if (
            parsed_url.scheme != "https"
            or parsed_url.hostname != JIRA_HOST
            or parsed_url.username
            or parsed_url.password
            or parsed_url.path not in ("", "/")
            or parsed_url.query
            or parsed_url.fragment
        ):
            return "Jira URL must point to the configured ScamShield Atlassian instance."
        if self.project_key != JIRA_PROJECT_KEY:
            return "Jira project key must be SCAM."
        if not self.email or not self.api_token:
            return "Jira credentials are not configured."
        return None

    def _record_failure(self, review_case_id: int, actor_id: int | None, status: int | None) -> None:
        self.db.add(
            ReviewCaseEvent(
                review_case_id=review_case_id,
                actor_user_id=actor_id,
                event_type="JIRA_SYNC_FAILED",
                notes=(
                    f"Jira returned HTTP {status}."
                    if status is not None
                    else "Jira connection failed."
                ),
            )
        )
        self.db.commit()

    def create_issue_for_review_case(
        self,
        review_case_id: int,
        actor_id: int | None,
    ) -> dict:
        configuration_error = self._configuration_error()
        if configuration_error:
            return {"success": False, "error": configuration_error}
        if not self.email or not self.api_token:
            return {"success": False, "error": "Jira credentials are not configured."}

        review_case = (
            self.db.query(ReviewCase)
            .filter(ReviewCase.id == review_case_id)
            .first()
        )
        if not review_case:
            return {"success": False, "error": "Review case not found."}

        if (
            not review_case.analysis
            or review_case.analysis.escalation_status != "ESCALATED"
            or review_case.analysis.risk_level not in {"HIGH", "CRITICAL"}
        ):
            return {
                "success": False,
                "error": "Only automatically escalated cases can be sent to Jira.",
            }

        reasons = review_case.escalation_reasons_json or []
        if isinstance(reasons, str):
            try:
                reasons = json.loads(reasons)
            except json.JSONDecodeError:
                reasons = []
        if not isinstance(reasons, list) or not reasons:
            reasons = (review_case.escalation_reason or "").split(",")
        if any(str(reason).strip().upper() == "USER_REQUEST" for reason in reasons):
            return {
                "success": False,
                "error": "User-requested reviews are not sent to Jira.",
            }

        existing = (
            self.db.query(JiraIntegration)
            .filter(JiraIntegration.review_case_id == review_case_id)
            .first()
        )
        if existing:
            return {
                "success": True,
                "issue_key": existing.jira_issue_key,
                "issue_url": f"{self.base_url}/browse/{existing.jira_issue_key}",
                "message": "Jira ticket already exists.",
            }

        analysis = review_case.analysis
        recommended_actions = analysis.recommended_action or ""
        if isinstance(recommended_actions, str):
            try:
                parsed_actions = json.loads(recommended_actions)
                if isinstance(parsed_actions, dict):
                    canonical_actions = parsed_actions.get("canonical")
                    if isinstance(canonical_actions, list):
                        recommended_actions = "; ".join(
                            str(action) for action in canonical_actions[:3]
                        )
            except json.JSONDecodeError:
                pass
        description_text = (
            f"ScamShield review case RV-{review_case.id}\n"
            f"Analysis ID: {analysis.id}\n"
            f"Risk level: {analysis.risk_level or 'N/A'}\n"
            f"Risk score: {analysis.risk_score if analysis.risk_score is not None else 'N/A'}\n"
            f"Classification: {analysis.classification or 'N/A'}\n"
            f"Category: {analysis.category or 'N/A'}\n"
            f"Escalation reason: {review_case.escalation_reason or 'N/A'}\n\n"
            f"Recommended action: {recommended_actions or 'Review the analysis in ScamShield.'}\n\n"
            f"Review in ScamShield: "
            f"{os.getenv('FRONTEND_URL', 'http://localhost:5173').rstrip('/')}"
            f"/admin/reviews/{review_case.id}"
        )
        payload = {
            "fields": {
                "project": {"key": JIRA_PROJECT_KEY},
                "summary": f"[ScamShield] Escalated review RV-{review_case.id}",
                "description": {
                    "type": "doc",
                    "version": 1,
                    "content": [
                        {
                            "type": "paragraph",
                            "content": [{"type": "text", "text": description_text}],
                        }
                    ],
                },
                "issuetype": {"name": "Task"},
            }
        }

        try:
            response = requests.post(
                f"{self.base_url}/rest/api/3/issue",
                json=payload,
                auth=HTTPBasicAuth(self.email, self.api_token),
                headers={"Accept": "application/json", "Content-Type": "application/json"},
                timeout=10,
            )
            if response.status_code != 201:
                self._record_failure(review_case_id, actor_id, response.status_code)
                logger.error(
                    "Jira issue creation failed for review case %s (HTTP %s).",
                    review_case_id,
                    response.status_code,
                )
                return {
                    "success": False,
                    "error": f"Jira issue creation failed (HTTP {response.status_code}).",
                }

            data = response.json()
            issue_key = data.get("key")
            issue_id = data.get("id")
            if not issue_key or not issue_id:
                raise ValueError("Jira response did not contain an issue key and ID.")

            self.db.add(
                JiraIntegration(
                    review_case_id=review_case_id,
                    jira_issue_id=str(issue_id),
                    jira_issue_key=str(issue_key),
                    status="CREATED",
                )
            )
            self.db.add(
                ReviewCaseEvent(
                    review_case_id=review_case_id,
                    actor_user_id=actor_id,
                    event_type="JIRA_CREATED",
                    notes=f"Linked to Jira Issue: {issue_key}",
                )
            )
            self.db.commit()
            return {
                "success": True,
                "issue_key": issue_key,
                "issue_url": f"{self.base_url}/browse/{issue_key}",
            }
        except (requests.RequestException, ValueError):
            self.db.rollback()
            logger.exception(
                "Jira integration failed while creating a ticket for review case %s.",
                review_case_id,
            )
            self._record_failure(review_case_id, actor_id, None)
            return {
                "success": False,
                "error": "Jira connection or response failed; details were recorded in the review audit log.",
            }
