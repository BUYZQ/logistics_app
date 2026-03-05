"""
Роутер управления сотрудниками (только для операторов):
  POST /employees/           — добавить сотрудника
  GET  /employees/           — список сотрудников своего склада
  GET  /employees/{id}       — детали сотрудника
  PATCH /employees/{id}/deactivate — деактивировать
"""
import logging
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User, UserRole, Warehouse
from app.schemas import EmployeeCreate, UserOut, WarehouseOut
from app.security import decode_token

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/employees", tags=["Сотрудники"])


def get_operator(authorization: Optional[str], db: Session) -> User:
    """Проверить, что запрос выполняется оператором."""
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Требуется авторизация")
    token = authorization[7:]
    user_id = decode_token(token)
    if not user_id:
        raise HTTPException(status_code=401, detail="Токен недействителен")
    user = db.query(User).filter(User.id == user_id, User.is_active == True).first()
    if not user:
        raise HTTPException(status_code=404, detail="Пользователь не найден")
    if user.role != UserRole.operator:
        raise HTTPException(status_code=403, detail="Доступ только для операторов")
    return user


@router.post("/", response_model=UserOut, status_code=201)
def create_employee(
    body: EmployeeCreate,
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db),
):
    """
    Оператор добавляет нового сотрудника в базу.
    Если role=operator — автоматически назначается operator_number.
    """
    operator = get_operator(authorization, db)

    # Проверяем что склад существует
    warehouse = db.query(Warehouse).filter(Warehouse.id == body.warehouse_id).first()
    if not warehouse:
        raise HTTPException(status_code=404, detail=f"Склад #{body.warehouse_id} не найден")

    # Проверяем уникальность телефона и email
    if body.phone:
        existing = db.query(User).filter(User.phone == body.phone).first()
        if existing:
            raise HTTPException(status_code=409, detail="Этот телефон уже зарегистрирован")
    if body.email:
        existing = db.query(User).filter(User.email == body.email).first()
        if existing:
            raise HTTPException(status_code=409, detail="Этот email уже зарегистрирован")

    # Авто-нумерация операторов
    operator_number = None
    if body.role == UserRole.operator:
        last_num = db.query(User).filter(
            User.role == UserRole.operator,
            User.operator_number != None,
        ).order_by(User.operator_number.desc()).first()
        operator_number = (last_num.operator_number + 1) if last_num else 1

    new_user = User(
        phone=body.phone,
        email=body.email,
        name=body.name,
        role=body.role,
        warehouse_id=body.warehouse_id,
        operator_number=operator_number,
        created_by_id=operator.id,
        is_active=True,
    )
    db.add(new_user)
    db.commit()
    db.refresh(new_user)

    logger.info(
        f"Employee created: {new_user.name} ({new_user.role}) "
        f"by operator #{operator.operator_number}"
    )
    return new_user


@router.get("/", response_model=List[UserOut])
def list_employees(
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db),
):
    """Список сотрудников в рамках склада оператора."""
    operator = get_operator(authorization, db)
    users = db.query(User).filter(
        User.warehouse_id == operator.warehouse_id,
        User.id != operator.id,
    ).order_by(User.created_at.desc()).all()
    return users


@router.get("/{employee_id}", response_model=UserOut)
def get_employee(
    employee_id: int,
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db),
):
    operator = get_operator(authorization, db)
    user = db.query(User).filter(
        User.id == employee_id,
        User.warehouse_id == operator.warehouse_id,
    ).first()
    if not user:
        raise HTTPException(status_code=404, detail="Сотрудник не найден")
    return user


@router.patch("/{employee_id}/deactivate", response_model=UserOut)
def deactivate_employee(
    employee_id: int,
    authorization: Optional[str] = Header(None),
    db: Session = Depends(get_db),
):
    """Деактивировать сотрудника (не удаляет из БД)."""
    operator = get_operator(authorization, db)
    user = db.query(User).filter(
        User.id == employee_id,
        User.warehouse_id == operator.warehouse_id,
    ).first()
    if not user:
        raise HTTPException(status_code=404, detail="Сотрудник не найден")
    if user.id == operator.id:
        raise HTTPException(status_code=400, detail="Нельзя деактивировать самого себя")
    user.is_active = False
    db.commit()
    db.refresh(user)
    return user


@router.get("/warehouses/", response_model=List[WarehouseOut], tags=["Склады"])
def list_warehouses(db: Session = Depends(get_db)):
    """Список всех складов."""
    return db.query(Warehouse).order_by(Warehouse.number).all()
