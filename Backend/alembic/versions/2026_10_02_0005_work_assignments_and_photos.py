"""Create work assignments, work photos, and work status logs tables

Revision ID: 0005_work_assignments_and_photos
Revises: 0004_payments_and_audit
Create Date: 2026-10-02 11:35:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '0005_work_assignments_and_photos'
down_revision: Union[str, None] = '0004_payments_and_audit'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Work Assignments table
    op.create_table(
        'work_assignments',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('customer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('customers.id', ondelete='CASCADE'), nullable=False),
        sa.Column('work_type', sa.String(length=50), nullable=False),
        sa.Column('team_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('teams.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('scheduled_start', sa.Date(), nullable=False),
        sa.Column('scheduled_end', sa.Date(), nullable=False),
        sa.Column('actual_start', sa.DateTime(timezone=True), nullable=True),
        sa.Column('actual_end', sa.DateTime(timezone=True), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=False, default='pending'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('assigned_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=False),
    )
    op.create_index('ix_work_assignments_customer_id', 'work_assignments', ['customer_id'])
    op.create_index('ix_work_assignments_work_type', 'work_assignments', ['work_type'])
    op.create_index('ix_work_assignments_team_id', 'work_assignments', ['team_id'])
    op.create_index('ix_work_assignments_status', 'work_assignments', ['status'])
    op.create_index('ix_work_assignments_scheduled_start', 'work_assignments', ['scheduled_start'])
    op.create_index('ix_work_assignments_scheduled_end', 'work_assignments', ['scheduled_end'])

    # 2. Work Photos table
    op.create_table(
        'work_photos',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('work_assignment_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('work_assignments.id', ondelete='CASCADE'), nullable=False),
        sa.Column('file_key', sa.String(length=255), nullable=False),
        sa.Column('caption', sa.String(length=255), nullable=True),
        sa.Column('uploaded_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_work_photos_work_assignment_id', 'work_photos', ['work_assignment_id'])
    op.create_index('ix_work_photos_uploaded_by', 'work_photos', ['uploaded_by'])

    # 3. Work Status Logs table
    op.create_table(
        'work_status_logs',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('work_assignment_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('work_assignments.id', ondelete='CASCADE'), nullable=False),
        sa.Column('from_status', sa.String(length=50), nullable=True),
        sa.Column('to_status', sa.String(length=50), nullable=False),
        sa.Column('changed_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_work_status_logs_work_assignment_id', 'work_status_logs', ['work_assignment_id'])
    op.create_index('ix_work_status_logs_changed_by', 'work_status_logs', ['changed_by'])


def downgrade() -> None:
    op.drop_table('work_status_logs')
    op.drop_table('work_photos')
    op.drop_table('work_assignments')
