# ☀️ Solar Rooftop Management Backend API

FastAPI backend for Solar Rooftop Installation & Sales Management mobile app (Flutter).

---

## 🚀 Quick Start

### 1. Requirements
- Docker & Docker Compose
- Python 3.12+ (for local development)

### 2. Environment Setup
Copy the example environment file:
```bash
cp .env.example .env
```

### 3. Run with Docker Compose
```bash
docker compose up --build -d
```
Services started:
- **FastAPI API**: [http://localhost:8000](http://localhost:8000)
- **Interactive Swagger Docs**: [http://localhost:8000/docs](http://localhost:8000/docs)
- **PostgreSQL 16**: `localhost:5432`
- **MinIO Console**: [http://localhost:9001](http://localhost:9001) (User: `minioadmin`, Password: `minioadmin`)

### 4. Database Migrations
```bash
# Inside docker api container or locally with virtual environment active
alembic upgrade head
```

### 5. Running Tests
```bash
pytest -v
```

### 6. Linting & Code Quality
```bash
ruff check .
ruff format .
```
