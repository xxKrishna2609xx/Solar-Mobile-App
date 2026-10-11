from dataclasses import dataclass
from typing import Any, BinaryIO, Dict, List, Optional
from fastapi import UploadFile


@dataclass
class UploadFileInfo:
    """Metadata and binary stream wrapper for uploaded files."""
    stream: Optional[BinaryIO] = None
    filename: Optional[str] = None
    content_type: Optional[str] = None
    size: int = 0


async def read_upload_file(file: Optional[UploadFile]) -> Optional[UploadFileInfo]:
    """
    Read an UploadFile, determine its size, reset the file stream position,
    and return an UploadFileInfo instance.
    """
    if file is None:
        return None
    content = await file.read()
    await file.seek(0)
    return UploadFileInfo(
        stream=file.file,
        filename=file.filename,
        content_type=file.content_type or "application/octet-stream",
        size=len(content),
    )


def paginate_list(
    items: List[Any],
    page: int = 1,
    page_size: int = 20,
    total: Optional[int] = None,
) -> Dict[str, Any]:
    """
    Format a consistent paginated dictionary for MongoDB and in-memory list results.
    """
    total_count = len(items) if total is None else total
    effective_page_size = max(1, page_size)
    pages = max(1, (total_count + effective_page_size - 1) // effective_page_size)
    return {
        "items": items,
        "total": total_count,
        "page": page,
        "page_size": page_size,
        "pages": pages,
    }
