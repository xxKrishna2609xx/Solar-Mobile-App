from app.storage.s3 import storage_service


def get_storage_backend():
    """Return the active storage service backend (S3 / MinIO)."""
    return storage_service


__all__ = ["get_storage_backend"]
