"""Preserve access for accounts created before email verification was added.

Revision ID: 202610080001
Revises: 202610070001
"""
from datetime import datetime, timezone
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "202610080001"
down_revision: Union[str, Sequence[str], None] = "202610070001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.execute(
        sa.text(
            "UPDATE users SET email_verified = TRUE "
            "WHERE email_verified = FALSE "
            "AND created_at < :legacy_cutoff"
        ).bindparams(
            sa.bindparam(
                "legacy_cutoff",
                value=datetime(2026, 10, 7, tzinfo=timezone.utc),
                type_=sa.DateTime(timezone=True),
            )
        )
    )


def downgrade() -> None:
    # Verification is user state; a downgrade must not revoke it.
    pass
