from datetime import datetime, timezone
import uuid
from typing import Any, Dict, List, Optional
import structlog
from pymongo import ASCENDING, MongoClient
from pymongo.collection import Collection
from pymongo.database import Database
from app.core.config import settings
from app.core.security import hash_password, normalize_phone, sanitize_input, verify_password

logger = structlog.get_logger()

_client: Optional[MongoClient] = None
_db: Optional[Database] = None


def get_mongo_client() -> Optional[MongoClient]:
    global _client
    if _client is None and settings.MONGODB_URI:
        try:
            _client = MongoClient(
                settings.MONGODB_URI,
                serverSelectionTimeoutMS=15000,
                connectTimeoutMS=15000,
                socketTimeoutMS=20000,
                retryWrites=True,
            )
        except Exception as e:
            logger.error("Failed to initialize MongoDB client", error=str(e))
    return _client


def get_mongo_db() -> Optional[Database]:
    global _db
    if _db is None:
        client = get_mongo_client()
        if client:
            try:
                # Use solar_app_db or portfolio_db
                _db = client["solar_app_db"]
            except Exception as e:
                logger.error("Failed to access MongoDB database", error=str(e))
    return _db



def init_mongo() -> bool:
    """Initialize collections, indexes, and seed demo accounts with salted bcrypt hashes."""
    db = get_mongo_db()
    if db is None:
        logger.warning("MongoDB not connected. Skipping MongoDB initialization.")
        return False

    try:
        # Check connection
        db.command("ping")
        logger.info("Successfully connected to MongoDB Atlas!")

        # Collections
        users_col: Collection = db["users"]
        leads_col: Collection = db["leads"]
        customers_col: Collection = db["customers"]

        # Ensure indexes (defends against race conditions & duplicates)
        users_col.create_index([("phone", ASCENDING)], unique=True)
        users_col.create_index([("email", ASCENDING)], unique=True, sparse=True)
        leads_col.create_index([("phone", ASCENDING)])
        customers_col.create_index([("phone", ASCENDING)])

        now = datetime.now(timezone.utc)

        # Seed or sync Super Admin account directly from environment variables
        super_admin_email = (settings.SUPER_ADMIN_EMAIL or "admin@solarpro.com").strip().lower()
        super_admin_phone = normalize_phone(settings.SUPER_ADMIN_PHONE or "9876543210")
        super_admin_name = settings.SUPER_ADMIN_NAME or "Super Admin"
        super_admin_pwd = settings.SUPER_ADMIN_PASSWORD or "Solar@2026"
        pwd_hash = hash_password(super_admin_pwd)

        existing = users_col.find_one({
            "$or": [{"email": super_admin_email}, {"phone": super_admin_phone}]
        })
        if not existing:
            admin_id = str(uuid.uuid4())
            doc = {
                "_id": admin_id,
                "id": admin_id,
                "name": super_admin_name,
                "phone": super_admin_phone,
                "email": super_admin_email,
                "role": "admin",
                "is_superadmin": True,
                "password_hash": pwd_hash,
                "is_active": True,
                "approval_status": "approved",
                "is_email_verified": True,
                "created_at": now,
                "updated_at": now,
                "last_login_at": None,
            }
            users_col.insert_one(doc)
            logger.info("Initialized Super Admin account from environment", email=super_admin_email)
        else:
            users_col.update_one(
                {"_id": existing["_id"]},
                {
                    "$set": {
                        "name": super_admin_name,
                        "email": super_admin_email,
                        "phone": super_admin_phone,
                        "role": "admin",
                        "is_superadmin": True,
                        "password_hash": pwd_hash,
                        "is_active": True,
                        "approval_status": "approved",
                        "is_email_verified": True,
                        "updated_at": now,
                    }
                }
            )
            logger.info("Synchronized Super Admin account from environment", email=super_admin_email)

        # Email verification indexes
        db["email_verifications"].create_index([("email", ASCENDING)])
        users_col.create_index([("approval_status", ASCENDING)])
        return True
    except Exception as e:
        logger.error("MongoDB initialization error", error=str(e))
        return False


def mongo_find_user_by_identifier(identifier: str) -> Optional[Dict[str, Any]]:
    """
    Find user by phone or email with strict injection protection.
    Guarantees no raw query evaluation or operator injection.
    """
    global _client, _db
    clean_id = str(identifier).strip()
    phone_clean = None
    try:
        phone_clean = normalize_phone(clean_id)
    except Exception:
        phone_clean = None

    query_conditions = [{"email": clean_id.lower()}]
    if phone_clean:
        query_conditions.append({"phone": phone_clean})
    else:
        query_conditions.append({"phone": clean_id})

    # Try up to 2 times with auto-reconnect
    for attempt in range(2):
        db = get_mongo_db()
        if db is None:
            return None
        try:
            users_col = db["users"]
            user = users_col.find_one({"$or": query_conditions, "is_active": True})
            return user
        except Exception as e:
            logger.warning("MongoDB query attempt failed, reconnecting", attempt=attempt, error=str(e))
            _client = None
            _db = None
            if attempt == 1:
                return None
    return None



