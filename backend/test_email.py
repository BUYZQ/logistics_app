import asyncio
import os
from dotenv import load_dotenv
from app.services.email_service import send_email
import aiosmtplib

load_dotenv()

async def main():
    print(f"Testing Google SMTP to {os.getenv('SMTP_USER')} on port 587 STARTTLS...")
    message = "123456"
    try:
        await aiosmtplib.send(
            message,
            sender=os.getenv('SMTP_USER'),
            recipients=[os.getenv('SMTP_USER')],
            hostname="smtp.gmail.com",
            port=465,
            username=os.getenv('SMTP_USER'),
            password=os.getenv('SMTP_PASSWORD'),
            use_tls=True,
        )
        print("Success!")
    except Exception as e:
        print(f"Exception: {e}")

if __name__ == "__main__":
    asyncio.run(main())
