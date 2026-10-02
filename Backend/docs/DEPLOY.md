# 🚀 Production Deployment & Operations Guide

This guide covers deploying the Solar Rooftop Backend to a production Linux VPS (e.g., Ubuntu 22.04 LTS / 24.04 LTS) or container cloud platform (Render, Railway, AWS ECS).

---

## 1. System Requirements
- **OS**: Ubuntu 22.04 LTS or newer
- **Memory**: Minimum 2 GB RAM (4 GB recommended)
- **Disk**: 20 GB SSD
- **Docker**: Docker Engine 24+ & Docker Compose v2+

---

## 2. Environment Configuration (`.env.prod`)

Create `.env.prod` in the project root:

```env
# Application Settings
ENVIRONMENT=prod
DEBUG=false
APP_NAME="Solar Rooftop Backend"
HOST=0.0.0.0
PORT=8000
WEB_CONCURRENCY=4

# Database Settings
POSTGRES_USER=solar_prod_user
POSTGRES_PASSWORD=generate_a_very_strong_random_password_here
POSTGRES_DB=solar_rooftop_prod
DATABASE_URL=postgresql+asyncpg://solar_prod_user:generate_a_very_strong_random_password_here@postgres:5432/solar_rooftop_prod

# Security Keys (Minimum 32 Characters)
JWT_SECRET=super_secret_jwt_key_at_least_32_characters_long
OTP_HMAC_SECRET=super_secret_otp_hmac_key_at_least_32_characters_long
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=30

# SMS & Notifications
SMS_PROVIDER=msg91
MSG91_AUTH_KEY=your_msg91_live_auth_key
MSG91_SENDER_ID=SOLAR
MSG91_TEMPLATE_ID=your_dlt_template_id
DEV_FIXED_OTP=false

# Object Storage (AWS S3 or MinIO)
STORAGE_BACKEND=s3
S3_BUCKET_NAME=solar-app-production-uploads
S3_REGION=ap-south-1
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
S3_PRESIGNED_EXPIRY_SECONDS=900

# Push Notifications (Firebase)
FCM_SERVER_KEY=your_firebase_cloud_messaging_key
```

---

## 3. Deploying with Docker Compose

1. **Clone repository and enter directory**:
   ```bash
   git clone <repo-url> /opt/solar-backend
   cd /opt/solar-backend
   ```

2. **Run database migrations**:
   ```bash
   docker compose -f docker-compose.prod.yml run --rm backend alembic upgrade head
   ```

3. **Seed initial Superadmin user**:
   ```bash
   docker compose -f docker-compose.prod.yml run --rm backend python -m app.cli create-admin --phone 9876543210 --name "Super Admin"
   ```

4. **Seed operational team templates**:
   ```bash
   docker compose -f docker-compose.prod.yml run --rm backend python -m app.cli seed-teams
   ```

5. **Start all production services in the background**:
   ```bash
   docker compose -f docker-compose.prod.yml up -d
   ```

---

## 4. Automated Database Backups

Set up a daily cron job for PostgreSQL dumps:

```bash
# Add to crontab (crontab -e)
0 2 * * * docker exec solar_prod_postgres pg_dump -U solar_prod_user solar_rooftop_prod | gzip > /opt/solar-backend/backups/backup_$(date +\%Y\%m\%d_\%H\%M\%S).sql.gz
```

### Restoring Database from Backup:
```bash
gunzip < /opt/solar-backend/backups/backup_20261002_020000.sql.gz | docker exec -i solar_prod_postgres psql -U solar_prod_user -d solar_rooftop_prod
```

---

## 5. SSL & Domain Configuration

For automated HTTPS with Let's Encrypt / Certbot:
```bash
sudo apt-get install certbot python3-certbot-nginx
sudo certbot --nginx -d api.yourdomain.com
```

---

## 6. Monitoring and Logs
- **Backend Logs**: `docker logs -f solar_prod_backend`
- **Nginx Access & Error Logs**: `docker logs -f solar_prod_nginx`
- **Database Status**: `docker exec -it solar_prod_postgres pg_isready`
