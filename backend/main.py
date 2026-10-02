import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

import models
from database import engine
from auth import router as auth_router
from analysis import router as analysis_router
from community import router as community_router
from monitoring import router as monitoring_router
from reviews import router as reviews_router
from admin import router as admin_router

load_dotenv()

from database import SessionLocal

# Create tables
models.Base.metadata.create_all(bind=engine)

def init_admin():
    admin_email = os.getenv("ADMIN_EMAIL")
    admin_pass = os.getenv("ADMIN_PASSWORD")
    if not admin_email or not admin_pass:
        if admin_email or admin_pass:
            print("Admin bootstrap skipped: configure both ADMIN_EMAIL and ADMIN_PASSWORD.")
        return

    db = SessionLocal()
    try:
        from auth import get_password_hash
        admin = db.query(models.User).filter(models.User.email == admin_email).first()
        if not admin:
            admin = models.User(
                email=admin_email,
                password_hash=get_password_hash(admin_pass),
                full_name="System Admin",
                role="admin",
                is_active=True
            )
            db.add(admin)
            db.commit()
    finally:
        db.close()

init_admin()

app = FastAPI(title="ScamShield API")

FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:5173")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[FRONTEND_URL],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth_router, prefix="/api")
app.include_router(analysis_router, prefix="/api")
app.include_router(community_router, prefix="/api")
app.include_router(monitoring_router, prefix="/api")
app.include_router(reviews_router, prefix="/api/reviews")
app.include_router(admin_router, prefix="/api/admin")

@app.get("/api/health")
def health_check():
    return {"status": "ok", "message": "ScamShield backend is running"}
