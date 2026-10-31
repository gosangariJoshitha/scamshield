# ScamShield 2.0 — Backend API & Real-Data Contract Map

**Document:** `SCAMSHIELD_API_DATA_MAP.md`  
**Backend:** FastAPI (Python 3.11) with PostgreSQL & SQLAlchemy ORM  
**Official Backend URL:** `https://scamshield-backend-f0wc.onrender.com/api`  
**Official Frontend URL:** `https://scamshield-psi-seven.vercel.app`  
**Architecture Policy:** Real backend data only | Zero mock production data  

---

## 1. Architectural Source of Truth Overview

```text
┌────────────────────────────────────────────────────────┐
│                   Flutter Mobile App                   │
│         (Presentation, ViewModels, UI State)          │
└───────────────────────────▲────────────────────────────┘
                            │ HTTPS / REST (JSON + Multipart)
                            │ Bearer Token Authorization
┌───────────────────────────▼────────────────────────────┐
│                  FastAPI Shared Backend                │
│       (/api/auth, /api/analysis, /api/calls, etc.)     │
└───────────────────────────▲────────────────────────────┘
                            │ SQLAlchemy Engine
┌───────────────────────────▼────────────────────────────┐
│                  PostgreSQL Database                   │
│        (Users, Analyses, CallHistory, Knowledge)       │
└────────────────────────────────────────────────────────┘
```

> [!CAUTION]
> The mobile Flutter app must **never** connect directly to PostgreSQL. All data queries, insertions, mutations, and aggregations must pass through authorized FastAPI endpoints.

---

## 2. Component-by-Component Source of Truth Map

| Mobile Component / Screen Field | Required Authoritative Source | HTTP Endpoint / Platform Source | Response Schema / Data Fields | Fallback / Offline Behavior |
| :--- | :--- | :--- | :--- | :--- |
| **User Name & Email** | Backend Auth DB | `GET /api/auth/me` | `{"id": int, "email": str, "full_name": str, "role": "user"}` | Show cached session if valid; if 401/403, prompt re-login. |
| **Total Analyses Count** | Backend SQL Count | `GET /api/analysis/dashboard` | `total_analyses: int` | Display skeleton loader while loading; show error card on failure. |
| **Scams Detected Count** | Backend SQL Count | `GET /api/analysis/dashboard` | `scams_detected: int` | Never fabricate or display hardcoded "12" or "85%". |
| **Safe Messages Count** | Backend SQL Count | `GET /api/analysis/dashboard` | `safe_messages: int` | Display genuine count or 0. |
| **High Risk Threats Count**| Backend SQL Count | `GET /api/analysis/dashboard` | `high_risk: int` | Real query: `risk_level IN ('HIGH', 'CRITICAL')`. |
| **Recent Analysis Feed** | User's Analysis History | `GET /api/analysis/history` | `List[AnalysisResponse]` | Empty state if `analyses.isEmpty`. |
| **Risk Score & Level** | Analysis Pipeline Response | `POST /api/analysis/{type}` | `risk_score: int (0-100)`, `risk_level: str` | Authoritative pipeline output; no random client scores. |
| **Classification** | Analysis Pipeline Response | `POST /api/analysis/{type}` | `classification: "GENUINE" | "SUSPICIOUS" | "SCAM"` | Exact server classification. |
| **Threat Indicators** | AI / NLP Extraction | `POST /api/analysis/{type}` | `indicators: List[str]` | Empty list if none detected. |
| **Supporting RAG Evidence**| ChromaDB Knowledge Base | `POST /api/analysis/{type}` | `retrieved_evidence_data: List[EvidenceItem]` | Explicit similarity score distinct from scam probability. |
| **AI Explanation** | LLM Reasoning Service | `POST /api/analysis/{type}` | `explanation: str`, `processing_status: str` | If degraded: `"COMPLETED_WITH_LIMITATIONS"` notice. |
| **Sentinel Enabled State** | Android OS / Service State| `CallBridge.guardianStatus` | Native EventChannel `CallGuardianStatus.enabled` | Reflects actual device setting and service state. |
| **Call Detection State** | Android Telecom Framework| `CallBridge.callEvents` | Native EventChannel `GuardianCallEvent.event` | `IDLE`, `RINGING`, `CALL_ACTIVE`, `CALL_ENDED`. |
| **Microphone Permission**| Android OS Runtime | `CallBridge.audioCapability` | Native MethodChannel `AudioCapability` | `hasPermission: bool`, `audioSource: str`. |
| **Call Finalized Summary** | Backend CallHistory DB | `POST /api/calls/finalize` | `CallHistoryDetailResponse` | Idempotent persist; local copy retained on network failure. |
| **Call History List** | Backend CallHistory DB | `GET /api/calls/history` | `CallHistoryListResponse (items, total, page)` | Genuine pagination; zero invented call records. |
| **Community Reports** | Backend Community DB | `GET /api/community/reports`| `List[CommunityReportResponse]` | Genuine community submissions. |
| **Theme Mode Preference**| Local Secure Storage | `FlutterSecureStorage` | `'light'` or `'dark'` key value | Defaults to system theme or light mode. |

