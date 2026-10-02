"""Create leads, customers, documents, and stage history tables

Revision ID: 0003_leads_customers_documents
Revises: 0002_auth_users_teams
Create Date: 2026-10-02 10:40:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '0003_leads_customers_documents'
down_revision: Union[str, None] = '0002_auth_users_teams'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Customers table
    op.create_table(
        'customers',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('mobile', sa.String(length=20), nullable=False),
        sa.Column('address', sa.Text(), nullable=False),
        sa.Column('latitude', sa.Float(), nullable=True),
        sa.Column('longitude', sa.Float(), nullable=True),
        sa.Column('sales_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('final_price', sa.BigInteger(), nullable=False, comment='Final price in paise'),
        sa.Column('capacity_kw', sa.Numeric(precision=6, scale=2), nullable=False),
        sa.Column('phase', sa.String(length=20), nullable=False),
        sa.Column('panel_brand', sa.String(length=100), nullable=False),
        sa.Column('panel_watt', sa.Integer(), nullable=False),
        sa.Column('panel_count', sa.Integer(), nullable=False),
        sa.Column('inverter_brand', sa.String(length=100), nullable=False),
        sa.Column('structure_type', sa.String(length=100), nullable=False),
        sa.Column('stage', sa.String(length=50), nullable=False, default='SALE_CONFIRMED'),
        sa.Column('sale_closed_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('is_deleted', sa.Boolean(), default=False, nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=False),
    )
    op.create_index('ix_customers_mobile', 'customers', ['mobile'], unique=True)
    op.create_index('ix_customers_sales_id', 'customers', ['sales_id'])
    op.create_index('ix_customers_user_id', 'customers', ['user_id'])
    op.create_index('ix_customers_stage', 'customers', ['stage'])
    op.create_index('ix_customers_is_deleted', 'customers', ['is_deleted'])

    # 2. Leads table
    op.create_table(
        'leads',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('name', sa.String(length=100), nullable=False),
        sa.Column('phone', sa.String(length=20), nullable=False),
        sa.Column('address', sa.Text(), nullable=True),
        sa.Column('expected_kw', sa.Numeric(precision=6, scale=2), nullable=True),
        sa.Column('source', sa.String(length=100), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=False, default='new'),
        sa.Column('follow_up_date', sa.DateTime(timezone=True), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('assigned_sales_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('customer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('customers.id', ondelete='SET NULL'), nullable=True),
        sa.Column('lost_reason', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=False),
    )
    op.create_index('ix_leads_phone', 'leads', ['phone'])
    op.create_index('ix_leads_status', 'leads', ['status'])
    op.create_index('ix_leads_assigned_sales_id', 'leads', ['assigned_sales_id'])
    op.create_index('ix_leads_customer_id', 'leads', ['customer_id'])

    # 3. Customer Documents table
    op.create_table(
        'customer_documents',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('customer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('customers.id', ondelete='CASCADE'), nullable=False),
        sa.Column('type', sa.String(length=50), nullable=False),
        sa.Column('file_key', sa.String(length=255), nullable=False),
        sa.Column('original_name', sa.String(length=255), nullable=False),
        sa.Column('mime_type', sa.String(length=100), nullable=False),
        sa.Column('size_bytes', sa.BigInteger(), nullable=False),
        sa.Column('uploaded_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=False),
    )
    op.create_index('ix_customer_documents_customer_id', 'customer_documents', ['customer_id'])
    op.create_index('ix_customer_documents_type', 'customer_documents', ['type'])
    op.create_index('ix_customer_documents_uploaded_by', 'customer_documents', ['uploaded_by'])

    # 4. Stage Histories table
    op.create_table(
        'stage_histories',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('customer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('customers.id', ondelete='CASCADE'), nullable=False),
        sa.Column('from_stage', sa.String(length=50), nullable=True),
        sa.Column('to_stage', sa.String(length=50), nullable=False),
        sa.Column('changed_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_stage_histories_customer_id', 'stage_histories', ['customer_id'])
    op.create_index('ix_stage_histories_changed_by', 'stage_histories', ['changed_by'])


def downgrade() -> None:
    op.drop_table('stage_histories')
    op.drop_table('customer_documents')
    op.drop_table('leads')
    op.drop_table('customers')
