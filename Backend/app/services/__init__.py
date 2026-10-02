"""Services package."""
from app.services.auth_service import AuthService
from app.services.customer_service import CustomerService
from app.services.document_service import DocumentService
from app.services.kedl_service import KedlService
from app.services.lead_service import LeadService
from app.services.payment_service import PaymentService
from app.services.team_service import TeamService
from app.services.user_service import UserService
from app.services.work_assignment_service import WorkAssignmentService

__all__ = [
    "AuthService",
    "TeamService",
    "UserService",
    "CustomerService",
    "LeadService",
    "DocumentService",
    "PaymentService",
    "WorkAssignmentService",
    "KedlService",
]
