import unittest
from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import AsyncMock, patch
from uuid import uuid4

from fastapi import FastAPI
from fastapi.testclient import TestClient

import auth
from app.services.rate_limiter import analysis_rate_limiter
from guardian_analysis import (
    _get_session_state,
    _sessions,
    clear_guardian_analysis_sessions,
    router,
)


class GuardianAnalysisApiTests(unittest.TestCase):
    def setUp(self):
        analysis_rate_limiter.reset()
        clear_guardian_analysis_sessions()
        app = FastAPI()
        app.include_router(router, prefix="/api")
        app.dependency_overrides[auth.get_current_verified_user] = (
            lambda: SimpleNamespace(id=31, role="user")
        )
        self.client = TestClient(app)
        self.client.__enter__()
        self.session_id = uuid4()

    def tearDown(self):
        self.client.__exit__(None, None, None)
        analysis_rate_limiter.reset()
        clear_guardian_analysis_sessions()

    def _segment(
        self,
        *,
        text="Your bank account will be suspended today. Send your OTP to verify this request now.",
        segment_id="segment-1",
        sequence=1,
        source="CALL_AUDIO",
    ):
        return {
            "session_id": str(self.session_id),
            "segment_id": segment_id,
            "sequence": sequence,
            "start_time": 0,
            "end_time": 5,
            "text": text,
            "is_final": True,
            "language": "en",
            "source": source,
            "created_at": datetime.now(timezone.utc).isoformat(),
        }

    def _core_result(self):
        actions = {
            "canonical": ["Do not share your OTP."],
            "translations": {
                "en": ["Do not share your OTP."],
                "hi": ["अपना OTP साझा न करें।"],
                "te": ["మీ OTPని పంచుకోవద్దు."],
            },
            "default_language": "en",
        }
        return SimpleNamespace(
            default_language="en",
            ml_result={
                "classification": "SCAM",
                "ml_probability": 0.97,
            },
            rag_result={"evidence_status": "MATCH_FOUND"},
            retrieved_evidence=[],
            llm_confidence=0.9,
            llm_reasoning="The request asks for an OTP and threatens account suspension.",
            processing_status="COMPLETED",
            category="OTP/Verification",
            safe_action="Do not share your OTP.",
            safe_actions=actions,
            final_indicators=["OTP solicitation", "account suspension threat"],
            risk_result={"risk_score": 94, "risk_level": "CRITICAL"},
            model_version="test-model",
            rag_version="test-rag",
            preprocessing_ms=1.0,
            ml_ms=2.0,
            embedding_ms=3.0,
            rag_ms=4.0,
            llm_ms=5.0,
            risk_engine_ms=1.0,
            total_ms=16.0,
        )

    def test_short_segment_waits_without_calling_analysis(self):
        with patch(
            "guardian_analysis.analyze_text_core",
            new_callable=AsyncMock,
        ) as analyze:
            response = self.client.post(
                "/api/guardian/analysis/segment",
                json=self._segment(text="Hello there."),
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json()["status"],
            "AI_WAITING_FOR_TRANSCRIPT",
        )
        analyze.assert_not_awaited()

    def test_suspicious_window_returns_shared_pipeline_analysis(self):
        with patch(
            "guardian_analysis.analyze_text_core",
            new_callable=AsyncMock,
            return_value=self._core_result(),
        ) as analyze:
            response = self.client.post(
                "/api/guardian/analysis/segment",
                json=self._segment(),
            )

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["status"], "AI_RESULT_READY")
        self.assertEqual(body["result"]["classification"], "SCAM")
        self.assertEqual(body["result"]["risk_score"], 94)
        self.assertEqual(body["result"]["scam_category"], "OTP/Verification")
        self.assertEqual(body["result"]["session_id"], str(self.session_id))
        self.assertNotIn("Send your OTP", response.text)
        analyze.assert_awaited_once()

    def test_repeated_transcript_text_is_not_analyzed_twice(self):
        with patch(
            "guardian_analysis.analyze_text_core",
            new_callable=AsyncMock,
            return_value=self._core_result(),
        ) as analyze:
            first = self.client.post(
                "/api/guardian/analysis/segment",
                json=self._segment(),
            )
            repeated = self.client.post(
                "/api/guardian/analysis/segment",
                json=self._segment(segment_id="segment-2", sequence=2),
            )

        self.assertEqual(first.json()["status"], "AI_RESULT_READY")
        self.assertEqual(repeated.json()["status"], "AI_DUPLICATE")
        analyze.assert_awaited_once()

    def test_device_microphone_source_is_rejected(self):
        with patch(
            "guardian_analysis.analyze_text_core",
            new_callable=AsyncMock,
        ) as analyze:
            response = self.client.post(
                "/api/guardian/analysis/segment",
                json=self._segment(source="DEVICE_MICROPHONE"),
            )

        self.assertEqual(response.status_code, 422)
        analyze.assert_not_awaited()

    def test_pipeline_failure_returns_unavailable_without_text(self):
        with patch(
            "guardian_analysis.analyze_text_core",
            new_callable=AsyncMock,
            side_effect=RuntimeError("private transcript text"),
        ):
            response = self.client.post(
                "/api/guardian/analysis/segment",
                json=self._segment(),
            )

        self.assertEqual(response.status_code, 503)
        self.assertEqual(response.json()["status"], "AI_UNAVAILABLE")
        self.assertNotIn("private transcript text", response.text)

    def test_analysis_sessions_are_scoped_to_user_and_finalization(self):
        session_id = uuid4()
        _get_session_state(31, session_id)
        _get_session_state(32, session_id)

        response = self.client.post(
            f"/api/guardian/analysis/session/{session_id}/finalize"
        )

        self.assertEqual(response.status_code, 200)
        self.assertNotIn((31, session_id), _sessions)
        self.assertIn((32, session_id), _sessions)

    def test_acceptance_scam_transcript_triggers_core_pipeline(self):
        acceptance_text = (
            "Your bank account has been blocked. Tell me the OTP immediately to verify it."
        )
        with patch(
            "guardian_analysis.analyze_text_core",
            new_callable=AsyncMock,
            return_value=self._core_result(),
        ) as analyze:
            response = self.client.post(
                "/api/guardian/analysis/segment",
                json=self._segment(text=acceptance_text),
            )

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["status"], "AI_RESULT_READY")
        self.assertEqual(body["result"]["classification"], "SCAM")
        self.assertGreaterEqual(body["result"]["risk_score"], 80)
        analyze.assert_awaited_once()

    def test_multilingual_hindi_transcript_triggers_analysis(self):
        hindi_text = "आपका बैंक खाता ब्लॉक कर दिया गया है। मुझे तुरंत ओटीपी बताओ।"
        with patch(
            "guardian_analysis.analyze_text_core",
            new_callable=AsyncMock,
            return_value=self._core_result(),
        ) as analyze:
            response = self.client.post(
                "/api/guardian/analysis/segment",
                json=self._segment(text=hindi_text, source="CALL_AUDIO"),
            )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "AI_RESULT_READY")
        analyze.assert_awaited_once()

    def test_llm_failure_fallback_returns_completed_with_limitations(self):
        fallback_core = self._core_result()
        fallback_core.llm_reasoning = None
        fallback_core.llm_confidence = None
        fallback_core.processing_status = "COMPLETED_WITH_LIMITATIONS"

        with patch(
            "guardian_analysis.analyze_text_core",
            new_callable=AsyncMock,
            return_value=fallback_core,
        ) as analyze:
            response = self.client.post(
                "/api/guardian/analysis/segment",
                json=self._segment(),
            )

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["status"], "AI_RESULT_READY")
        self.assertIn("temporarily unavailable", body["message"])
        self.assertEqual(
            body["result"]["reasoning"],
            "AI explanation temporarily unavailable.",
        )
        self.assertEqual(
            body["result"]["processing_status"],
            "COMPLETED_WITH_LIMITATIONS",
        )
        analyze.assert_awaited_once()


if __name__ == "__main__":
    unittest.main()

