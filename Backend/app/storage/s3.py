from typing import BinaryIO, Optional
try:
    import aioboto3
    from botocore.config import Config
except ImportError:
    aioboto3 = None
    Config = None
from app.core.config import settings
from app.storage.base import BaseStorageService


class S3StorageService(BaseStorageService):
    def __init__(self):
        self.session = aioboto3.Session() if aioboto3 else None
        self.endpoint_url = settings.STORAGE_ENDPOINT if settings.STORAGE_PROVIDER == "minio" else None
        self.aws_access_key_id = settings.STORAGE_ACCESS_KEY
        self.aws_secret_access_key = settings.STORAGE_SECRET_KEY
        self.region_name = settings.STORAGE_REGION
        self.bucket_name = settings.STORAGE_BUCKET_NAME
        self.use_ssl = settings.STORAGE_USE_SSL

    def _get_client(self):
        return self.session.client(
            "s3",
            endpoint_url=self.endpoint_url,
            aws_access_key_id=self.aws_access_key_id,
            aws_secret_access_key=self.aws_secret_access_key,
            region_name=self.region_name,
            use_ssl=self.use_ssl,
            config=Config(signature_version="s3v4"),
        )

    async def upload_file(
        self,
        file_obj: BinaryIO,
        destination_path: str,
        content_type: str = "application/octet-stream",
    ) -> str:
        async with self._get_client() as s3:
            await s3.upload_fileobj(
                file_obj,
                self.bucket_name,
                destination_path,
                ExtraArgs={"ContentType": content_type},
            )
        return destination_path

    async def download_file(self, file_path: str) -> bytes:
        async with self._get_client() as s3:
            response = await s3.get_object(Bucket=self.bucket_name, Key=file_path)
            async with response["Body"] as stream:
                return await stream.read()

    async def delete_file(self, file_path: str) -> bool:
        async with self._get_client() as s3:
            await s3.delete_object(Bucket=self.bucket_name, Key=file_path)
            return True

    async def get_presigned_url(
        self,
        file_path: str,
        expires_in: int = 3600,
        operation: str = "get_object",
    ) -> str:
        async with self._get_client() as s3:
            return await s3.generate_presigned_url(
                ClientMethod=operation,
                Params={"Bucket": self.bucket_name, "Key": file_path},
                ExpiresIn=expires_in,
            )


storage_service = S3StorageService()
