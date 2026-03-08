from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime, ForeignKey, Enum as SAEnum, Float
from sqlalchemy.orm import DeclarativeBase, relationship
from datetime import datetime
import enum


class UserRole(str, enum.Enum):
    operator = "operator"
    expeditor = "expeditor"


class OrderStatus(str, enum.Enum):
    pending = "pending"
    accepted = "accepted"
    inTransit = "inTransit"
    delivered = "delivered"
    cancelled = "cancelled"


class Base(DeclarativeBase):
    pass


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    phone = Column(String(20), unique=True, nullable=True, index=True)
    email = Column(String(255), unique=True, nullable=True, index=True)
    name = Column(String(100), nullable=False)
    role = Column(SAEnum(UserRole), nullable=False)
    warehouse_id = Column(Integer, ForeignKey("warehouses.id"), nullable=True)
    # Порядковый номер оператора (автоматически, только для операторов)
    operator_number = Column(Integer, nullable=True)
    avatar_url = Column(String(500), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    created_by_id = Column(Integer, ForeignKey("users.id"), nullable=True)

    warehouse = relationship("Warehouse", back_populates="users")
    created_by = relationship("User", remote_side=[id])

    def __str__(self):
        role_name = "Оператор" if self.role == UserRole.operator else "Экспедитор"
        return f"{self.name} ({role_name})"


class OTPCode(Base):
    __tablename__ = "otp_codes"

    id = Column(Integer, primary_key=True, index=True)
    # Контакт: номер телефона или email
    contact = Column(String(255), nullable=False, index=True)
    code = Column(String(6), nullable=False)
    expires_at = Column(DateTime, nullable=False)
    is_used = Column(Boolean, default=False)
    attempts = Column(Integer, default=0)
    created_at = Column(DateTime, default=datetime.utcnow)

    def __str__(self):
        return f"OTP для {self.contact}"


class Warehouse(Base):
    __tablename__ = "warehouses"

    id = Column(Integer, primary_key=True)
    number = Column(Integer, unique=True, nullable=False)   # 1-4
    address = Column(String(255), nullable=False)

    users = relationship("User", back_populates="warehouse")

    def __str__(self):
        return f"Склад №{self.number} ({self.address})"


class ChatRoom(Base):
    __tablename__ = "chat_rooms"

    id = Column(Integer, primary_key=True, index=True)
    order_id = Column(String(50), index=True, nullable=False)
    order_number = Column(String(100), nullable=False)
    operator_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    expeditor_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    operator = relationship("User", foreign_keys=[operator_id])
    expeditor = relationship("User", foreign_keys=[expeditor_id])
    messages = relationship("ChatMessage", back_populates="room", cascade="all, delete-orphan")

    def __str__(self):
        return f"Чат заказа {self.order_number}"


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id = Column(Integer, primary_key=True, index=True)
    room_id = Column(Integer, ForeignKey("chat_rooms.id", ondelete="CASCADE"), nullable=False)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    text = Column(String(1000), nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)
    is_read = Column(Boolean, default=False)

    room = relationship("ChatRoom", back_populates="messages")
    sender = relationship("User", foreign_keys=[sender_id])

    def __str__(self):
        return f"Сообщение от {self.sender_id} в {self.timestamp}"


class Order(Base):
    __tablename__ = "orders"

    id = Column(String(50), primary_key=True, index=True)
    number = Column(String(100), unique=True, index=True, nullable=False)
    cargoName = Column(String(255), nullable=False)
    cargoWeight = Column(String(100), nullable=False)
    fromAddress = Column(String(255), nullable=False)
    toAddress = Column(String(255), nullable=False)
    fromLat = Column(Float, nullable=False)
    fromLng = Column(Float, nullable=False)
    toLat = Column(Float, nullable=False)
    toLng = Column(Float, nullable=False)
    date = Column(DateTime, default=datetime.utcnow)
    status = Column(SAEnum(OrderStatus), default=OrderStatus.pending)
    operatorId = Column(String(50), nullable=False)
    expeditorId = Column(String(50), nullable=True)
    expeditorName = Column(String(255), nullable=True)
    expeditorPhone = Column(String(50), nullable=True)
    comment = Column(String(1000), nullable=True)
    operatorName = Column(String(255), nullable=True)
    
    # We could store photos as JSON, or a comma-separated string, or a separate table.
    # For simplicity, since SQLite backend:
    attachedPhotos = Column(String, nullable=True) # JSON dumped or comma separated

    def __str__(self):
        return f"Заказ {self.number} ({self.status})"
