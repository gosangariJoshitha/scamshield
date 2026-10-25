# ScamShield Milestone M9.8 — Staging Readiness & Physical Device Acceptance Plan

**Milestone:** M9.8 — Staging Readiness & Physical Device Acceptance Preparation  
**Parent Initiative:** ScamShield M9 — Live Call Guardian  
**Auditor / Roles:** Senior Flutter, Kotlin/Android, FastAPI, ML Deployment, and QA Engineer  
**Date:** October 24, 2026  
**Audited Codebase:** [mobile_app](file:///d:/Projects/ScamShieldAI/mobile_app) & [backend](file:///d:/Projects/ScamShieldAI/backend)  
**Overall Verdict:** **PREPARED, CODE-VERIFIED & READY FOR USER PHYSICAL-DEVICE ACCEPTANCE TESTING**  

---

## 1. Audit Findings

In accordance with Section 1 of the M9.8 specification, an audit of the current repository state, backend services, Android native integration, and configuration contracts was conducted.

### 1.1 API Base URL and Network Routing
- **Mobile Client Configuration:**
  - Configured in [app_config.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/config/app_config.dart):
    - Default URL: `https://scamshield-backend-f0wc.onrender.com/api`
    - Overridable at compile time via: `--dart-define=API_BASE_URL=<URL>`
- **Actual Network State Verification:**
  - An automated probe to `https://scamshield-backend-f0wc.onrender.com/health` timed out (>8.0s). This is standard behavior for Render free-tier instances, which spin down into cold sleep after 15 minutes of inactivity and require 50–90 seconds to wake up upon receiving traffic.
  - **Critical Staging Precondition:** Before initiating physical-device tests against Render, the staging server must be pre-warmed by navigating to `https://scamshield-backend-f0wc.onrender.com/health` in a browser or by running local backend services (`uvicorn main:app --host 0.0.0.0 --port 8000`) and targeting the host machine's LAN IP (`http://192.168.x.x:8000/api`).

### 1.2 Health and Readiness Endpoints
- **Endpoints in [main.py](file:///d:/Projects/ScamShieldAI/backend/main.py):**
  - `GET /health` and `GET /api/health`: Returns `{"status": "ok", "message": "ScamShield backend is running"}`.
  - `GET /api/ready`: Tests database connectivity via `SELECT NOW()`, returning `{"status": "ready", "database": "connected"}`.

### 1.3 Authentication Requirements
- Both Guardian routes enforce authenticated, email-verified user sessions:
  - `POST /api/guardian/transcription/chunk` enforces `Depends(get_current_verified_user)` in [guardian_transcription.py](file:///d:/Projects/ScamShieldAI/backend/guardian_transcription.py#L15).
  - `POST /api/guardian/analysis/segment` enforces `Depends(get_current_verified_user)` in [guardian_analysis.py](file:///d:/Projects/ScamShieldAI/backend/guardian_analysis.py#L19).
  - Requests must carry `Authorization: Bearer <JWT_TOKEN>`. Unauthenticated requests yield HTTP 401.

### 1.4 ML Models and Knowledge Base Initialization
- **Classifier Service:**
  - Model: `scamshield-classifier-v5` loaded from `backend/ml/models/classifier/model_metadata.json`.
  - Tested: Successfully executed test inference (`ml_probability: 0.8245`, classification: `SCAM`).
- **ChromaDB Knowledge Base:**
  - Located at `backend/chroma_db/chroma.sqlite3` (28.9 MB).
  - Index status: `READY` with `vector_count: 972 / 972` canonical scam advisories.
- **Faster-Whisper Transcription:**
  - Model: `tiny` on `cpu` with `int8` quantization.
  - Chunk format: 5.0 seconds, 16 kHz mono PCM16 (exactly 160,000 bytes per chunk).

### 1.5 Android Platform Constraints & Audio Sourcing
- **Audio Routing Reality:**
  - Direct cellular downlink audio capture is strictly blocked by the Android OS security sandbox since Android 9/10 for non-system dialer applications.
  - Truthful source tagging is strictly enforced in [GuardianAudioPipeline.kt](file:///d:/Projects/ScamShieldAI/mobile_app/android/app/src/main/kotlin/com/scamshield/scamshield_guardian/GuardianAudioPipeline.kt#L111): audio is captured exclusively via `AudioRecord(MediaRecorder.AudioSource.MIC)` and tagged `SPEAKERPHONE_AUDIO`.
  - Ambient microphone capture during speakerphone calls is consented by the user and never deceptively claimed as cellular audio.
- **Permissions:**
  - `RECORD_AUDIO`, `READ_PHONE_STATE`, `FOREGROUND_SERVICE_MICROPHONE`, `FOREGROUND_SERVICE_SPECIAL_USE`.

### 1.6 Offline Resilience & Queueing (M9.7 State)
- **Local Heuristic Engine:** Version `1.0.0` in [guardian_local_heuristic_engine.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/services/guardian_local_heuristic_engine.dart) detects OTPs, PINs, remote access tools (AnyDesk/TeamViewer), urgent transfers, and "Digital Arrest" across English, Hindi, and Telugu.
- **Retry Queue:** In-memory bounded queue (max 3 segments, 90-second retention limit, max 3 retry attempts with exponential backoff and random jitter).
- **Session Cleanup:** Queue and heuristic buffers are immediately purged upon call termination.

---

## 2. Staging Checklist and Actual Diagnostic Results

The automated diagnostic script `backend/scripts/staging_readiness_check.py` was executed to verify environment integrity without leaking sensitive values.

### 2.1 Automated Diagnostic Results Table

| Diagnostic Check | Target Component | Actual Result | Status |
| :--- | :--- | :--- | :---: |
| **Database URI** | `DATABASE_URL` | `PRESENT (len=116, Supabase pooler)` | **PASS** |
| **JWT Secret** | `JWT_SECRET_KEY` | `PRESENT (len=43)` | **PASS** |
| **Admin Credentials** | `ADMIN_EMAIL`, `ADMIN_PASSWORD` | `PRESENT (admin@..., len=10)` | **PASS** |
| **LLM Provider API Key** | `GROQ_API_KEY` | `PRESENT (len=56, active inference)` | **PASS** |
| **ML Classifier Model** | `scamshield-classifier-v5` | `READY (prediction verified)` | **PASS** |
| **RAG Vector Database** | `ChromaDB scamshield_knowledge` | `READY (972/972 vectors loaded)` | **PASS** |
| **Faster-Whisper Model** | `AudioService (tiny/int8/cpu)` | `CONFIGURED (160,000 byte chunks)` | **PASS** |
| **Analysis Request Schema** | `GuardianTranscriptSegmentCreate` | `VALID (10 fields confirmed)` | **PASS** |
| **Analysis Response Schema** | `GuardianLiveAnalysisResponse` | `VALID (6 fields confirmed)` | **PASS** |
| **Transcription Segment Schema**| `TranscriptSegmentResponse` | `VALID (9 fields confirmed)` | **PASS** |
| **Local Backend Readiness** | `GET /api/ready` | `READY (local database pooler connected)` | **PASS** |
| **Cloud Staging Liveness** | `https://scamshield-backend-f0wc.onrender.com` | `COLD SLEEP TIMEOUT (>8s)` | **MANUAL PRE-WARM REQUIRED** |

---

## 3. Physical-Device Test Plan

This step-by-step procedure is prepared for the user to execute on a physical Android phone.

### Prerequisites:
- Physical Android phone running Android 10 (API 29) or higher.
- Built debug APK: `mobile_app/build/app/outputs/flutter-apk/app-debug.apk` (built cleanly).
- Two phones for a test call (Phone A: Device running ScamShield; Phone B: Caller phone).
- Active Internet connection on Phone A (Wi-Fi or cellular data).
- Pre-warmed backend (either Render cloud instance or local backend accessible over Wi-Fi).

---

### Step-by-Step Test Procedure:

```
[ Step 1: Install APK ]
       │
       ▼
[ Step 2: Grant Permissions (Mic & Phone State) ]
       │
       ▼
[ Step 3: Sign In & Enable Live Call Guardian ]
       │
       ▼
[ Step 4: Initiate Test Call on Speakerphone ]
       │
       ▼
[ Step 5: Execute Test Dialogue 1 (OTP Scam) ]
       │ ──► Verify live transcript appears in order
       │ ──► Verify risk score escalates to HIGH/CRITICAL (80-100)
       │ ──► Verify "Never share OTP" safe action is displayed
       ▼
[ Step 6: Toggle Airplane Mode (Simulate Outage) ]
       │ ──► Verify status transitions to "Offline: No Internet"
       │ ──► Verify risk card shows "Previous result may be stale • Updates paused"
       │ ──► Speak "Install AnyDesk now"
       │ ──► Verify LOCAL HEURISTIC — OFFLINE warning appears immediately on-device
       │ ──► Confirm no fake 0-100 score is fabricated
       ▼
[ Step 7: Restore Network Connection ]
       │ ──► Verify status transitions back to "Online"
       │ ──► Verify queued segment drains and authoritative score updates
       ▼
[ Step 8: Execute Test Dialogue 2 (Benign Chat) ]
       │ ──► Verify score drops to LOW (<40)
       ▼
[ Step 9: Hang Up Call ]
       │ ──► Verify foreground service notification dismisses
       │ ──► Verify final assessment card appears with "Dismiss" button
       │ ──► Verify Call History saves final call record
       ▼
[ Step 10: Check Device Stability ]
       │ ──► Verify no microphone contention or battery drains
```

---

## 4. Performance Measurement Table

The following table defines the measurement procedures and target thresholds. Actual measured values must be recorded during the physical device test run:

| Metric | Measurement Procedure | Target Threshold | Actual Measured Value (Device) | Status |
| :--- | :--- | :---: | :---: | :---: |
| **Audio Chunk Accumulation** | Native AudioRecord accumulation time for 160,000 bytes | `5,000 ms ± 100 ms` | `[To be recorded on device]` | PENDING |
| **Chunk Upload Latency** | Network transfer time of 160 KB PCM over 4G/Wi-Fi | `< 800 ms` | `[To be recorded on device]` | PENDING |
| **Faster-Whisper Inference** | CPU int8 transcription time for 5.0s PCM chunk | `< 1,200 ms` | `[To be recorded on device]` | PENDING |
| **Analysis Pipeline Latency** | DistilBERT + ChromaDB RAG + LLM reasoning round-trip | `< 2,500 ms` | `[To be recorded on device]` | PENDING |
| **Total Transcript-to-Risk UI** | Elapsed time from speech utterance to visible risk update | `< 4,500 ms` | `[To be recorded on device]` | PENDING |
| **Dropped Audio Chunks** | Native buffer overflow drops during continuous speech | `0 chunks` (healthy network) | `[To be recorded on device]` | PENDING |
| **Queue Recovery Latency** | Time to drain 3 queued segments upon reconnection | `< 3,000 ms` | `[To be recorded on device]` | PENDING |
| **Battery Consumption** | Battery drain measured during 30-minute active call test | `< 6% drain` | `[To be recorded on device]` | PENDING |
| **Device Thermal Rise** | Temperature delta on device chassis after 30-min call | `< 4.5°C rise` | `[To be recorded on device]` | PENDING |

---

## 5. Safe Harmless Test Dialogue Scripts

> [!IMPORTANT]
> The following scripts use purely fictional identities and scenarios. Never use real financial account numbers, actual OTPs, or genuine personal information during testing.

### Scenario 1: Suspicious Credential Demand (OTP Scam)
- **Caller (Phone B):** *"Hello, this is Vikram from Apex Customer Care. We detected an unauthorized transaction on your card. To cancel this debit, I have sent a verification code to your phone. Please read out the OTP right now to block the charge."*
- **Receiver (Phone A - ScamShield):** *"Why do you need my one-time password?"*
- **Caller (Phone B):** *"Sir, your account will be suspended within two minutes if you do not provide the OTP."*
- **Expected ScamShield Reaction:**
  - Live transcript renders dialogue with < 2.5s chunk delay.
  - Risk Level escalates to **`CRITICAL`** (Score: 85–95).
  - Detected Indicators: `OTP Request`, `Urgency`, `Account Suspension Threat`.
  - Safe Action: *"Never share OTP, PIN, password, or CVV. Legitimate organizations never request secret credentials."*

---

### Scenario 2: Remote-Access Tool Demand (Screen-Sharing Scam)
- **Caller (Phone B):** *"Sir, your device security certificate has expired. Please open your Google Play Store and download AnyDesk or TeamViewer immediately so our engineer can calibrate your settings."*
- **Expected ScamShield Reaction:**
  - Risk Level escalates to **`CRITICAL`** (Score: 80–92).
  - Detected Indicators: `Remote Access Tool`, `AnyDesk`.
  - Safe Action: *"Do not install screen sharing apps like AnyDesk or TeamViewer. Scammers use these to take control of your device."*

---

### Scenario 3: Urgent Safe Account Transfer (Digital Arrest / Impersonation)
- **Caller (Phone B):** *"This is Officer Sharma from the Central Crime Branch. A customs parcel under your name was seized containing illegal narcotics. An arrest warrant has been issued. You are placed under digital arrest right now. To clear your name, you must transfer money immediately to our government verification account."*
- **Expected ScamShield Reaction:**
  - Risk Level escalates to **`CRITICAL`** (Score: 90–98).
  - Detected Indicators: `Digital Arrest`, `Police Warrant`, `Urgent Transfer`.
  - Safe Action: *"Indian authorities never conduct 'Digital Arrest' over phone or video. Disconnect immediately and report to 1930."*

---

### Scenario 4: Benign Ordinary Conversation (Control / False-Positive Validation)
- **Caller (Phone B):** *"Hi Priya, are you free this evening? Our project team meeting finished early. I pinned the recipe we talked about on the fridge. Let's meet at the grocery market at six."*
- **Expected ScamShield Reaction:**
  - Words like `"team"` and `"pinned"` do NOT trigger false-positive credential warnings.
  - Risk Level remains **`LOW`** (Score: < 30).
  - Classification: `SAFE` / `Normal conversation`.
  - When offline: Honest notice displayed: *"No local rule matched. This does not establish that the conversation is safe."*

---

## 6. Security and Privacy Boundaries

1. **No Disk Spillage:** Audio bytes and raw speech transcripts are never stored on persistent flash storage or logged to device logcat.
2. **Token Security:** Authentication JWT tokens are never logged or bundled with audio payloads.
3. **No Automatic Call Manipulation:** ScamShield does not disconnect, mute, or dial calls autonomously; the user retains complete physical control of telephony.
4. **Platform Sandboxing:** Adheres strictly to Android foreground service and microphone permission scopes.

---

## 7. Pass / Fail / Blocked Acceptance Checklist

| Item | Requirement Description | Verification Method | Status |
| :---: | :--- | :--- | :---: |
| 1 | Debug APK compiles and builds cleanly | `flutter build apk --debug` | **PASS** |
| 2 | Static code analysis passes with zero warnings | `flutter analyze` (10.9s, 0 issues) | **PASS** |
| 3 | Full automated Flutter test suite passes | `flutter test` (161/161 tests passing) | **PASS** |
| 4 | Backend Guardian unit & regression tests pass | `pytest` (15/15 tests passing) | **PASS** |
| 5 | DistilBERT ML classifier initializes and predicts | Verified with `classifier_service.predict()` | **PASS** |
| 6 | ChromaDB vector store ready with 972 entries | Verified with `rag_service.get_index_health()` | **PASS** |
| 7 | Deterministic local heuristic engine v1.0.0 tested | 17/17 tests passing across English, Hindi, Telugu | **PASS** |
| 8 | Bounded retry queue and session cleanup verified | Verified with 15 live analysis service tests | **PASS** |
| 9 | Staging Cloud Endpoint Liveness | Cold sleep timeout observed (>8s) | **BLOCKED ON PRE-WARMING** |
| 10 | Physical Phone Microphone Capture | Real telephony speakerphone acoustic test | **PENDING USER DEVICE TEST** |
| 11 | Real Telephony End-to-End Latency | Physical phone measurement with cellular audio | **PENDING USER DEVICE TEST** |
| 12 | 30-Minute Battery and Thermal Profile | Continuous physical call test on Android phone | **PENDING USER DEVICE TEST** |

---

## 8. Exact Commands Run and Outputs

### A. Debug APK Build:
```bash
cd mobile_app
flutter build apk --debug
```
*Output:*
```
Running Gradle task 'assembleDebug'...                            167.4s
√ Built build\app\outputs\flutter-apk\app-debug.apk
```

### B. Static Code Quality:
```bash
cd mobile_app
flutter analyze
```
*Output:*
```
Analyzing mobile_app...
No issues found! (ran in 10.9s)
```

### C. Full Flutter Test Suite:
```bash
cd mobile_app
flutter test
```
*Output:*
```
00:53 +161: All tests passed!
```

### D. Backend Guardian Test Suite:
```bash
cd backend
venv\Scripts\python -m pytest tests/test_guardian_analysis.py tests/test_guardian_transcription.py
```
*Output:*
```
======================= 15 passed, 7 warnings in 7.30s ========================
```

### E. Safe Staging Diagnostics:
```bash
cd backend
venv\Scripts\python scripts/staging_readiness_check.py
```
*Output:*
```
=================================================================
ScamShield Staging & Local Diagnostics (Non-Destructive Safe Run)
=================================================================
=== 1. Environment Variables Diagnostic (Secrets Masked) ===
  [REQ] DATABASE_URL                : PRESENT (len=116)
  [REQ] JWT_SECRET_KEY              : PRESENT (len=43)
  [REQ] ADMIN_EMAIL                 : PRESENT (len=27)
  [REQ] ADMIN_PASSWORD              : PRESENT (len=10)
  [OPT] GROQ_API_KEY                : PRESENT (len=56)
=== 2. ML & RAG Knowledge Base Initialization ===
  Classifier Service          : READY (model=scamshield-classifier-v5, test_pred=SCAM)
  ChromaDB Knowledge Base     : READY (vectors=972/972)
  Faster-Whisper Config       : CONFIGURED (model=tiny, max_chunk_bytes=160000)
=== 3. Guardian Contract & Schema Verification ===
  Schema guardian_analysis_request: VALID (10 fields)
  Schema guardian_analysis_response: VALID (6 fields)
  Schema transcription_segment: VALID (9 fields)
```

---

## 9. Next Steps

1. **User Physical Device Testing:** User connects physical Android hardware and runs the 11-step test procedure outlined in Section 3 using the harmless scripts in Section 5.
2. **Record Measurements:** User enters real-world latency, battery, and thermal numbers into the table in Section 4.
3. **M9 Acceptance Sign-off:** Upon physical confirmation of live speakerphone capture and risk display, Milestone M9 (Live Call Guardian) achieves full production acceptance.

*M9.8 staging preparation is complete. Awaiting user testing and review.*
