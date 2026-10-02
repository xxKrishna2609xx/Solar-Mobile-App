"""Create service_tickets, ticket_images, ticket_comments, and ticket_status_logs tables

Revision ID: 0007_service_tickets
Revises: 0006_kedl_tracker
Create Date: 2026-10-02 11:50:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '0007_service_tickets'
down_revision: Union[str, None] = '0006_kedl_tracker'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Service Tickets table
    op.create_table(
        'service_tickets',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('ticket_no', sa.String(length=50), nullable=False),
        sa.Column('customer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('customers.id', ondelete='CASCADE'), nullable=False),
        sa.Column('type', sa.String(length=50), nullable=False),
        sa.Column('title', sa.String(length=200), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.Column('error_code', sa.String(length=50), nullable=True),
        sa.Column('status', sa.String(length=50), nullable=False, default='open'),
        sa.Column('priority', sa.String(length=50), nullable=False, default='normal'),
        sa.Column('assigned_to', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('resolved_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('resolution_note', sa.Text(), nullable=True),
        sa.Column('created_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.func.now(), onupdate=sa.func.now(), nullable=False),
    )
    op.create_index('ix_service_tickets_ticket_no', 'service_tickets', ['ticket_no'], unique=True)
    op.create_index('ix_service_tickets_customer_id', 'service_tickets', ['customer_id'])
    op.create_index('ix_service_tickets_type', 'service_tickets', ['type'])
    op.create_index('ix_service_tickets_status', 'service_tickets', ['status'])
    op.create_index('ix_service_tickets_priority', 'service_tickets', ['priority'])
    op.create_index('ix_service_tickets_assigned_to', 'service_tickets', ['assigned_to'])

    # 2. Ticket Images table
    op.create_table(
        'ticket_images',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('ticket_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('service_tickets.id', ondelete='CASCADE'), nullable=False),
        sa.Column('file_key', sa.String(length=255), nullable=False),
        sa.Column('uploaded_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_ticket_images_ticket_id', 'ticket_images', ['ticket_id'])

    # 3. Ticket Comments table
    op.create_table(
        'ticket_comments',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('ticket_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('service_tickets.id', ondelete='CASCADE'), nullable=False),
        sa.Column('author_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('message', sa.Text(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_ticket_comments_ticket_id', 'ticket_comments', ['ticket_id'])

    # 4. Ticket Status Logs table
    op.create_table(
        'ticket_status_logs',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('ticket_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('service_tickets.id', ondelete='CASCADE'), nullable=False),
        sa.Column('from_status', sa.String(length=50), nullable=True),
        sa.Column('to_status', sa.String(length=50), nullable=False),
        sa.Column('changed_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='SET NULL'), nullable=True),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now(), nullable=False),
    )
    op.create_index('ix_ticket_status_logs_ticket_id', 'ticket_status_logs', ['ticket_id'])


def downgrade() -> None:
    op.drop_table('ticket_status_logs')
    op.drop_table('ticket_comments')
    op.drop_table('ticket_images')
    op.drop_table('service_tickets')
