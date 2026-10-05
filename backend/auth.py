import hashlib
import hmac
import logging
import os
import secrets
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, Form, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from passlib.context import CryptContext
from jose import JWTError, jwt
from dotenv import load_dotenv

import models, schemas, database
from app.services.email_service import EmailDeliveryError, email_service

load_dotenv()

SECRET_KEY = os.getenv("JWT_SECRET_KEY")
if not SECRET_KEY or len(SECRET_KEY.encode("utf-8")) < 32:
    raise RuntimeError("JWT_SECRET_KEY must contain at least 32 UTF-8 bytes")

ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
REMEMBER_ME_EXPIRE_DAYS = int(os.getenv("JWT_REMEMBER_ME_EXPIRE_DAYS", "30"))
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

router = APIRouter(prefix="/auth", tags=["auth"])
logger = logging.getLogger(__name__)

def verify_password(plain_password, hashed_password):
    return pwd_context.verify(plain_password, hashed_password)

def get_password_hash(password):
    return pwd_context.hash(password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(database.get_db)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("email")
        if not isinstance(email, str):
            raise credentials_exception
        token_data = schemas.TokenData(email=email)
    except JWTError:
        raise credentials_exception
    user = db.query(models.User).filter(models.User.email == token_data.email).first()
    if user is None or not user.is_active:
        raise credentials_exception
    return user

def get_current_regular_user(current_user: models.User = Depends(get_current_user)):
    if current_user.role != "user":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="User portal access required")
    if not current_user.email_verified:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Please verify your email before analyzing content.",
        )
    return current_user

@router.post("/signup", response_model=schemas.SignupResponse)
def signup(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    normalized_email = str(user.email).strip().lower()
    db_user = db.query(models.User).filter(func.lower(models.User.email) == normalized_email).first()
    if db_user:
        raise HTTPException(status_code=409, detail="Email already registered")
    
    hashed_password = get_password_hash(user.password)
    new_user = models.User(
        full_name=user.full_name,
        email=normalized_email,
        password_hash=hashed_password,
        role="user",
        email_verified=False,
    )
    db.add(new_user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Email already registered")
    db.refresh(new_user)
    try:
        challenge_id = _create_email_challenge(
            db,
            new_user,
            "EMAIL_VERIFICATION",
        )
    except HTTPException as exc:
        if exc.status_code != status.HTTP_503_SERVICE_UNAVAILABLE:
            raise
        logger.warning("Signup verification email was not sent for user %s.", new_user.id)
        return {
            "account_created": True,
            "email_verified": False,
            "verification_email_sent": False,
            "message": (
                "Account created, but the verification email could not be sent. "
                "Sign in to request another code."
            ),
        }
    return {
        "account_created": True,
        "email_verified": False,
        "verification_email_sent": True,
        "verification_challenge_id": challenge_id,
        "message": "Account created. Enter the verification code sent to your email.",
    }

@router.post(
    "/login",
    response_model=schemas.LoginResponse,
    response_model_exclude_none=True,
)
def login_user(
    form_data: OAuth2PasswordRequestForm = Depends(),
    remember_me: bool = Form(False),
    db: Session = Depends(database.get_db),
):
    return _login_for_role(form_data, db, "user", remember_me)

@router.post(
    "/admin/login",
    response_model=schemas.LoginResponse,
    response_model_exclude_none=True,
)
def login_admin(
    form_data: OAuth2PasswordRequestForm = Depends(),
    remember_me: bool = Form(False),
    db: Session = Depends(database.get_db),
):
    return _login_for_role(form_data, db, "admin", remember_me)

def _login_for_role(
    form_data: OAuth2PasswordRequestForm,
    db: Session,
    required_role: str,
    remember_me: bool = False,
):
    normalized_email = form_data.username.strip().lower()
    user = db.query(models.User).filter(func.lower(models.User.email) == normalized_email).first()
    password_fits_bcrypt = len(form_data.password.encode("utf-8")) <= 72
    if (
        not user
        or not user.is_active
        or user.role != required_role
        or not password_fits_bcrypt
        or not verify_password(form_data.password, user.password_hash)
    ):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid credentials or account access is not permitted for this portal",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if user.two_factor_enabled:
        challenge_id = _create_email_challenge(db, user, "LOGIN")
        return {
            "requires_two_factor": True,
            "challenge_id": challenge_id,
            "remember_me": remember_me,
        }

    return _create_login_response(user, remember_me)

def _create_login_response(user: models.User, remember_me: bool = False) -> dict:
    access_token_expires = (
        timedelta(days=REMEMBER_ME_EXPIRE_DAYS)
        if remember_me
        else timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    access_token = create_access_token(
        data={"sub": str(user.id), "email": user.email, "role": user.role},
        expires_delta=access_token_expires
    )
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "requires_two_factor": False,
    }

def _hash_verification_code(code: str) -> str:
    return hmac.new(
        SECRET_KEY.encode("utf-8"),
        code.encode("ascii"),
        hashlib.sha256,
    ).hexdigest()

def _create_email_challenge(
    db: Session,
    user: models.User,
    purpose: str,
    *,
    minimum_interval_seconds: int = 0,
) -> str:
    if not email_service.is_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Email verification is unavailable because email delivery is not configured.",
        )

    now = datetime.utcnow()
    if minimum_interval_seconds:
        recent_challenge = db.query(models.AuthChallenge.id).filter(
            models.AuthChallenge.user_id == user.id,
            models.AuthChallenge.purpose == purpose,
            models.AuthChallenge.created_at
            > now - timedelta(seconds=minimum_interval_seconds),
        ).first()
        if recent_challenge:
            raise HTTPException(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                detail="Please wait before requesting another verification code.",
            )

    db.query(models.AuthChallenge).filter(
        models.AuthChallenge.expires_at <= now,
    ).delete(synchronize_session=False)
    db.query(models.AuthChallenge).filter(
        models.AuthChallenge.user_id == user.id,
        models.AuthChallenge.purpose == purpose,
        models.AuthChallenge.consumed_at.is_(None),
    ).update(
        {"consumed_at": now},
        synchronize_session=False,
    )
    challenge_id = secrets.token_urlsafe(32)
    code = f"{secrets.randbelow(1_000_000):06d}"
    challenge = models.AuthChallenge(
        challenge_id_hash=hashlib.sha256(challenge_id.encode("utf-8")).hexdigest(),
        user_id=user.id,
        purpose=purpose,
        code_hash=_hash_verification_code(code),
        expires_at=now + timedelta(minutes=10),
        attempts=0,
    )
    db.add(challenge)
    db.commit()
    try:
        email_service.send_verification_code(user.email, code, purpose)
    except EmailDeliveryError as exc:
        db.delete(challenge)
        db.commit()
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Verification email could not be sent. Please try again later.",
        ) from exc
    return challenge_id

