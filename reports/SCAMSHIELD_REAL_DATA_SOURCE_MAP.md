# ScamShield — Real-Data Source of Truth Map
**Document Type:** Authoritative Data Source & Field Mapping Specification  
**Application Target:** Mobile App (Flutter) & Shared FastAPI Backend  
**Date:** October 25, 2026  
**Policy:** Zero Mock Data • Zero Fabricated Stats • Zero Synthesized Evidence  

---

## 1. Overview & Data Integrity Rules
In accordance with Rule 5 of the Master Prompt ("Real data only"), every dynamic value, statistic, risk metric, status badge, and history item displayed across the ScamShield mobile application must originate from an authoritative backend API endpoint or verified local hardware platform event.

**Strict Prohibitions:**
- No static placeholder integers for "Threats Blocked" or "Scams Prevented".
- No random number generation for risk scores or model confidences.
- No dummy analysis history or simulated call records in production builds.
- No synthetic community engagement stats or fake user testimonials.

---

## 2. Global Real-Data Field Mapping

| UI Screen | Dynamic Field / Component | Authoritative Source of Truth | Transport / Protocol | Fallback / Empty Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **Auth / Shell** | Current User ID, Full Name, Email, Role, Email Verified | `GET /api/auth/me` or decrypted payload of JWT returned by `POST /api/auth/login` | Bearer Token in `Authorization` header | Redirects to `LandingScreen` / `AuthenticationScreen` on 401 |
| **Auth / Shell** | Admin Access Rights | `GET /api/auth/me` role check (`role == 'admin'`) + 2FA verified challenge | Bearer Token in `Authorization` header | Forbidden (403) error dialog; access denied |
| **Home Dashboard** | Total Analyses Count | `GET /api/analysis/dashboard` -> `total_analyses` | REST JSON (Authenticated) | Display `0` with "No analyses yet" prompt |
| **Home Dashboard** | Scams Detected Count | `GET /api/analysis/dashboard` -> `scams_detected` | REST JSON (Authenticated) | Display `0` |
| **Home Dashboard** | Safe Messages Count | `GET /api/analysis/dashboard` -> `safe_messages` | REST JSON (Authenticated) | Display `0` |
| **Home Dashboard** | High Risk Detections Count | `GET /api/analysis/dashboard` -> `high_risk` | REST JSON (Authenticated) | Display `0` |
| **Home Dashboard** | Recent Analyses List | `GET /api/analysis/history` (sliced to top 5) | REST JSON (Authenticated) | Display "No recent activity" empty state card |
| **Home Dashboard** | Live Call Guardian Status | `CallBridge.getCallGuardianStatus()` | Android Native MethodChannel (`com.scamshield/native`) | "Protection Inactive" with permission request trigger |
| **Home Dashboard** | Active Call Duration Timer | Real-time stopwatch ticking from `GuardianCallEvent.timestamp` when state is `OFFHOOK` | Platform Event Channel (`com.scamshield/native/callEvents`) | Timer resets to `00:00` upon `IDLE` state |
| **Analyze Input** | File Size Limit & Extension Validation | Client-side validation: Max 10MB (Image), 20MB (PDF), 25MB (Audio) before upload | Local Device Filesystem / `file_picker` | Immediate local validation message; blocks submission |
| **Analysis Result** | Overall Risk Score (0-100) | `schemas.AnalysisResponse.risk_score` from `POST /api/analysis/{type}` | REST JSON (Multipart / JSON) | "Unavailable" if API error occurs; retry permitted |
| **Analysis Result** | Risk Level Classification | `schemas.AnalysisResponse.risk_level` (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`) | REST JSON (Multipart / JSON) | Display neutral badge with error details |
| **Analysis Result** | Classification Label | `schemas.AnalysisResponse.classification` (`SCAM`, `SUSPICIOUS`, `GENUINE`, `INCONCLUSIVE`) | REST JSON | Displays raw classification from backend |
| **Analysis Result** | Scam Category | `schemas.AnalysisResponse.category` (e.g. `Bank & KYC`, `Lottery`, `Phishing`, `Job Scam`) | REST JSON | "Uncategorized" |
| **Analysis Result** | Detected Indicators | `schemas.AnalysisResponse.indicators` (List of strings) | REST JSON | Hide section if empty list returned |
| **Analysis Result** | Retrieved Knowledge Evidence | `schemas.AnalysisResponse.retrieved_evidence_data` (List of evidence records) | REST JSON | Hide evidence section if no matches found |
| **Analysis Result** | Reasoning / Explanation | `schemas.AnalysisResponse.explanation` | REST JSON | Omit card if null or empty |
| **Analysis Result** | Machine Learning Probability | `schemas.AnalysisResponse.ml_probability` (0.0 to 1.0) | REST JSON | Hidden if null |
| **Analysis Result** | LLM Confidence Score | `schemas.AnalysisResponse.llm_confidence` (0.0 to 1.0) | REST JSON | Hidden if null |
| **Analysis Result** | Recommended Safe Action | `schemas.AnalysisResponse.safe_actions` (`canonical` list) or `recommended_action` | REST JSON | Display generic safety advisory if missing |
| **Analysis History** | Historic Analysis Records | `GET /api/analysis/history` | REST JSON (Authenticated) | Display clean empty state with "Analyze Now" button |
| **Analysis History** | Filter by Classification / Risk | Client-side filter applied to authenticated `AnalysisRecord` list | In-memory filtering of real records | Displays "No matching records found" |
| **Live Call Guardian** | Telephony Call State | `TelephonyManager` / `CallScreeningService` native event | Android EventChannel (`com.scamshield/native/callEvents`) | Displays `IDLE` when no call is active |
| **Live Call Guardian** | Microphone Capture Pipeline | `AudioRecord` streaming PCM bytes to `GuardianAudioPipeline` | Android EventChannel (`com.scamshield/native/audioEvents`) | Displays "Audio Capture Inactive" |
| **Live Call Guardian** | Live Speech Transcript | `POST /api/guardian/transcribe` -> `transcript` | REST JSON (Authenticated chunk payload) | Empty transcript placeholder ("Listening...") |
| **Live Call Guardian** | Live Risk Analysis & Alerts | `POST /api/guardian/analyze` -> `risk_score`, `indicators`, `alert` | REST JSON (Authenticated) | Displays "Monitoring for risk..." |
| **Protected Calls** | Finalized Call History | `GET /api/calls/history?page=1&limit=20` | REST JSON (Authenticated) | "No protected calls recorded yet" |
| **Protected Calls** | Call Detail / Summary | `GET /api/calls/{session_id}` | REST JSON (Authenticated) | 404 / 403 error page if not owned by user |
| **User Profile** | User Details (Name, Email, Role) | Authenticated `User` model restored from secure session | Secure Storage / `GET /api/auth/me` | Prompt to sign in if session invalid |
| **Settings** | Theme Preference | Key `scamshield_theme_mode` in `FlutterSecureStorage` | Local Secure Key-Value | Default to system preference |
| **Community** | Community Posts / Reports | Currently unsupported on mobile client | N/A | Honest "Coming Soon" dialog — zero fake posts |

---

## 3. Guardian Hardware & Runtime State Authority
The Live Call Guardian state cannot be synthesized. It is governed strictly by the Android device lifecycle:

```
[Device Hardware]
      │
      ├── Android Telephony State ────► CallStateGuardianService / ScamShieldCallScreeningService
      │                                       │
      ├── AudioRecord (Microphone) ────► GuardianAudioPipeline (16kHz PCM mono)
      │                                       │
      ▼                                       ▼
  MethodChannel / EventChannel ◄────── Native Bridge (MainActivity.kt)
      │
      ▼
  Dart CallBridge ────► GuardianAudioService ────► GuardianTranscriptionService
                                                                │
                                                                ▼
                                                   POST /api/guardian/transcribe
                                                                │
                                                                ▼
                                                   POST /api/guardian/analyze
                                                                │
                                                                ▼
                                                    POST /api/calls/finalize
```

---

## 4. Verification Checkpoint
All endpoints referenced in this map have been validated against:
- `backend/analysis.py` (Lines 61-189)
- `backend/calls.py` (Lines 19-161)
- `backend/guardian_transcription.py` & `backend/guardian_analysis.py`
- `mobile_app/lib/services/api_service.dart` & `analysis_service.dart`
- Tested and verified passing with `pytest` and `flutter test`.