def mongo_create_user(
    name: str,
    phone: str,
    password: str,
    role: str = "client",
    email: Optional[str] = None,
    is_email_verified: Optional[bool] = None,
) -> Dict[str, Any]:
    """Create a new user with salted bcrypt password in MongoDB Atlas."""
    db = get_mongo_db()
    if db is None:
        raise RuntimeError("MongoDB is not available.")

    users_col = db["users"]
    now = datetime.now(timezone.utc)
    phone_normalized = normalize_phone(phone)

    # Check existence
    if users_col.find_one({"phone": phone_normalized}):
        raise ValueError("A user with this mobile number already exists.")

    if email and users_col.find_one({"email": email.strip().lower()}):
        raise ValueError("A user with this email address already exists.")

    pwd_hash = hash_password(password)
    user_id = str(uuid.uuid4())

    # Client role is auto-approved; employee and admin roles require Super Admin approval
    is_client = role.lower() == "client"
    approval_status = "approved" if is_client else "pending"
    is_active = True if is_client else False

    # Client role requires verification before login; others default to True
    if is_email_verified is None:
        is_email_verified = False if is_client else True

    doc = {
        "_id": user_id,
        "id": user_id,
        "name": sanitize_input(name),
        "phone": phone_normalized,
        "email": sanitize_input(email.lower()) if email else None,
        "role": role.lower(),
        "requested_role": role.lower(),
        "password_hash": pwd_hash,
        "is_active": is_active,
        "approval_status": approval_status,
        "is_email_verified": is_email_verified,
        "created_at": now,
        "updated_at": now,
        "last_login_at": None,
    }

    users_col.insert_one(doc)
    return doc


def mongo_get_registration_approvals(status: str = "pending") -> List[Dict[str, Any]]:
    """Fetch employee/admin registration requests for Super Admin review."""
    db = get_mongo_db()
    if db is None:
        return []
    users_col = db["users"]
    query: Dict[str, Any] = {"role": {"$ne": "client"}, "is_superadmin": {"$ne": True}}
    if status and status.lower() != "all":
        query["approval_status"] = status.lower()

    cursor = users_col.find(query).sort("created_at", -1)
    results = []
    for doc in cursor:
        results.append({
            "id": str(doc["_id"]),
            "name": doc.get("name", ""),
            "phone": doc.get("phone", ""),
            "email": doc.get("email"),
            "role": doc.get("role", "employee"),
            "requested_role": doc.get("requested_role") or doc.get("role", "employee"),
            "approval_status": doc.get("approval_status", "pending"),
            "is_active": doc.get("is_active", False),
            "created_at": doc.get("created_at").isoformat() if doc.get("created_at") else None,
            "approved_at": doc.get("approved_at").isoformat() if doc.get("approved_at") else None,
        })
    return results


def mongo_approve_user(user_id: str) -> Optional[Dict[str, Any]]:
    """Approve a pending employee/admin registration and activate their account."""
    from pymongo import ReturnDocument
    db = get_mongo_db()
    if db is None:
        return None
    users_col = db["users"]
    now = datetime.now(timezone.utc)
    res = users_col.find_one_and_update(
        {"_id": user_id},
        {"$set": {"approval_status": "approved", "is_active": True, "approved_at": now, "updated_at": now}},
        return_document=ReturnDocument.AFTER,
    )
    if res:
        res["id"] = str(res["_id"])
        res.pop("password_hash", None)
    return res


def mongo_reject_user(user_id: str) -> Optional[Dict[str, Any]]:
    """Reject a pending employee/admin registration and disable account."""
    from pymongo import ReturnDocument
    db = get_mongo_db()
    if db is None:
        return None
    users_col = db["users"]
    now = datetime.now(timezone.utc)
    res = users_col.find_one_and_update(
        {"_id": user_id},
        {"$set": {"approval_status": "rejected", "is_active": False, "rejected_at": now, "updated_at": now}},
        return_document=ReturnDocument.AFTER,
    )
    if res:
        res["id"] = str(res["_id"])
        res.pop("password_hash", None)
    return res


def mongo_update_login_timestamp(user_id: str) -> None:
    db = get_mongo_db()
    if db is not None:
        now = datetime.now(timezone.utc)
        db["users"].update_one({"_id": user_id}, {"$set": {"last_login_at": now}})


def mongo_create_lead(lead_data: Dict[str, Any]) -> Dict[str, Any]:
    db = get_mongo_db()
    if db is None:
        raise RuntimeError("MongoDB is not available.")
    leads_col = db["leads"]
    now = datetime.now(timezone.utc)
    lead_id = str(uuid.uuid4())
    doc = {
        "_id": lead_id,
        "id": lead_id,
        "name": sanitize_input(lead_data.get("name", "")),
        "phone": sanitize_input(lead_data.get("phone", "")),
        "area": sanitize_input(lead_data.get("area", "")),
        "kw": float(lead_data.get("kw", 3.0)),
        "status": lead_data.get("status", "new"),
        "source": lead_data.get("source", "Direct"),
        "created_at": now,
        "updated_at": now,
    }
    leads_col.insert_one(doc)
    return doc


