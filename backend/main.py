import sys
import os

# Ensure backend directory is in sys.path regardless of execution working directory
BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
if BACKEND_DIR not in sys.path:
    sys.path.insert(0, BACKEND_DIR)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func
from dotenv import load_dotenv
from urllib.parse import urlsplit

import models
from database import SessionLocal
from auth import router as auth_router
from analysis import router as analysis_router
from community import router as community_router
from monitoring import router as monitoring_router
from reviews import router as reviews_router
from admin import router as admin_router
from guardian_transcription import router as guardian_transcription_router
from guardian_analysis import router as guardian_analysis_router
from calls import router as calls_router
from app.services.notification_worker import notification_worker

load_dotenv(os.path.join(BACKEND_DIR, ".env"))
load_dotenv()

def init_admin():
    admin_email = os.getenv("ADMIN_EMAIL", "").strip().lower()
    admin_pass = os.getenv("ADMIN_PASSWORD")
    if not admin_email or not admin_pass:
        if admin_email or admin_pass:
            print("Admin bootstrap skipped: configure both ADMIN_EMAIL and ADMIN_PASSWORD.")
        return

    db = SessionLocal()
    try:
        from auth import get_password_hash, verify_password
        admin = db.query(models.User).filter(
            func.lower(models.User.email) == admin_email
        ).first()
        if not admin:
            admin = models.User(
                email=admin_email,
                password_hash=get_password_hash(admin_pass),
                full_name="System Admin",
                role="admin",
                is_active=True,
                email_verified=True,
                two_factor_enabled=True,
            )
            db.add(admin)
            db.commit()
            return

        changed = False
        if admin.email != admin_email:
            admin.email = admin_email
            changed = True
        if admin.role != "admin":
            admin.role = "admin"
            changed = True
        if not admin.email_verified:
            admin.email_verified = True
            changed = True
        try:
            password_matches = verify_password(admin_pass, admin.password_hash)
        except (TypeError, ValueError):
            password_matches = False
        if not password_matches:
            admin.password_hash = get_password_hash(admin_pass)
            changed = True
        if not admin.two_factor_enabled:
            admin.two_factor_enabled = True
            changed = True
        if changed:
            db.commit()
    finally:
        db.close()

# Admin bootstrap is handled safely during application startup

app = FastAPI(title="ScamShield API")

FRONTEND_URLS = [
    origin.strip().rstrip("/")
    for origin in os.getenv("FRONTEND_URL", "http://localhost:5173").split(",")
    if origin.strip()
]
has_local_frontend = any(
    urlsplit(origin).scheme == "http"
    and urlsplit(origin).hostname in {"localhost", "127.0.0.1"}
    for origin in FRONTEND_URLS
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=FRONTEND_URLS,
    allow_origin_regex=(
        r"^http://(?:localhost|127\.0\.0\.1):517[0-9]$"
        if has_local_frontend
        else None
    ),
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
app.include_router(guardian_transcription_router, prefix="/api")
app.include_router(guardian_analysis_router, prefix="/api")
app.include_router(calls_router, prefix="/api")


@app.on_event("startup")
def startup_event():
    import threading
    def _bootstrap():
        try:
            init_admin()
        except Exception as exc:
            print(f"Admin bootstrap deferred during startup ({type(exc).__name__}).")
    threading.Thread(target=_bootstrap, daemon=True, name="admin-bootstrap").start()
    notification_worker.start()


@app.on_event("shutdown")
def stop_notification_worker():
    notification_worker.stop()


@app.get("/")
def root():
    return {
        "status": "ok",
        "service": "ScamShield API",
        "health": "/health",
        "docs": "/docs",
    }


@app.get("/health")
@app.get("/api/health")
def health_check():
    return {"status": "ok", "message": "ScamShield backend is running"}


@app.get("/api/ready")
def readiness_check():
    db_ok = False
    db = None
    try:
        db = SessionLocal()
        db.execute(func.now())
        db_ok = True
    except Exception:
        db_ok = False
    finally:
        if db:
            db.close()
    return {
        "status": "ready" if db_ok else "degraded",
        "database": "connected" if db_ok else "unreachable",
    }


if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8000))
    uvicorn.run("backend.main:app", host="0.0.0.0", port=port)

