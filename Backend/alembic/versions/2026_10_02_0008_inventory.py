"""Create suppliers, inventory_items, stock_movements, serial_items, and planned_materials tables

Revision ID: 0008_inventory
Revises: 0007_service_tickets
Create Date: 2026-10-02 12:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '0008_inventory'
down_revision: Union[str, None] = '0007_service_tickets'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Suppliers Table
    op.create_table(
        'suppliers',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('name', sa.String(length=150), nullable=False),
        sa.Column('phone', sa.String(length=20), nullable=True),
        sa.Column('address', sa.Text(), nullable=True),
        sa.Column('gst_no', sa.String(length=30), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('is_deleted', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    )
    op.create_index('ix_suppliers_name', 'suppliers', ['name'])

    # 2. Inventory Items Table
    op.create_table(
        'inventory_items',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('category', sa.Enum('panel', 'inverter', 'structure', 'cable', 'electrical', 'civil', 'meter', 'other', name='itemcategory'), nullable=False),
        sa.Column('name', sa.String(length=150), nullable=False),
        sa.Column('brand', sa.String(length=100), nullable=True),
        sa.Column('model', sa.String(length=100), nullable=True),
        sa.Column('unit', sa.Enum('pcs', 'meter', 'kg', 'set', 'bag', name='itemunit'), nullable=False, server_default='pcs'),
        sa.Column('has_serial', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('min_stock', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('stock_qty', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('specs', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('is_deleted', sa.Boolean(), nullable=False, server_default='false'),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    )
    op.create_index('ix_inventory_items_category', 'inventory_items', ['category'])
    op.create_index('ix_inventory_items_name', 'inventory_items', ['name'])

    # 3. Stock Movements Table
    op.create_table(
        'stock_movements',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('item_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('inventory_items.id', ondelete='CASCADE'), nullable=False),
        sa.Column('type', sa.Enum('in', 'out', 'adjust', 'return', name='stockmovementtype'), nullable=False),
        sa.Column('qty', sa.Integer(), nullable=False),
        sa.Column('supplier_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('suppliers.id', ondelete='SET NULL'), nullable=True),
        sa.Column('customer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('customers.id', ondelete='SET NULL'), nullable=True),
        sa.Column('unit_cost', sa.BigInteger(), nullable=True),
        sa.Column('invoice_no', sa.String(length=100), nullable=True),
        sa.Column('note', sa.Text(), nullable=True),
        sa.Column('moved_by', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='RESTRICT'), nullable=False),
        sa.Column('moved_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    )
    op.create_index('ix_stock_movements_item_id', 'stock_movements', ['item_id'])
    op.create_index('ix_stock_movements_type', 'stock_movements', ['type'])
    op.create_index('ix_stock_movements_supplier_id', 'stock_movements', ['supplier_id'])
    op.create_index('ix_stock_movements_customer_id', 'stock_movements', ['customer_id'])

    # 4. Serial Items Table
    op.create_table(
        'serial_items',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('item_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('inventory_items.id', ondelete='CASCADE'), nullable=False),
        sa.Column('serial_no', sa.String(length=100), nullable=False),
        sa.Column('status', sa.Enum('in_stock', 'installed', 'returned', 'defective', name='serialstatus'), nullable=False, server_default='in_stock'),
        sa.Column('customer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('customers.id', ondelete='SET NULL'), nullable=True),
        sa.Column('supplier_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('suppliers.id', ondelete='SET NULL'), nullable=True),
        sa.Column('warranty_months', sa.Integer(), nullable=False, server_default='0'),
        sa.Column('warranty_until', sa.DateTime(timezone=True), nullable=True),
        sa.Column('installed_on', sa.DateTime(timezone=True), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.Column('updated_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
        sa.UniqueConstraint('item_id', 'serial_no', name='uq_item_serial_no'),
    )
    op.create_index('ix_serial_items_item_id', 'serial_items', ['item_id'])
    op.create_index('ix_serial_items_serial_no', 'serial_items', ['serial_no'])
    op.create_index('ix_serial_items_status', 'serial_items', ['status'])
    op.create_index('ix_serial_items_customer_id', 'serial_items', ['customer_id'])

    # 5. Planned Materials Table
    op.create_table(
        'planned_materials',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('customer_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('customers.id', ondelete='CASCADE'), nullable=False),
        sa.Column('item_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('inventory_items.id', ondelete='CASCADE'), nullable=False),
        sa.Column('qty', sa.Integer(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('now()'), nullable=False),
    )
    op.create_index('ix_planned_materials_customer_id', 'planned_materials', ['customer_id'])
    op.create_index('ix_planned_materials_item_id', 'planned_materials', ['item_id'])


def downgrade() -> None:
    op.drop_table('planned_materials')
    op.drop_table('serial_items')
    op.drop_table('stock_movements')
    op.drop_table('inventory_items')
    op.drop_table('suppliers')
    op.execute('DROP TYPE IF EXISTS serialstatus')
    op.execute('DROP TYPE IF EXISTS stockmovementtype')
    op.execute('DROP TYPE IF EXISTS itemunit')
    op.execute('DROP TYPE IF EXISTS itemcategory')
