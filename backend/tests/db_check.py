import os
from sqlalchemy import create_engine
from dotenv import load_dotenv

load_dotenv()

DATABASE_URL = os.getenv("DATABASE_URL", "")
if DATABASE_URL.startswith("postgresql://"):
    DATABASE_URL = DATABASE_URL.replace("postgresql://", "postgresql+psycopg2://", 1)

print("Checking configured database connection (connection details hidden).")
try:
    engine = create_engine(DATABASE_URL, pool_pre_ping=True, pool_recycle=300)
    conn = engine.connect()
    print("Connection successful!")
    conn.close()
except Exception as e:
    print("Database connection failed:", type(e).__name__)