def mongo_get_leads() -> List[Dict[str, Any]]:
    db = get_mongo_db()
    if db is None:
        return []
    leads_col = db["leads"]
    return list(leads_col.find({}).sort("created_at", -1))


def mongo_create_customer(customer_data: Dict[str, Any]) -> Dict[str, Any]:
    db = get_mongo_db()
    if db is None:
        raise RuntimeError("MongoDB is not available.")
    customers_col = db["customers"]
    now = datetime.now(timezone.utc)
    cust_id = str(uuid.uuid4())
    doc = {
        "_id": cust_id,
        "id": cust_id,
        "name": sanitize_input(customer_data.get("name", "")),
        "phone": sanitize_input(customer_data.get("phone", "")),
        "email": sanitize_input(customer_data.get("email", "")),
        "address": sanitize_input(customer_data.get("address", "")),
        "kw": float(customer_data.get("kw", 5.0)),
        "status": customer_data.get("status", "active"),
        "created_at": now,
        "updated_at": now,
    }
    customers_col.insert_one(doc)
    return doc


def mongo_get_customers() -> List[Dict[str, Any]]:
    db = get_mongo_db()
    if db is None:
        return []
    customers_col = db["customers"]
    return list(customers_col.find({}).sort("created_at", -1))


def mongo_store_otp(phone: str, code_hash: str, expires_at: datetime) -> None:
    db = get_mongo_db()
    if db is None:
        return
    db["otp_codes"].insert_one({
        "_id": str(uuid.uuid4()),
        "phone": phone,
        "code_hash": code_hash,
        "expires_at": expires_at,
        "attempts": 0,
        "consumed_at": None,
        "created_at": datetime.now(timezone.utc),
    })


def mongo_verify_otp(phone: str, otp: str) -> bool:
    from app.core.security import verify_token_hash
    db = get_mongo_db()
    if db is None:
        return False
    now = datetime.now(timezone.utc)
    rec = db["otp_codes"].find_one({
        "phone": phone,
        "consumed_at": None,
        "expires_at": {"$gt": now},
    }, sort=[("created_at", -1)])
    if not rec:
        return False
    if rec.get("attempts", 0) >= 5:
        return False
    valid = verify_token_hash(otp, rec["code_hash"])
    if valid:
        db["otp_codes"].update_one({"_id": rec["_id"]}, {"$set": {"consumed_at": now}})
        return True
    else:
        db["otp_codes"].update_one({"_id": rec["_id"]}, {"$inc": {"attempts": 1}})
        return False


def mongo_find_user_by_email(email: str) -> Optional[Dict[str, Any]]:
    """Look up user by email directly."""
    db = get_mongo_db()
    if db is None:
        return None
    return db["users"].find_one({"email": email.strip().lower(), "is_active": True})


def mongo_store_email_verification(email: str, code_hash: str, expires_at: datetime) -> None:
    """Store email verification token record in MongoDB Atlas."""
    db = get_mongo_db()
    if db is None:
        return
    db["email_verifications"].insert_one({
        "_id": str(uuid.uuid4()),
        "email": email.strip().lower(),
        "code_hash": code_hash,
        "expires_at": expires_at,
        "attempts": 0,
        "consumed_at": None,
        "created_at": datetime.now(timezone.utc),
    })


def mongo_verify_email_code(email: str, code: str) -> bool:
    """Verify email code against Mongo records with attempts limit and expiry."""
    from app.core.security import verify_token_hash
    db = get_mongo_db()
    if db is None:
        return False
    now = datetime.now(timezone.utc)
    rec = db["email_verifications"].find_one({
        "email": email.strip().lower(),
        "consumed_at": None,
        "expires_at": {"$gt": now},
    }, sort=[("created_at", -1)])

    if not rec:
        # Dev mock fallback
        if settings.ENV == "dev" and settings.DEV_MOCK_OTP and code == settings.DEV_MOCK_OTP:
            return True
        return False

    if rec.get("attempts", 0) >= 5:
        return False

    valid = verify_token_hash(code, rec["code_hash"]) or (
        settings.ENV == "dev" and settings.DEV_MOCK_OTP and code == settings.DEV_MOCK_OTP
    )

    if valid:
        db["email_verifications"].update_one({"_id": rec["_id"]}, {"$set": {"consumed_at": now}})
        return True
    else:
        db["email_verifications"].update_one({"_id": rec["_id"]}, {"$inc": {"attempts": 1}})
        return False


def mongo_mark_email_verified(email: str) -> bool:
    """Mark user as verified in MongoDB Atlas."""
    db = get_mongo_db()
    if db is None:
        return False
    now = datetime.now(timezone.utc)
    res = db["users"].update_one(
        {"email": email.strip().lower()},
        {"$set": {"is_email_verified": True, "email_verified_at": now, "updated_at": now}},
    )
    return res.modified_count > 0 or res.matched_count > 0



