import json
from typing import Literal

from pydantic import BaseModel, EmailStr, Field, field_validator, model_validator
from typing import Optional, List, Any, Dict
from datetime import datetime


def _validate_password_strength(password: str) -> str:
    if len(password) < 8:
        raise ValueError("Password must be at least 8 characters")
    if not any(character.isupper() for character in password) or not any(character.isdigit() for character in password):
        raise ValueError("Password must contain at least one uppercase letter and one number")
    if len(password.encode("utf-8")) > 72:
        raise ValueError("Password must be at most 72 UTF-8 bytes")
    return password


class UserCreate(BaseModel):
    full_name: str = Field(min_length=1, max_length=120)
    email: EmailStr
    password: str = Field(min_length=8, max_length=72)

    @field_validator("full_name")
    @classmethod
    def validate_full_name(cls, full_name: str) -> str:
        normalized_name = full_name.strip()
        if not normalized_name:
            raise ValueError("Full name must not be blank")
        return normalized_name

    @field_validator("password")
    @classmethod
    def validate_password_strength(cls, password: str) -> str:
        return _validate_password_strength(password)

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserResponse(BaseModel):
    id: int
    full_name: str
    email: EmailStr
    role: str
    is_active: bool
    email_verified: bool
    created_at: datetime
    updated_at: datetime
    two_factor_enabled: bool
    email_notifications: bool
    community_updates: bool
    marketing_updates: bool

    class Config:
        from_attributes = True

    @field_validator("two_factor_enabled", "marketing_updates", mode="before")
    @classmethod
    def default_disabled_preferences(cls, value: Optional[bool]) -> bool:
        return False if value is None else value

    @field_validator("email_notifications", "community_updates", mode="before")
    @classmethod
    def default_enabled_preferences(cls, value: Optional[bool]) -> bool:
        return True if value is None else value

class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    two_factor_enabled: Optional[bool] = None
    email_notifications: Optional[bool] = None
    community_updates: Optional[bool] = None
    marketing_updates: Optional[bool] = None

class PasswordChange(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8, max_length=72)

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, password: str) -> str:
        return _validate_password_strength(password)

class Token(BaseModel):
    access_token: str
    token_type: str


class LoginResponse(BaseModel):
    access_token: Optional[str] = None
    token_type: Optional[str] = None
    requires_two_factor: bool = False
    challenge_id: Optional[str] = None


class SignupResponse(BaseModel):
    account_created: bool
    email_verified: bool
    verification_email_sent: bool
    verification_challenge_id: Optional[str] = None
    message: str


class EmailVerification(BaseModel):
    challenge_id: str = Field(min_length=20, max_length=200)
    code: str = Field(pattern=r"^\d{6}$")


class EmailResend(BaseModel):
    challenge_id: Optional[str] = Field(default=None, min_length=20, max_length=200)


class LoginVerification(BaseModel):
    challenge_id: str = Field(min_length=20, max_length=200)
    code: str = Field(pattern=r"^\d{6}$")
    remember_me: bool = False


class PasswordResetVerification(LoginVerification):
    new_password: str = Field(min_length=8, max_length=72)

    @field_validator("new_password")
    @classmethod
    def validate_new_password(cls, password: str) -> str:
        return _validate_password_strength(password)

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
    language: Optional[str] = None
    
    class Config:
        from_attributes = True

class SafeActionsResponse(BaseModel):
    canonical: List[str]
    translations: Dict[str, List[str]]
    default_language: Literal["en", "hi", "te"] = "en"


class LLMReasoningResponse(BaseModel):
    classification: str
    scam_category: str
    risk_reasoning: str
    suspicious_indicators: List[str]
    evidence: List[Dict[str, Any]]
    safe_action: str
    safe_actions: Optional["SafeActionsResponse"] = None
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
    safe_actions: Optional[SafeActionsResponse] = None
    
    # M5 LLM Fields
    input_type: Optional[str] = "text"
    original_filename: Optional[str] = None
    llm_confidence: Optional[float] = None
    llm_reasoning: Optional[str] = None
    processing_status: Optional[str] = "COMPLETED"
    model_version: Optional[str] = None
    rag_version: Optional[str] = None
    
    # M8 Escalation Fields
    escalation_status: Optional[str] = None
    review_case_id: Optional[int] = None
    email_notification_status: Optional[str] = None
    jira_status: Optional[str] = None
    jira_issue_key: Optional[str] = None
    jira_issue_url: Optional[str] = None
    
    created_at: datetime

    class Config:
        from_attributes = True

    @model_validator(mode="before")
    @classmethod
    def unpack_safe_actions(cls, value: Any) -> Any:
        if isinstance(value, dict):
            data = value.copy()
        else:
            data = {
                name: getattr(value, name)
                for name in cls.model_fields
                if hasattr(value, name)
            }

        stored_actions = data.get("recommended_action")
        if isinstance(stored_actions, str):
            try:
                parsed = json.loads(stored_actions)
            except json.JSONDecodeError:
                return data
            if isinstance(parsed, dict) and isinstance(parsed.get("canonical"), list):
                data["safe_actions"] = parsed
                data["recommended_action"] = "\n".join(
                    action
                    for action in parsed["canonical"]
                    if isinstance(action, str)
                )
        return data

class DashboardStats(BaseModel):
    total_analyses: int
    scams_detected: int
    safe_messages: int
    high_risk: int

class ForgotPassword(BaseModel):
    email: EmailStr

class CommunityReportCreate(BaseModel):
    content: str
    category: str
    description: Optional[str] = None
    evidence: Optional[str] = None
    analysis_id: Optional[int] = None

class CommunityReportResponse(BaseModel):
    id: int
    content: str
    category: str
    description: Optional[str] = None
    evidence: Optional[str] = None
    analysis_id: Optional[int] = None
    reporter_name: Optional[str] = None
    status: str
    created_at: datetime

    class Config:
        from_attributes = True
