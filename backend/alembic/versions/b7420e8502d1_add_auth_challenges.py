"""Add persisted email verification challenges."""

from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "b7420e8502d1"
down_revision: Union[str, Sequence[str], None] = "6d1511ddd859"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "auth_challenges",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("challenge_id_hash", sa.String(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("purpose", sa.String(), nullable=False),
        sa.Column("code_hash", sa.String(), nullable=False),
        sa.Column("expires_at", sa.DateTime(), nullable=False),
        sa.Column("attempts", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("consumed_at", sa.DateTime(), nullable=True),
        sa.Column("created_at", sa.DateTime(), server_default=sa.text("now()"), nullable=False),
        sa.ForeignKeyConstraint(["user_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
        sa.UniqueConstraint("challenge_id_hash"),
    )
    op.create_index(op.f("ix_auth_challenges_id"), "auth_challenges", ["id"])
    op.create_index(
        op.f("ix_auth_challenges_challenge_id_hash"),
        "auth_challenges",
        ["challenge_id_hash"],
    )
    op.create_index(op.f("ix_auth_challenges_user_id"), "auth_challenges", ["user_id"])
    op.create_index(op.f("ix_auth_challenges_purpose"), "auth_challenges", ["purpose"])


def downgrade() -> None:
    op.drop_index(op.f("ix_auth_challenges_purpose"), table_name="auth_challenges")
    op.drop_index(op.f("ix_auth_challenges_user_id"), table_name="auth_challenges")
    op.drop_index(
        op.f("ix_auth_challenges_challenge_id_hash"),
        table_name="auth_challenges",
    )
    op.drop_index(op.f("ix_auth_challenges_id"), table_name="auth_challenges")
    op.drop_table("auth_challenges")
