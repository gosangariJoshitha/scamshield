"""Add a durable outbox for analysis notifications.

Revision ID: 202610080002
Revises: 202610080001
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202610080002"
down_revision: Union[str, Sequence[str], None] = "202610080001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "analysis_notifications",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "analysis_id",
            sa.Integer(),
            sa.ForeignKey("analyses.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("channel", sa.String(), nullable=False),
        sa.Column("status", sa.String(), nullable=False, server_default="PENDING"),
        sa.Column("retry_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("last_attempt_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("next_attempt_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("error_summary", sa.String(), nullable=True),
        sa.Column("provider_reference", sa.String(), nullable=True),
        sa.Column("idempotency_key", sa.String(), nullable=False, unique=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column(
            "updated_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.UniqueConstraint(
            "analysis_id",
            "channel",
            name="uq_analysis_notification_channel",
        ),
        sa.CheckConstraint(
            "channel IN ('EMAIL', 'JIRA')",
            name="ck_analysis_notification_channel",
        ),
        sa.CheckConstraint(
            "status IN ('PENDING', 'PROCESSING', 'SENT', 'CREATED', 'FAILED', 'NOT_REQUIRED')",
            name="ck_analysis_notification_status",
        ),
    )
    op.create_index(
        "ix_analysis_notifications_status_next_attempt",
        "analysis_notifications",
        ["status", "next_attempt_at"],
    )
    op.execute(
        sa.text(
            """
            INSERT INTO analysis_notifications
                (analysis_id, channel, status, idempotency_key)
            SELECT id, 'EMAIL',
                   COALESCE(email_notification_status, 'PENDING'),
                   'analysis-' || CAST(id AS VARCHAR) || '-email'
            FROM analyses
            """
        )
    )
    op.execute(
        sa.text(
            """
            INSERT INTO analysis_notifications
                (analysis_id, channel, status, idempotency_key, provider_reference)
            SELECT id, 'JIRA',
                   CASE
                       WHEN jira_issue_key IS NOT NULL THEN 'CREATED'
                       WHEN jira_status IN ('FAILED', 'PENDING') THEN jira_status
                       ELSE 'PENDING'
                   END,
                   'analysis-' || CAST(id AS VARCHAR) || '-jira',
                   jira_issue_key
            FROM analyses
            WHERE risk_level IN ('HIGH', 'CRITICAL')
            """
        )
    )


def downgrade() -> None:
    op.drop_index(
        "ix_analysis_notifications_status_next_attempt",
        table_name="analysis_notifications",
    )
    op.drop_table("analysis_notifications")
