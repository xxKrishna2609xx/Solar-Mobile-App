# 📦 STEP 09: Inventory Management

> Follow `RULES.md` / `01_MASTER_CONTEXT.md`. Steps 02 to 04 must be complete.

## 🎯 Goal
Track solar materials: stock in/out, serial numbers for panels and inverters, and materials used per customer project.

## 📋 Tasks

### 1. Models + migration
**Supplier**: `id, name, phone, address, gst_no, is_active`

**InventoryItem**: `id, category (panel|inverter|structure|cable|electrical|civil|meter|other), name, brand, model, unit (pcs|meter|kg|set|bag), has_serial (bool), min_stock, stock_qty (maintained via movements), specs (JSONB, e.g. wattage, kW), is_active`

**StockMovement**: `id, item_id, type (in|out|adjust|return), qty, supplier_id (for in), customer_id (for out), unit_cost (nullable), invoice_no, note, moved_by, moved_at`

**SerialItem**: `id, item_id, serial_no (unique per item), status (in_stock|installed|returned|defective), customer_id (nullable), supplier_id, warranty_months, warranty_until, installed_on`

### 2. Endpoints (admin full access; sales read-only; labour can see items issued to their jobs)
- Suppliers CRUD
- Items CRUD + `GET /api/v1/inventory/items?category=&low_stock=true&search=`
- `POST /api/v1/inventory/stock-in` (items + qty + serial numbers list for serial items; validates serial count equals qty)
- `POST /api/v1/inventory/stock-out` for a customer (serial items must pick specific serials from stock)
- `POST /api/v1/inventory/adjust` (admin, reason required)
- `GET /api/v1/inventory/movements` filters: item, customer, type, date range
- `GET /api/v1/inventory/low-stock`
- `GET /api/v1/customers/{id}/materials` lists materials and serials issued to that customer
- `GET /api/v1/serials/{serial_no}` returns the customer, install date and warranty status (useful for service tickets)
- `PATCH /api/v1/serials/{id}/status` mark defective/returned

### 3. Logic
- **Stock can never go negative.** Use transactions with row locks.
- Stock out for a serial item sets the serial's `customer_id`, `status=installed`, `installed_on`, and `warranty_until`.
- Every quantity change must come from a StockMovement (single source of truth).
- Optional **planned material list per customer** (`PlannedMaterial`: customer_id, item_id, qty) to compare planned vs. issued. **(Optional, build if time permits)**

### 4. Tests
- Concurrent stock-out does not oversell
- Serial uniqueness and count validation
- Low-stock endpoint, warranty calculation

## ✅ Acceptance Checklist
- [ ] Stock in/out updates quantities and serial status correctly
- [ ] Customer materials view shows serial numbers with warranty dates
- [ ] Negative stock is impossible
- [ ] Tests pass, migration applies cleanly
