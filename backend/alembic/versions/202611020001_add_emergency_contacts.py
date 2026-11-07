"""Add emergency_contacts table.

Revision ID: 202611020001
Revises: 202610090001
"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202611020001"
down_revision: Union[str, Sequence[str], None] = "202610090001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "emergency_contacts",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("phone_number", sa.String(length=20), nullable=False),
        sa.Column("relationship_type", sa.String(length=50), nullable=True, server_default="Family"),
        sa.Column("is_active", sa.Boolean(), nullable=False, server_default=sa.true()),
        sa.Column("notify_sms", sa.Boolean(), nullable=False, server_default=sa.true()),
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
    op.create_index("ix_emergency_contacts_id", "emergency_contacts", ["id"])
    op.create_index("ix_emergency_contacts_user_id", "emergency_contacts", ["user_id"])


def downgrade() -> None:
    op.drop_index("ix_emergency_contacts_user_id", table_name="emergency_contacts")
    op.drop_index("ix_emergency_contacts_id", table_name="emergency_contacts")
    op.drop_table("emergency_contacts")

