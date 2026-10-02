import enum


class UserRole(str, enum.Enum):
    ADMIN = "admin"
    SALES = "sales"
    LABOUR = "labour"
    KEDL = "kedl"
    CLIENT = "client"


class TeamType(str, enum.Enum):
    STRUCTURE = "structure"
    ELECTRICAL = "electrical"
    CIVIL = "civil"


class WorkType(str, enum.Enum):
    STRUCTURE = "structure"
    ELECTRICAL = "electrical"
    CIVIL = "civil"


class WorkStatus(str, enum.Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class CustomerStage(str, enum.Enum):
    SALE_CONFIRMED = "SALE_CONFIRMED"
    DOCUMENTS_RECEIVED = "DOCUMENTS_RECEIVED"
    ADVANCE_VERIFIED = "ADVANCE_VERIFIED"
    STRUCTURE_WORK = "STRUCTURE_WORK"
    ELECTRICAL_WORK = "ELECTRICAL_WORK"
    CIVIL_WORK = "CIVIL_WORK"
    INSTALLATION_COMPLETE = "INSTALLATION_COMPLETE"
    KEDL_PROCESS = "KEDL_PROCESS"
    SYSTEM_LIVE = "SYSTEM_LIVE"
    HANDED_OVER = "HANDED_OVER"


class LeadStatus(str, enum.Enum):
    NEW = "new"
    CONTACTED = "contacted"
    FOLLOW_UP = "follow_up"
    CONVERTED = "converted"
    LOST = "lost"


class DocumentType(str, enum.Enum):
    E_BILL = "e_bill"
    AADHAAR = "aadhaar"
    PAN = "pan"
    CANCELLED_CHEQUE = "cancelled_cheque"
    REGISTRY = "registry"
    OTHER = "other"


class SystemPhase(str, enum.Enum):
    SINGLE = "single"
    THREE = "three"


class PaymentMode(str, enum.Enum):
    CASH = "cash"
    UPI = "upi"
    BANK_TRANSFER = "bank_transfer"
    CHEQUE = "cheque"
    OTHER = "other"


class PaymentStatus(str, enum.Enum):
    PENDING = "pending"
    SALES_APPROVED = "sales_approved"
    VERIFIED = "verified"
    REJECTED = "rejected"


class PaymentAction(str, enum.Enum):
    SUBMITTED = "submitted"
    SALES_APPROVED = "sales_approved"
    VERIFIED = "verified"
    REJECTED = "rejected"
    UPDATED = "updated"
