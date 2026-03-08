import logging
import uuid
import json
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Order, OrderStatus, User, UserRole
from app.schemas import OrderCreate, OrderUpdate, OrderOut
from app.routers.auth import get_current_user

logger = logging.getLogger(__name__)
router = APIRouter(prefix="/orders", tags=["Заявки"])

@router.get("", response_model=List[OrderOut])
async def list_orders(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Получить список заявок.
    Оператор видит все заявки (своего склада или вообще).
    Экспедитор видит Pending заявки без экспедитора и свои заявки (где он expeditorId).
    """
    if user.role == UserRole.operator:
        # В идеале оператор видит заявки своего склада, но пока просто все:
        orders = db.query(Order).order_by(Order.date.desc()).all()
    else:
        # Экспедитор
        orders = db.query(Order).filter(
            (Order.expeditorId == str(user.id)) | 
            ((Order.status == OrderStatus.pending) & (Order.expeditorId == None))
        ).order_by(Order.date.desc()).all()
    return orders

@router.post("", response_model=OrderOut)
async def create_order(
    body: OrderCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Создание заявки (только для операторов).
    """
    if user.role != UserRole.operator:
        raise HTTPException(status_code=403, detail="Только оператор может создавать заявки")

    # Сгенерировать ID для заказа, если number должен быть уникальным
    order_id = str(uuid.uuid4())
    
    new_order = Order(
        id=order_id,
        number=body.number,
        cargoName=body.cargoName,
        cargoWeight=body.cargoWeight,
        fromAddress=body.fromAddress,
        toAddress=body.toAddress,
        fromLat=body.fromLat,
        fromLng=body.fromLng,
        toLat=body.toLat,
        toLng=body.toLng,
        status=OrderStatus.pending,
        operatorId=str(user.id),
        operatorName=user.name,
        expeditorId=body.expeditorId,
        expeditorName=body.expeditorName,
        expeditorPhone=body.expeditorPhone,
        comment=body.comment,
        attachedPhotos=json.dumps(body.attachedPhotos) if body.attachedPhotos else None,
    )

    db.add(new_order)
    db.commit()
    db.refresh(new_order)
    return new_order

@router.put("/{order_id}/status", response_model=OrderOut)
async def update_order_status(
    order_id: str,
    body: OrderUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """
    Обновить статус или детали экспедитора (принятие заказа, изменение статуса).
    """
    order = db.query(Order).filter(Order.id == order_id).first()
    if not order:
        raise HTTPException(status_code=404, detail="Заявка не найдена")

    # Если экспедитор берет pending заказ, запишем его данные
    if body.status:
        order.status = body.status
    
    if body.expeditorId is not None:
        order.expeditorId = body.expeditorId
    if body.expeditorName is not None:
        order.expeditorName = body.expeditorName
    if body.expeditorPhone is not None:
        order.expeditorPhone = body.expeditorPhone
    if body.comment is not None:
        order.comment = body.comment
    if body.attachedPhotos is not None:
        order.attachedPhotos = json.dumps(body.attachedPhotos)

    db.commit()
    db.refresh(order)
    return order
