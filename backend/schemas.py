import json
from typing import Literal

from pydantic import BaseModel, EmailStr, Field, field_validator, model_validator
from typing import Optional, List, Any, Dict
from datetime import datetime
from uuid import UUID


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
    content: str = Field(max_length=20000)

class RetrievedEvidence(BaseModel):
    knowledge_id: int
    title: str
    category: str
    similarity_score: float
    pattern: str
    description: str = ""
    indicators: List[str] = Field(default_factory=list)
    risk_level: Optional[str] = None
    safe_action: str
    source: str
    language: Optional[str] = None
    source_type: Optional[str] = None
    
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


class GuardianTranscriptSegmentCreate(BaseModel):
    session_id: UUID
    segment_id: str = Field(min_length=1, max_length=160)
    sequence: int = Field(ge=1)
    start_time: float = Field(ge=0)
    end_time: float = Field(ge=0)
    text: str = Field(min_length=1, max_length=1600)
    is_final: Literal[True]
    language: Literal["en", "hi", "te", "und"] = "und"
    source: str = Field(min_length=1, max_length=40)
    created_at: datetime

    @model_validator(mode="after")
    def validate_segment(self) -> "GuardianTranscriptSegmentCreate":
        if self.end_time < self.start_time:
            raise ValueError("end_time must not be earlier than start_time")
        if not self.text.strip():
            raise ValueError("Transcript text must not be blank")
        return self


class GuardianLiveAnalysisResult(BaseModel):
    risk_score: int = Field(ge=0, le=100)
    risk_level: Literal["LOW", "MEDIUM", "HIGH", "CRITICAL"]
    classification: Literal["SCAM", "SUSPICIOUS", "GENUINE"]
    scam_category: str
    detected_indicators: List[str]
    reasoning: str
    supporting_evidence: List[RetrievedEvidence]
    ml_probability: float = Field(ge=0, le=1)
    llm_confidence: Optional[float] = Field(default=None, ge=0, le=1)
    safe_action: str
    safe_actions: SafeActionsResponse
    timestamp: datetime
    session_id: UUID
    language: Literal["en", "hi", "te"]
    evidence_status: str
    processing_status: Literal["COMPLETED", "COMPLETED_WITH_LIMITATIONS"]
    model_version: str
    rag_version: str
    timings_ms: Dict[str, Optional[float]]


class GuardianLiveAnalysisResponse(BaseModel):
    session_id: UUID
    status: Literal[
        "AI_WAITING_FOR_TRANSCRIPT",
        "AI_DUPLICATE",
        "AI_RESULT_READY",
        "AI_UNAVAILABLE",
    ]
    message: str
    processed_sequence: int = 0
    window_id: Optional[str] = None
    result: Optional[GuardianLiveAnalysisResult] = None

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


class CallFinalizeRequest(BaseModel):
    session_id: str = Field(min_length=1, max_length=120)
    started_at: Optional[datetime] = None
    ended_at: Optional[datetime] = None
    duration_seconds: int = Field(default=0, ge=0)
    guardian_enabled: bool = True
    guardian_status: str = "ENABLED"
    final_risk_score: int = Field(default=0, ge=0, le=100)
    final_risk_level: str = "LOW"
    classification: str = "GENUINE"
    scam_category: str = "General"
    risk_reasoning: Optional[str] = None
    safe_action: Optional[str] = None
    detected_indicators: List[str] = Field(default_factory=list)
    supporting_evidence: List[Dict[str, Any]] = Field(default_factory=list)
    protection_actions: List[Dict[str, Any]] = Field(default_factory=list)
    analysis_status: str = "COMPLETED"
    transcription_status: str = "COMPLETED"
    audio_status: str = "AVAILABLE"


class CallHistoryItemResponse(BaseModel):
    id: int
    session_id: str
    started_at: Optional[datetime] = None
    ended_at: datetime
    duration_seconds: int
    final_risk_score: int
    final_risk_level: str
    classification: str
    scam_category: str
    analysis_status: str
    created_at: datetime

    class Config:
        from_attributes = True


class CallHistoryDetailResponse(BaseModel):
    id: int
    session_id: str
    user_id: int
    started_at: Optional[datetime] = None
    ended_at: datetime
    duration_seconds: int
    guardian_enabled: bool
    guardian_status: str
    final_risk_score: int
    final_risk_level: str
    classification: str
    scam_category: str
    risk_reasoning: Optional[str] = None
    safe_action: Optional[str] = None
    detected_indicators: Optional[List[str]] = None
    supporting_evidence: Optional[List[Dict[str, Any]]] = None
    protection_actions: Optional[List[Dict[str, Any]]] = None
    analysis_status: str
    transcription_status: str
    audio_status: str
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class CallHistoryListResponse(BaseModel):
    items: List[CallHistoryItemResponse]
    total: int
    page: int
    limit: int
    has_next: bool

