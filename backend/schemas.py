from pydantic import BaseModel, EmailStr
from typing import Optional, List, Any, Dict
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
    two_factor_enabled: bool
    email_notifications: bool
    community_updates: bool
    marketing_updates: bool

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    two_factor_enabled: Optional[bool] = None
    email_notifications: Optional[bool] = None
    community_updates: Optional[bool] = None
    marketing_updates: Optional[bool] = None

class PasswordChange(BaseModel):
    current_password: str
    new_password: str

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None

class NormalizedAnalysisInput(BaseModel):
    input_type: str
    original_filename: Optional[str] = None
    original_text: Optional[str] = None
    extracted_text: str
    metadata: Dict[str, Any] = {}

class AnalysisCreate(BaseModel):
    content: str

class RetrievedEvidence(BaseModel):
    knowledge_id: int
    title: str
    category: str
    similarity_score: float
    pattern: str
    safe_action: str
    source: str
    
    class Config:
        from_attributes = True

class LLMReasoningResponse(BaseModel):
    classification: str
    scam_category: str
    risk_reasoning: str
    suspicious_indicators: List[str]
    evidence: List[Dict[str, Any]]
    safe_action: str
    confidence: float

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
    retrieved_evidence_data: Optional[List[RetrievedEvidence]] = []
    evidence_status: Optional[str] = "NO_RELEVANT_MATCH"
    recommended_action: str
    
    # M5 LLM Fields
    input_type: Optional[str] = "text"
    original_filename: Optional[str] = None
    llm_confidence: Optional[float] = None
    llm_reasoning: Optional[str] = None
    processing_status: Optional[str] = "COMPLETED"
    model_version: Optional[str] = None
    rag_version: Optional[str] = None
    
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
