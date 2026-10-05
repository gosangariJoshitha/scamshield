import html
import logging
import os

import requests


logger = logging.getLogger(__name__)


class EmailDeliveryError(RuntimeError):
    pass


class EmailService:
    def __init__(self) -> None:
        self.api_key = os.getenv("SENDGRID_API_KEY", "").strip()
        self.sender_email = (
            os.getenv("SENDGRID_SENDER_EMAIL")
            or os.getenv("SENDGRID_FROM_EMAIL")
            or ""
        ).strip()

    @property
    def is_configured(self) -> bool:
        return bool(self.api_key and self.sender_email)

    def send_verification_code(
        self,
        recipient: str,
        code: str,
        purpose: str,
    ) -> None:
        if not self.is_configured:
            raise EmailDeliveryError("Email delivery is not configured.")

        if purpose == "LOGIN":
            subject = "Your ScamShield sign-in verification code"
            action = "complete your ScamShield sign-in"
        elif purpose == "EMAIL_VERIFICATION":
            subject = "Verify your ScamShield email address"
            action = "verify your ScamShield email address"
        elif purpose == "PASSWORD_RESET":
            subject = "Your ScamShield password reset code"
            action = "reset your ScamShield password"
        else:
            raise ValueError("Unsupported verification email purpose.")

        text_content = (
            f"Use this verification code to {action}: {code}\n"
            "This code expires in 10 minutes. If you did not request it, "
            "you can ignore this email."
        )
        html_content = (
            "<p>Use this verification code to "
            f"{html.escape(action)}:</p>"
            f"<p style=\"font-size:24px;font-weight:bold;letter-spacing:4px\">"
            f"{html.escape(code)}</p>"
            "<p>This code expires in 10 minutes. If you did not request it, "
            "you can ignore this email.</p>"
        )
        payload = {
            "personalizations": [{"to": [{"email": recipient}]}],
            "from": {"email": self.sender_email},
            "subject": subject,
            "content": [
                {"type": "text/plain", "value": text_content},
                {"type": "text/html", "value": html_content},
            ],
        }

        try:
            response = requests.post(
                "https://api.sendgrid.com/v3/mail/send",
                json=payload,
                headers={
                    "Authorization": f"Bearer {self.api_key}",
                    "Content-Type": "application/json",
                },
                timeout=10,
            )
        except requests.RequestException as exc:
            logger.error("SendGrid email request failed (%s).", type(exc).__name__)
            raise EmailDeliveryError("Email could not be delivered.") from exc

        if response.status_code != 202:
            logger.error(
                "SendGrid rejected an email request (HTTP %s).",
                response.status_code,
            )
            raise EmailDeliveryError("Email could not be delivered.")

    def send_analysis_report(
        self,
        recipient: str,
        *,
        analysis_id: int,
        risk_level: str,
        risk_score: int,
        classification: str,
        category: str,
        recommended_action: str,
        jira_status: str,
        jira_issue_key: str | None,
        jira_issue_url: str | None,
    ) -> None:
        if not self.is_configured:
            raise EmailDeliveryError("Email delivery is not configured.")

        subject = f"ScamShield Analysis — {risk_level.title()} Risk"
        incident = (
            f"\nJira incident: {jira_issue_key} ({jira_issue_url})"
            if jira_issue_key and jira_issue_url
            else (
                f"\nJira escalation status: {jira_status}"
                if jira_status != "NOT_REQUIRED"
                else "\nJira escalation: Not required"
            )
        )
        text_content = (
            f"Analysis ID: {analysis_id}\n"
            f"Risk Score: {risk_score}/100\n"
            f"Classification: {classification}\n"
            f"Category: {category or 'General'}\n"
            f"Recommended Action: {recommended_action or 'Review the result in ScamShield.'}"
            f"{incident}\n\n"
            "This summary does not include the original submitted message."
        )
        html_content = (
            f"<h2>{html.escape(subject)}</h2>"
            f"<p><strong>Analysis ID:</strong> {analysis_id}</p>"
            f"<p><strong>Risk Score:</strong> {risk_score}/100</p>"
            f"<p><strong>Classification:</strong> {html.escape(classification)}</p>"
            f"<p><strong>Category:</strong> {html.escape(category or 'General')}</p>"
            f"<p><strong>Recommended Action:</strong> "
            f"{html.escape(recommended_action or 'Review the result in ScamShield.')}</p>"
            f"<p>{html.escape(incident.strip())}</p>"
            "<p>This summary does not include the original submitted message.</p>"
        )
        payload = {
            "personalizations": [{"to": [{"email": recipient}]}],
            "from": {"email": self.sender_email},
            "subject": subject,
            "content": [
                {"type": "text/plain", "value": text_content},
                {"type": "text/html", "value": html_content},
            ],
        }
        try:
            response = requests.post(
                "https://api.sendgrid.com/v3/mail/send",
                json=payload,
                headers={
                    "Authorization": f"******",
                    "Content-Type": "application/json",
                },
                timeout=10,
            )
        except requests.RequestException as exc:
            logger.error("Analysis email request failed (%s).", type(exc).__name__)
            raise EmailDeliveryError("Email could not be delivered.") from exc

        if response.status_code != 202:
            logger.error(
                "SendGrid rejected an analysis email (HTTP %s).",
                response.status_code,
            )
            raise EmailDeliveryError("Email could not be delivered.")


email_service = EmailService()
