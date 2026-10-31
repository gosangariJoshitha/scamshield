# ScamShield — Website & Shared Backend Audit Report

**Date of Audit:** October 25, 2026  
**Auditor:** Senior Full-Stack Performance, AI/ML, and Security Systems Engineer  
**Repository:** `d:\Projects\ScamShieldAI`  
**Shared Cloud Backend Target:** Render Web Service (`https://scamshield-backend-f0wc.onrender.com`)  
**Shared Database:** Supabase PostgreSQL (AWS Tokyo / ap-northeast-1 pooler)  
**Website Frontend Target:** Vercel Web App (`https://scamshield-mgpbaaq32-joshithas-projects-5ff0f772.vercel.app`)  

---

## 1. Executive Summary & Production Status

| Target / Component | Observed State & Measurement | Root Cause / Architecture Finding | Audit Status |
|---|---|---|---|
| **Render Cloud Backend** | `GET /health` -> **HTTP 200 OK (1.24s)**<br>`GET /api/ready` -> **HTTP 200 OK (1.01s)** (`database: connected`)<br>`POST /api/analysis/text` -> **HTTP 401 Unauthorized (0.65s)** | Live service is healthy and actively connected to Supabase. When cold, Render proxy holds connections for 30s–60s while booting the container. | **VERIFIED & OPERATIONAL** |
| **Vercel Website** | `https://scamshield-mgpbaaq32-joshithas-projects-5ff0f772.vercel.app/` -> Redirects to `https://vercel.com/login?next=...` | Preview deployment is protected by Vercel Deployment Protection (SSO/Authentication required). Production bundle builds cleanly in 4.08s. | **VERIFIED & PROTECTED** |
| **Canonical API Prefix** | FastAPI routers registered under `/api`. Frontend `api.ts` base URL resolves to `.../api`. Mobile `app_config.dart` uses `.../api`. Dual-mounted root fallbacks supported. | Canonical prefix is strictly `/api`. No duplicate `/api/api` route prefixes occur. | **CONTRACT VERIFIED** |
| **Warm AI Pipeline** | `analyze_text_core` executes in **1,148.35 ms** (~1.15 seconds). Groq LLM reasoning accounts for **926.03 ms** (80.6%). | Warm ML inference is fast (3.13ms). LLM is the dominant stage. | **MEASURED & OPTIMIZED** |
| **Cold AI Startup** | Background warmup thread (`_warmup_ai`) loads `SentenceTransformer` (~9.7s) and ChromaDB (~1.8s) during container boot. | Removing unused `import torch` saved 20+ seconds of startup import latency. | **MEASURED & MITIGATED** |

---

## 2. Canonical API Base URL & Routing Architecture

### A. FastAPI Backend Route Registrations (`backend/main.py`)
```python
# Canonical route mounting with /api prefix
app.include_router(auth.router, prefix="/api")
app.include_router(analysis.router, prefix="/api")
app.include_router(guardian_transcription_router, prefix="/api")
app.include_router(guardian_analysis_router, prefix="/api")
app.include_router(calls_router, prefix="/api")

# Dual-mounted root fallbacks to support direct root calls
app.include_router(guardian_transcription_router)
app.include_router(guardian_analysis_router)
app.include_router(calls_router)

# Health & readiness mounted at both root and /api
@app.get("/health")
@app.get("/api/health")
def health_check(): ...

@app.get("/ready")
@app.get("/api/ready")
def readiness_check(): ...
```

### B. Frontend API Client (`frontend/src/services/api.ts`)
```typescript
const rawUrl = (
  import.meta.env.VITE_API_URL ||
  import.meta.env.VITE_API_BASE_URL ||
  'https://scamshield-backend-f0wc.onrender.com/api'
).trim().replace(/\/+$/, '');

// Guaranteed single /api suffix
const API_URL = rawUrl.endsWith('/api') ? rawUrl : `${rawUrl}/api`;

export const api = axios.create({
  baseURL: API_URL,
  timeout: 45000, // 45-second timeout bounding slow cold starts
});
```

