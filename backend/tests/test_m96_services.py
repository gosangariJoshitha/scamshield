import os
import unittest
from unittest.mock import patch

from app.services.llm_service import LLMService
from app.services.rag_service import RagService


class GuardianRagRerankingTests(unittest.TestCase):
    @staticmethod
    def _candidate(category, score):
        return {"category": category, "similarity_score": score}

    def test_secret_solicitation_prioritizes_scam_patterns_over_genuine(self):
        candidates = [
            self._candidate("otp_genuine", 0.95),
            self._candidate("vishing", 0.82),
            self._candidate("bank_notice_genuine", 0.8),
            self._candidate("otp", 0.72),
        ]

        ranked = RagService._rerank_results(
            "A caller says send the OTP now or my account will be blocked.",
            candidates,
        )

        self.assertEqual([item["category"] for item in ranked], ["vishing", "otp"])

    def test_negated_otp_warning_does_not_filter_genuine_knowledge(self):
        candidates = [
            self._candidate("otp_genuine", 0.95),
            self._candidate("vishing", 0.82),
        ]

        ranked = RagService._rerank_results(
            "Do not share your OTP with callers.",
            candidates,
        )

        self.assertEqual(ranked[0]["category"], "otp_genuine")

    def test_reverse_order_secret_request_prioritizes_scam(self):
        candidates = [
            self._candidate("otp_genuine", 0.95),
            self._candidate("vishing", 0.82),
        ]

        ranked = RagService._rerank_results(
            "Your OTP tell me right now.",
            candidates,
        )

        self.assertEqual([item["category"] for item in ranked], ["vishing"])

    def test_hindi_secret_request_prioritizes_scam_patterns(self):
        candidates = [
            self._candidate("otp_genuine", 0.95),
            self._candidate("vishing", 0.85),
        ]

        ranked = RagService._rerank_results(
            "तुरंत अपना ओटीपी बताओ खाता ब्लॉक हो जाएगा।",
            candidates,
        )

        self.assertEqual([item["category"] for item in ranked], ["vishing"])


class LLMProviderConfigurationTests(unittest.TestCase):
    def _service(self, **values):
        with patch.dict(os.environ, values, clear=True), patch(
            "app.services.llm_service.load_dotenv"
        ):
            return LLMService()

    def test_auto_prefers_openrouter_when_configured(self):
        service = self._service(
            LLM_PROVIDER="auto",
            OPENROUTER_API_KEY="openrouter-test-key",
            GROQ_API_KEY="groq-test-key",
        )

        self.assertEqual(service.provider, "openrouter")
        self.assertEqual(service.api_key, "openrouter-test-key")
        self.assertEqual(service.base_url, "https://openrouter.ai/api/v1")

    def test_auto_preserves_groq_when_openrouter_is_not_configured(self):
        service = self._service(
            LLM_PROVIDER="auto",
            GROQ_API_KEY="groq-test-key",
        )

        self.assertEqual(service.provider, "groq")
        self.assertEqual(service.api_key, "groq-test-key")
        self.assertEqual(service.base_url, "https://api.groq.com/openai/v1")

    def test_explicit_openrouter_selection_does_not_silently_use_groq(self):
        service = self._service(
            LLM_PROVIDER="openrouter",
            GROQ_API_KEY="groq-test-key",
        )

        self.assertEqual(service.provider, "openrouter")
        self.assertIsNone(service.api_key)


if __name__ == "__main__":
    unittest.main()
