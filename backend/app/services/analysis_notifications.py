import json
import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import or_

from database import SessionLocal
from models import Analysis, AnalysisNotification
from app.services.email_service import EmailDeliveryError, email_service
from app.services.jira_service import JiraService


logger = logging.getLogger(__name__)
MAX_NOTIFICATION_RETRIES = 3


def _ensure_outbox_rows(db, analysis: Analysis) -> None:
    if analysis.notifications:
        return
    db.add(
        AnalysisNotification(
            analysis_id=analysis.id,
            channel="EMAIL",
            status="PENDING",
            idempotency_key=f"analysis-{analysis.id}-email",
        )
    )
    if analysis.risk_level in {"HIGH", "CRITICAL"}:
        db.add(
            AnalysisNotification(
                analysis_id=analysis.id,
                channel="JIRA",
                status="PENDING",
                idempotency_key=f"analysis-{analysis.id}-jira",
            )
        )
    db.commit()


def _claim_notification(db, notification_id: int) -> AnalysisNotification | None:
    now = datetime.now(timezone.utc)
    notification = (
        db.query(AnalysisNotification)
        .filter(AnalysisNotification.id == notification_id)
        .with_for_update(skip_locked=True)
        .first()
    )
    if notification is None or notification.status in {
        "PROCESSING", "SENT", "CREATED", "NOT_REQUIRED"
    }:
        return None
    if notification.status == "FAILED":
        next_attempt_at = notification.next_attempt_at
        if next_attempt_at is not None and next_attempt_at.tzinfo is None:
            next_attempt_at = next_attempt_at.replace(tzinfo=timezone.utc)
        if (
            notification.retry_count >= MAX_NOTIFICATION_RETRIES
            or next_attempt_at is None
            or next_attempt_at > now
        ):
            return None
    notification.status = "PROCESSING"
    notification.retry_count += 1
    notification.last_attempt_at = now
    notification.next_attempt_at = None
    notification.error_summary = None
    db.commit()
    return notification


def _set_retry_or_failure(
    notification: AnalysisNotification,
    *,
    retryable: bool,
    summary: str,
) -> None:
    notification.status = "FAILED"
    notification.error_summary = summary[:500]
    if retryable and notification.retry_count < MAX_NOTIFICATION_RETRIES:
        delay_seconds = min(30 * (2 ** (notification.retry_count - 1)), 600)
        notification.next_attempt_at = datetime.now(timezone.utc) + timedelta(
            seconds=delay_seconds
        )
    else:
        notification.next_attempt_at = None


def _process_jira(db, analysis: Analysis, notification: AnalysisNotification) -> None:
    if not analysis.review_case or analysis.escalation_status != "ESCALATED":
        _set_retry_or_failure(
            notification,
            retryable=False,
            summary="Automatic review case is unavailable.",
        )
        analysis.jira_status = "FAILED"
        db.commit()
        return

    result = JiraService(db).create_issue_for_review_case(
        analysis.review_case.id,
        actor_id=None,
    )
    if result.get("success"):
        notification.status = "CREATED"
        notification.provider_reference = result.get("issue_key")
        notification.error_summary = None
        analysis.jira_status = "CREATED"
        analysis.jira_issue_key = result.get("issue_key")
        analysis.jira_issue_url = result.get("issue_url")
    else:
        _set_retry_or_failure(
            notification,
            retryable=bool(result.get("retryable")),
            summary="Jira delivery failed.",
        )
        analysis.jira_status = "FAILED"
        logger.warning("Jira delivery failed for analysis %s.", analysis.id)
    db.commit()


def _process_email(db, analysis: Analysis, notification: AnalysisNotification) -> None:
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

    try:
        provider_reference = email_service.send_analysis_report(
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
            idempotency_key=notification.idempotency_key,
        )
    except EmailDeliveryError as exc:
        _set_retry_or_failure(
            notification,
            retryable=exc.retryable,
            summary="Email delivery failed.",
        )
        analysis.email_notification_status = "FAILED"
        logger.warning("Analysis email delivery failed for analysis %s.", analysis.id)
    else:
        notification.status = "SENT"
        notification.provider_reference = (
            provider_reference if isinstance(provider_reference, str) else None
        )
        notification.error_summary = None
        notification.next_attempt_at = None
        analysis.email_notification_status = "SENT"
    db.commit()


