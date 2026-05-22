"""
Dashboard router — панель статистики для начальника.
GET /dashboard       → HTML страница (защищена сессией admin)
GET /dashboard/stats → JSON с агрегированными данными
"""
import os
from datetime import datetime, timedelta
from typing import Any, Dict

from fastapi import APIRouter, Depends, Request
from fastapi.responses import HTMLResponse, JSONResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import (
    ChatMessage, ChatRoom, Order, OrderStatus, User, UserRole, Warehouse
)

router = APIRouter(prefix="/dashboard", tags=["Dashboard"])

BASE_DIR = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
templates = Jinja2Templates(directory=os.path.join(BASE_DIR, "templates"))


def _require_admin(request: Request):
    """Redirect to /admin/login if not authenticated."""
    token = request.session.get("token")
    if not token:
        return RedirectResponse(url="/admin/login", status_code=302)
    return None


def _get_stats(db: Session) -> Dict[str, Any]:
    # ── Orders ─────────────────────────────────────────────────────────────
    total_orders = db.query(func.count(Order.id)).scalar() or 0
    orders_by_status: Dict[str, int] = {}
    for status in OrderStatus:
        cnt = db.query(func.count(Order.id)).filter(Order.status == status).scalar() or 0
        orders_by_status[status.value] = cnt

    # Orders per day — last 7 days
    today = datetime.utcnow().replace(hour=0, minute=0, second=0, microsecond=0)
    daily_labels = []
    daily_counts = []
    for i in range(6, -1, -1):
        day_start = today - timedelta(days=i)
        day_end = day_start + timedelta(days=1)
        cnt = (
            db.query(func.count(Order.id))
            .filter(Order.date >= day_start, Order.date < day_end)
            .scalar()
            or 0
        )
        daily_labels.append(day_start.strftime("%d.%m"))
        daily_counts.append(cnt)

    # ── Users ───────────────────────────────────────────────────────────────
    total_users = db.query(func.count(User.id)).scalar() or 0
    active_users = db.query(func.count(User.id)).filter(User.is_active == True).scalar() or 0
    inactive_users = total_users - active_users
    operators = db.query(func.count(User.id)).filter(User.role == UserRole.operator).scalar() or 0
    expeditors = db.query(func.count(User.id)).filter(User.role == UserRole.expeditor).scalar() or 0

    # ── Warehouses ──────────────────────────────────────────────────────────
    warehouses = db.query(Warehouse).order_by(Warehouse.number).all()
    warehouse_labels = []
    warehouse_operators = []
    warehouse_expeditors = []
    for wh in warehouses:
        warehouse_labels.append(f"Склад №{wh.number}")
        op_cnt = (
            db.query(func.count(User.id))
            .filter(User.warehouse_id == wh.id, User.role == UserRole.operator)
            .scalar()
            or 0
        )
        ex_cnt = (
            db.query(func.count(User.id))
            .filter(User.warehouse_id == wh.id, User.role == UserRole.expeditor)
            .scalar()
            or 0
        )
        warehouse_operators.append(op_cnt)
        warehouse_expeditors.append(ex_cnt)

    # ── Chat ────────────────────────────────────────────────────────────────
    total_chat_rooms = db.query(func.count(ChatRoom.id)).scalar() or 0
    total_messages = db.query(func.count(ChatMessage.id)).scalar() or 0
    unread_messages = (
        db.query(func.count(ChatMessage.id)).filter(ChatMessage.is_read == False).scalar() or 0
    )

    # Delivery rate
    delivered = orders_by_status.get("delivered", 0)
    delivery_rate = round((delivered / total_orders * 100) if total_orders else 0, 1)

    return {
        "orders": {
            "total": total_orders,
            "by_status": orders_by_status,
            "daily_labels": daily_labels,
            "daily_counts": daily_counts,
            "delivery_rate": delivery_rate,
        },
        "users": {
            "total": total_users,
            "active": active_users,
            "inactive": inactive_users,
            "operators": operators,
            "expeditors": expeditors,
        },
        "warehouses": {
            "total": len(warehouses),
            "labels": warehouse_labels,
            "operators": warehouse_operators,
            "expeditors": warehouse_expeditors,
        },
        "chat": {
            "rooms": total_chat_rooms,
            "messages": total_messages,
            "unread": unread_messages,
        },
    }


@router.get("/stats", response_class=JSONResponse)
async def get_stats(request: Request, db: Session = Depends(get_db)):
    redir = _require_admin(request)
    if redir:
        return JSONResponse({"error": "unauthorized"}, status_code=401)
    return _get_stats(db)


@router.get("", response_class=HTMLResponse)
async def dashboard_page(request: Request, db: Session = Depends(get_db)):
    redir = _require_admin(request)
    if redir:
        return redir
    stats = _get_stats(db)
    now = datetime.utcnow().strftime("%d.%m.%Y %H:%M UTC")
    return templates.TemplateResponse(
        "dashboard.html", {"request": request, "stats": stats, "now": now}
    )
