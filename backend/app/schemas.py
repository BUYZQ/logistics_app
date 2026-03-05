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
