"""
SMS-сервис через sms.ru API.
Документация: https://sms.ru/?panel=api
"""
import httpx
import logging
import os
from dotenv import load_dotenv

load_dotenv()

SMSRU_API_ID = os.getenv("SMSRU_API_ID", "")
SMSRU_URL = "https://sms.ru/sms/send"

logger = logging.getLogger(__name__)


async def send_sms(phone: str, message: str) -> bool:
    """
    Отправить SMS через sms.ru.
    phone: номер в формате +79141234567 или 79141234567
    Возвращает True при успехе.
    """
    # Нормализуем номер (только цифры)
    normalized = "".join(filter(str.isdigit, phone))
    if normalized.startswith("8"):
        normalized = "7" + normalized[1:]

    if not SMSRU_API_ID:
        # Режим разработки — выводим код в консоль
        logger.warning(f"[DEV MODE] SMS to {phone}: {message}")
        print(f"\n{'='*50}\n📱 SMS to {phone}:\n{message}\n{'='*50}\n")
        return True

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(SMSRU_URL, data={
                "api_id": SMSRU_API_ID,
                "to": normalized,
                "msg": message,
                "json": 1,
            })
            data = resp.json()
            status = data.get("sms", {}).get(normalized, {}).get("status", "")
            if status == "OK":
                logger.info(f"SMS sent to {phone}")
                return True
            else:
                error = data.get("sms", {}).get(normalized, {}).get("status_text", "Unknown error")
                logger.error(f"SMS error to {phone}: {error}")
                return False
    except Exception as e:
        logger.error(f"SMS exception: {e}")
        return False


def is_phone(contact: str) -> bool:
    """Определить, является ли контакт телефонным номером."""
    digits = "".join(filter(str.isdigit, contact))
    return len(digits) >= 10 and "@" not in contact
