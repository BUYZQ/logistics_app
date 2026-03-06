"""
Некст — FastAPI Backend
Точка входа приложения.
"""
from fastapi import FastAPI, Response
from fastapi.middleware.cors import CORSMiddleware
from sqladmin import Admin

from app.database import init_db, engine
from app.routers import auth, employees, chat, orders
from app.admin import UserAdmin, OTPCodeAdmin, WarehouseAdmin, admin_auth_backend

app = FastAPI(
    title="Некст — API",
    description="Backend для системы управления логистикой пищевых товаров",
    version="1.0.0",
)

from pathlib import Path
BASE_DIR = Path(__file__).resolve().parent

# Подключение админки с авторизацией
admin = Admin(
    app, 
    engine, 
    title="Некст — База данных", 
    authentication_backend=admin_auth_backend, 
    templates_dir=str(BASE_DIR.parent / "templates")
)
admin.add_view(UserAdmin)
admin.add_view(OTPCodeAdmin)
admin.add_view(WarehouseAdmin)

# CORS — разрешаем запросы из Flutter приложения
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # В продакшене укажите конкретные домены
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup():
    """Инициализация БД при запуске."""
    init_db()


@app.get("/", tags=["Health"])
def root():
    return {"status": "ok", "service": "Некст API", "version": "1.0.0"}


@app.get("/health", tags=["Health"])
def health():
    return {"status": "healthy"}


@app.get("/favicon.ico", include_in_schema=False)
async def favicon():
    return Response(status_code=204)

# Подключаем роутеры
app.include_router(auth.router)
app.include_router(employees.router)
app.include_router(chat.router)
app.include_router(orders.router)
