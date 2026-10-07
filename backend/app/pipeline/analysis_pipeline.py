import asyncio
import json
import logging
import time
from dataclasses import dataclass
from typing import Any
from fastapi import BackgroundTasks

from sqlalchemy.orm import Session

from app.services.classifier_service import classifier_service
from app.services.escalation_service import EscalationService
from app.services.llm_service import llm_service
from app.services.rag_service import rag_service
from app.services.risk_engine import calculate_risk
from app.services.safety_actions import detect_language, fallback_safe_actions
from app.services.text_service import preprocess_text
from app.services.analysis_notifications import process_analysis_notifications
from models import Analysis, AnalysisEvidence, AnalysisNotification, AnalysisPerformance
from schemas import NormalizedAnalysisInput


logger = logging.getLogger(__name__)


@dataclass(frozen=True)
class AnalysisCoreResult:
    default_language: str
    ml_result: dict[str, Any]
    rag_result: dict[str, Any]
    retrieved_evidence: list[dict[str, Any]]
    llm_response: Any
    llm_confidence: float | None
    llm_reasoning: str | None
    processing_status: str
    category: str
    safe_action: str
    safe_actions: dict[str, Any]
    final_indicators: list[str]
    risk_result: dict[str, Any]
    model_version: str
    rag_version: str
    preprocessing_ms: float
    ml_ms: float
    embedding_ms: float | None
    rag_ms: float | None
    llm_ms: float
    risk_engine_ms: float
    total_ms: float


def _fallback_category(text: str, classification: str) -> str:
    text_lower = text.lower()
    if "otp" in text_lower or "verification" in text_lower or "code" in text_lower:
        return "OTP/Verification"
    if any(term in text_lower for term in ("bank", "account", "blocked", "kyc")):
        return "Banking/KYC"
    if any(term in text_lower for term in ("job", "salary", "hire", "work from home")):
        return "Job/Employment"
    if any(term in text_lower for term in ("prize", "won", "lottery", "winner")):
        return "Lottery/Prize"
    if any(term in text_lower for term in ("delivery", "package", "shipment")):
        return "Delivery/Postal"
    if classification == "GENUINE":
        return "Normal Message"
    return "General"


async def analyze_text_core(
    text: str,
    detected_language: str | None = None,
) -> AnalysisCoreResult:
    """Run the shared, non-persistent text analysis stages used by all inputs."""
    total_started = time.perf_counter()
    default_language = detect_language(text, detected_language)

    preprocessing_started = time.perf_counter()
    processed_text = preprocess_text(text)
    preprocessing_ms = (time.perf_counter() - preprocessing_started) * 1000

    ml_started = time.perf_counter()
    ml_result = await asyncio.to_thread(
        classifier_service.predict_processed,
        processed_text,
    )
    ml_ms = (time.perf_counter() - ml_started) * 1000

    try:
        rag_result = await asyncio.to_thread(
            rag_service.search,
            text,
            language=default_language,
        )
    except Exception as error:
        logger.warning("RAG retrieval failed (%s).", type(error).__name__)
        rag_result = {
            "evidence_status": "RETRIEVAL_UNAVAILABLE",
            "retrieved_evidence": [],
            "timings": {"embedding_ms": None, "retrieval_ms": None},
        }
    retrieved_evidence = rag_result.get("retrieved_evidence", [])
    timings = rag_result.get("timings", {})

    llm_started = time.perf_counter()
    try:
        llm_response = await llm_service.generate_reasoning(
            text=text,
            ml_result=ml_result,
            retrieved_evidence=retrieved_evidence,
            indicators=[],
            default_language=default_language,
        )
    except Exception as error:
        logger.warning("LLM reasoning failed (%s).", type(error).__name__)
        llm_response = None
    llm_ms = (time.perf_counter() - llm_started) * 1000

    llm_confidence = None
    llm_reasoning = None
    processing_status = "COMPLETED"
    llm_indicators: list[str] = []
    category = "General"
    safe_action = (
        "Please verify the source through official channels before taking any action."
    )
    safe_actions = None

    if llm_response:
        llm_confidence = llm_response.confidence
        llm_reasoning = llm_response.risk_reasoning
        llm_indicators = llm_response.suspicious_indicators
        category = llm_response.scam_category
        safe_action = llm_response.safe_action
        if llm_response.safe_actions:
            safe_actions = llm_response.safe_actions.model_dump()
    else:
        processing_status = "COMPLETED_WITH_LIMITATIONS"
        category = _fallback_category(text, ml_result["classification"])
        if retrieved_evidence:
            safe_action = retrieved_evidence[0].get("safe_action", safe_action)

    if rag_result.get("evidence_status") == "RETRIEVAL_UNAVAILABLE":
        processing_status = "COMPLETED_WITH_LIMITATIONS"

    if safe_actions is None:
        safe_actions = fallback_safe_actions(default_language, safe_action)
        safe_action = "\n".join(safe_actions["canonical"])

    all_indicators = list(set(llm_indicators))
    risk_started = time.perf_counter()
    risk_result = calculate_risk(
        ml_probability=ml_result["ml_probability"],
        text=text,
        classification=ml_result["classification"],
        llm_indicators=all_indicators,
        retrieved_evidence=retrieved_evidence,
    )
    risk_engine_ms = (time.perf_counter() - risk_started) * 1000
    final_indicators = list(
        set(all_indicators + risk_result.get("risk_factors", []))
    )

    return AnalysisCoreResult(
        default_language=default_language,
        ml_result=ml_result,
        rag_result=rag_result,
        retrieved_evidence=retrieved_evidence,
        llm_response=llm_response,
        llm_confidence=llm_confidence,
        llm_reasoning=llm_reasoning,
        processing_status=processing_status,
        category=category,
        safe_action=safe_action,
        safe_actions=safe_actions,
        final_indicators=final_indicators,
        risk_result=risk_result,
        model_version=ml_result.get("model_version", "unknown"),
        rag_version="scamshield-rag-v1",
        preprocessing_ms=preprocessing_ms,
        ml_ms=ml_ms,
        embedding_ms=timings.get("embedding_ms"),
        rag_ms=timings.get("retrieval_ms"),
        llm_ms=llm_ms,
        risk_engine_ms=risk_engine_ms,
        total_ms=(time.perf_counter() - total_started) * 1000,
    )


