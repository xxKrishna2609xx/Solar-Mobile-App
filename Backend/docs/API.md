# 🔌 API Documentation

## Base URLs
- Local Development: `http://localhost:8000/api/v1`
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
- OpenAPI JSON: `http://localhost:8000/openapi.json`

## Common Response Formats

### Standard Success / Health
`GET /api/v1/health`
```json
{
  "status": "ok",
  "db": "ok"
}
```

### Standard Error Format
```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Resource not found.",
    "details": {}
  }
}
```

### Paginated List Format
```json
{
  "items": [],
  "total": 0,
  "page": 1,
  "page_size": 20,
  "pages": 0
}
```
