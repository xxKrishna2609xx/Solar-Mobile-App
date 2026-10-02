from abc import ABC, abstractmethod
from typing import BinaryIO, Optional


class BaseStorageService(ABC):
    @abstractmethod
    async def upload_file(
        self,
        file_obj: BinaryIO,
        destination_path: str,
        content_type: str = "application/octet-stream",
    ) -> str:
        """Upload a file to storage and return its storage key or URL."""
        pass

    @abstractmethod
    async def download_file(self, file_path: str) -> bytes:
        """Download file bytes from storage."""
        pass

    @abstractmethod
    async def delete_file(self, file_path: str) -> bool:
        """Delete a file from storage."""
        pass

    @abstractmethod
    async def get_presigned_url(
        self,
        file_path: str,
        expires_in: int = 3600,
        operation: str = "get_object",
    ) -> str:
        """Generate a presigned URL for upload or download."""
        pass