def process_analysis_notifications(analysis_id: int) -> None:
    db = SessionLocal()
    try:
        analysis = db.query(Analysis).filter(Analysis.id == analysis_id).first()
        if analysis is None:
            logger.error("Notifications skipped because analysis %s was not found.", analysis_id)
            return

        _ensure_outbox_rows(db, analysis)
        notification_ids = [
            row.id
            for row in sorted(
                analysis.notifications,
                key=lambda row: 0 if row.channel == "JIRA" else 1,
            )
        ]

        for notification_id in notification_ids:
            notification = _claim_notification(db, notification_id)
            if notification is None:
                continue
            analysis = db.query(Analysis).filter(Analysis.id == analysis_id).first()
            if analysis is None:
                logger.error("Analysis %s disappeared during notification delivery.", analysis_id)
                return
            try:
                if notification.channel == "JIRA":
                    _process_jira(db, analysis, notification)
                elif notification.channel == "EMAIL":
                    _process_email(db, analysis, notification)
            except Exception:
                db.rollback()
                logger.exception(
                    "Notification delivery failed for analysis %s.",
                    analysis_id,
                )
                failed = (
                    db.query(AnalysisNotification)
                    .filter(AnalysisNotification.id == notification_id)
                    .first()
                )
                analysis = db.query(Analysis).filter(Analysis.id == analysis_id).first()
                if failed is not None:
                    _set_retry_or_failure(
                        failed,
                        retryable=False,
                        summary="Notification delivery failed unexpectedly.",
                    )
                if analysis is not None:
                    if failed is not None and failed.channel == "JIRA":
                        analysis.jira_status = "FAILED"
                    elif failed is not None:
                        analysis.email_notification_status = "FAILED"
                db.commit()
    finally:
        db.close()


def process_pending_analysis_notifications(batch_size: int = 25) -> None:
    db = SessionLocal()
    try:
        now = datetime.now(timezone.utc)
        analysis_ids = [
            analysis_id
            for (analysis_id,) in db.query(AnalysisNotification.analysis_id)
            .filter(
                or_(
                    AnalysisNotification.status == "PENDING",
                    (
                        (AnalysisNotification.status == "FAILED")
                        & (AnalysisNotification.retry_count < MAX_NOTIFICATION_RETRIES)
                        & (AnalysisNotification.next_attempt_at <= now)
                    ),
                )
            )
            .order_by(AnalysisNotification.created_at)
            .limit(batch_size)
            .all()
        ]
    finally:
        db.close()

    for analysis_id in dict.fromkeys(analysis_ids):
        process_analysis_notifications(analysis_id)


def recover_interrupted_notifications() -> None:
    db = SessionLocal()
    try:
        cutoff = datetime.now(timezone.utc) - timedelta(minutes=5)
        stuck_rows = (
            db.query(AnalysisNotification)
            .filter(
                AnalysisNotification.status == "PROCESSING",
                AnalysisNotification.last_attempt_at < cutoff,
            )
            .with_for_update(skip_locked=True)
            .all()
        )
        for row in stuck_rows:
            row.status = "FAILED"
            if row.channel == "JIRA" and row.retry_count < MAX_NOTIFICATION_RETRIES:
                row.next_attempt_at = datetime.now(timezone.utc)
                row.error_summary = (
                    "Interrupted delivery will be reconciled by Jira idempotency lookup."
                )
            else:
                row.next_attempt_at = None
                row.error_summary = (
                    "Delivery was interrupted after starting; automatic retry suppressed "
                    "to prevent duplicate provider delivery."
                )
            analysis = db.query(Analysis).filter(Analysis.id == row.analysis_id).first()
            if analysis is not None:
                if row.channel == "JIRA":
                    analysis.jira_status = "FAILED"
                else:
                    analysis.email_notification_status = "FAILED"
        db.commit()
    except Exception:
        db.rollback()
        logger.exception("Unable to recover interrupted notification records.")
    finally:
        db.close()
