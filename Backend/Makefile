.PHONY: up down migrate revision test lint format clean

up:
	docker compose up -d

down:
	docker compose down

migrate:
	alembic upgrade head

revision:
	@read -p "Enter migration message: " msg; \
	alembic revision --autogenerate -m "$$msg"

test:
	pytest -v

lint:
	ruff check .

format:
	ruff format .

clean:
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type f -name "*.pyc" -delete