---

## 3. Comprehensive FastAPI Endpoint Inventory

### A. Authentication & Account Management (`prefix="/api"`)

```text
POST /api/auth/signup
  Request:  { "email": str, "password": str, "full_name": str }
  Response: { "account_created": bool, "verification_email_sent": bool, "verification_challenge_id": str }

POST /api/auth/verify-email
  Request:  { "challenge_id": str, "code": str }
  Response: { "email_verified": bool, "message": str }

POST /api/auth/login
  Request:  FormData { "username": email, "password": password, "remember_me": bool }
  Response: { "access_token": str, "token_type": "bearer", "requires_two_factor": bool, "challenge_id": str? }

POST /api/auth/login/verify
  Request:  { "challenge_id": str, "code": str, "remember_me": bool }
  Response: { "access_token": str, "token_type": "bearer" }

POST /api/auth/admin/login
  Request:  FormData { "username": email, "password": password, "remember_me": bool }
  Response: { "access_token": str, "token_type": "bearer", "requires_two_factor": bool, "challenge_id": str? }

GET /api/auth/me
  Headers:  Authorization: Bearer <token>
  Response: { "id": int, "email": str, "full_name": str, "role": "user" | "admin", "is_active": bool }

POST /api/auth/forgot-password
  Request:  { "email": str }
  Response: { "message": str, "challenge_id": str }

POST /api/auth/reset-password
  Request:  { "challenge_id": str, "code": str, "new_password": str, "remember_me": bool }
  Response: { "message": str }
```

### B. Analysis Engine (`prefix="/api/analysis"`)

```text
POST /api/analysis/text
  Headers:  Authorization: Bearer <token>
  Request:  { "content": str }
  Response: AnalysisResponse (risk_score, risk_level, classification, category, explanation, indicators, retrieved_evidence_data, safe_actions)

POST /api/analysis/image
  Headers:  Authorization: Bearer <token>
  Request:  MultipartFormData { "file": binary, "language": "en" | "hi" | "te" }
  Response: AnalysisResponse

POST /api/analysis/pdf
  Headers:  Authorization: Bearer <token>
  Request:  MultipartFormData { "file": binary }
  Response: AnalysisResponse

POST /api/analysis/audio
  Headers:  Authorization: Bearer <token>
  Request:  MultipartFormData { "file": binary }
  Response: AnalysisResponse

GET /api/analysis/dashboard
  Headers:  Authorization: Bearer <token>
  Response: { "total_analyses": int, "scams_detected": int, "safe_messages": int, "high_risk": int }

GET /api/analysis/history
  Headers:  Authorization: Bearer <token>
  Response: List[AnalysisResponse]

GET /api/analysis/{analysis_id}
  Headers:  Authorization: Bearer <token>
  Response: AnalysisResponse
```

### C. Sentinel & Live Call Services (`prefix="/api"`)

