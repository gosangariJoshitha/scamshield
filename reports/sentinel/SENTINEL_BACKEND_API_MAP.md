# ScamShield 2.0 — Sentinel Phase Backend API Map

## 1. Executive Summary & Architecture

The Sentinel live-call protection subsystem in ScamShield 2.0 connects the Flutter Android mobile application with the shared FastAPI backend (`https://scamshield-backend-f0wc.onrender.com`).

All mobile call intelligence routes reuse the established production server, persistent PostgreSQL database, and ChromaDB vector store. There is zero duplication of backend intelligence services, zero simulated or random risk scores, and all endpoints enforce authenticated, account-scoped authorization.

```
+--------------------------------------------------------------------------------------------------------+
|                                    ScamShield Sentinel Data Flow                                       |
+--------------------------------------------------------------------------------------------------------+
   [ Android OS PhoneState / Mic / Speakerphone ]
                    │
                    ▼
   [ CallStateGuardianService.kt / CallBridge ] (Canonical UUIDv4 session_id)
                    │
                    ├──────────────────────────────────────────────────────┐
                    │                                                      │
                    ▼ (5s Bounded PCM 16kHz)                               ▼ (Metadata)
   [ POST /guardian/transcription/chunk ]                     [ Local UI State Machine ]
                    │ (Faster-Whisper int8)                                │
                    ▼                                                      │
       { transcript segment }                                             │
                    │                                                      │
                    ▼                                                      │
   [ POST /guardian/analysis/segment ]                                     │
                    │ (Text Normalization + Regex Indicators)             │
                    │ (ChromaDB cosine RAG retrieval, KB collection)      │
                    │ (ML Classifier / Probabilities)                     │
                    │ (LLM Grounded Reasoning & Localization)             │
                    ▼                                                      │
       { risk_level, severity, indicators, safe_actions }                 │
                    │                                                      │
                    ▼                                                      │
   [ Live Alerts & UI Updates ] <──────────────────────────────────────────┘
                    │
                    │ (Call Ended)
                    ▼
   [ POST /guardian/transcription/session/{id}/finalize ]
   [ POST /guardian/analysis/session/{id}/finalize ]
   [ POST /calls/finalize ] (Idempotent, Persisted to PostgreSQL)
                    │
                    ▼
   [ GET /calls/history & GET /calls/{id} ] -> [ Call Report & History Screen ]
```

---

## 2. Exhaustive Endpoint Specifications

### A. Guardian Audio Transcription Chunk Ingestion

- **Route:** `POST /guardian/transcription/chunk`
- **Controller/Module:** `backend/guardian_transcription.py`
- **Authentication:** Bearer JWT (`HTTPBearer` via `get_current_active_user`)
- **Authorization:** Derives `user_id` strictly from JWT token claims.

#### Request Schema
```json
{
  "session_id": "c9a0b123-4567-89ab-cdef-0123456789ab",
  "sequence": 1,
  "start_time": 0.0,
  "end_time": 5.0,
  "audio_base64": "<base64-encoded 16kHz 16-bit mono PCM>",
  "sample_rate": 16000,
  "channels": 1,
  "audio_format": "pcm_s16le",
  "source": "SPEAKERPHONE_AUDIO"
}
```

#### Response Schema (`200 OK`)
```json
{
  "session_id": "c9a0b123-4567-89ab-cdef-0123456789ab",
  "segment_id": "seg_1_1729851600",
  "sequence": 1,
  "start_time": 0.0,
  "end_time": 5.0,
  "text": "Hello, I am calling from the national lottery reward center.",
  "is_final": true,
  "language": "en",
  "created_at": "2026-10-31T05:00:00Z",
  "source": "SPEAKERPHONE_AUDIO"
}
```

#### Idempotency & Error Handling
- **Duplicate Prevention:** In-memory LRU deduplication cache (`_seen_chunk_keys`) tracks `(session_id, sequence)`. Re-transmitting an identical sequence returns the cached segment immediately.
- **Queue Bounds:** Max 2 concurrent chunk processing requests per session. Backpressure drops excess chunks with status code `429 Too Many Requests` or structured fallback rather than crashing worker threads.
- **Speech Absent:** When audio contains silence/background noise below energy threshold, returns empty text with `"is_final": true` without fabricating words.