def _verify_email_challenge(
    db: Session,
    challenge_id: str,
    code: str,
    purpose: str,
) -> models.User:
    challenge_hash = hashlib.sha256(challenge_id.encode("utf-8")).hexdigest()
    challenge = db.query(models.AuthChallenge).filter(
        models.AuthChallenge.challenge_id_hash == challenge_hash,
        models.AuthChallenge.purpose == purpose,
    ).first()
    now = datetime.utcnow()
    if (
        challenge is None
        or challenge.consumed_at is not None
        or challenge.expires_at <= now
        or challenge.attempts >= 5
    ):
        raise HTTPException(status_code=400, detail="Invalid or expired verification code.")

    submitted_hash = _hash_verification_code(code)
    if not hmac.compare_digest(challenge.code_hash, submitted_hash):
        challenge.attempts += 1
        if challenge.attempts >= 5:
            challenge.consumed_at = now
        db.commit()
        raise HTTPException(status_code=400, detail="Invalid or expired verification code.")

    challenge.consumed_at = now
    db.commit()
    user = db.query(models.User).filter(
        models.User.id == challenge.user_id,
        models.User.is_active.is_(True),
    ).first()
    if user is None:
        raise HTTPException(status_code=400, detail="Invalid or expired verification code.")
    return user

@router.post("/login/verify", response_model=schemas.Token)
def verify_login(data: schemas.LoginVerification, db: Session = Depends(database.get_db)):
    user = _verify_email_challenge(
        db,
        data.challenge_id,
        data.code,
        "LOGIN",
    )
    if not user.two_factor_enabled:
        raise HTTPException(status_code=400, detail="Two-step verification is no longer enabled.")
    return _create_login_response(user, data.remember_me)


