"""
SMS service via sms.ru API.
Docs: https://sms.ru/docs/api/api_group_sms/send
"""
import logging
import os
from dataclasses import dataclass
from typing import Optional

import httpx
from dotenv import load_dotenv

load_dotenv()

SMSRU_API_ID = os.getenv("SMSRU_API_ID", "")
SMSRU_FROM = os.getenv("SMSRU_FROM", "")
SMSRU_URL = "https://sms.ru/sms/send"

logger = logging.getLogger(__name__)


@dataclass
class SmsSendResult:
    success: bool
    error: Optional[str] = None
    status_code: Optional[int] = None


def normalize_sms_phone(phone: str) -> str:
    normalized = "".join(filter(str.isdigit, phone))
    if normalized.startswith("8"):
        normalized = "7" + normalized[1:]
    return normalized


async def send_sms_result(phone: str, message: str) -> SmsSendResult:
    """
    Send SMS via sms.ru and return provider details.
    If SMSRU_API_ID is empty, development mode prints the message to server logs.
    """
    normalized = normalize_sms_phone(phone)

    if not SMSRU_API_ID:
        logger.warning("[DEV MODE] SMS to %s: %s", phone, message)
        print(f"\n{'=' * 50}\nSMS to {phone}:\n{message}\n{'=' * 50}\n")
        return SmsSendResult(success=True)

    payload = {
        "api_id": SMSRU_API_ID,
        "to": normalized,
        "msg": message,
        "json": 1,
    }
    if SMSRU_FROM:
        payload["from"] = SMSRU_FROM

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.post(SMSRU_URL, data=payload)
            resp.raise_for_status()
            data = resp.json()

        sms_data = data.get("sms", {}).get(normalized, {})
        status = sms_data.get("status", "")
        if status == "OK":
            logger.info("SMS sent to %s", phone)
            return SmsSendResult(success=True)

        error = sms_data.get("status_text") or data.get("status_text") or "Unknown SMS.RU error"
        status_code = sms_data.get("status_code") or data.get("status_code")
        logger.error("SMS error to %s: %s", phone, error)
        return SmsSendResult(success=False, error=error, status_code=status_code)
    except Exception as exc:
        logger.error("SMS exception: %s", exc)
        return SmsSendResult(success=False, error=str(exc))


async def send_sms(phone: str, message: str) -> bool:
    result = await send_sms_result(phone, message)
    return result.success


def is_phone(contact: str) -> bool:
    """Return True when contact looks like a phone number."""
    digits = "".join(filter(str.isdigit, contact))
    return len(digits) >= 10 and "@" not in contact