---

### B. Guardian Real-Time Analysis Segment

- **Route:** `POST /guardian/analysis/segment`
- **Controller/Module:** `backend/guardian_analysis.py`
- **Authentication:** Bearer JWT (`HTTPBearer`)
- **Authorization:** Verifies user access and matches `session_id`.

#### Request Schema
```json
{
  "session_id": "c9a0b123-4567-89ab-cdef-0123456789ab",
  "segment_id": "seg_1_1729851600",
  "sequence": 1,
  "text": "You have won a prize of 50,000 rupees. Please share your bank account details and OTP to claim it.",
  "is_final": true,
  "language": "en",
  "source": "SPEAKERPHONE_AUDIO",
  "timestamp": "2026-10-31T05:00:00Z"
}
```

#### Processing Pipeline in Endpoint:
1. **Normalization:** Case folding, whitespace trimming, script preservation for mixed English, Hindi (Devanagari/Hinglish), and Telugu.
2. **Indicator Extraction:** Scans for high-risk pattern markers: OTP, PIN, password, banking, lottery, urgent action, remote access (AnyDesk, TeamViewer), government/police impersonation.
3. **ChromaDB RAG Retrieval:** Uses the transcript segment as a vector query against the existing `scamshield_knowledge` collection (cosine distance threshold >= 0.3).
4. **Authoritative Classifier:** Feeds text and retrieved context into the calibrated risk engine.
5. **Multilingual Safety Generation:** Produces localized actionable advice for English, Hindi, and Telugu.

#### Response Schema (`200 OK`)
```json
{
  "session_id": "c9a0b123-4567-89ab-cdef-0123456789ab",
  "segment_id": "seg_1_1729851600",
  "sequence": 1,
  "risk_score": 92,
  "risk_level": "HIGH",
  "classification": "SCAM",
  "scam_category": "LOTTERY_PRIZE_SCAM",
  "detected_indicators": [
    "Prize Claim",
    "Bank Details",
    "Urgent Action",
    "OTP Request"
  ],
  "reasoning": "The caller claimed a prize reward and requested personal banking details and OTP, matching known financial phishing patterns.",
  "supporting_evidence": [
    {
      "source_id": "kb_lottery_fraud_04",
      "title": "Advance Fee & Lottery Prize Fraud Schemes",
      "similarity": 0.88
    }
  ],
  "safe_actions": [
    "Do not share any personal or banking details.",
    "Do not share OTP or passwords.",
    "Hang up immediately and block this caller."
  ],
  "action_translations": {
    "hi": [
      "कोई भी व्यक्तिगत या बैंक विवरण साझा न करें।",
      "ओटीपी या पासवर्ड कभी साझा न करें।",
      "कॉल तुरंत काटें और इस नंबर को ब्लॉक करें।"
    ],
    "te": [
      "వ్యక్తిగత లేదా బ్యాంకింగ్ వివరాలను పంచుకోవద్దు.",
      "ఓటీపీ లేదా పాస్‌వర్డ్‌లను ఎవరికీ చెప్పవద్దు.",
      "కాల్ వెంటనే ముగించి, ఈ నంబర్‌ను బ్లాక్ చేయండి."
    ]
  },
  "status": "ANALYSIS_ACTIVE"
}
```

---

### C. Guardian Transcription Session Finalization

- **Route:** `POST /guardian/transcription/session/{session_id}/finalize`
- **Controller/Module:** `backend/guardian_transcription.py`
- **Authentication:** Bearer JWT

#### Request Schema
```json
{
  "session_id": "c9a0b123-4567-89ab-cdef-0123456789ab",
  "ended_at": "2026-10-31T05:03:25Z",
  "total_chunks_sent": 41
}
```

