from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.models import Base, Warehouse
import os
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./nekst.db")

# connect_args нужен только для SQLite
connect_args = {"check_same_thread": False} if DATABASE_URL.startswith("sqlite") else {}

engine = create_engine(DATABASE_URL, connect_args=connect_args)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """Создание таблиц и начальных данных."""
    Base.metadata.create_all(bind=engine)
    # Создаём 4 склада при первом запуске
    db = SessionLocal()
    try:
        if db.query(Warehouse).count() == 0:
            warehouses = [
                Warehouse(number=1, address="ул. Амгинская, 5, Нерюнгри, Респ. Саха (Якутия), 678960"),
                Warehouse(number=2, address="ул. Амгинская, 6, Нерюнгри, Респ. Саха (Якутия), 678960"),
                Warehouse(number=3, address="ул. Амгинская, 7, Нерюнгри, Респ. Саха (Якутия), 678960"),
                Warehouse(number=4, address="ул. Амгинская, 8, Нерюнгри, Респ. Саха (Якутия), 678960"),
            ]
            db.add_all(warehouses)
            db.commit()
    finally:
        db.close()
