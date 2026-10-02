"""Create payments and payment audit logs tables

Revision ID: 0004_payments_and_audit
Revises: 0003_leads_customers_documents
Create Date: 2026-10-02 10:55:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '0004_payments_and_audit'
down_revision: Union[str, None] = '0003_leads_customers_documents'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Payments table
    op.create_table(
        'payments',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('customer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('customers.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('stage_no', sa.Integer(), nullable=False, default=1),
        sa.Column('amount', sa.BigInteger(), nullable=False, comment='Amount in paise'),
        sa.Column('mode', sa.String(length=50), nullable=False),
        sa.Column('reference_no', sa.String(length=100), nullable=True),
        sa.Column('paid_on', sa.DateTime(timezone=True), nullable=False),
        sa.Column('proof_key', sa.String(length=255), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=False, default='pending'),
        sa.Column('submitted_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('submitted_by_role', sa.String(length=50), nullable=False),
        sa.Column('sales_approved_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('sales_approved_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('verified_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('verified_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('rejection_reason', sa.Text(), nullable=True),
        sa.Column('remarks', sa.Text(), nullable=True),
        sa.Column('is_deleted', sa.Boolean(), default=False, nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=False),
    )
    op.create_index('ix_payments_customer_id', 'payments', ['customer_id'])
    op.create_index('ix_payments_status', 'payments', ['status'])
    op.create_index('ix_payments_submitted_by', 'payments', ['submitted_by'])
    op.create_index('ix_payments_is_deleted', 'payments', ['is_deleted'])

    # 2. Payment Audit Logs table
    op.create_table(
        'payment_audit_logs',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('payment_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('payments.id', ondelete='CASCADE'), nullable=False),
        sa.Column('action', sa.String(length=50), nullable=False),
        sa.Column('actor_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('old_status', sa.String(length=50), nullable=True),
        sa.Column('new_status', sa.String(length=50), nullable=False),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_payment_audit_logs_payment_id', 'payment_audit_logs', ['payment_id'])
    op.create_index('ix_payment_audit_logs_actor_id', 'payment_audit_logs', ['actor_id'])


def downgrade() -> None:
    op.drop_table('payment_audit_logs')
    op.drop_table('payments')