@router.post("/verify-email")
def verify_email(
    data: schemas.EmailVerification,
    db: Session = Depends(database.get_db),
):
    user = _verify_email_challenge(
        db,
        data.challenge_id,
        data.code,
        "EMAIL_VERIFICATION",
    )
    if user.role != "user":
        raise HTTPException(status_code=400, detail="Invalid or expired verification code.")
    user.email_verified = True
    db.commit()
    return {"email_verified": True, "message": "Email address verified."}


@router.post("/resend-verification")
def resend_verification(
    db: Session = Depends(database.get_db),
    current_user: models.User = Depends(get_current_user),
):
    if current_user.role != "user":
        raise HTTPException(status_code=403, detail="User portal access required.")
    if current_user.email_verified:
        return {"email_verified": True, "message": "Email address is already verified."}

    challenge_id = _create_email_challenge(
        db,
        current_user,
        "EMAIL_VERIFICATION",
        minimum_interval_seconds=60,
    )
    return {
        "email_verified": False,
        "challenge_id": challenge_id,
        "message": "A new verification code was sent.",
    }

@router.get("/me", response_model=schemas.UserResponse)
def read_users_me(current_user: models.User = Depends(get_current_user)):
    return current_user

@router.post("/logout")
def logout(current_user: models.User = Depends(get_current_user)):
    return {"message": "Successfully logged out"}

@router.post("/forgot-password")
def forgot_password(req: schemas.ForgotPassword, db: Session = Depends(database.get_db)):
    if not email_service.is_configured:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Password reset is unavailable because email delivery is not configured.",
        )

    normalized_email = str(req.email).strip().lower()
    user = db.query(models.User).filter(
        func.lower(models.User.email) == normalized_email,
        models.User.role == "user",
        models.User.is_active.is_(True),
    ).first()
    if not user:
        return {
            "message": "If an active account exists for that email, a verification code will be sent.",
            "challenge_id": secrets.token_urlsafe(32),
        }

    challenge_id = _create_email_challenge(db, user, "PASSWORD_RESET")
    return {
        "message": "If an active account exists for that email, a verification code will be sent.",
        "challenge_id": challenge_id,
    }

@router.post("/reset-password")
def reset_password(data: schemas.PasswordResetVerification, db: Session = Depends(database.get_db)):
    user = _verify_email_challenge(
        db,
        data.challenge_id,
        data.code,
        "PASSWORD_RESET",
    )
    if user.role != "user":
        raise HTTPException(status_code=400, detail="Invalid or expired verification code.")
    user.password_hash = get_password_hash(data.new_password)
    db.commit()
    return {"message": "Password successfully reset."}

@router.put("/me", response_model=schemas.UserResponse)
def update_profile(update_data: schemas.UserUpdate, current_user: models.User = Depends(get_current_user), db: Session = Depends(database.get_db)):
    if update_data.full_name is not None:
        current_user.full_name = update_data.full_name
    if update_data.two_factor_enabled is not None:
        if update_data.two_factor_enabled and not email_service.is_configured:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Two-step verification requires configured email delivery.",
            )
        current_user.two_factor_enabled = update_data.two_factor_enabled
    if update_data.email_notifications is not None:
        current_user.email_notifications = update_data.email_notifications
    if update_data.community_updates is not None:
        current_user.community_updates = update_data.community_updates
    if update_data.marketing_updates is not None:
        current_user.marketing_updates = update_data.marketing_updates
        
    db.commit()
    db.refresh(current_user)
    return current_user

@router.post("/change-password")
def change_password(data: schemas.PasswordChange, current_user: models.User = Depends(get_current_user), db: Session = Depends(database.get_db)):
    if len(data.current_password.encode("utf-8")) > 72 or not verify_password(data.current_password, current_user.password_hash):
        raise HTTPException(status_code=400, detail="Incorrect current password")
    if len(data.new_password.encode("utf-8")) > 72:
        raise HTTPException(status_code=422, detail="New password must be at most 72 UTF-8 bytes")
    
    current_user.password_hash = get_password_hash(data.new_password)
    db.commit()
    return {"message": "Password updated successfully"}

@router.delete("/me")
def delete_account(current_user: models.User = Depends(get_current_user), db: Session = Depends(database.get_db)):
    db.query(models.AuthChallenge).filter(
        models.AuthChallenge.user_id == current_user.id,
    ).delete(synchronize_session=False)
    db.delete(current_user)
    db.commit()
    return {"message": "Account deleted successfully"}
