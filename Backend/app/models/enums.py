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
