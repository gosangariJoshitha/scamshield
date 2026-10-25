"""
ScamShield Safe Staging & Environment Diagnostic Script
Milestone M9.8 - Safe Verification Without Secret Leakage
"""
import os
import sys
from pathlib import Path

# Setup sys.path
BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

from dotenv import load_dotenv
load_dotenv(BACKEND_DIR / ".env")
load_dotenv()


def check_env_variables() -> dict[str, str]:
    required_keys = [
        "DATABASE_URL",
        "JWT_SECRET_KEY",
        "ADMIN_EMAIL",
        "ADMIN_PASSWORD",
        "LLM_PROVIDER",
        "WHISPER_MODEL",
        "WHISPER_DEVICE",
        "WHISPER_COMPUTE_TYPE",
    ]
    optional_keys = [
        "OPENROUTER_API_KEY",
        "GROQ_API_KEY",
        "CHROMA_PERSIST_DIRECTORY",
        "FRONTEND_URL",
    ]

    report = {}
    print("\n=== 1. Environment Variables Diagnostic (Secrets Masked) ===")
    for key in required_keys:
        val = os.getenv(key)
        if val:
            status = f"PRESENT (len={len(val)})"
        else:
            status = "MISSING (Required)"
        report[key] = status
        print(f"  [REQ] {key:<28}: {status}")

    for key in optional_keys:
        val = os.getenv(key)
        if val:
            status = f"PRESENT (len={len(val)})"
        else:
            status = "NOT SET (Optional/Fallback)"
        report[key] = status
        print(f"  [OPT] {key:<28}: {status}")
    return report


def check_ml_models() -> dict[str, any]:
    print("\n=== 2. ML & RAG Knowledge Base Initialization ===")
    report = {}
    
    # Check Classifier
    try:
        from app.services.classifier_service import classifier_service
        if classifier_service.load_error:
            status = f"ERROR: {classifier_service.load_error}"
        else:
            pred = classifier_service.predict("Test account verification warning")
            status = f"READY (model={classifier_service.model_version}, test_pred={pred['classification']})"
    except Exception as e:
        status = f"FAILED: {e}"
    report["classifier"] = status
    print(f"  Classifier Service          : {status}")

    # Check RAG Knowledge Base
    try:
        from app.services.rag_service import rag_service
        health = rag_service.get_index_health()
        status = f"{health['status']} (vectors={health['vector_count']}/{health['expected_minimum']})"
    except Exception as e:
        status = f"FAILED: {e}"
    report["rag_chromadb"] = status
    print(f"  ChromaDB Knowledge Base     : {status}")

    # Check Faster-Whisper Configuration
    try:
        from app.services.audio_service import WHISPER_MODEL_NAME, WHISPER_CHUNK_MAX_BYTES
        status = f"CONFIGURED (model={WHISPER_MODEL_NAME}, max_chunk_bytes={WHISPER_CHUNK_MAX_BYTES})"
    except Exception as e:
        status = f"FAILED: {e}"
    report["faster_whisper"] = status
    print(f"  Faster-Whisper Config       : {status}")

    return report


def check_guardian_schemas() -> dict[str, str]:
    print("\n=== 3. Guardian Contract & Schema Verification ===")
    report = {}
    try:
        from schemas import GuardianTranscriptSegmentCreate, GuardianLiveAnalysisResponse
        from guardian_transcription import TranscriptSegmentResponse

        req_fields = list(GuardianTranscriptSegmentCreate.model_fields.keys())
        resp_fields = list(GuardianLiveAnalysisResponse.model_fields.keys())
        tx_fields = list(TranscriptSegmentResponse.model_fields.keys())

        report["guardian_analysis_request"] = f"VALID ({len(req_fields)} fields: {', '.join(req_fields[:5])}...)"
        report["guardian_analysis_response"] = f"VALID ({len(resp_fields)} fields: {', '.join(resp_fields)})"
        report["transcription_segment"] = f"VALID ({len(tx_fields)} fields: {', '.join(tx_fields)})"

        for k, v in report.items():
            print(f"  Schema {k:<21}: {v}")
    except Exception as e:
        report["schema_check"] = f"FAILED: {e}"
        print(f"  Schema check error: {e}")

    return report


if __name__ == "__main__":
    print("=================================================================")
    print("ScamShield Staging & Local Diagnostics (Non-Destructive Safe Run)")
    print("=================================================================")
    check_env_variables()
    check_ml_models()
    check_guardian_schemas()
    print("\nDiagnostic complete.\n")
