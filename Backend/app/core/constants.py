"""Central place for business-rule constants that were previously scattered across services."""
from app.models.enums import CustomerStage

# Ordered customer project timeline shown to clients: (stage, display title)
STAGE_ORDER = [
    (CustomerStage.SALE_CONFIRMED, "Sale Confirmed"),
    (CustomerStage.DOCUMENTS_RECEIVED, "Documents Received"),
    (CustomerStage.ADVANCE_VERIFIED, "Advance Payment Verified"),
    (CustomerStage.STRUCTURE_WORK, "Structure Installation"),
    (CustomerStage.ELECTRICAL_WORK, "Electrical Wiring & Inverter"),
    (CustomerStage.CIVIL_WORK, "Civil Works"),
    (CustomerStage.INSTALLATION_COMPLETE, "Installation Complete"),
    (CustomerStage.KEDL_PROCESS, "KEDL Discom Paperwork"),
    (CustomerStage.SYSTEM_LIVE, "System Live & Net Metering"),
    (CustomerStage.HANDED_OVER, "Project Handed Over"),
]
