import asyncio
import os
from app.services.email_service import send_otp_email

# Грузим .env принудительно, если нужно
from dotenv import load_dotenv
load_dotenv()

async def test():
    print(f"SMTP Config: USER={os.getenv('SMTP_USER')}, PORT={os.getenv('SMTP_PORT')}")
    success = await send_otp_email("test@gmail.com", "123456")
    print("Success:", success)

asyncio.run(test())
