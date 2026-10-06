import json
import unittest
from datetime import datetime
from io import BytesIO
from types import SimpleNamespace
from unittest.mock import AsyncMock, Mock, patch

from fastapi import BackgroundTasks, HTTPException, UploadFile
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from starlette.datastructures import Headers

import models
from analysis import _populate_retrieved_evidence
from admin import get_admin_system_health
from app.pipeline.input_router import InputRouter
from app.pipeline.analysis_pipeline import run_analysis_pipeline
from app.services.classifier_service import ClassifierService
from app.services.risk_engine import calculate_risk
from schemas import AnalysisResponse, NormalizedAnalysisInput
from app.services.text_service import preprocess_text


class AnalysisCoreTests(unittest.TestCase):
    def test_preprocessing_normalizes_unicode_and_whitespace(self):
        text = "  Please share your OTP \n\n 12345 "
        self.assertEqual(preprocess_text(text), "please share your otp 12345")

    def test_classifier_loads_configured_model_and_predicts(self):
        service = ClassifierService()
        self.assertIsNotNone(service.clf)
        self.assertIsNotNone(service.vectorizer)
        self.assertEqual(service.model_version, "scamshield-classifier-v5")

        result = service.predict("urgent your account is blocked click here and send OTP")
        self.assertIn(result["classification"], {"SCAM", "GENUINE"})
        self.assertGreaterEqual(result["ml_probability"], 0.0)
        self.assertLessEqual(result["ml_probability"], 1.0)
        self.assertEqual(result["model_version"], service.model_version)

    def test_risk_score_is_bounded(self):
        for probability, text, classification in (
            (0.9, "urgent otp", "SCAM"),
            (0.1, "hello mom", "GENUINE"),
        ):
            with self.subTest(probability=probability):
                result = calculate_risk(probability, text, classification)
                self.assertGreaterEqual(result["risk_score"], 0)
                self.assertLessEqual(result["risk_score"], 100)
                self.assertIn(
                    result["risk_level"],
                    {"LOW", "MEDIUM", "HIGH", "CRITICAL"},
                )

    def test_genuine_low_probability_is_low_risk(self):
        result = calculate_risk(0.1, "hello mom how are you", "GENUINE")
        self.assertEqual(result["risk_level"], "LOW")

    def test_risk_threshold_boundaries(self):
        cases = (
            (0.29, "LOW"),
            (0.30, "MEDIUM"),
            (0.60, "HIGH"),
            (0.80, "CRITICAL"),
        )
        for probability, expected in cases:
            with self.subTest(probability=probability):
                result = calculate_risk(probability, "", "SCAM")
                self.assertEqual(result["risk_level"], expected)


class AdminHealthTests(unittest.TestCase):
    def test_admin_health_returns_timestamp_and_measured_service_status(self):
        engine = create_engine("sqlite://")
        with sessionmaker(bind=engine)() as db:
            admin = models.User(
                id=1,
                full_name="Admin Test",
                email="admin-test@example.com",
                password_hash="unused-test-hash",
                role="admin",
                is_active=True,
            )
            with (
                patch(
                    "admin.classifier_service",
                    SimpleNamespace(clf=object(), vectorizer=object()),
                ),
                patch(
                    "admin.rag_service",
                    SimpleNamespace(
                        collection=SimpleNamespace(count=lambda: 80)
                    ),
                ),
            ):
                health = get_admin_system_health(db, admin)

        timestamp = datetime.fromisoformat(health["system_time"])
        self.assertIsNotNone(timestamp.tzinfo)
        self.assertEqual(health["database"]["status"], "up")
        self.assertTrue(health["database"]["latency"].endswith("ms"))
        self.assertEqual(health["ml_engine"]["status"], "up")
        self.assertEqual(health["rag_service"]["status"], "up")
        engine.dispose()


