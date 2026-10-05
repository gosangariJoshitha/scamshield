"""Create the core application tables.

Revision ID: 000000000001
Revises:
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "000000000001"
down_revision: Union[str, Sequence[str], None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("full_name", sa.String(), nullable=True),
        sa.Column("email", sa.String(), nullable=False),
        sa.Column("password_hash", sa.String(), nullable=False),
        sa.Column("role", sa.String(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.Column("updated_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_users_id", "users", ["id"], unique=False)
    op.create_index("ix_users_full_name", "users", ["full_name"], unique=False)
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    op.create_table(
        "analyses",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=True),
        sa.Column("content", sa.String(), nullable=True),
        sa.Column("risk_score", sa.Integer(), nullable=True),
        sa.Column("risk_level", sa.String(), nullable=True),
        sa.Column("classification", sa.String(), nullable=True),
        sa.Column("ml_probability", sa.Float(), nullable=True),
        sa.Column("category", sa.String(), nullable=True),
        sa.Column("indicators", sa.JSON(), nullable=True),
        sa.Column("explanation", sa.String(), nullable=True),
        sa.Column("evidence", sa.JSON(), nullable=True),
        sa.Column("recommended_action", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_analyses_id", "analyses", ["id"], unique=False)

    op.create_table(
        "community_reports",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=True),
        sa.Column("content", sa.String(), nullable=False),
        sa.Column("category", sa.String(), nullable=True),
        sa.Column("description", sa.String(), nullable=True),
        sa.Column("evidence", sa.String(), nullable=True),
        sa.Column("status", sa.String(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("now()"), nullable=True),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_community_reports_id", "community_reports", ["id"], unique=False)


def downgrade() -> None:
    op.drop_index("ix_community_reports_id", table_name="community_reports")
    op.drop_table("community_reports")
    op.drop_index("ix_analyses_id", table_name="analyses")
    op.drop_table("analyses")
    op.drop_index("ix_users_email", table_name="users")
    op.drop_index("ix_users_full_name", table_name="users")
    op.drop_index("ix_users_id", table_name="users")
    op.drop_table("users")
