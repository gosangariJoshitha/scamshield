"""Link community reports to their source analysis.

Revision ID: 202610050001
Revises: b7420e8502d1
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202610050001"
down_revision: Union[str, Sequence[str], None] = "b7420e8502d1"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "community_reports",
        sa.Column("analysis_id", sa.Integer(), nullable=True),
    )
    op.create_index(
        "ix_community_reports_analysis_id",
        "community_reports",
        ["analysis_id"],
        unique=False,
    )
    op.create_foreign_key(
        "fk_community_reports_analysis_id_analyses",
        "community_reports",
        "analyses",
        ["analysis_id"],
        ["id"],
    )


def downgrade() -> None:
    op.drop_constraint(
        "fk_community_reports_analysis_id_analyses",
        "community_reports",
        type_="foreignkey",
    )
    op.drop_index("ix_community_reports_analysis_id", table_name="community_reports")
    op.drop_column("community_reports", "analysis_id")
