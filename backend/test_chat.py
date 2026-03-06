import sys
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.database import SessionLocal
from app.models import User, OTPCode, ChatRoom, ChatMessage, UserRole

db = SessionLocal()

op = db.query(User).filter(User.role == UserRole.operator).first()
ex = db.query(User).filter(User.role == UserRole.expeditor).first()

if not op or not ex:
    print("Not enough users to test chat")
    sys.exit(0)

print(f"Testing chat between Op({op.name}) and Ex({ex.name})")

from fastapi.testclient import TestClient
from app.main import app
from app.security import create_access_token

client = TestClient(app)

op_token = create_access_token(op.id)
ex_token = create_access_token(ex.id)

op_headers = {"Authorization": f"Bearer {op_token}"}
ex_headers = {"Authorization": f"Bearer {ex_token}"}

# Create chat
resp = client.post("/chat/rooms", json={"order_id": "99", "order_number": "TEST-123", "expeditor_id": ex.id}, headers=op_headers)
if resp.status_code != 200:
    print(f"Error creating room: {resp.status_code} - {resp.text}")
    sys.exit(1)
    
room = resp.json()
print("Room created:", room)

room_id = room["id"]

# Send message
resp = client.post(f"/chat/rooms/{room_id}/messages", json={"text": "Hello there!"}, headers=op_headers)
if resp.status_code != 200:
    print(f"Error sending message: {resp.status_code} - {resp.text}")
    sys.exit(1)

print("Message sent:", resp.json())

# Get messages
resp = client.get(f"/chat/rooms/{room_id}/messages", headers=ex_headers)
print("Expeditor reading messages:", resp.json())

# List rooms
resp = client.get("/chat/rooms", headers=op_headers)
print("Operator rooms:", resp.json())

print("All tests passed.")
