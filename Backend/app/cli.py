import argparse
import asyncio
import sys
from sqlalchemy import select
from app.core.security import normalize_phone
from app.db.session import AsyncSessionLocal
from app.models.enums import TeamType, UserRole
from app.models.team import Team
from app.models.user import User


async def create_admin(name: str, phone: str):
    """Create an administrator user."""
    normalized_phone = normalize_phone(phone)
    async with AsyncSessionLocal() as db:
        stmt = select(User).where(User.phone == normalized_phone, User.is_deleted == False)  # noqa: E712
        existing = (await db.execute(stmt)).scalar_one_or_none()
        if existing:
            if existing.role == UserRole.ADMIN:
                print(f"Admin with phone {normalized_phone} already exists (ID: {existing.id}).")
                return
            existing.role = UserRole.ADMIN
            existing.name = name
            existing.is_active = True
            await db.commit()
            print(f"Updated existing user {normalized_phone} to role 'admin'.")
            return

        admin_user = User(
            name=name,
            phone=normalized_phone,
            role=UserRole.ADMIN,
            is_active=True,
        )
        db.add(admin_user)
        await db.commit()
        await db.refresh(admin_user)
        print(f"Successfully created admin '{name}' with phone {normalized_phone} (ID: {admin_user.id}).")


async def seed_teams():
    """Seed default teams (Structure A/B, Electrical A/B, Civil A/B)."""
    default_teams = [
        ("Structure Team A", TeamType.STRUCTURE),
        ("Structure Team B", TeamType.STRUCTURE),
        ("Electrical Team A", TeamType.ELECTRICAL),
        ("Electrical Team B", TeamType.ELECTRICAL),
        ("Civil Team A", TeamType.CIVIL),
        ("Civil Team B", TeamType.CIVIL),
    ]

    async with AsyncSessionLocal() as db:
        created_count = 0
        for name, team_type in default_teams:
            stmt = select(Team).where(Team.name == name, Team.type == team_type)
            existing = (await db.execute(stmt)).scalar_one_or_none()
            if not existing:
                team = Team(name=name, type=team_type)
                db.add(team)
                created_count += 1
        await db.commit()
        print(f"Team seeding completed. Created {created_count} new teams.")


def main():
    parser = argparse.ArgumentParser(description="Solar Backend Management CLI")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # create-admin command
    create_admin_parser = subparsers.add_parser("create-admin", help="Create an initial admin user")
    create_admin_parser.add_argument("--name", required=True, help="Full name of the admin")
    create_admin_parser.add_argument("--phone", required=True, help="10-digit Indian phone number")

    # seed-teams command
    subparsers.add_parser("seed-teams", help="Seed default labour teams")

    args = parser.parse_args()

    if args.command == "create-admin":
        asyncio.run(create_admin(args.name, args.phone))
    elif args.command == "seed-teams":
        asyncio.run(seed_teams())


if __name__ == "__main__":
    main()