```text
POST /api/guardian/transcription/chunk
  Headers:  Authorization: Bearer <token>
  Request:  MultipartFormData { "file": binary (16kHz PCM), "session_id": UUID, "sequence": int, "source": str }
  Response: { "segments": [{ "session_id": str, "segment_id": str, "sequence": int, "text": str, "is_final": bool }], "language": str }

POST /api/guardian/analysis/segment
  Headers:  Authorization: Bearer <token>
  Request:  GuardianTranscriptSegmentCreate { "session_id": UUID, "segment_id": str, "sequence": int, "text": str, "source": str }
  Response: GuardianLiveAnalysisResponse { "status": str, "processed_sequence": int, "result": GuardianLiveAnalysisResult }

POST /api/calls/finalize
  Headers:  Authorization: Bearer <token>
  Request:  CallFinalizeRequest {
              "session_id": str,
              "started_at": datetime,
              "ended_at": datetime,
              "duration_seconds": int,
              "guardian_enabled": bool,
              "final_risk_score": int,
              "final_risk_level": str,
              "classification": str,
              "scam_category": str,
              "detected_indicators": List[str],
              "supporting_evidence": List[dict],
              "protection_actions": List[str],
              "analysis_status": str
            }
  Response: CallHistoryDetailResponse (Idempotent: updates existing incomplete record if new results arrive)

GET /api/calls/history
  Headers:  Authorization: Bearer <token>
  Query:    ?page=1&limit=20&risk_level=HIGH
  Response: CallHistoryListResponse { "items": List[CallHistoryItemResponse], "total": int, "page": int, "limit": int, "has_next": bool }

GET /api/calls/{session_id}
  Headers:  Authorization: Bearer <token>
  Response: CallHistoryDetailResponse
```

### D. Community & Admin Services (`prefix="/api"`)

```text
GET /api/community/reports
  Headers:  Authorization: Bearer <token>
  Response: List[CommunityReportResponse] { "id": int, "content": str, "category": str, "description": str, "reporter_name": str, "created_at": datetime }

POST /api/community/reports
  Headers:  Authorization: Bearer <token>
  Request:  { "content": str, "category": str, "description": str, "evidence": str, "analysis_id": int? }
  Response: CommunityReportResponse

GET /api/admin/overview
  Headers:  Authorization: Bearer <admin_token>
  Response: AdminOverviewResponse

GET /api/admin/users
  Headers:  Authorization: Bearer <admin_token>
  Query:    ?skip=0&limit=20
  Response: AdminPage { "items": List[User], "total": int, "page": int }
```

---

## 4. Strict Zero-Mock Policy & Verification

### Prohibited Patterns
1. **No Math.random() or Simulated Scores:** Risk scores must strictly reflect `AnalysisResponse.risk_score`.
2. **No Fabricated Time Trends:** If the user has 3 analyses, the UI shows those 3 analyses. Do not render artificial line graphs claiming 150 threats over the past 30 days.
3. **No Faked Guardian Triggers:** The app must not invent simulated active phone calls unless explicitly running inside a mock unit-test environment.
4. **No Demo Fallbacks on Server Outage:** If the backend returns `503 Service Unavailable`, show `Analysis service is temporarily unavailable` with a Retry button. Do not substitute dummy success data.

---

## 5. API Gap Analysis & Remediation Strategy

1. **Dashboard Trends Aggregation:**
   - *Current situation:* Backend provides aggregate numbers (`total_analyses`, `scams_detected`, `safe_messages`, `high_risk`) via `/api/analysis/dashboard`, but not a pre-binned daily/weekly timeseries endpoint.
   - *Client-side calculation:* The mobile client safely filters the user's fetched `AnalysisRecord` list by timestamp (`created_at`) to derive accurate time-window totals (Today, Last 7 Days, Last 30 Days).
2. **Community Integration:**
   - *Current situation:* The mobile UI previously showed a dialog stating "Community features coming soon", despite the backend having `/api/community/reports`.
   - *Remediation:* Wire the Community Insights screen directly to `GET /api/community/reports` and `POST /api/community/reports` in Phase 08.
