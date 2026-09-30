from pydantic import BaseModel, EmailStr
from typing import Optional, List, Any
from datetime import datetime

class UserCreate(BaseModel):
    full_name: str
    email: EmailStr
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    role: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class AnalysisCreate(BaseModel):
    content: str

class AnalysisResponse(BaseModel):
    id: int
    content: str
    risk_score: int
    risk_level: str
    classification: str
    ml_probability: float
    category: str
    indicators: List[str]
    explanation: str
    evidence: List[str]
    recommended_action: str
    created_at: datetime

    class Config:
        from_attributes = True

class DashboardStats(BaseModel):
    total_analyses: int
    scams_detected: int
    safe_messages: int
    high_risk: int

class ForgotPassword(BaseModel):
    email: EmailStr

class ResetPassword(BaseModel):
    token: str
    new_password: str

class CommunityReportCreate(BaseModel):
    content: str
    category: str
    description: Optional[str] = None
    evidence: Optional[str] = None

class CommunityReportResponse(BaseModel):
    id: int
    content: str
    category: str
    description: Optional[str] = None
    evidence: Optional[str] = None
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
