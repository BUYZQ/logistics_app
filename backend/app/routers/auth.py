"""
Роутер авторизации:
  POST /auth/send-otp   — отправить OTP на телефон или email
  POST /auth/verify-otp — проверить OTP и получить JWT
  GET  /auth/me         — информация о текущем пользователе
"""
import random
import string
import logging
import re
from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException, status, Header
from sqlalchemy.orm import Session
from typing import Optional

from app.database import get_db
from app.models import User, OTPCode
from app.schemas import SendOTPRequest, VerifyOTPRequest, TokenResponse, UserOut
from app.security import create_access_token, decode_token
from app.services.sms_service import send_sms, is_phone
from app.services.email_service import send_otp_email

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/auth", tags=["Авторизация"])

OTP_TTL_MINUTES = 10
MAX_OTP_ATTEMPTS = 5


def generate_otp() -> str:
    return "".join(random.choices(string.digits, k=6))


def normalize_phone(phone: str) -> str:
    # Оставляем только плюс и цифры
    digits = "".join(filter(str.isdigit, phone))
    # Приводим номера 8914... и 7914... к +7...
    if digits.startswith("8") or digits.startswith("7"):
        digits = "7" + digits[1:]
    return "+" + digits


def is_email(contact: str) -> bool:
    return "@" in contact


@router.post("/send-otp")
async def send_otp(body: SendOTPRequest, db: Session = Depends(get_db)):
    """
    Отправить 6-значный OTP код на телефон или email.
    Пользователь должен быть в базе (добавлен оператором).
    """
    contact = body.contact.strip()

    # Нормализация телефона
    if is_email(contact):
        contact = contact.lower()
        user = db.query(User).filter(User.email == contact, User.is_active == True).first()
        contact_type = "email"
    else:
        contact = normalize_phone(contact)
        # Ищем по нормализованному номеру (сравниваем без форматирования)
        users = db.query(User).filter(User.is_active == True).all()
        user = next((u for u in users if u.phone and normalize_phone(u.phone) == contact), None)
        contact_type = "phone"

    if not user:
        raise HTTPException(
            status_code=404,
            detail=f"Пользователь {contact} не найден."
        )

    # Проверяем лимит — не чаще раза в минуту
    recent = (
        db.query(OTPCode)
        .filter(
            OTPCode.contact == contact,
            OTPCode.created_at >= datetime.utcnow() - timedelta(minutes=1),
        )
        .first()
    )
    if recent:
        raise HTTPException(status_code=429, detail="Подождите минуту перед повторной отправкой")

    # Инвалидируем старые коды
    db.query(OTPCode).filter(
        OTPCode.contact == contact,
        OTPCode.is_used == False,
    ).update({"is_used": True})

    code = generate_otp()
    otp = OTPCode(
        contact=contact,
        code=code,
        expires_at=datetime.utcnow() + timedelta(minutes=OTP_TTL_MINUTES),
    )
    db.add(otp)
    db.commit()

    # Отправляем
    message = f"Некст: ваш код входа {code}. Действителен {OTP_TTL_MINUTES} минут."
    if contact_type == "phone":
        sent = await send_sms(contact, message)
    else:
        sent = await send_otp_email(contact, code)

    if not sent:
        raise HTTPException(status_code=500, detail="Не удалось отправить код. Попробуйте позже.")

    return {
        "message": f"Код отправлен на {contact}",
        "expires_in_minutes": OTP_TTL_MINUTES,
    }


@router.post("/verify-otp", response_model=TokenResponse)
async def verify_otp(body: VerifyOTPRequest, db: Session = Depends(get_db)):
    """
    Проверить OTP код и вернуть JWT токен.
    """
    contact = body.contact.strip()
    if is_email(contact):
        contact = contact.lower()
    else:
        contact = normalize_phone(contact)

    otp = (
        db.query(OTPCode)
        .filter(
            OTPCode.contact == contact,
            OTPCode.is_used == False,
            OTPCode.expires_at >= datetime.utcnow(),
        )
        .order_by(OTPCode.created_at.desc())
        .first()
    )

    if not otp:
        raise HTTPException(status_code=400, detail="Код недействителен или истёк срок действия")

    # Ограничение попыток
    otp.attempts += 1
    if otp.attempts > MAX_OTP_ATTEMPTS:
        otp.is_used = True
        db.commit()
        raise HTTPException(status_code=400, detail="Превышено число попыток. Запросите новый код.")

    if otp.code != body.code.strip():
        db.commit()
        remaining = MAX_OTP_ATTEMPTS - otp.attempts
        raise HTTPException(
            status_code=400,
            detail=f"Неверный код. Осталось попыток: {remaining}"
        )

    otp.is_used = True
    db.commit()

    # Находим пользователя
    if "@" in contact:
        user = db.query(User).filter(User.email == contact).first()
    else:
        users = db.query(User).all()
        user = next((u for u in users if u.phone and normalize_phone(u.phone) == contact), None)

    if not user or not user.is_active:
        raise HTTPException(status_code=403, detail="Аккаунт деактивирован")

    token = create_access_token(user.id)
    return TokenResponse(access_token=token, user=UserOut.model_validate(user))


async def get_current_user(
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db),
) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Требуется авторизация")
    token = authorization[7:]
    user_id = decode_token(token)
    if not user_id:
        raise HTTPException(status_code=401, detail="Токен недействителен или истёк")
    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    return user


@router.get("/me", response_model=UserOut)
async def get_me(user: User = Depends(get_current_user)):
    """Получить информацию о текущем пользователе по JWT."""
    return user
