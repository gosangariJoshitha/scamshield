"""Add email verification and analysis notification tracking.

Revision ID: 202610070001
Revises: 202610060001
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202610070001"
down_revision: Union[str, Sequence[str], None] = "202610060001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "users",
        sa.Column(
            "email_verified",
            sa.Boolean(),
            nullable=False,
            server_default=sa.false(),
        ),
    )
    op.add_column(
        "analyses",
        sa.Column(
            "escalation_status",
            sa.String(),
            nullable=False,
            server_default="NOT_ESCALATED",
        ),
    )
    op.add_column(
        "analyses",
        sa.Column(
            "email_notification_status",
            sa.String(),
            nullable=False,
            server_default="NOT_REQUIRED",
        ),
    )
    op.add_column(
        "analyses",
        sa.Column(
            "jira_status",
            sa.String(),
            nullable=False,
            server_default="NOT_REQUIRED",
        ),
    )
    op.add_column(
        "analyses",
        sa.Column("jira_issue_key", sa.String(), nullable=True),
    )
    op.add_column(
        "analyses",
        sa.Column("jira_issue_url", sa.String(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("analyses", "jira_issue_url")
    op.drop_column("analyses", "jira_issue_key")
    op.drop_column("analyses", "jira_status")
    op.drop_column("analyses", "email_notification_status")
    op.drop_column("analyses", "escalation_status")
    op.drop_column("users", "email_verified")
