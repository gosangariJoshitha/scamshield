from sqlalchemy import (
    CheckConstraint,
    Column,
    DateTime,
    Float,
    ForeignKey,
    Index,
    Integer,
    JSON,
    String,
    UniqueConstraint,
    Boolean,
)
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, index=True)
    email = Column(String, unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    role = Column(String, default="user")
    is_active = Column(Boolean, default=True)
    email_verified = Column(Boolean, nullable=False, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Settings and Preferences
    two_factor_enabled = Column(Boolean, default=False)
    email_notifications = Column(Boolean, default=True)
    community_updates = Column(Boolean, default=True)
    marketing_updates = Column(Boolean, default=False)
    
    analyses = relationship("Analysis", back_populates="user")
    reports = relationship("CommunityReport", back_populates="user")
    notifications = relationship("Notification", back_populates="user")
    call_histories = relationship("CallHistory", back_populates="user", cascade="all, delete-orphan")

class Analysis(Base):
    __tablename__ = "analyses"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    content = Column(String)
    risk_score = Column(Integer)
    risk_level = Column(String)
    classification = Column(String)
    ml_probability = Column(Float)
    category = Column(String)
    indicators = Column(JSON)
    explanation = Column(String)
    evidence = Column(JSON)
    recommended_action = Column(String)
    
    # M5 LLM Fields
    input_type = Column(String, default="text")
    original_filename = Column(String, nullable=True)
    original_text = Column(String, nullable=True)
    llm_confidence = Column(Float, nullable=True)
    llm_reasoning = Column(String, nullable=True)
    processing_status = Column(String, default="COMPLETED")
    model_version = Column(String, nullable=True)
    rag_version = Column(String, nullable=True)
    escalation_status = Column(String, nullable=False, default="NOT_ESCALATED")
    email_notification_status = Column(String, nullable=False, default="PENDING")
    jira_status = Column(String, nullable=False, default="NOT_REQUIRED")
    jira_issue_key = Column(String, nullable=True)
    jira_issue_url = Column(String, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="analyses")
    retrieved_evidences = relationship("AnalysisEvidence", back_populates="analysis")
    review_case = relationship("ReviewCase", back_populates="analysis", uselist=False)
    community_reports = relationship("CommunityReport", back_populates="analysis")
    notifications = relationship(
        "AnalysisNotification",
        back_populates="analysis",
        cascade="all, delete-orphan",
    )

    @property
    def review_case_id(self):
        return self.review_case.id if self.review_case else None


class AnalysisNotification(Base):
    __tablename__ = "analysis_notifications"
    __table_args__ = (
        UniqueConstraint("analysis_id", "channel", name="uq_analysis_notification_channel"),
        CheckConstraint(
            "channel IN ('EMAIL', 'JIRA')",
            name="ck_analysis_notification_channel",
        ),
        CheckConstraint(
            "status IN ('PENDING', 'PROCESSING', 'SENT', 'CREATED', 'FAILED', 'NOT_REQUIRED')",
            name="ck_analysis_notification_status",
        ),
        Index("ix_analysis_notifications_status_next_attempt", "status", "next_attempt_at"),
    )

    id = Column(Integer, primary_key=True, index=True)
    analysis_id = Column(
        Integer,
        ForeignKey("analyses.id", ondelete="CASCADE"),
        nullable=False,
    )
    channel = Column(String, nullable=False)
    status = Column(
        String,
        nullable=False,
        default="PENDING",
        server_default="PENDING",
    )
    retry_count = Column(
        Integer,
        nullable=False,
        default=0,
        server_default="0",
    )
    last_attempt_at = Column(DateTime(timezone=True), nullable=True)
    next_attempt_at = Column(DateTime(timezone=True), nullable=True)
    error_summary = Column(String, nullable=True)
    provider_reference = Column(String, nullable=True)
    idempotency_key = Column(String, nullable=False, unique=True)
    created_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
    )
    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    analysis = relationship("Analysis", back_populates="notifications")


class CommunityReport(Base):
    __tablename__ = "community_reports"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    analysis_id = Column(Integer, ForeignKey("analyses.id"), nullable=True, index=True)
    content = Column(String, nullable=False)
    category = Column(String)
    description = Column(String)
    evidence = Column(String)
    status = Column(String, default="Pending")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="reports")
    analysis = relationship("Analysis", back_populates="community_reports")

class KnowledgeEntry(Base):
    __tablename__ = "knowledge_entries"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    pattern = Column(String)
    category = Column(String)
    description = Column(String)
    indicators = Column(JSON) # List of strings
    example = Column(String)
    safe_action = Column(String)
    risk_level = Column(String)
    source = Column(String)
    source_type = Column(String, nullable=True) # e.g. HUMAN_VERIFIED_CASE, VERIFIED_COMMUNITY_REPORT
    source_reference = Column(String, nullable=True) # e.g. review_case_id
    status = Column(String, default="ACTIVE") # DRAFT, PENDING, APPROVED, REJECTED, ACTIVE, INACTIVE
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

class AnalysisEvidence(Base):
    __tablename__ = "analysis_evidence"
    
    id = Column(Integer, primary_key=True, index=True)
    analysis_id = Column(Integer, ForeignKey("analyses.id"))
    knowledge_id = Column(Integer, ForeignKey("knowledge_entries.id"), nullable=True)
    evidence_type = Column(String, default="RAG_MATCH")
    content = Column(String)
    similarity_score = Column(Float)
    source_reference = Column(String)
    language = Column(String, nullable=True)
    localized_safe_action = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    analysis = relationship("Analysis", back_populates="retrieved_evidences")
    knowledge_entry = relationship("KnowledgeEntry")