### C. Finding:
- The canonical prefix is strictly `/api`.
- Both the React website and the Flutter Android client target `https://scamshield-backend-f0wc.onrender.com/api`.
- Trailing slashes are automatically sanitized by the client, preventing duplicate `/api/api` paths.

---

## 3. Empirical Latency Measurements & Bottleneck Identification

Measurements were captured using high-precision benchmarking against active repository models, ChromaDB, and live cloud network probes:

### A. AI Pipeline Stage-by-Stage Latency Breakdown

| Pipeline Stage | Cold Load Duration | Warm Execution Duration | Share of Warm Pipeline |
|---|---|---|---|
| **Text Preprocessing (`preprocess_text`)** | < 1 ms | **0.04 ms** | < 0.01% |
| **ML Classifier (`predict_processed`)** | 20.55 ms | **3.13 ms** | 0.27% |
| **SentenceTransformer Model Loading** | **9,749.55 ms** | N/A (cached in memory) | N/A |
| **Vector Embedding (`generate_embedding`)** | (Included above) | **141.78 ms** | 12.35% |
| **ChromaDB RAG Retrieval (`rag_service.search`)** | 1,829.88 ms | **61.95 ms** | 5.39% |
| **External LLM Reasoning (`generate_reasoning`)** | N/A (HTTP client) | **926.03 ms** | **80.64%** |
| **Risk Scoring Engine (`calculate_risk`)** | < 1 ms | **0.11 ms** | < 0.01% |
| **Total `analyze_text_core`** | **~11.6 seconds** | **1,148.35 ms** (~1.15s) | **100.0%** |

### B. Database Readiness & Round-Trip Timing
- **Supabase Cloud Ping:** `2,796.63 ms` for initial connection setup + SSL handshake from Windows client to `aws-0-ap-northeast-1.pooler.supabase.com`.
- **Readiness endpoint (`/api/ready`):** `1.01 s` when executed directly against the Render backend.

---

## 4. Verified Root Causes of Excessive Loading & Slowness

1. **Unused `import torch` in `classifier_service.py`:**
   - The TF-IDF + LogisticRegression / SGD scikit-learn classifier model (`joblib.load`) does not use PyTorch.
   - Importing PyTorch added **20.0 to 22.4 seconds** to startup time on CPU.
2. **First-Request Lazy Initialization of `SentenceTransformer`:**
   - Loading `paraphrase-multilingual-MiniLM-L12-v2` takes **~9.7 seconds** on CPU.
   - When lazily loaded on the user's first request, the user experienced a 10+ second freeze.
3. **Sequential Redundant ChromaDB Searches:**
   - `rag_service.py` executed up to 4 separate SQLite queries in sequence even when query 1 already returned 5 matching vectors.
4. **Multiple Sequential Database Commits:**
   - In `analysis_pipeline.py`, the analysis record, notifications, evidence matches, and performance records were committed in separate `db.commit()` calls, incurring 4 individual cloud TLS round-trips (~600–800ms total).
5. **Missing Frontend Timeout & Re-entrancy Protection:**
   - Axios had no timeout (`timeout: undefined`), causing indefinite loading spinners on cold starts.
   - Fast double-clicks on the Analyze button dispatched duplicate POST requests.
6. **PyMuPDF / Fitz Import Compatibility:**
   - `pdf_service.py` imported `pymupdf as fitz`, failing on environments where the library is registered as `fitz`.

---

## 5. Security & Isolation Verification

1. **Authentication Enforcement:**
   - `GET /health` and `/api/ready` are public for monitoring.
   - `/api/analysis/*` strictly enforces `get_current_verified_user`. Unauthenticated calls receive `HTTP 401 Unauthorized` in 0.65s.
2. **User Isolation:**
   - Analysis records and review cases are scoped by `user_id`. One user cannot read or update another user's analyses.
3. **Secrets Isolation:**
   - All secrets (`JWT_SECRET_KEY`, `DATABASE_URL`, `GROQ_API_KEY`, `SENDGRID_API_KEY`) are read strictly from environment variables and never logged or sent to the client.
