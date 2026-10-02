"""Create kedl_files, kedl_demands, kedl_documents, and kedl_status_logs tables

Revision ID: 0006_kedl_tracker
Revises: 0005_work_assignments_and_photos
Create Date: 2026-10-02 11:42:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '0006_kedl_tracker'
down_revision: Union[str, None] = '0005_work_assignments_and_photos'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Kedl Files table
    op.create_table(
        'kedl_files',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('customer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('customers.id', ondelete='CASCADE'), nullable=False),
        sa.Column('file_type', sa.String(length=50), nullable=False),
        sa.Column('status', sa.String(length=50), nullable=False, default='not_started'),
        sa.Column('application_no', sa.String(length=100), nullable=True),
        sa.Column('submitted_on', sa.DateTime(timezone=True), nullable=True),
        sa.Column('approved_on', sa.DateTime(timezone=True), nullable=True),
        sa.Column('assigned_to', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('remarks', sa.Text(), nullable=True),
        sa.Column('is_deleted', sa.Boolean(), default=False, nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=False),
        sa.UniqueConstraint('customer_id', 'file_type', name='uq_customer_kedl_file_type'),
    )
    op.create_index('ix_kedl_files_customer_id', 'kedl_files', ['customer_id'])
    op.create_index('ix_kedl_files_file_type', 'kedl_files', ['file_type'])
    op.create_index('ix_kedl_files_status', 'kedl_files', ['status'])
    op.create_index('ix_kedl_files_assigned_to', 'kedl_files', ['assigned_to'])
    op.create_index('ix_kedl_files_is_deleted', 'kedl_files', ['is_deleted'])

    # 2. Kedl Demands table
    op.create_table(
        'kedl_demands',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('kedl_file_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('kedl_files.id', ondelete='CASCADE'), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('amount', sa.BigInteger(), nullable=True, comment='Demand fee in paise if applicable'),
        sa.Column('due_date', sa.Date(), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=False, default='open'),
        sa.Column('paid_on', sa.DateTime(timezone=True), nullable=True),
        sa.Column('receipt_key', sa.String(length=255), nullable=True),
        sa.Column('raised_on', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('raised_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=False),
    )
    op.create_index('ix_kedl_demands_kedl_file_id', 'kedl_demands', ['kedl_file_id'])
    op.create_index('ix_kedl_demands_status', 'kedl_demands', ['status'])

    # 3. Kedl Documents table
    op.create_table(
        'kedl_documents',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('kedl_file_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('kedl_files.id', ondelete='CASCADE'), nullable=False),
        sa.Column('doc_type', sa.String(length=50), nullable=False, default='other'),
        sa.Column('file_key', sa.String(length=255), nullable=False),
        sa.Column('original_name', sa.String(length=255), nullable=False),
        sa.Column('uploaded_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=False),
    )
    op.create_index('ix_kedl_documents_kedl_file_id', 'kedl_documents', ['kedl_file_id'])

    # 4. Kedl Status Logs table
    op.create_table(
        'kedl_status_logs',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('kedl_file_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('kedl_files.id', ondelete='CASCADE'), nullable=False),
        sa.Column('from_status', sa.String(length=50), nullable=True),
        sa.Column('to_status', sa.String(length=50), nullable=False),
        sa.Column('changed_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_kedl_status_logs_kedl_file_id', 'kedl_status_logs', ['kedl_file_id'])


def downgrade() -> None:
    op.drop_table('kedl_status_logs')
    op.drop_table('kedl_documents')
    op.drop_table('kedl_demands')
    op.drop_table('kedl_files')
