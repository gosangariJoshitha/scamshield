from app.services.classifier_service import classifier_service
from app.services.risk_engine import calculate_risk
from app.services.rag_service import rag_service
from app.services.llm_service import llm_service
from schemas import NormalizedAnalysisInput
from models import Analysis, AnalysisEvidence
from sqlalchemy.orm import Session
import os

async def run_analysis_pipeline(db: Session, input_data: NormalizedAnalysisInput, user_id: int):
    text = input_data.extracted_text

    # 1. Run ML Classifier
    ml_result = classifier_service.predict(text)
    
    # 2. Run RAG Retrieval
    rag_result = rag_service.search(text)
    retrieved_evidence = rag_result.get("retrieved_evidence", [])
    
    # 3. Compile base indicators (M3)
    base_indicators = []
    
    # 4. Call LLM for Reasoning (M5)
    llm_response = await llm_service.generate_reasoning(
        text=text,
        ml_result=ml_result,
        retrieved_evidence=retrieved_evidence,
        indicators=base_indicators
    )
    
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
    # We pass the indicators to the risk engine to let it bump the score
    risk_result = calculate_risk(
        ml_probability=ml_result["ml_probability"], 
        text=text, 
        classification=ml_result["classification"],
        llm_indicators=all_indicators,
        retrieved_evidence=retrieved_evidence
    )
    
    # Ensure all indicators are combined
    final_indicators = list(set(all_indicators + risk_result.get("risk_factors", [])))
    
    model_version = os.getenv("OPENROUTER_MODEL", "meta-llama/llama-3-8b-instruct:free") if llm_response else "scamshield-classifier-v1"
    rag_version = "scamshield-rag-v1" if retrieved_evidence else None

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
    
    analysis_record.retrieved_evidence_data = retrieved_evidence
    analysis_record.evidence_status = rag_result.get("evidence_status", "NO_RELEVANT_MATCH")
    
    return analysis_record
