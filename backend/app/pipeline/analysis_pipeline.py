from app.services.classifier_service import classifier_service
from app.services.risk_engine import calculate_risk
from app.services.rag_service import rag_service
from app.services.llm_service import llm_service
from schemas import NormalizedAnalysisInput
from models import Analysis, AnalysisEvidence, AnalysisPerformance
from app.services.escalation_service import EscalationService
from sqlalchemy.orm import Session
import os
import time

async def run_analysis_pipeline(db: Session, input_data: NormalizedAnalysisInput, user_id: int, extraction_ms: float = 0):
    t_total_start = time.perf_counter()
    text = input_data.extracted_text

    # 1. Run ML Classifier
    t0 = time.perf_counter()
    ml_result = classifier_service.predict(text)
    ml_ms = (time.perf_counter() - t0) * 1000
    
    # 2. Run RAG Retrieval
    t0 = time.perf_counter()
    rag_result = rag_service.search(text)
    retrieved_evidence = rag_result.get("retrieved_evidence", [])
    rag_ms = (time.perf_counter() - t0) * 1000
    
    # 3. Compile base indicators (M3)
    base_indicators = []
    
    # 4. Call LLM for Reasoning (M5)
    t0 = time.perf_counter()
    llm_response = await llm_service.generate_reasoning(
        text=text,
        ml_result=ml_result,
        retrieved_evidence=retrieved_evidence,
        indicators=base_indicators
    )
    llm_ms = (time.perf_counter() - t0) * 1000
    
    # Prepare LLM data
    llm_confidence = None
    llm_reasoning = None
    processing_status = "COMPLETED"
    llm_indicators = []
    category = "General"
    safe_action = "Please verify the source through official channels before taking any action."

    if llm_response:
        llm_confidence = llm_response.confidence
        llm_reasoning = llm_response.risk_reasoning
        llm_indicators = llm_response.suspicious_indicators
        category = llm_response.scam_category
        safe_action = llm_response.safe_action
    else:
        processing_status = "COMPLETED_WITH_LIMITATIONS"
        # Fallback heuristic for category mapping
        text_lower = text.lower()
        if "otp" in text_lower or "verification" in text_lower or "code" in text_lower:
            category = "OTP/Verification"
        elif "bank" in text_lower or "account" in text_lower or "blocked" in text_lower or "kyc" in text_lower:
            category = "Banking/KYC"
        elif "job" in text_lower or "salary" in text_lower or "hire" in text_lower or "work from home" in text_lower:
            category = "Job/Employment"
        elif "prize" in text_lower or "won" in text_lower or "lottery" in text_lower or "winner" in text_lower:
            category = "Lottery/Prize"
        elif "delivery" in text_lower or "package" in text_lower or "shipment" in text_lower:
            category = "Delivery/Postal"
        elif ml_result["classification"] == "GENUINE":
            category = "Normal Message"

        if retrieved_evidence and len(retrieved_evidence) > 0:
            safe_action = retrieved_evidence[0].get("safe_action", safe_action)
            
    # Combine ML, RAG and LLM indicators
    all_indicators = list(set(base_indicators + llm_indicators))
    
    # 5. Risk Engine
    t0 = time.perf_counter()
    risk_result = calculate_risk(
        ml_probability=ml_result["ml_probability"], 
        text=text, 
        classification=ml_result["classification"],
        llm_indicators=all_indicators,
        retrieved_evidence=retrieved_evidence
    )
    risk_engine_ms = (time.perf_counter() - t0) * 1000
    
    # Ensure all indicators are combined
    final_indicators = list(set(all_indicators + risk_result.get("risk_factors", [])))
    
    model_version = os.getenv("OPENROUTER_MODEL", "meta-llama/llama-3-8b-instruct:free") if llm_response else "scamshield-classifier-v1"
    rag_version = "scamshield-rag-v1" if retrieved_evidence else None

    t0 = time.perf_counter()
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
        evidence=[], # JSON is empty, use relationship
        recommended_action=safe_action,
        llm_confidence=llm_confidence,
        llm_reasoning=llm_reasoning,
        processing_status=processing_status,
        model_version=model_version,
        rag_version=rag_version
    )
    
    db.add(analysis_record)
    db.commit()
    db.refresh(analysis_record)
    
    # 6. Save RAG Evidence to Relational Table
    for ev in retrieved_evidence:
        db_ev = AnalysisEvidence(
            analysis_id=analysis_record.id,
            knowledge_id=ev["knowledge_id"] if ev["knowledge_id"] else None,
            evidence_type="RAG_MATCH",
            content=ev["pattern"],
            similarity_score=ev["similarity_score"],
            source_reference=ev["source"]
        )
        db.add(db_ev)
    
    if retrieved_evidence:
        db.commit()
        
    database_ms = (time.perf_counter() - t0) * 1000
    
    total_ms = (time.perf_counter() - t_total_start) * 1000 + extraction_ms
    
    # 7. Record performance metrics
    perf_record = AnalysisPerformance(
        analysis_id=analysis_record.id,
        input_type=input_data.input_type,
        extraction_ms=extraction_ms,
        preprocessing_ms=0, # Included in input extraction or ML steps for now
        ml_ms=ml_ms,
        embedding_ms=0, # Included in RAG time
        rag_ms=rag_ms,
        llm_ms=llm_ms,
        risk_engine_ms=risk_engine_ms,
        database_ms=database_ms,
        total_ms=total_ms,
        status="SUCCESS" if llm_response else "FALLBACK",
        error_message=None
    )
    db.add(perf_record)
    db.commit()
    
    # 8. M8 Escalation Engine Evaluation
    escalation_service = EscalationService(db)
    evaluation = escalation_service.evaluate_analysis(analysis_record, analysis_record.user)
    if evaluation.get("should_escalate"):
        review_case = escalation_service.create_escalated_case(analysis_record, evaluation)
        analysis_record.escalation_status = "ESCALATED"
        analysis_record.review_case_id = review_case.id
    
    analysis_record.retrieved_evidence_data = retrieved_evidence
    analysis_record.evidence_status = rag_result.get("evidence_status", "NO_RELEVANT_MATCH")
    
    return analysis_record
