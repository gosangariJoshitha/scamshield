# ScamShield Milestone M9.7 Implementation and Verification Report

**Milestone:** M9.7 — Offline-First Fallback & Network Resilience  
**Parent Initiative:** ScamShield M9 — Live Call Guardian  
**Auditor / Roles:** Senior Flutter, Android Kotlin, FastAPI, ML Integration, and Application Security Engineer  
**Date:** October 24, 2026  
**Audited Codebase:** [mobile_app](file:///d:/Projects/ScamShieldAI/mobile_app) & [backend](file:///d:/Projects/ScamShieldAI/backend)  
**Overall Verdict:** **IMPLEMENTED, VERIFIED & PASSING ALL AUTOMATED TEST SUITES (161/161 FLUTTER, 15/15 BACKEND)**  

---

## 1. Audit Findings

In accordance with Phase A of the M9.7 specification, an initial audit was conducted across Flutter services, presentation widgets, native Android services, and backend APIs:

### 1.1 Inspected Components
- **Flutter Live Analysis & Transcription Services:**
  - [guardian_live_analysis_service.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/services/guardian_live_analysis_service.dart)
  - [guardian_transcription_service.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/services/guardian_transcription_service.dart)
  - [guardian_audio_service.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/services/guardian_audio_service.dart)
  - [api_service.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/services/api_service.dart)
- **Active-Call Presentation & Protection Widgets:**
  - [guardian_live_risk_card.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/widgets/guardian_live_risk_card.dart)
  - [guardian_protection_panel.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/widgets/guardian_protection_panel.dart)
  - [home_screen.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/screens/home/home_screen.dart)
- **Backend Guardian Analysis & AI Pipeline:**
  - [guardian_analysis.py](file:///d:/Projects/ScamShieldAI/backend/guardian_analysis.py)
  - [analysis_pipeline.py](file:///d:/Projects/ScamShieldAI/backend/app/pipeline/analysis_pipeline.py)
  - [schemas.py](file:///d:/Projects/ScamShieldAI/backend/schemas.py)

### 1.2 Identified Pre-Implementation Gaps
Prior to M9.7, the following gaps in offline-first resilience were identified:
1. **Network Connectivity Indistinguishability:**
   - When an HTTP request failed, the client treated all errors as generic `AI_ERROR` or `AI_UNAVAILABLE`.
   - The app could not distinguish between:
     - No network connection (device offline / no route).
     - Network available but backend unreachable (DNS failure, connect timeout, 502/503/504 gateway failure).
     - Backend reachable but analysis processing failed (HTTP 500, JSON malformed).
     - Backend recovered and analysis available (HTTP 200).
2. **Absence of Bounded Retry Queueing:**
   - `GuardianLiveAnalysisService` maintained only a single `_pendingSegment`. If multiple transcript segments arrived during a network drop, only the latest was retained, while intermediate segments were discarded without structured queueing, backoff, or bounded retention.
3. **Absence of Local Heuristic Protection:**
   - If the device went offline or the backend was unreachable, Live Call Guardian provided zero risk indications—even if the caller demanded OTPs, PINs, remote access screen-sharing (AnyDesk/TeamViewer), or threatened "Digital Arrest".
4. **Honest Labeling & Boundary Enforcement:**
   - Previous implementations lacked a clear offline presentation mechanism that could warn users about high-risk keywords without fabricating a 0–100 ML score or falsely implying that no match means the call is safe.

---

## 2. Existing Functionality Reused

In strict adherence to the frozen architecture:
1. **Authoritative Online AI Pipeline:**
   - Reused `POST /guardian/analysis/segment` in [guardian_analysis.py](file:///d:/Projects/ScamShieldAI/backend/guardian_analysis.py).
   - Reused DistilBERT classifier, ChromaDB RAG, and OpenRouter reasoning in `analysis_pipeline.py`.
   - **No second classifier, RAG database, or duplicate backend was created.** Online analysis remains the sole authoritative source for composite risk scoring.
2. **M9.4 Transcription Pipeline:**
   - Reused 5-second 16kHz mono PCM16 speakerphone acquisition in `GuardianAudioPipeline.kt`.
   - Reused Faster-Whisper chunk transcription in `guardian_transcription.py`.
3. **M9.6 Explainability & Verification Components:**
   - Reused animated risk meter, evidence expansion tiles, and multilingual safe action resolution in [guardian_live_risk_card.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/widgets/guardian_live_risk_card.dart).

---

## 3. Changes and Files Modified

### 3.1 New Local Heuristic Engine
- **File Created:** [guardian_local_heuristic_engine.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/services/guardian_local_heuristic_engine.dart)
- **Role:** Pure Dart, deterministic, versioned (`1.0.0`) local rules engine executing on-device without network calls or external dependencies.

### 3.2 Live Analysis Service Resilience & Queueing
- **File Modified:** [guardian_live_analysis_service.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/services/guardian_live_analysis_service.dart)
- **Enhancements:**
  - Added `GuardianNetworkStatus` state tracking (`online`, `backendUnreachable`, `noNetwork`, `analysisFailed`, `unknown`).
  - Added injectable `networkProbe` callback (`Future<bool> Function()?`) with `_defaultProbe` (`InternetAddress.lookup('dns.google')`).
  - Added bounded retry queue (`_retryQueue`) with max 3 segments, 90-second retention limit, and max 3 retry attempts per segment.
  - Added transient vs. permanent error filtering: 400, 401, 403, and 422 are treated as permanent failures (never queued), while timeouts, client exceptions, and 502/503/504 trigger bounded queueing.
  - Integrated `_localHeuristicEngine.evaluate(latest.text)` immediately upon receiving transcript segments, delivering instantaneous on-device protection.
  - Cleaned up queue and heuristic state on `endSession()` and `dispose()`.

### 3.3 Data Models
- **File Modified:** [guardian_analysis_models.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/models/guardian_analysis_models.dart)
- **Enhancements:**
  - Added `enum GuardianNetworkStatus`.
  - Added `networkStatus`, `localHeuristicResult`, and `queuedCount` fields to `GuardianLiveAnalysisSnapshot`.

### 3.4 Live Risk Presentation
- **File Modified:** [guardian_live_risk_card.dart](file:///d:/Projects/ScamShieldAI/mobile_app/lib/widgets/guardian_live_risk_card.dart)
- **Enhancements:**
  - Added `_buildNetworkStatusBadge` providing visual status chips (`No Internet`, `Backend Unreachable`, `Analysis Failed`, `Online`, `Checking`).
  - Added `_buildLocalHeuristicSection` displaying the `LOCAL HEURISTIC — OFFLINE` alert box when rules match, or the honest disclaimer when no rule matches.
  - Updated State 3 (offline before first result) and State 4 (degraded with preserved result) to display queued request counters (`"${snapshot.queuedCount} analysis request(s) queued for reconnection"`) and inline retry actions.
  - Preserved previous valid online results with a clear `"Updates paused • Previous result may be stale"` warning.

---

## 4. Local Rule Coverage and Limitations

### 4.1 Implemented Rule Definitions (`GuardianLocalHeuristicEngine` v1.0.0)

| Rule ID | Category / Target | Monitored Patterns / Phrases | Safe Action Guidance |
| :--- | :--- | :--- | :--- |
| **`RULE_CREDENTIAL_DEMAND`** | Confidential credentials | **English:** `otp`, `one-time password`, `atm pin`, `upi pin`, `cvv`, `netbanking password`, `passcode`<br>**Hindi (Devanagari):** `ओटीपी`, `पिन`, `पासवर्ड`, `सीवीवी`<br>**Hindi (Roman):** `otp batao`, `pin batao`, `password batao`, `otp dijiye`<br>**Telugu (Script):** `ఓటీపీ`, `పిన్`, `పాస్‌వర్డ్`<br>**Telugu (Roman):** `otp cheppandi`, `pin cheppandi`, `otp ivvandi` | *"Never share OTP, PIN, password, or CVV. Legitimate banks and government agencies never ask for secret credentials."* |
| **`RULE_REMOTE_ACCESS_TOOL`** | Screen-sharing remote control apps | **English:** `anydesk`, `teamviewer`, `rustdesk`, `quicksupport`, `airdroid`<br>**Hindi (Devanagari):** `एनीडेस्क`, `टीमव्यूअर`, `रस्टडेस्क`, `क्विकसपोर्ट`<br>**Telugu (Script):** `ఎనీడెస్క్`, `టీమ్‌వ్యూయర్`, `రస్ట్‌డెస్క్` | *"Never install AnyDesk, TeamViewer, or remote access apps on instructions from unknown callers."* |
| **`RULE_URGENT_TRANSFER`** | Safe account transfer / fee threat | **English:** `transfer money immediately`, `send money now`, `pay fee to unblock`, `safe account`, `urgent transfer`, `pay penalty now`<br>**Hindi (Devanagari):** `पैसे ट्रांसफर`, `पैसे भेजो`, `तुरंत पैसे`, `खाता ब्लॉक`<br>**Hindi (Roman):** `paise bhejo`, `turant paise transfer`, `khata block ho jayega`<br>**Telugu (Script):** `డబ్బులు పంపండి`, `వెంటనే డబ్బులు`, `ఖాతా బ్లాక్`<br>**Telugu (Roman):** `dabbu pampandi`, `dabbulu transfer`, `khata block` | *"Never transfer money to a 'safe account' or unblock fee. Verify directly with your bank through official branches."* |
| **`RULE_GOVT_IMPERSONATION_ARREST`** | Digital arrest intimidation | **English:** `digital arrest`, `cbi officer`, `narcotics bureau`, `customs parcel`, `police warrant`, `arrest warrant`, `illegal parcel`<br>**Hindi (Devanagari):** `डिजिटल अरेस्ट`, `गिरफ्तारी वारंट`, `पुलिस केस`, `सीबीआई`<br>**Telugu (Script):** `డిజిటల్ అరెస్ట్`, `అరెస్ట్ వారెంట్`, `పోలీస్ కేసు` | *"Indian authorities never conduct 'Digital Arrest' over phone or video. Disconnect immediately and report to 1930."* |

### 4.2 Normalization & False-Positive Avoidance
- Safe normalization preserves letters, numbers, and Indian Unicode scripts (Devanagari `\u0900–\u097F` and Telugu `\u0C00–\u0C7F`) while stripping punctuation and collapsing whitespace.
- Word boundary protections prevent matching substrings inside benign vocabulary:
  - English: `\b` boundary ensures `"opinion"`, `"spinning"`, `"pinpoint"` do not trigger the `pin` rule.
  - Indian scripts: Word boundaries utilize whitespace-delimited lookaheads `(?:^|\s)(term)(?=\s|$)` to accommodate non-ASCII Unicode boundaries.
  - Benign tests verified: *"Our project team meeting is scheduled for tomorrow"*, *"I left my laptop on the office desk"*, and *"A gift parcel arrived from my grandmother"* trigger zero rules.

### 4.3 Truthfulness Constraints
1. **Honest Labeling:** All local rule outputs are explicitly headlined `LOCAL HEURISTIC — OFFLINE`.
2. **No Score Fabrication:** The engine **never** invents a 0–100 score or risk tier for local heuristics.
3. **No False Safety Claims:** When no rule matches, the UI displays:
   > *"No local rule matched. This does not establish that the conversation is safe. Full AI analysis requires backend connectivity."*
4. **No Overwrite of Authoritative AI:** Local heuristics do not overwrite newer authoritative online AI results.

---

## 5. Queue / Retry Policy and Retention Limits

| Parameter | Configuration Value | Architectural Rationale |
| :--- | :--- | :--- |
| **Max Queue Size** | `3 segments` | Strictly bounded memory footprint; prevents memory accumulation during long outages. |
| **Queue Retention Limit** | `90 seconds` | Transcript segments older than 90 seconds lose active-call relevance and are automatically purged. |
| **Max Retry Attempts** | `3 attempts per segment` | Prevents endless retry storms on persistently bad connections. |
| **Failure Eligibility** | Transient only | Network timeouts, socket failures, and HTTP 502/503/504 are queued. 400, 401, 403, and 422 are rejected immediately without retry. |
| **Backoff Strategy** | Exponential with jitter | `min(8000, 1000 * 2^(attempts-1)) + random(0–250ms)`. Prevents thundering herd upon reconnection. |
| **Session Isolation** | Session ID pinning | Items are pruned if `segment.sessionId != _sessionId` or `segment.sequence <= _lastAnalyzedSequence`. |
| **Call End Cleanup** | Immediate purge | `_retryQueue.clear()` and `_localHeuristicResult = null` executed synchronously in `_clearSessionData()`. |

---

## 6. Privacy and Security Considerations

1. **In-Memory Buffering Only:**
   - Queued transcript segments are stored strictly in an in-memory Dart `List<_QueuedSegment>` inside `GuardianLiveAnalysisService`.
   - Transcripts are **never** written to SharedPreferences, SQLite, file caches, or local disk databases.
2. **Zero Secret Persistence:**
   - Authentication tokens are fetched on-demand from `tokenProvider()` at request time and are never bundled into queued segment objects or persisted locally.
3. **Log Sanitization:**
   - Raw transcript text, audio bytes, and auth tokens are not written to application logs.
4. **Session Lifetime Enforcement:**
   - When `endSession()` or `dispose()` is called, all queues and memory buffers are immediately erased.

---

## 7. Test Results

### 7.1 Static Code Analysis (`flutter analyze`)
Command:
```bash
flutter analyze
```
Output:
```
Analyzing mobile_app...
No issues found! (ran in 10.9s)
```
**Result:** **PASS (0 errors, 0 warnings, 0 lints)**

### 7.2 Local Heuristic Engine Unit Tests
Command:
```bash
flutter test test/services/guardian_local_heuristic_engine_test.dart
```
Output:
```
00:00 +0: GuardianLocalHeuristicEngine Tests version is 1.0.0
00:00 +1: English phrase detection detects confidential credential demands (OTP, PIN, CVV, Password)
00:00 +2: English phrase detection detects remote access screen-sharing tools
00:00 +3: English phrase detection detects urgent fund transfers and safe account demands
00:00 +4: English phrase detection detects digital arrest and government agency intimidation
00:00 +5: Hindi language coverage (Devanagari & Romanized) detects OTP demand in Devanagari script
00:00 +6: Hindi language coverage (Devanagari & Romanized) detects remote access in Devanagari script
00:00 +7: Hindi language coverage (Devanagari & Romanized) detects digital arrest and police in Devanagari script
00:00 +8: Hindi language coverage (Devanagari & Romanized) detects Romanized Hindi phrases
00:00 +9: Telugu language coverage (Telugu script & Romanized) detects OTP demand in Telugu script
00:00 +10: Telugu language coverage (Telugu script & Romanized) detects digital arrest in Telugu script
00:00 +11: Telugu language coverage (Telugu script & Romanized) detects Romanized Telugu phrases
00:00 +12: False positive prevention does not trigger on substrings like pin inside opinion, spinning, or shopping
00:00 +13: False positive prevention does not trigger on benign team, support, or desk discussions
00:00 +14: False positive prevention does not trigger on benign family and parcel chats
00:00 +15: Truthful no-match behavior returns honest no-match notice when text has no suspicious patterns
00:00 +16: Truthful no-match behavior returns honest no-match notice on empty or whitespace input
00:00 +17: All tests passed!
```
**Result:** **PASS (17/17 passed)**

### 7.3 Live Analysis Service Resilience Tests
Command:
```bash
flutter test test/services/guardian_live_analysis_service_test.dart
```
Output:
```
00:00 +9: distinguishes noNetwork when network probe reports offline
00:00 +10: distinguishes backendUnreachable when network is up but backend returns 503
00:01 +11: does not queue permanent authentication failures (401)
00:01 +12: bounds retry queue to maximum size (3) and discards oldest
00:01 +13: evaluates local heuristics immediately on device upon transcript reception
00:01 +14: cleans up retry queue and local heuristics on endSession
00:02 +15: All tests passed!
```
**Result:** **PASS (15/15 passed)**

### 7.4 Live Risk Card Widget Resilience Tests
Command:
```bash
flutter test test/screens/guardian_live_risk_card_test.dart
```
Output:
```
00:04 +13: renders offline no-network state with network status badge and queued count
00:04 +14: renders local heuristic warning when rule matched during offline state
00:04 +15: renders honest no-match notice when offline and no local rule matches
00:04 +16: preserves previous online result with stale warning and local heuristic alert
00:05 +17: All tests passed!
```
**Result:** **PASS (17/17 passed)**

### 7.5 Full Flutter Application Test Suite
Command:
```bash
flutter test
```
Output:
```
...
00:53 +161: All tests passed!
```
**Result:** **PASS (161/161 passed, 0 failed across entire app)**

### 7.6 Backend Guardian Test Suite
Command:
```bash
venv\Scripts\python -m pytest tests/test_guardian_analysis.py tests/test_guardian_transcription.py
```
Output:
```
tests\test_guardian_analysis.py ..........                               [ 66%]
tests\test_guardian_transcription.py .....                               [100%]
======================= 15 passed, 7 warnings in 7.30s ========================
```
**Result:** **PASS (15/15 passed, 0 regressions)**

---

## 8. Remaining Limitations and Physical-Device Test Plan

While automated test coverage is 100% passing across unit, widget, and integration levels, the following real-world behaviors require validation on physical Android hardware:

1. **Cellular Handover & Tunnel Transitions:**
   - Transitioning between Wi-Fi and 4G/5G LTE during an active speakerphone call while streaming audio chunks.
   - Verifying that the queue drains cleanly and the UI transitions smoothly from `Offline • Updates paused` back to `Online`.
2. **Airplane Mode Edge Case:**
   - Toggling Airplane Mode on/off during an active call to confirm `GuardianNetworkStatus.noNetwork` displays immediately without app crashes.
3. **Acoustic Noise Impact on Keywords:**
   - Evaluating whether acoustic background noise alters Faster-Whisper transcription of Indian phrases (e.g. "OTP" transcribed as "O TP").
4. **Physical Haptic Feedback in Offline Mode:**
   - Validating tactile alert patterns when high-risk local heuristic rules match while offline.

---

## 9. M9.7 Acceptance Checklist

| Item | Requirement Description | Verification Evidence | Status |
| :---: | :--- | :--- | :---: |
| 1 | Network awareness distinguishing no-network vs backend-unreachable vs server-failure | Verified in `guardian_live_analysis_service_test.dart` | **ACCEPTED** |
| 2 | Connectivity status not treated as proof backend is reachable | Verified: probes and status codes differentiated | **ACCEPTED** |
| 3 | Previous valid result preserved during outage with stale notice | Verified in `guardian_live_risk_card_test.dart` ("preserves previous online result with stale warning") | **ACCEPTED** |
| 4 | Deterministic local heuristic engine implemented (v1.0.0) | Verified in `guardian_local_heuristic_engine.dart` (pure Dart, zero deps) | **ACCEPTED** |
| 5 | Rules for credentials, remote access, urgent transfers, and digital arrest | Verified in `guardian_local_heuristic_engine_test.dart` (17/17 tests passing) | **ACCEPTED** |
| 6 | English, Hindi (Devanagari + Roman), and Telugu (Script + Roman) support | Verified in `guardian_local_heuristic_engine_test.dart` | **ACCEPTED** |
| 7 | False positive avoidance on substrings (opinion, spinning, shopping, team) | Verified in `guardian_local_heuristic_engine_test.dart` | **ACCEPTED** |
| 8 | Truthful `LOCAL HEURISTIC — OFFLINE` labeling | Verified in `guardian_live_risk_card.dart` | **ACCEPTED** |
| 9 | No fabricated 0–100 scores or risk tiers for heuristics | Code audit confirms zero score synthesis | **ACCEPTED** |
| 10 | Honest no-match disclaimer displayed when no rules match | Verified: `"No local rule matched. This does not establish that the conversation is safe."` | **ACCEPTED** |
| 11 | Bounded retry queue with max size (3), retention (90s), max attempts (3) | Verified in `guardian_live_analysis_service_test.dart` | **ACCEPTED** |
| 12 | Exponential backoff with jitter on retries | Verified in `guardian_live_analysis_service.dart` | **ACCEPTED** |
| 13 | Permanent failures (401, 403, 422) not queued | Verified in `guardian_live_analysis_service_test.dart` | **ACCEPTED** |
| 14 | In-memory buffering only; no disk persistence of transcripts or tokens | Code audit confirms purely in-memory buffers | **ACCEPTED** |
| 15 | Session cleanup on `endSession` and `dispose` | Verified in `guardian_live_analysis_service_test.dart` | **ACCEPTED** |
| 16 | All test suites passing without regressions | 161/161 Flutter tests, 15/15 Backend tests, 0 analyzer issues | **ACCEPTED** |

---

## 10. Recommended Next Step Within Frozen M9 Plan

**Next Step:** Proceed to **Milestone M9.8 (End-to-End Live Call Guardian Physical Device Acceptance & Staging Validation)**.

M9.8 will focus on:
1. Physical Android phone deployment with live SIM audio calls.
2. Acoustic latency measurement across speakerphone audio capture, Faster-Whisper transcription, and AI risk rendering.
3. Offline recovery validation under physical network disconnection.

*Awaiting user approval before proceeding to Milestone M9.8.*
