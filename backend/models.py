from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, JSON, Float
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
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())
    
    # Settings and Preferences
    two_factor_enabled = Column(Boolean, default=False)
    email_notifications = Column(Boolean, default=True)
    community_updates = Column(Boolean, default=True)
    marketing_updates = Column(Boolean, default=False)
    
    analyses = relationship("Analysis", back_populates="user")
    reports = relationship("CommunityReport", back_populates="user")

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
    
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    user = relationship("User", back_populates="analyses")
    retrieved_evidences = relationship("AnalysisEvidence", back_populates="analysis")

class CommunityReport(Base):
    __tablename__ = "community_reports"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    content = Column(String, nullable=False)
    category = Column(String)
    description = Column(String)
    evidence = Column(String)
    status = Column(String, default="Pending")
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="reports")

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
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    analysis = relationship("Analysis", back_populates="retrieved_evidences")
    knowledge_entry = relationship("KnowledgeEntry")
