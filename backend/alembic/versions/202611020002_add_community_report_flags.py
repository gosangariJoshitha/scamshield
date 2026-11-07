"""Add community_report_flags table.

Revision ID: 202611020002
Revises: 202611020001
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202611020002"
down_revision: Union[str, Sequence[str], None] = "202611020001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "community_report_flags",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "report_id",
            sa.Integer(),
            sa.ForeignKey("community_reports.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column(
            "reporter_user_id",
            sa.Integer(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("reason", sa.String(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            nullable=False,
            server_default=sa.func.now(),
        ),
        sa.UniqueConstraint("report_id", "reporter_user_id", name="uq_report_reporter_flag"),
    )
    op.create_index("ix_community_report_flags_id", "community_report_flags", ["id"])
    op.create_index("ix_community_report_flags_report_id", "community_report_flags", ["report_id"])
    op.create_index("ix_community_report_flags_reporter_user_id", "community_report_flags", ["reporter_user_id"])


def downgrade() -> None:
    op.drop_index("ix_community_report_flags_reporter_user_id", table_name="community_report_flags")
    op.drop_index("ix_community_report_flags_report_id", table_name="community_report_flags")
    op.drop_index("ix_community_report_flags_id", table_name="community_report_flags")
    op.drop_table("community_report_flags")