async def run_analysis_pipeline(
    db: Session,
    input_data: NormalizedAnalysisInput,
    user_id: int,
    extraction_ms: float | None = None,
    background_tasks: BackgroundTasks | None = None,
):
    total_started = time.perf_counter()
    text = input_data.extracted_text
    core_result = await analyze_text_core(
        text,
        input_data.metadata.get("detected_language"),
    )
    default_language = core_result.default_language
    ml_result = core_result.ml_result
    rag_result = core_result.rag_result
    retrieved_evidence = core_result.retrieved_evidence
    llm_response = core_result.llm_response
    llm_confidence = core_result.llm_confidence
    llm_reasoning = core_result.llm_reasoning
    processing_status = core_result.processing_status
    category = core_result.category
    safe_action = core_result.safe_action
    safe_actions = core_result.safe_actions
    final_indicators = core_result.final_indicators
    risk_result = core_result.risk_result
    model_version = core_result.model_version
    rag_version = core_result.rag_version
    preprocessing_ms = core_result.preprocessing_ms
    ml_ms = core_result.ml_ms
    embedding_ms = core_result.embedding_ms
    rag_ms = core_result.rag_ms
    llm_ms = core_result.llm_ms
    risk_engine_ms = core_result.risk_engine_ms

    database_started = time.perf_counter()
    analysis_record = Analysis(
        user_id=user_id,
        content=text,
        input_type=input_data.input_type,
        original_filename=input_data.original_filename,
        original_text=input_data.original_text,
        risk_score=risk_result["risk_score"],
        risk_level=risk_result["risk_level"],
        classification=ml_result["classification"],
        ml_probability=ml_result["ml_probability"],
        category=category,
        indicators=final_indicators,
        explanation=llm_reasoning or "",
        evidence=[],
        recommended_action=json.dumps(
            safe_actions,
            ensure_ascii=False,
        ),
        llm_confidence=llm_confidence,
        llm_reasoning=llm_reasoning,
        processing_status=processing_status,
        model_version=model_version,
        rag_version=rag_version,
        email_notification_status="PENDING",
        jira_status=(
            "PENDING" if risk_result["risk_level"] in {"HIGH", "CRITICAL"}
            else "NOT_REQUIRED"
        ),
    )
    db.add(analysis_record)
    db.flush()
    db.add(
        AnalysisNotification(
            analysis_id=analysis_record.id,
            channel="EMAIL",
            status="PENDING",
            idempotency_key=f"analysis-{analysis_record.id}-email",
        )
    )
    if risk_result["risk_level"] in {"HIGH", "CRITICAL"}:
        db.add(
            AnalysisNotification(
                analysis_id=analysis_record.id,
                channel="JIRA",
                status="PENDING",
                idempotency_key=f"analysis-{analysis_record.id}-jira",
            )
        )
    db.commit()
    db.refresh(analysis_record)

    for evidence in retrieved_evidence:
        db.add(
            AnalysisEvidence(
                analysis_id=analysis_record.id,
                knowledge_id=evidence["knowledge_id"] or None,
                evidence_type="RAG_MATCH",
                content=evidence["pattern"],
                similarity_score=evidence["similarity_score"],
                source_reference=evidence["source"],
                language=evidence.get("language"),
                localized_safe_action=evidence.get("safe_action"),
            )
        )
    if retrieved_evidence:
        db.commit()

    escalation_service = EscalationService(db)
    evaluation = escalation_service.evaluate_analysis(
        analysis_record,
        analysis_record.user,
    )
    if evaluation.get("should_escalate"):
        review_case = escalation_service.create_escalated_case(
            analysis_record,
            evaluation,
        )
        analysis_record.escalation_status = "ESCALATED"
        analysis_record.review_case = review_case
        db.commit()
    else:
        analysis_record.escalation_status = "NOT_ESCALATED"

    database_ms = (time.perf_counter() - database_started) * 1000
    total_ms = (time.perf_counter() - total_started) * 1000
    if extraction_ms is not None:
        total_ms += extraction_ms

    performance_record = AnalysisPerformance(
        analysis_id=analysis_record.id,
        input_type=input_data.input_type,
        extraction_ms=extraction_ms,
        preprocessing_ms=preprocessing_ms,
        ml_ms=ml_ms,
        embedding_ms=embedding_ms,
        rag_ms=rag_ms,
        llm_ms=llm_ms,
        risk_engine_ms=risk_engine_ms,
        database_ms=database_ms,
        total_ms=total_ms,
        status="SUCCESS" if llm_response else "FALLBACK",
        error_message=None,
    )
    try:
        db.add(performance_record)
        db.commit()
    except Exception:
        db.rollback()
        logger.exception(
            "Unable to persist performance metrics for analysis %s.",
            analysis_record.id,
        )

    analysis_record.retrieved_evidence_data = retrieved_evidence
    analysis_record.evidence_status = rag_result.get(
        "evidence_status",
        "NO_RELEVANT_MATCH",
    )
    if background_tasks is not None:
        background_tasks.add_task(
            process_analysis_notifications,
            analysis_record.id,
        )
    return analysis_record
