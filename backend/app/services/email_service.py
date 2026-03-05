"""
Email-сервис через Яндекс SMTP (или любой другой SMTP).
"""
import aiosmtplib
import logging
import os
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from dotenv import load_dotenv

load_dotenv()

SMTP_HOST = os.getenv("SMTP_HOST", "smtp.yandex.ru")
SMTP_PORT = int(os.getenv("SMTP_PORT", "465"))
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
EMAIL_FROM = os.getenv("EMAIL_FROM", SMTP_USER)

logger = logging.getLogger(__name__)


async def send_email(to_email: str, subject: str, body: str) -> bool:
    """
    Отправить email через SMTP.
    Возвращает True при успехе.
    """
    if not SMTP_USER or not SMTP_PASSWORD or SMTP_USER == "":
        # Режим разработки — выводим в консоль
        logger.warning(f"[DEV MODE] Email to {to_email}: {subject}\n{body}")
        print(f"\n{'='*50}\n📧 Получено письмо для {to_email}:\n\nВаш код входа: {body}\n{'='*50}\n")
        return True

    msg = MIMEMultipart("alternative")
    msg["Subject"] = subject
    msg["From"] = f"Nekst App <{EMAIL_FROM}>"
    msg["To"] = to_email

    html_body = f"""
    <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto;">
      <h2 style="color: #3B7EF6;">Некст — Авторизация</h2>
      <p>Ваш код подтверждения:</p>
      <div style="
        background: #f0f4ff;
        border: 2px solid #3B7EF6;
        border-radius: 12px;
        padding: 20px;
        text-align: center;
        font-size: 32px;
        font-weight: bold;
        letter-spacing: 8px;
        color: #3B7EF6;
      ">{body}</div>
      <p style="color: #888; font-size: 13px; margin-top: 16px;">
        Код действителен 10 минут. Не передавайте его никому.
      </p>
    </div>
    """

    msg.attach(MIMEText(body, "plain"))
    msg.attach(MIMEText(html_body, "html"))

    try:
        await aiosmtplib.send(
            msg,
            hostname=SMTP_HOST,
            port=SMTP_PORT,
            username=SMTP_USER,
            password=SMTP_PASSWORD,
            use_tls=True,
        )
        logger.info(f"Email sent to {to_email}")
        return True
    except Exception as e:
        logger.error(f"Email exception: {type(e).__name__}: {e}")
        print(f"\n❌ ОШИБКА ОТПРАВКИ EMAIL: {type(e).__name__} - {e}")
        print("💡 ПРОВЕРЬТЕ: 1. Включен ли IMAP/POP3 в настройках Яндекс Почты (Все настройки -> Почтовые программы).")
        print("           2. Правильный ли 'Пароль приложения'.\n")
        return False


async def send_otp_email(to_email: str, code: str) -> bool:
    return await send_email(
        to_email=to_email,
        subject="Код подтверждения — Некст",
        body=code,
    )
