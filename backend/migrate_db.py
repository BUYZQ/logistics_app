import sqlite3
import os

db_path = os.path.join(os.path.dirname(__file__), 'nekst.db')
conn = sqlite3.connect(db_path)
try:
    conn.execute("ALTER TABLE users ADD COLUMN avatar_url VARCHAR(500)")
    conn.commit()
    print("Column avatar_url added successfully.")
except sqlite3.OperationalError as e:
    print(f"Skipping migration: {e}")
conn.close()
