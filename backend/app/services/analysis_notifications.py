import logging
import json

from database import SessionLocal
from models import Analysis
from app.services.email_service import EmailDeliveryError, email_service
from app.services.jira_service import JiraService


logger = logging.getLogger(__name__)


def process_analysis_notifications(analysis_id: int) -> None:
    db = SessionLocal()
    try:
        analysis = db.query(Analysis).filter(Analysis.id == analysis_id).first()
        if analysis is None:
            logger.error("Notifications skipped because analysis %s was not found.", analysis_id)
            return

        if analysis.risk_level in {"HIGH", "CRITICAL"}:
            try:
                if not analysis.review_case or analysis.escalation_status != "ESCALATED":
                    raise RuntimeError("Automatic review case is unavailable.")
                jira_result = JiraService(db).create_issue_for_review_case(
                    analysis.review_case.id,
                    actor_id=None,
                )
                if jira_result.get("success"):
                    analysis.jira_status = "CREATED"
                    analysis.jira_issue_key = jira_result.get("issue_key")
                    analysis.jira_issue_url = jira_result.get("issue_url")
                else:
                    analysis.jira_status = "FAILED"
                    logger.warning(
                        "Jira escalation failed for analysis %s: %s",
                        analysis_id,
                        jira_result.get("error", "unknown integration error"),
                    )
                db.commit()
            except Exception:
                db.rollback()
                logger.exception("Jira escalation failed for analysis %s.", analysis_id)
                try:
                    analysis = db.query(Analysis).filter(Analysis.id == analysis_id).first()
                    if analysis is not None:
                        analysis.jira_status = "FAILED"
                        db.commit()
                except Exception:
                    db.rollback()
                    logger.exception(
                        "Unable to persist Jira failure status for analysis %s.",
                        analysis_id,
                    )

        try:
            analysis = db.query(Analysis).filter(Analysis.id == analysis_id).first()
            if analysis is None:
                logger.error(
                    "Analysis email skipped because analysis %s was not found.",
                    analysis_id,
                )
                return
            recommended_action = analysis.recommended_action or ""
            try:
                stored_actions = json.loads(recommended_action)
                if isinstance(stored_actions, dict):
                    canonical_actions = stored_actions.get("canonical")
                    if isinstance(canonical_actions, list):
                        recommended_action = " ".join(
                            action for action in canonical_actions
                            if isinstance(action, str)
                        )
            except json.JSONDecodeError:
                pass
            email_service.send_analysis_report(
                analysis.user.email,
                analysis_id=analysis.id,
                risk_level=analysis.risk_level or "LOW",
                risk_score=analysis.risk_score or 0,
                classification=analysis.classification or "UNKNOWN",
                category=analysis.category or "General",
                recommended_action=recommended_action,
                jira_status=analysis.jira_status or "NOT_REQUIRED",
                jira_issue_key=analysis.jira_issue_key,
                jira_issue_url=analysis.jira_issue_url,
            )
            analysis.email_notification_status = "SENT"
            db.commit()
        except EmailDeliveryError:
            db.rollback()
            logger.warning("Analysis email delivery failed for analysis %s.", analysis_id)
            try:
                analysis = db.query(Analysis).filter(Analysis.id == analysis_id).first()
                if analysis is not None:
                    analysis.email_notification_status = "FAILED"
                    db.commit()
            except Exception:
                db.rollback()
                logger.exception(
                    "Unable to persist email failure status for analysis %s.",
                    analysis_id,
                )
        except Exception:
            db.rollback()
            logger.exception("Analysis email processing failed for analysis %s.", analysis_id)
            try:
                analysis = db.query(Analysis).filter(Analysis.id == analysis_id).first()
                if analysis is not None:
                    analysis.email_notification_status = "FAILED"
                    db.commit()
            except Exception:
                db.rollback()
                logger.exception(
                    "Unable to persist email processing failure for analysis %s.",
                    analysis_id,
                )
    finally:
        db.close()
