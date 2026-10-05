"""Persist the language-specific guidance used for analysis evidence.

Revision ID: 202610060001
Revises: 202610050001
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202610060001"
down_revision: Union[str, Sequence[str], None] = "202610050001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("analysis_evidence", sa.Column("language", sa.String(), nullable=True))
    op.add_column(
        "analysis_evidence",
        sa.Column("localized_safe_action", sa.String(), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("analysis_evidence", "localized_safe_action")
    op.drop_column("analysis_evidence", "language")
