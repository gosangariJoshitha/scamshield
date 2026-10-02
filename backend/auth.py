import os
from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import func
from sqlalchemy.exc import IntegrityError
from passlib.context import CryptContext
from jose import JWTError, jwt
from dotenv import load_dotenv

import models, schemas, database

load_dotenv()

SECRET_KEY = os.getenv("JWT_SECRET_KEY")
if not SECRET_KEY or len(SECRET_KEY.encode("utf-8")) < 32:
    raise RuntimeError("JWT_SECRET_KEY must contain at least 32 UTF-8 bytes")

ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("JWT_ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
ALLOW_DEV_PASSWORD_RESET_TOKEN = (
    os.getenv("APP_ENV", "").strip().lower() == "development"
    and os.getenv("ALLOW_DEV_PASSWORD_RESET_TOKEN", "").strip().lower() == "true"
)

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/auth/login")

router = APIRouter(prefix="/auth", tags=["auth"])

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
    return current_user

@router.post("/signup", response_model=schemas.UserResponse)
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
        role="user"
    )
    db.add(new_user)
    try:
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(status_code=409, detail="Email already registered")
    db.refresh(new_user)
    return new_user

@router.post("/login", response_model=schemas.Token)
def login_user(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(database.get_db)):
    return _login_for_role(form_data, db, "user")

@router.post("/admin/login", response_model=schemas.Token)
def login_admin(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(database.get_db)):
    return _login_for_role(form_data, db, "admin")

def _login_for_role(form_data: OAuth2PasswordRequestForm, db: Session, required_role: str):
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
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id), "email": user.email, "role": user.role},
        expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=schemas.UserResponse)
def read_users_me(current_user: models.User = Depends(get_current_user)):
    return current_user

@router.post("/logout")
def logout(current_user: models.User = Depends(get_current_user)):
    return {"message": "Successfully logged out"}

@router.post("/forgot-password")
def forgot_password(req: schemas.ForgotPassword, db: Session = Depends(database.get_db)):
    if not ALLOW_DEV_PASSWORD_RESET_TOKEN:
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
        return {"message": "If an account exists, password reset instructions will be sent."}
    
    reset_token = create_access_token(
        data={
            "sub": str(user.id),
            "email": user.email,
            "role": "user",
            "purpose": "reset_password",
        },
        expires_delta=timedelta(minutes=15)
    )
    return {
        "message": "Development reset token created.",
        "dev_token": reset_token
    }

@router.post("/reset-password")
def reset_password(req: schemas.ResetPassword, db: Session = Depends(database.get_db)):
    try:
        payload = jwt.decode(req.token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("email")
        purpose: str = payload.get("purpose")
        
        if (
            purpose != "reset_password"
            or payload.get("role") != "user"
            or not isinstance(email, str)
        ):
            raise HTTPException(status_code=400, detail="Invalid token")
            
        user = db.query(models.User).filter(
            func.lower(models.User.email) == email.lower(),
            models.User.role == "user",
            models.User.is_active.is_(True),
        ).first()
        if not user:
            raise HTTPException(status_code=400, detail="Invalid token")
            
        user.password_hash = get_password_hash(req.new_password)
        db.commit()
        return {"message": "Password successfully reset."}
        
    except JWTError:
        raise HTTPException(status_code=400, detail="Invalid or expired token")

@router.put("/me", response_model=schemas.UserResponse)
def update_profile(update_data: schemas.UserUpdate, current_user: models.User = Depends(get_current_user), db: Session = Depends(database.get_db)):
    if update_data.full_name is not None:
        current_user.full_name = update_data.full_name
    if update_data.two_factor_enabled is not None:
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
    db.delete(current_user)
    db.commit()
    return {"message": "Account deleted successfully"}
