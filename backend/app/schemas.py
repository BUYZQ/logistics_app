from pydantic import BaseModel, EmailStr, field_validator
from typing import Optional
from datetime import datetime
from app.models import UserRole


# ── Auth ─────────────────────────────────────────────────────────────────────

class SendOTPRequest(BaseModel):
    """Отправить OTP-код на телефон или email."""
    contact: str  # +79141234567 или user@example.ru

    @field_validator("contact")
    @classmethod
    def validate_contact(cls, v: str) -> str:
        v = v.strip()
        if not v:
            raise ValueError("Поле не может быть пустым")
        return v


class VerifyOTPRequest(BaseModel):
    """Подтвердить OTP-код."""
    contact: str
    code: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: "UserOut"


# ── Users / Employees ─────────────────────────────────────────────────────────

class EmployeeCreate(BaseModel):
    """Оператор создаёт нового сотрудника."""
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    name: str
    role: UserRole
    warehouse_id: int

    @field_validator("phone", "email")
    @classmethod
    def at_least_one(cls, v):
        return v

    def model_post_init(self, __context):
        if not self.phone and not self.email:
            raise ValueError("Нужно указать телефон или email")


class UserOut(BaseModel):
    id: int
    phone: Optional[str]
    email: Optional[str]
    name: str
    role: UserRole
    warehouse_id: Optional[int]
    operator_number: Optional[int]
    is_active: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class WarehouseOut(BaseModel):
    id: int
    number: int
    address: str

    model_config = {"from_attributes": True}


# ── Chat ─────────────────────────────────────────────────────────────────────

class ChatMessageCreate(BaseModel):
    text: str

    @field_validator("text")
    @classmethod
    def not_empty(cls, v):
        if not v.strip():
            raise ValueError("Сообщение не может быть пустым")
        return v.strip()


class ChatMessageOut(BaseModel):
    id: int
    room_id: int
    sender_id: int
    text: str
    timestamp: datetime
    is_read: bool

    model_config = {"from_attributes": True}


class ChatRoomCreate(BaseModel):
    """Создаёт или возвращает существующий чат для заказа"""
    order_id: str
    order_number: str
    # ID экспедитора. ID оператора берется из токена создающего
    expeditor_id: int


class ChatRoomOut(BaseModel):
    id: int
    order_id: str
    order_number: str
    operator_id: int
    expeditor_id: int
    created_at: datetime
    # Последнее сообщение (если есть)
    last_message: Optional[ChatMessageOut] = None
    unread_count: int = 0
    # Имя и ID собеседника (вычисляется в роутере для фронтенда)
    other_user_name: Optional[str] = None
    other_user_id: Optional[str] = None

    model_config = {"from_attributes": True}

class ChatRoomDetailOut(ChatRoomOut):
    messages: list[ChatMessageOut] = []


# ── Orders ───────────────────────────────────────────────────────────────────

from app.models import OrderStatus

class OrderBase(BaseModel):
    number: str
    cargoName: str
    cargoWeight: str
    fromAddress: str
    toAddress: str
    fromLat: float
    fromLng: float
    toLat: float
    toLng: float
    expeditorId: Optional[str] = None
    expeditorName: Optional[str] = None
    expeditorPhone: Optional[str] = None
    comment: Optional[str] = None
    attachedPhotos: Optional[str] = None

class OrderCreate(OrderBase):
    pass

class OrderUpdate(BaseModel):
    status: Optional[OrderStatus] = None
    expeditorId: Optional[str] = None
    expeditorName: Optional[str] = None
    expeditorPhone: Optional[str] = None
    comment: Optional[str] = None
    attachedPhotos: Optional[str] = None

class OrderOut(OrderBase):
    id: str
    date: datetime
    status: OrderStatus
    operatorId: str
    operatorName: Optional[str] = None

    model_config = {"from_attributes": True}
