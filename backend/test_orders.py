import asyncio
import httpx
from app.security import create_access_token

async def test():
    token = create_access_token(1) # user 1
    print(f"Token: {token}")
    
    async with httpx.AsyncClient() as client:
        try:
            r = await client.get('http://0.0.0.0:8000/orders', headers={'Authorization': f'Bearer {token}'}, timeout=5.0)
            print(f"Status: {r.status_code}")
            print(f"Body: {r.text}")
        except Exception as e:
            print(f"Error: {e}")

if __name__ == '__main__':
    asyncio.run(test())
