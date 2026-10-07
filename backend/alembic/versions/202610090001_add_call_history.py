"""Add call_history table for M9.9 protected call summaries.

Revision ID: 202610090001
Revises: 202610080002
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202610090001"
down_revision: Union[str, Sequence[str], None] = "202610080002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "call_history",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("session_id", sa.String(), nullable=False),
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("started_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column(
            "ended_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.Column("duration_seconds", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("guardian_enabled", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("guardian_status", sa.String(), nullable=False, server_default="ENABLED"),
        sa.Column("final_risk_score", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("final_risk_level", sa.String(), nullable=False, server_default="LOW"),
        sa.Column("classification", sa.String(), nullable=False, server_default="GENUINE"),
        sa.Column("scam_category", sa.String(), nullable=False, server_default="General"),
        sa.Column("risk_reasoning", sa.Text(), nullable=True),
        sa.Column("safe_action", sa.Text(), nullable=True),
        sa.Column("detected_indicators", sa.JSON(), nullable=True),
        sa.Column("supporting_evidence", sa.JSON(), nullable=True),
        sa.Column("protection_actions", sa.JSON(), nullable=True),
        sa.Column("analysis_status", sa.String(), nullable=False, server_default="COMPLETED"),
        sa.Column("transcription_status", sa.String(), nullable=False, server_default="COMPLETED"),
        sa.Column("audio_status", sa.String(), nullable=False, server_default="AVAILABLE"),
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
    )
    op.create_index("ix_call_history_id", "call_history", ["id"])
    op.create_index("ix_call_history_session_id", "call_history", ["session_id"], unique=True)
    op.create_index("ix_call_history_user_id", "call_history", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_call_history_user_id", table_name="call_history")
    op.drop_index("ix_call_history_session_id", table_name="call_history")
    op.drop_index("ix_call_history_id", table_name="call_history")
    op.drop_table("call_history")