class AnalysisPerformance(Base):
    __tablename__ = "analysis_performance"
    
    id = Column(Integer, primary_key=True, index=True)
    analysis_id = Column(Integer, ForeignKey("analyses.id"))
    input_type = Column(String)
    
    extraction_ms = Column(Float, nullable=True)
    preprocessing_ms = Column(Float, nullable=True)
    ml_ms = Column(Float, nullable=True)
    embedding_ms = Column(Float, nullable=True)
    rag_ms = Column(Float, nullable=True)
    llm_ms = Column(Float, nullable=True)
    risk_engine_ms = Column(Float, nullable=True)
    database_ms = Column(Float, nullable=True)
    total_ms = Column(Float, nullable=True)
    
    status = Column(String, default="SUCCESS")
    error_message = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    analysis = relationship("Analysis")

class ReviewCase(Base):
    __tablename__ = "review_cases"

    id = Column(Integer, primary_key=True, index=True)
    analysis_id = Column(Integer, ForeignKey("analyses.id"), unique=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    assigned_reviewer_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    status = Column(String, default="PENDING", index=True) # PENDING, ASSIGNED, IN_REVIEW, NEEDS_INFORMATION, VERIFIED, REJECTED, CLOSED
    priority = Column(String, default="LOW", index=True) # LOW, MEDIUM, HIGH, URGENT
    escalation_reason = Column(String)
    escalation_reasons_json = Column(JSON)
    review_decision = Column(String, nullable=True) # CONFIRMED_SCAM, CONFIRMED_GENUINE, UNCERTAIN, INSUFFICIENT_INFORMATION
    reviewer_notes = Column(String, nullable=True)
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    assigned_at = Column(DateTime(timezone=True), nullable=True)
    review_started_at = Column(DateTime(timezone=True), nullable=True)
    reviewed_at = Column(DateTime(timezone=True), nullable=True)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    analysis = relationship("Analysis", back_populates="review_case")
    user = relationship("User", foreign_keys=[user_id])
    reviewer = relationship("User", foreign_keys=[assigned_reviewer_id])
    events = relationship("ReviewCaseEvent", back_populates="review_case")
    jira_integration = relationship("JiraIntegration", back_populates="review_case", uselist=False)

class ReviewCaseEvent(Base):
    __tablename__ = "review_case_events"

    id = Column(Integer, primary_key=True, index=True)
    review_case_id = Column(Integer, ForeignKey("review_cases.id"), index=True)
    actor_user_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    event_type = Column(String)
    previous_status = Column(String, nullable=True)
    new_status = Column(String, nullable=True)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    review_case = relationship("ReviewCase", back_populates="events")
    actor = relationship("User", foreign_keys=[actor_user_id])

class JiraIntegration(Base):
    __tablename__ = "jira_integrations"

    id = Column(Integer, primary_key=True, index=True)
    review_case_id = Column(Integer, ForeignKey("review_cases.id"), unique=True)
    jira_issue_id = Column(String)
    jira_issue_key = Column(String)
    status = Column(String, default="SYNCED")
    last_synced_at = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    review_case = relationship("ReviewCase", back_populates="jira_integration")

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    type = Column(String)
    title = Column(String)
    message = Column(String)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="notifications")

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(Integer, primary_key=True, index=True)
    actor_id = Column(Integer, ForeignKey("users.id"), nullable=True) # Could be system (null) or a specific user/admin
    action = Column(String, index=True) # e.g. LOGIN, REVIEW_DECISION, USER_DEACTIVATED
    resource_type = Column(String, index=True) # e.g. USER, REVIEW_CASE, KNOWLEDGE_ENTRY
    resource_id = Column(String, index=True, nullable=True) 
    result = Column(String) # SUCCESS, FAILURE
    details = Column(JSON, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    actor = relationship("User", foreign_keys=[actor_id])


class AuthChallenge(Base):
    __tablename__ = "auth_challenges"

    id = Column(Integer, primary_key=True, index=True)
    challenge_id_hash = Column(String, unique=True, nullable=False, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False, index=True)
    purpose = Column(String, nullable=False, index=True)
    code_hash = Column(String, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    attempts = Column(Integer, nullable=False, default=0)
    consumed_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime, nullable=False, server_default=func.now())


class CallHistory(Base):
    __tablename__ = "call_history"

    id = Column(Integer, primary_key=True, index=True)
    session_id = Column(String, unique=True, index=True, nullable=False)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), index=True, nullable=False)

    started_at = Column(DateTime(timezone=True), nullable=True)
    ended_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    duration_seconds = Column(Integer, default=0, nullable=False)

    guardian_enabled = Column(Boolean, default=True, nullable=False)
    guardian_status = Column(String, default="ENABLED", nullable=False)

    final_risk_score = Column(Integer, default=0, nullable=False)
    final_risk_level = Column(String, default="LOW", nullable=False)
    classification = Column(String, default="GENUINE", nullable=False)
    scam_category = Column(String, default="General", nullable=False)

    risk_reasoning = Column(String, nullable=True)
    safe_action = Column(String, nullable=True)
    detected_indicators = Column(JSON, nullable=True)
    supporting_evidence = Column(JSON, nullable=True)
    protection_actions = Column(JSON, nullable=True)

    analysis_status = Column(String, default="COMPLETED", nullable=False)
    transcription_status = Column(String, default="COMPLETED", nullable=False)
    audio_status = Column(String, default="AVAILABLE", nullable=False)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user = relationship("User", back_populates="call_histories")