#### Response Schema (`200 OK`)
```json
{
  "session_id": "c9a0b123-4567-89ab-cdef-0123456789ab",
  "status": "COMPLETED",
  "total_segments": 38,
  "dropped_chunks": 3,
  "complete_transcript": "Hello, I am calling from the national lottery reward center...",
  "primary_language": "en"
}
```

---

### D. Guardian Analysis Session Finalization

- **Route:** `POST /guardian/analysis/session/{session_id}/finalize`
- **Controller/Module:** `backend/guardian_analysis.py`
- **Authentication:** Bearer JWT

#### Response Schema (`200 OK`)
```json
{
  "session_id": "c9a0b123-4567-89ab-cdef-0123456789ab",
  "status": "COMPLETED",
  "final_risk_score": 92,
  "final_risk_level": "HIGH",
  "classification": "SCAM",
  "scam_category": "LOTTERY_PRIZE_SCAM",
  "detected_indicators": [
    "Prize Claim",
    "Bank Details",
    "Urgent Action",
    "OTP Request",
    "Scam Pattern Match"
  ],
  "reasoning": "The caller claimed a prize reward of ₹50,000 and demanded bank details and OTP. This exactly matches known advance-fee lottery fraud.",
  "supporting_evidence": [...],
  "safe_actions": [...],
  "action_translations": {...}
}
```

---

### E. Idempotent Call Finalization & Database Persistence

- **Route:** `POST /calls/finalize`
- **Controller/Module:** `backend/calls.py`
- **Authentication:** Bearer JWT
- **Database Table:** `call_history`

#### Request Schema
```json
{
  "session_id": "c9a0b123-4567-89ab-cdef-0123456789ab",
  "started_at": "2026-10-31T05:00:00Z",
  "ended_at": "2026-10-31T05:03:25Z",
  "duration_seconds": 205,
  "phone_number": "+91 98765 43210",
  "caller_type": "Unknown Number",
  "final_risk_score": 92,
  "final_risk_level": "HIGH",
  "classification": "SCAM",
  "scam_category": "LOTTERY_PRIZE_SCAM",
  "analysis_status": "COMPLETED",
  "transcription_status": "COMPLETED",
  "audio_status": "SPEAKERPHONE_CAPTURED",
  "guardian_enabled": true,
  "guardian_status": "RUNNING",
  "risk_reasoning": "The caller claimed a prize reward and asked for personal and banking details.",
  "safe_action": "Do not share any personal or banking details. Block and report this number.",
  "detected_indicators": [
    "Prize Claim",
    "Bank Details",
    "Urgent Action",
    "Unknown Number",
    "Scam Pattern Match"
  ],
  "supporting_evidence": [
    {"source": "kb_lottery_fraud_04", "title": "Advance Fee Fraud", "score": 0.88}
  ],
  "protection_actions": [
    {"action": "Do not share any personal or banking details."},
    {"action": "Do not make any payments."},
    {"action": "Block and report this number."}
  ]
}
```

#### Idempotency Behavior:
- Checks if a record with `(user_id, session_id)` already exists in `call_history`.
- If existing: Updates timestamps and final status if not already completed, preventing duplicate records.
- Returns the persisted record with canonical integer ID.

#### Response Schema (`200 OK`)
```json
{
  "id": 142,
  "session_id": "c9a0b123-4567-89ab-cdef-0123456789ab",
  "user_id": 12,
  "final_risk_score": 92,
  "final_risk_level": "HIGH",
  "classification": "SCAM",
  "scam_category": "LOTTERY_PRIZE_SCAM",
  "duration_seconds": 205,
  "started_at": "2026-10-31T05:00:00Z",
  "ended_at": "2026-10-31T05:03:25Z",
  "created_at": "2026-10-31T05:03:26Z"
}
```

---

### F. Call History Retrieval & Single Call Detail

- **Routes:**
  - `GET /calls/history?page=1&limit=20`
  - `GET /calls/{session_id}`
  - `GET /calls/detail/{id}`
- **Controller/Module:** `backend/calls.py`
- **Authentication:** Bearer JWT
- **Authorization:** Scoped exclusively to `WHERE user_id = current_user.id`. Requests for other users' sessions return `404 Not Found` or `403 Forbidden`.
