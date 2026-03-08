import os
import shutil
from uuid import uuid4
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.routers.auth import get_current_user

router = APIRouter(prefix="/upload", tags=["Upload"])

UPLOAD_DIR = "uploads/avatars"
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.post("/avatar")
def upload_avatar(
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Загрузить аватарку и сохранить ссылку в профиль пользователя."""
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Разрешены только изображения")
    
    # Генерируем уникальное имя файла
    ext = file.filename.split(".")[-1] if "." in file.filename else "jpg"
    filename = f"{uuid4().hex}.{ext}"
    file_path = os.path.join(UPLOAD_DIR, filename)

    # Сохраняем файл на диск
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # Сохраняем путь в БД
    avatar_url = f"/{UPLOAD_DIR}/{filename}"
    current_user.avatar_url = avatar_url
    db.commit()

    return {"avatarUrl": avatar_url}
