"""Focused API tests for the Guardian live-transcription endpoints."""

import unittest
from datetime import datetime, timezone
from types import SimpleNamespace
from unittest.mock import patch
from uuid import uuid4

from fastapi import FastAPI
from fastapi.testclient import TestClient

import auth
from app.services.audio_service import TranscriptionSegment
from app.services.rate_limiter import analysis_rate_limiter
from guardian_transcription import _cache_lock, _cache_put, _transcript_cache, router


class GuardianTranscriptionApiTests(unittest.TestCase):
    def setUp(self):
        analysis_rate_limiter.reset()
        with _cache_lock:
            _transcript_cache.clear()
        app = FastAPI()
        app.include_router(router, prefix="/api")
        app.dependency_overrides[auth.get_current_verified_user] = (
            lambda: SimpleNamespace(id=31, role="user")
        )
        self.client = TestClient(app)
        self.client.__enter__()
        self.session_id = str(uuid4())
        self.chunk_id = str(uuid4())

    def tearDown(self):
        self.client.__exit__(None, None, None)
        analysis_rate_limiter.reset()
        with _cache_lock:
            _transcript_cache.clear()

    @staticmethod
    def _chunk_fields(session_id, chunk_id, *, source="CALL_AUDIO", sequence=1):
        return {
            "session_id": session_id,
            "chunk_id": chunk_id,
            "sequence": str(sequence),
            "timestamp_ms": "1770000005000",
            "call_started_at_ms": "1770000000000",
            "duration_ms": "5000",
            "sample_rate_hz": "16000",
            "channels": "1",
            "encoding": "PCM_16BIT",
            "source": source,
        }

    def _post_chunk(self, *, source="CALL_AUDIO", sequence=1):
        return self.client.post(
            "/api/guardian/transcription/chunk",
            data=self._chunk_fields(
                self.session_id,
                self.chunk_id,
                source=source,
                sequence=sequence,
            ),
            files={
                "file": (
                    "chunk.pcm",
                    b"\x00\x00" * 80_000,
                    "application/octet-stream",
                )
            },
        )

    def test_device_microphone_source_is_rejected_without_whisper(self):
        with patch(
            "guardian_transcription.audio_service.transcribe_pcm_chunk"
        ) as transcribe:
            response = self._post_chunk(source="DEVICE_MICROPHONE")

        self.assertEqual(response.status_code, 422)
        self.assertEqual(
            response.json()["detail"],
            "Live transcription is unavailable for this audio source.",
        )
        transcribe.assert_not_called()

    def test_supported_pcm_chunk_returns_final_timestamped_segment(self):
        segment = TranscriptionSegment(
            segment_id=f"{self.chunk_id}:0",
            sequence=1,
            start_time=0.4,
            end_time=2.2,
            text="Transcribed speech.",
            is_final=True,
            language="en",
            created_at=datetime(2026, 10, 7, tzinfo=timezone.utc),
        )
        with patch(
            "guardian_transcription.audio_service.transcribe_pcm_chunk",
            return_value=[segment],
        ) as transcribe:
            response = self._post_chunk()

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["language"], "en")
        self.assertEqual(len(body["segments"]), 1)
        self.assertEqual(body["segments"][0]["session_id"], self.session_id)
        self.assertEqual(body["segments"][0]["text"], "Transcribed speech.")
        self.assertTrue(body["segments"][0]["is_final"])
        self.assertEqual(body["segments"][0]["start_time"], 0.4)
        transcribe.assert_called_once()
        self.assertEqual(
            transcribe.call_args.kwargs["chunk_start_seconds"],
            0,
        )

    def test_duplicate_chunk_returns_cached_transcript_without_retranscribing(self):
        segment = TranscriptionSegment(
            segment_id=f"{self.chunk_id}:0",
            sequence=1,
            start_time=0,
            end_time=1,
            text="One transcript only.",
            is_final=True,
            language="en",
            created_at=datetime.now(timezone.utc),
        )
        with patch(
            "guardian_transcription.audio_service.transcribe_pcm_chunk",
            return_value=[segment],
        ) as transcribe:
            first = self._post_chunk()
            second = self._post_chunk()

        self.assertEqual(first.status_code, 200)
        self.assertEqual(second.status_code, 200)
        self.assertEqual(first.json(), second.json())
        transcribe.assert_called_once()

    def test_finalize_removes_only_authenticated_users_session_cache(self):
        session_id = str(uuid4())
        chunk_id = str(uuid4())
        _cache_put((31, session_id, chunk_id), [])
        _cache_put((32, session_id, str(uuid4())), [])
        response = self.client.post(
            f"/api/guardian/transcription/session/{session_id}/finalize"
        )

        self.assertEqual(response.status_code, 200)
        with _cache_lock:
            self.assertFalse(
                any(
                    key[0] == 31 and key[1] == session_id
                    for key in _transcript_cache
                )
            )
            self.assertTrue(
                any(
                    key[0] == 32 and key[1] == session_id
                    for key in _transcript_cache
                )
            )


if __name__ == "__main__":
    unittest.main()
