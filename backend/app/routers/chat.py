from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import or_, desc
from typing import List
from app.database import get_db
from app.models import User, ChatRoom, ChatMessage, UserRole
from app.schemas import ChatRoomCreate, ChatRoomOut, ChatRoomDetailOut, ChatMessageCreate, ChatMessageOut
from app.routers.auth import get_current_user

router = APIRouter(prefix="/chat", tags=["Chat"])


@router.get("/rooms", response_model=List[ChatRoomOut])
def get_user_rooms(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Возвращает список чатов для текущего пользователя"""
    if current_user.role == UserRole.operator:
        rooms = db.query(ChatRoom).filter(ChatRoom.operator_id == current_user.id).order_by(desc(ChatRoom.created_at)).all()
    else:
        rooms = db.query(ChatRoom).filter(ChatRoom.expeditor_id == current_user.id).order_by(desc(ChatRoom.created_at)).all()

    # Формируем DTO
    result = []
    for room in rooms:
        last_msg = db.query(ChatMessage).filter(ChatMessage.room_id == room.id).order_by(desc(ChatMessage.timestamp)).first()
        unread = db.query(ChatMessage).filter(
            ChatMessage.room_id == room.id,
            ChatMessage.sender_id != current_user.id,
            ChatMessage.is_read == False
        ).count()

        # Вычисляем данные собеседника
        other_user = room.expeditor if current_user.role == UserRole.operator else room.operator
        
        room_data = ChatRoomOut.model_validate(room)
        room_data.last_message = ChatMessageOut.model_validate(last_msg) if last_msg else None
        room_data.unread_count = unread
        
        if other_user:
            room_data.other_user_name = other_user.name
            room_data.other_user_id = str(other_user.id)
            room_data.other_user_avatar_url = other_user.avatar_url
        else:
            room_data.other_user_name = "Удаленный пользователь"
            room_data.other_user_id = ""
            room_data.other_user_avatar_url = None
        
        result.append(room_data)

    return result


@router.post("/rooms", response_model=ChatRoomOut)
def create_or_get_room(
    room_in: ChatRoomCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Создает новый чат или возвращает существующий для данного заказа"""
    # Determine operator_id and expeditor_id
    operator_id = current_user.id if current_user.role == UserRole.operator else room_in.operator_id
    expeditor_id = current_user.id if current_user.role == UserRole.expeditor else room_in.expeditor_id

    if not operator_id or not expeditor_id:
        raise HTTPException(
            status_code=400, 
            detail="Необходимо указать оператора и экспедитора для начала чата"
        )

    # Ищем существующий чат
    existing_room = db.query(ChatRoom).filter(
        ChatRoom.order_id == room_in.order_id,
        ChatRoom.operator_id == operator_id,
        ChatRoom.expeditor_id == expeditor_id
    ).first()

    if existing_room:
        other_user = existing_room.expeditor if current_user.role == UserRole.operator else existing_room.operator
        unread = db.query(ChatMessage).filter(
            ChatMessage.room_id == existing_room.id,
            ChatMessage.sender_id != current_user.id,
            ChatMessage.is_read == False
        ).count()

        room_data = ChatRoomOut.model_validate(existing_room)
        room_data.other_user_name = other_user.name if other_user else "Удаленный пользователь"
        room_data.other_user_id = str(other_user.id) if other_user else ""
        room_data.other_user_avatar_url = getattr(other_user, 'avatar_url', None) if other_user else None
        room_data.unread_count = unread
        return room_data

    # Создаем новый
    new_room = ChatRoom(
        order_id=room_in.order_id,
        order_number=room_in.order_number,
        operator_id=operator_id,
        expeditor_id=expeditor_id
    )
    db.add(new_room)
    db.commit()
    db.refresh(new_room)

    other_user = new_room.expeditor if current_user.role == UserRole.operator else new_room.operator
    room_data = ChatRoomOut.model_validate(new_room)
    room_data.other_user_name = other_user.name if other_user else "Удаленный пользователь"
    room_data.other_user_id = str(other_user.id) if other_user else ""
    room_data.other_user_avatar_url = getattr(other_user, 'avatar_url', None) if other_user else None
    room_data.unread_count = 0
    return room_data


@router.get("/rooms/{room_id}/messages", response_model=ChatRoomDetailOut)
def get_room_messages(
    room_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Получить все сообщения в чате и отметить их прочитанными"""
    room = db.query(ChatRoom).filter(ChatRoom.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Чат не найден")

    if current_user.id not in [room.operator_id, room.expeditor_id]:
        raise HTTPException(status_code=403, detail="Нет доступа к этому чату")

    # Отмечаем чужие сообщения прочитанными
    unread_msgs = db.query(ChatMessage).filter(
        ChatMessage.room_id == room.id,
        ChatMessage.sender_id != current_user.id,
        ChatMessage.is_read == False
    ).all()
    
    for msg in unread_msgs:
        msg.is_read = True
    if unread_msgs:
        db.commit()

    messages = db.query(ChatMessage).filter(ChatMessage.room_id == room.id).order_by(ChatMessage.timestamp).all()
    
    other_user = room.expeditor if current_user.role == UserRole.operator else room.operator
    
    result = ChatRoomDetailOut.model_validate(room)
    result.other_user_name = other_user.name if other_user else "Удаленный пользователь"
    result.other_user_id = str(other_user.id) if other_user else ""
    result.other_user_avatar_url = getattr(other_user, 'avatar_url', None) if other_user else None
    result.messages = [ChatMessageOut.model_validate(m) for m in messages]
    result.unread_count = 0 # since we marked them as read
    
    return result


@router.post("/rooms/{room_id}/messages", response_model=ChatMessageOut)
def send_message(
    room_id: int,
    msg_in: ChatMessageCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """Отправить сообщение в чат"""
    room = db.query(ChatRoom).filter(ChatRoom.id == room_id).first()
    if not room:
        raise HTTPException(status_code=404, detail="Чат не найден")

    if current_user.id not in [room.operator_id, room.expeditor_id]:
        raise HTTPException(status_code=403, detail="Нет доступа к этому чату")

    new_msg = ChatMessage(
        room_id=room.id,
        sender_id=current_user.id,
        text=msg_in.text
    )
    db.add(new_msg)
    db.commit()
    db.refresh(new_msg)

    return new_msg
