from sqladmin import ModelView, Admin
from sqladmin.authentication import AuthenticationBackend
from starlette.requests import Request
from app.models import User, OTPCode, Warehouse
import os

# Простая авторизация для админки
class AdminAuth(AuthenticationBackend):
    async def login(self, request: Request) -> bool:
        form = await request.form()
        username, password = form.get("username"), form.get("password")
        
        # Замените пароль в продакшене!
        if username == "admin" and password == "admin":
            # Сохраняем сессию
            request.session.update({"token": "admin_token"})
            return True
        return False

    async def logout(self, request: Request) -> bool:
        request.session.clear()
        return True

    async def authenticate(self, request: Request) -> bool:
        token = request.session.get("token")
        if not token:
            return False
        return True

admin_auth_backend = AdminAuth(secret_key=os.getenv("SECRET_KEY", "super_secret_admin_key"))

class UserAdmin(ModelView, model=User):
    name = "Сотрудник"
    name_plural = "Сотрудники"
    icon = "fa-solid fa-user"
    column_list = [User.id, User.name, User.phone, User.email, User.role, User.warehouse, User.is_active]
    column_searchable_list = [User.name, User.phone, User.email]
    column_default_sort = ("id", True)
    
    # Прячем технические поля из формы создания/редактирования
    form_excluded_columns = [User.operator_number, User.created_at, User.created_by, User.created_by_id]
    
    # Русификация названий колонок
    column_labels = {
        User.id: "ID",
        User.name: "ФИО",
        User.phone: "Телефон",
        User.email: "Email",
        User.role: "Роль",
        User.warehouse: "Склад",
        User.warehouse_id: "ID Склада",
        User.is_active: "Активен",
        User.operator_number: "Номер оператора",
        User.created_at: "Дата создания",
    }
    
    # Русификация значений ролей
    column_formatters = {
        User.role: lambda m, a: "Оператор" if m.role.value == "operator" else "Экспедитор"
    }

class OTPCodeAdmin(ModelView, model=OTPCode):
    name = "OTP Код"
    name_plural = "OTP Коды"
    icon = "fa-solid fa-key"
    column_list = [OTPCode.id, OTPCode.contact, OTPCode.code, OTPCode.expires_at, OTPCode.is_used, OTPCode.attempts]
    column_searchable_list = [OTPCode.contact]
    column_default_sort = ("id", True)
    
    column_labels = {
        OTPCode.id: "ID",
        OTPCode.contact: "Контакт (Телефон/Email)",
        OTPCode.code: "Код",
        OTPCode.expires_at: "Истекает",
        OTPCode.is_used: "Использован",
        OTPCode.attempts: "Попытки",
        OTPCode.created_at: "Дата создания",
    }

class WarehouseAdmin(ModelView, model=Warehouse):
    name = "Склад"
    name_plural = "Склады"
    icon = "fa-solid fa-warehouse"
    column_list = [Warehouse.id, Warehouse.number, Warehouse.address]
    column_searchable_list = [Warehouse.address]
    column_default_sort = ("number", False)

    column_labels = {
        Warehouse.id: "ID",
        Warehouse.number: "Номер склада",
        Warehouse.address: "Адрес",
        Warehouse.users: "Сотрудники",
    }
