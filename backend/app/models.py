from sqlalchemy import create_engine, Column, Integer, String, Boolean, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import DeclarativeBase, relationship
from datetime import datetime
import enum


class UserRole(str, enum.Enum):
    operator = "operator"
    expeditor = "expeditor"


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