class InputChannelTests(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        self.router = InputRouter()

    async def test_text_and_email_inputs_are_extracted(self):
        text_result = await self.router.route_and_extract(
            input_type="text",
            content="  Verify your account now.  ",
        )
        self.assertEqual(text_result.extracted_text, "Verify your account now.")
        self.assertEqual(text_result.original_text, "  Verify your account now.  ")

        email_result = await self.router.route_and_extract(
            input_type="email",
            email_data={
                "subject": "Account warning",
                "sender": "security@example.test",
                "body": "Visit the link to restore access.",
            },
        )
        self.assertIn("Subject: Account warning", email_result.extracted_text)
        self.assertIn("From: security@example.test", email_result.extracted_text)
        self.assertIn(
            "Body:\nVisit the link to restore access.",
            email_result.extracted_text,
        )
        self.assertEqual(email_result.input_type, "email")

    async def test_pdf_image_and_audio_dispatch_to_their_extractors(self):
        async def upload(filename, mime_type, content):
            return UploadFile(
                filename=filename,
                file=BytesIO(content),
                headers=Headers({"content-type": mime_type}),
            )

        pdf_extractor = Mock(return_value=("PDF text", {"page_count": 1}))
        image_extractor = Mock(
            return_value=("Image text", {"detected_blocks": 1})
        )
        audio_extractor = Mock(
            return_value=("Audio transcript", {"detected_language": "en"})
        )
        with (
            patch(
                "app.pipeline.input_router.pdf_service",
                SimpleNamespace(extract_text=pdf_extractor),
            ),
            patch(
                "app.pipeline.input_router.ocr_service",
                SimpleNamespace(extract_text=image_extractor),
            ),
            patch(
                "app.pipeline.input_router.audio_service",
                SimpleNamespace(extract_text=audio_extractor),
            ),
        ):
            pdf_file = await upload("notice.pdf", "application/pdf", b"%PDF-test")
            pdf_result = await self.router.route_and_extract(
                input_type="pdf",
                file=pdf_file,
            )
            pdf_extractor.assert_called_once_with(b"%PDF-test")
            self.assertEqual(pdf_result.input_type, "pdf")
            self.assertEqual(pdf_result.extracted_text, "PDF text")

            image_file = await upload(
                "notice.png",
                "image/png",
                b"\x89PNG\r\n\x1a\nimage bytes",
            )
            image_result = await self.router.route_and_extract(
                input_type="image",
                file=image_file,
                image_language="hi",
            )
            image_extractor.assert_called_once_with(
                b"\x89PNG\r\n\x1a\nimage bytes",
                "hi",
            )
            self.assertEqual(image_result.input_type, "image")

            audio_file = await upload(
                "recording.mp3", "audio/mpeg", b"ID3audio bytes"
            )
            audio_result = await self.router.route_and_extract(
                input_type="audio",
                file=audio_file,
            )
            audio_extractor.assert_called_once_with(
                b"ID3audio bytes", "recording.mp3"
            )
            self.assertEqual(audio_result.input_type, "audio")
            self.assertEqual(audio_result.extracted_text, "Audio transcript")

    async def test_empty_extraction_is_rejected(self):
        with self.assertRaises(HTTPException) as error:
            await self.router.route_and_extract(input_type="text", content="  ")
        self.assertEqual(error.exception.status_code, 400)

    async def test_uploads_over_size_limit_are_rejected_before_extraction(self):
        file = UploadFile(
            filename="oversized.pdf",
            file=BytesIO(b"12345"),
            headers=Headers({"content-type": "application/pdf"}),
        )
        with (
            patch("app.pipeline.input_router.MAX_UPLOAD_BYTES", 4),
            patch("app.pipeline.input_router.pdf_service.extract_text") as extract,
            self.assertRaises(HTTPException) as error,
        ):
            await self.router.route_and_extract(input_type="pdf", file=file)

        self.assertEqual(error.exception.status_code, 413)
        extract.assert_not_called()

    async def test_upload_signature_and_mime_must_match_declared_format(self):
        file = UploadFile(
            filename="notice.pdf",
            file=BytesIO(b"not a PDF"),
            headers=Headers({"content-type": "application/pdf"}),
        )
        with self.assertRaises(HTTPException) as error:
            await self.router.route_and_extract(input_type="pdf", file=file)
        self.assertEqual(error.exception.status_code, 400)

        mismatched = UploadFile(
            filename="notice.png",
            file=BytesIO(b"\x89PNG\r\n\x1a\ncontent"),
            headers=Headers({"content-type": "image/jpeg"}),
        )
        with self.assertRaises(HTTPException) as error:
            await self.router.route_and_extract(input_type="image", file=mismatched)
        self.assertEqual(error.exception.status_code, 415)

    async def test_text_and_email_limits_return_payload_too_large(self):
        with (
            patch("app.pipeline.input_router.MAX_TEXT_CHARS", 4),
            self.assertRaises(HTTPException) as error,
        ):
            await self.router.route_and_extract(
                input_type="text",
                content="12345",
            )
        self.assertEqual(error.exception.status_code, 413)

        with (
            patch("app.pipeline.input_router.MAX_EMAIL_BODY_CHARS", 4),
            self.assertRaises(HTTPException) as error,
        ):
            await self.router.route_and_extract(
                input_type="email",
                email_data={"subject": "", "sender": "", "body": "12345"},
            )
        self.assertEqual(error.exception.status_code, 413)


class PipelinePerformanceTests(unittest.IsolatedAsyncioTestCase):
    async def test_pipeline_persists_measured_stage_timings(self):
        engine = create_engine(
            "sqlite://",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        models.Base.metadata.create_all(bind=engine)
        session_factory = sessionmaker(bind=engine, autoflush=False)
        try:
            with session_factory() as db:
                user = models.User(
                    full_name="Pipeline Test",
                    email="pipeline-test@example.com",
                    password_hash="unused-test-hash",
                    role="user",
                    is_active=True,
                )
                db.add(user)
                db.commit()
                db.refresh(user)

                with (
                    patch(
                        "app.pipeline.analysis_pipeline.classifier_service.predict_processed",
                        return_value={
                            "classification": "GENUINE",
                            "ml_probability": 0.1,
                            "model_version": "unit-test-model",
                        },
                    ),
                    patch(
                        "app.pipeline.analysis_pipeline.rag_service.search",
                        return_value={
                            "evidence_status": "MATCH_FOUND",
                            "retrieved_evidence": [{
                                "knowledge_id": 0,
                                "title": "Localized pattern",
                                "category": "test",
                                "similarity_score": 0.9,
                                "pattern": "Localized pattern details",
                                "safe_action": "అధికారిక మార్గంలో ధృవీకరించండి.",
                                "source": "test",
                                "language": "te",
                            }],
                            "timings": {"embedding_ms": 1.25, "retrieval_ms": 0.75},
                        },
                    ) as rag_search,
                    patch(
                        "app.pipeline.analysis_pipeline.llm_service.generate_reasoning",
                        new_callable=AsyncMock,
                        return_value=None,
                    ),
                    patch(
                        "app.services.jira_service.JiraService.create_issue_for_review_case"
                    ) as jira_create,
                ):
                    analysis = await run_analysis_pipeline(
                        db,
                        NormalizedAnalysisInput(
                            input_type="text",
                            extracted_text="A normal family message.",
                            metadata={"detected_language": "te"},
                        ),
                        user.id,
                    )

                rag_search.assert_called_once_with(
                    "A normal family message.",
                    language="te",
                )
                _populate_retrieved_evidence(analysis)
                self.assertEqual(
                    analysis.retrieved_evidence_data[0]["safe_action"],
                    "అధికారిక మార్గంలో ధృవీకరించండి.",
                )
                performance = (
                    db.query(models.AnalysisPerformance)
                    .filter_by(analysis_id=analysis.id)
                    .one()
                )
                stored_actions = json.loads(analysis.recommended_action)
                self.assertEqual(len(stored_actions["canonical"]), 3)
                self.assertEqual(
                    stored_actions["default_language"],
                    "te",
                )
                response = AnalysisResponse.model_validate(analysis)
                self.assertEqual(
                    response.safe_actions.canonical,
                    stored_actions["canonical"],
                )
                self.assertIsNone(performance.extraction_ms)
                self.assertGreater(performance.preprocessing_ms, 0)
                self.assertGreater(performance.ml_ms, 0)
                self.assertEqual(performance.embedding_ms, 1.25)
                self.assertEqual(performance.rag_ms, 0.75)
                self.assertGreater(performance.llm_ms, 0)
                self.assertGreater(performance.risk_engine_ms, 0)
                self.assertGreater(performance.database_ms, 0)
                self.assertGreater(performance.total_ms, 0)
                self.assertEqual(performance.status, "FALLBACK")
                jira_create.assert_not_called()
        finally:
            models.Base.metadata.drop_all(bind=engine)
            engine.dispose()

    async def test_pipeline_sends_automatically_escalated_cases_to_jira(self):
        engine = create_engine(
            "sqlite://",
            connect_args={"check_same_thread": False},
            poolclass=StaticPool,
        )
        models.Base.metadata.create_all(bind=engine)
        session_factory = sessionmaker(bind=engine, autoflush=False)
        try:
            with session_factory() as db:
                user = models.User(
                    full_name="Escalation Test",
                    email="escalation-test@example.com",
                    password_hash="unused-test-hash",
                    role="user",
                    is_active=True,
                )
                db.add(user)
                db.commit()
                db.refresh(user)

                background_tasks = BackgroundTasks()

                with (
                    patch.dict("os.environ", {"JIRA_ENABLED": "true"}),
                    patch(
                        "app.pipeline.analysis_pipeline.classifier_service.predict_processed",
                        return_value={
                            "classification": "SCAM",
                            "ml_probability": 0.99,
                            "model_version": "unit-test-model",
                        },
                    ),
                    patch(
                        "app.pipeline.analysis_pipeline.rag_service.search",
                        return_value={
                            "evidence_status": "NO_RELEVANT_MATCH",
                            "retrieved_evidence": [],
                            "timings": {"embedding_ms": 1.0, "retrieval_ms": 1.0},
                        },
                    ),
                    patch(
                        "app.pipeline.analysis_pipeline.llm_service.generate_reasoning",
                        new_callable=AsyncMock,
                        return_value=None,
                    ),
                    patch(
                        "app.pipeline.analysis_pipeline.EscalationService.evaluate_analysis",
                        return_value={
                            "should_escalate": True,
                            "priority": "HIGH",
                            "reasons": ["CRITICAL_RISK"],
                        },
                    ),
                    patch(
                        "app.pipeline.analysis_pipeline.EscalationService.create_escalated_case",
                        return_value=models.ReviewCase(
                            id=4242,
                            user_id=user.id,
                            status="PENDING",
                            priority="URGENT",
                            escalation_reason="CRITICAL_RISK",
                            escalation_reasons_json=["CRITICAL_RISK"],
                        ),
                    ),
                    patch(
                        "app.services.jira_service.JiraService.create_issue_for_review_case",
                        return_value={"success": True, "issue_key": "SCAM-4242"},
                    ) as jira_create,
                    patch(
                        "app.services.analysis_notifications.SessionLocal",
                        session_factory,
                    ),
                    patch(
                        "app.services.analysis_notifications.email_service.send_analysis_report"
                    ),
                ):
                    await run_analysis_pipeline(
                        db,
                        NormalizedAnalysisInput(
                            input_type="text",
                            extracted_text="Urgent account verification alert.",
                            metadata={},
                        ),
                        user.id,
                        background_tasks=background_tasks,
                    )
                    await background_tasks()

                jira_create.assert_called_once_with(4242, actor_id=None)
        finally:
            models.Base.metadata.drop_all(bind=engine)
            engine.dispose()


if __name__ == "__main__":
    unittest.main()
