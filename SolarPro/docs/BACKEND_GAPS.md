# SolarPro — Backend Contract Gap Analysis

> **Generated:** Prompt 1 (Contract Check)  
> **Source Documents Checked:**  
> - `Backend/docs/API.md`  
> - `Backend/docs/FLUTTER_INTEGRATION.md`  
> - `Backend/app/models/enums.py`  
> - `Backend/app/models/customer.py`, `lead.py`, `payment.py`, `inventory.py`, `kedl.py`, `ticket.py`  
> - `Backend/app/schemas/`

---

## 1. Summary of Gaps Between Business Requirements & FastAPI Backend

Each item from the owner's specifications has been evaluated against the existing backend implementation:

| Item | Requirement Description | Backend Status | Backend Reality vs. Proposed Client Handling |
| :--- | :--- | :---: | :--- |
| **a) Roles** | Main Admin (1), Co-Admin (4), Salesman, KEDL, Electrician, Structure, Civil, Service. | **PARTIAL** | Backend defines `UserRole` as: `admin`, `manager`, `sales`, `labour`, `technician`, `kedl`, `office_staff`, `client`.<br>• `main_admin` and `co_admin` both map to `admin` / `manager`.<br>• `salesman` maps to `sales`.<br>• `kedl` maps to `kedl`.<br>• `electrician`, `structure`, and `civil` map to `technician` or `labour` users belonging to a `Team` of `type` (`structure`, `electrical`, `civil`).<br>• `service` maps to `technician`. |
| **b) Lead Outcomes** | Outcomes: `FOLLOW-UP`, `CLOSED`, `RETURNED`. | **PARTIAL** | Backend `LeadStatus` enum has: `new`, `contacted`, `follow_up`, `converted`, `lost`.<br>• `follow_up` directly maps to `follow_up`.<br>• `closed` corresponds to invoking `POST /leads/{id}/convert`.<br>• `returned` maps to `lost` (with a rejection reason logged). |
| **c) Subsidy & Panels** | Subsidy (DCR panels) vs. Non-Subsidy (NDCR panels). | **MISSING** | Neither `Customer` nor `LeadConvert` schema currently has `is_subsidy` or `panel_category` (DCR/NDCR) columns.<br>• *Client Handling:* Store in local form state; send as part of project notes/specs until a backend migration adds `is_subsidy: bool` and `dcr_type: str`. |
| **d) Equipment Details** | Detailed equipment specs: wire sizes (AC/DC/Earthing), SPD ACDB/DCDB, solar meter, structure height, civil/earthing notes. | **PARTIAL** | Current `Customer` table contains: `panel_brand`, `panel_watt`, `panel_count`, `inverter_brand`, `structure_type`, `capacity_kw`, `phase`.<br>Missing granular columns: inverter quantity/capacity, structure height, wire brands/sizes, ACDB/DCDB SPD details, solar meter brand/quantity, civil and earthing text notes.<br>• *Client Handling:* Capture in the multi-step UI form; save in local draft and pass supported fields to `convert` endpoint. Additional specs can be passed via `specs` JSON if backend inventory allocation is used. |
| **e) Loan Details** | Loan: Yes/No, Bank Name, Loan Amount, and arbitrary number of installments. | **MISSING** | The backend currently tracks individual payments against `final_price` via `payments` table, but has no dedicated `Loan` or `LoanInstallment` entity.<br>• *Client Handling:* Build against a repository interface with a mock/local persistence layer for loan details until backend Step 11 creates loan tables. |
| **f) Free-form Payment Plan** | Salesman defines custom milestones per customer (percentage or fixed amount, arbitrary number). | **MISSING** | The backend validates total payments against `customer.final_price` and enforces minimum 20% advance for stage advance, but does not store an arbitrary milestone plan schedule entity.<br>• *Client Handling:* Implement local plan builder UI, validate that percentages sum to 100% or amounts equal `final_price`, and manage via `PaymentPlanRepositoryMock`. |
| **g) KEDL File Types** | Name Change (`name_change`), Load Increase (backend `load`), Net Metering (`net`). | **EXISTS** | Backend `KedlFileType` enum defines `name_change`, `load`, and `net`.<br>• *UI Requirement:* The label displayed in the UI must be **"Load Increase"** for the enum value `load`. |
| **h) Employee-Scoped Lists** | Scoped queries: Salesman sees only own leads/customers; site teams see assigned team jobs; KEDL/Service see assigned work. | **EXISTS** | • `/api/v1/leads?assigned_to=<id>` & automatic scoping for sales role.<br>• `/api/v1/work-assignments?team_id=<id>`.<br>• `/api/v1/kedl-files` (KEDL role is automatically filtered to assigned files in `kedl_service.py`).<br>• `/api/v1/tickets?assigned_to=<id>`. |

---

## 2. Recommended Backend Enhancements (For Step 11)

When the backend is expanded in Step 11, the following migrations and schema additions should be executed:
1. **`Customer` Model Extension**:
   - Add `is_subsidy: bool = Field(default=True)`
   - Add `panel_type: str = Field(default="DCR")` (DCR vs NDCR)
   - Add `equipment_specs: JSONB` to store wire dimensions, SPD ratings, structure height, and meter specs.
2. **`LoanDetails` & `LoanInstallments` Table**:
   - Foreign key to `customers.id`, storing `bank_name`, `amount`, and child records for installments.
3. **`PaymentPlanMilestone` Table**:
   - Stores the salesman's customized milestone terms per customer project.
