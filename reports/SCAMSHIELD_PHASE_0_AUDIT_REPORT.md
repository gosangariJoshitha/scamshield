# ScamShield Mobile Application — Phase 0 Baseline Audit Report
**Document Type:** Technical Architecture, Codebase Audit & Baseline Verification  
**Date:** October 25, 2026  
**Status:** Read-Only Audit Complete — Ready for Review  
**Platform:** Flutter Android (API 35 / Android 15 Target) | Backend: FastAPI + Supabase PostgreSQL  

---

## 1. Executive Summary & Audit Mandate
ScamShield is an AI-powered scam detection and live call protection cybersecurity platform. This audit establishes the verified technical baseline of the existing Flutter mobile application (`mobile_app/`), its integration with the live shared FastAPI backend (`https://scamshield-backend-f0wc.onrender.com`), and its aesthetic alignment with the finalized reference website (`https://scamshield-psi-seven.vercel.app/`).

### Strict Boundaries Maintained:
- **Phase 0 Mode:** Strictly read-only. No application code, dependencies, backend files, or database contents were modified.
- **Reference Website Status:** Complete and frozen. Inspected solely for visual language, color tokens, and product messaging.
- **Authentication Screens Status:** User Login, User Signup, and Admin Login (encapsulated in `mobile_app/lib/screens/auth/authentication_screen.dart`) are frozen and untouched.
- **Real-Data Policy:** Every dynamic field in the audit has been traced directly to an authoritative backend API or verified device hardware event. No mocks, sample stats, or fabricated risk scores are accepted.

---

## 2. Environment & Toolchain Verification

| Check | Command Run | Verified Result | Notes |
| :--- | :--- | :--- | :--- |
| **Flutter Version** | `flutter --version` | `Flutter 3.47.1 • channel stable` | Tools • Dart 3.13.1 |
| **Dart SDK** | `dart --version` | `Dart SDK version: 3.13.1` | Stable channel |
| **Static Analyzer** | `flutter analyze` | **No issues found!** (0 errors, 0 warnings, 23.0s) | Clean codebase |
| **Mobile Tests** | `flutter test` | **166 passed** (0 failures, 1m 47s) | Models, services, Guardian E2E, navigation |
| **Backend Tests** | `pytest tests/test_calls.py` | **11 passed** (0 failures, 14.23s) | Protected call persistence & history |
| **Backend Tests** | `pytest tests/test_guardian_analysis.py` | **10 passed** (0 failures, 2.79s) | Live heuristic & pipeline analysis |
| **Physical Device** | `flutter devices` | **OnePlus CPH2467 (2511885a)** | Android 15 (API 35) connected via USB |
| **Git Working Tree** | `git status` | `On branch main`, up to date with `origin/main` | Clean working tree |

---

## 3. Architecture & Codebase Inventory

### 3.1 Mobile Architecture Pattern
The Flutter application follows a clean separation of concerns:
- **State Management & Coordination:** State is managed via structured `StatefulWidget` controllers with event-driven subscriptions (`StreamSubscription` for Guardian audio/transcription/risk feeds) and dependency injection via service providers.
- **Secure Persistence:** `flutter_secure_storage` (^10.0.0) manages session tokens (`user_token`, `admin_token`, `scamshield_theme_mode`).
- **HTTP Client:** `ApiService` wraps Dart `http` client with timeout handling, token authorization headers, JSON decoding, and multipart upload streaming.

### 3.2 Mobile Screen Inventory

| Screen File | Lines | Primary Purpose | Status / Notes |
| :--- | :--- | :--- | :--- |
| `lib/screens/landing/landing_screen.dart` | 898 | Mobile onboarding, brand hero, capability strip, feature overview, auth entry | In scope for Phase 1 redesign |
| `lib/screens/auth/authentication_screen.dart` | 968 | User Login, User Signup, Admin Login (2FA verification flow) | **FROZEN** — No visual redesign permitted |
| `lib/screens/auth/password_reset_screen.dart` | 338 | Password recovery request & challenge submission | Integrated with AuthService |
| `lib/screens/home/home_screen.dart` | 2,721 | Main authenticated portal, bottom navigation, Guardian live card, recent analyses | Monolithic; target for Phase 2 refactoring |
| `lib/screens/analyze/analyze_screen.dart` | 550 | Multimodal input: Text, Screenshot/Image, PDF Document, Audio Voice Message | Genuine API multipart integration |
| `lib/screens/results/analysis_result_screen.dart` | 1,159 | Risk summary, evidence matching, reasoning, indicators, safe action guidance | Genuine backend result rendering |
| `lib/screens/history/history_screen.dart` | 726 | Dual-tab history: Analysis records and Protected Call sessions with search/filters | Connects to `/analysis/history` and `/calls/history` |
| `lib/screens/history/call_summary_screen.dart` | 733 | Detailed post-call report: Risk score, detected indicators, evidence, recommendations | Connects to `/calls/{session_id}` |
| `lib/screens/profile/profile_screen.dart` | 312 | User profile details, appearance mode toggle, honest community coming-soon modal | Real User model backed |
| `lib/screens/settings/settings_screen.dart` | 275 | Guardian configuration shortcuts, Privacy Center navigation, app info | Honest settings only |
| `lib/screens/privacy/privacy_center_screen.dart` | 196 | Transparent retention policy, privacy-first architecture, local processing disclosures | Accurately explains ephemeral buffers |
| `lib/screens/login/admin_portal_screen.dart` | 2,271 | Authenticated Admin portal: overview, review center, community moderation, users | Distinct from Admin Login screen |

### 3.3 Core Services & Platform Integrations

| Service File | Responsibilities | Key Endpoints / Platform Channels |
| :--- | :--- | :--- |
| `services/api_service.dart` | HTTP GET, POST JSON, POST Multipart, error translation | Shared base URL: `AppConfig.apiBaseUri` |
| `services/auth_service.dart` | Login, signup, admin 2FA verification, token refresh, logout | `/auth/login`, `/auth/register`, `/auth/verify-code`, `/auth/admin-login` |
| `services/analysis_service.dart` | Dashboard metrics fetch, history load, text/image/pdf/audio submission | `/analysis/dashboard`, `/analysis/history`, `/analysis/{type}` |
| `services/call_history_service.dart` | Call finalization, call history query, call summary detail retrieval | `/calls/finalize`, `/calls/history`, `/calls/{id}` |
| `services/guardian_audio_service.dart` | Streams raw audio chunks from Android native audio event channel | `com.scamshield/native/audioEvents` |
| `services/guardian_transcription_service.dart` | Chunks speech-to-text processing via backend Whisper pipeline | `/guardian/transcribe` |
| `services/guardian_live_analysis_service.dart` | Evaluates incremental transcription for high-risk scam indicators | `/guardian/analyze` |
| `services/guardian_protection_service.dart` | Coordinates call screening, permission handling, active call state | `com.scamshield/native` MethodChannel |
| `native/call_bridge.dart` | Dart bridge to Android native services with structured status DTOs | `com.scamshield/native` |

---

## 4. UI/UX & Design Discrepancy Findings
Comparison between the finalized reference website (`frontend/src/index.css`) and the Flutter mobile app reveals significant visual inconsistencies:

1. **Color Token Drift:**
   - **Website Reference:** Primary Cyan `#06B6D4`, Hover `#0891B2`, Light `#22D3EE`, Midnight Background `#0B1120`, Dark Card `#111827`, Border `#334155`.
   - **Current Flutter App:** Primary Teal `#087E8B`, Dark Background `#0B111B`, Surface `#151C28`.
   - **Inconsistency:** Ad-hoc inline colors (e.g., `#12A77A`, `#2585E8`, `#8846D8`, `#E55F61`) are hardcoded across `landing_screen.dart` and `home_screen.dart` instead of referencing a cohesive design token system.

2. **Typography Hierarchy:**
   - The reference website uses **Inter** with bold headings, clean letter-spacing, and clear label uppercase tracking.
   - The Flutter mobile app currently defaults to system Roboto without standardized typography scaling tokens.

3. **Landing Page Experience:**
   - `landing_screen.dart` currently presents a functional but basic scroll view. It lacks the modern SaaS visual polish of the website's hero section ("Don't Just Detect Scams. Understand Them."), the interactive example analysis card, and the step-by-step pipeline illustration (Input -> Extract -> Detect -> Verify -> Explain -> Protect).

4. **Component Monoliths:**
   - `home_screen.dart` is 2,721 lines, mixing tab controllers, Guardian live subscriptions, dashboard metric loading, and widget cards in a single file.
   - Extracting reusable, tokenized components in Phase 1 will enable clean modularization in subsequent phases.

---

## 5. Live Call Guardian & Android Platform Realities

### 5.1 Android Platform Capabilities & Limitations
On Android 10+ (API 29 through API 35), the Android OS enforces strict sandboxing:
- **Cellular Audio Sandboxing:** Third-party applications **cannot** record two-sided cellular downlink voice audio directly through telephony APIs without system signature or root privileges.
- **Acoustic Microphone Capture:** `ScamShield` captures nearby acoustic audio via the device microphone (`RECORD_AUDIO` with a foreground service of type `specialUse|microphone`).
- **Speakerphone Advantage:** When the user places an incoming/outgoing call on speakerphone, both the device user and the remote caller's audio leak into the acoustic environment, allowing transcription and live scam heuristics to evaluate conversation content.

### 5.2 Representation & Privacy Integrity
- The application UI **must never** claim "100% Cellular Call Wiretap Protection".
- The UI **must clearly distinguish** between:
  1. *Guardian Enabled* (monitoring service armed).
  2. *Call Detected* (telephony state ringing/offhook).
  3. *Audio Capture Active* (microphone stream initialized).
  4. *Transcription In Progress* (chunks being sent to backend).
  5. *Live Heuristic Active* (analyzing transcript).
- **Ephemeral Processing:** Raw audio chunks and partial transcripts are cleared upon call completion.

---

## 6. Prioritized Defect & Gap Matrix (P0 - P3)

| ID | Priority | Category | Finding / Gap Description | Target Phase |
| :--- | :--- | :--- | :--- | :--- |
| **GAP-01** | **P1** | UI / Architecture | `home_screen.dart` (2,721 lines) and `landing_screen.dart` (898 lines) have high file coupling and ad-hoc inline styling. | Phase 1 & 2 |
| **GAP-02** | **P1** | Design Consistency | Color palette (`#087E8B`) differs from frozen website (`#06B6D4` / `#0B1120`). Ad-hoc hex values scattered across widgets. | Phase 1 |
| **GAP-03** | **P2** | UX / Mobile Landing | Mobile landing screen lacks the compelling visual cards, typography scale, and pipeline explanation present on the website. | Phase 1 |
| **GAP-04** | **P2** | Guardian Transparency | Guardian status card needs clearer visual distinction between "Microphone Listening" vs "Remote Audio Inaudible / Speakerphone Recommended". | Phase 6 |
| **GAP-05** | **P2** | Responsive Sizing | Fixed padding and card heights in analysis results risk overflow on compact devices (screen width < 360dp). | Phase 4 & 11 |
| **GAP-06** | **P3** | Empty State Polish | Dashboard and history empty states are functional but can be upgraded with modern illustrations and guided quick-action triggers. | Phase 2 & 5 |

---

## 7. Recommended Implementation Sequence
1. **Phase 1: Mobile Design Foundation and Landing Experience** (Immediate next step)
   - Establish `app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, and reusable card/badge widgets aligned with `#06B6D4` / `#0B1120`.
   - Upgrade `LandingScreen` with mobile-first hero, visual scam example, pipeline steps, and trust metrics.
   - Preserve frozen auth screens completely.
2. **Phase 2: Home Dashboard & Genuine Security Overview**
   - Connect dashboard strictly to `/api/analysis/dashboard` and real device state.
3. **Phase 3: Multimodal Analysis Input Experience** (Text, Image, PDF, Audio)
4. **Phase 4: Analysis Results, Evidence, and Safe Actions**
5. **Phase 5: Analysis History, Search, and Filtering**
6. **Phase 6: Live Call Guardian & Audio Pipeline**
7. **Phase 7: Call History & Call Summary Details**
8. **Phase 8: Profile, Settings, Privacy, and Security**
9. **Phase 9: Secondary Features & Community Entry Points**
10. **Phase 10: Authentication Integration & Session Lifecycle Verification**
11. **Phase 11: End-to-End QA, Device Testing & Release Readiness**

---

## 8. Physical Device Testing Plan (OnePlus Android 15)
- **Target Device:** OnePlus CPH2467 (`2511885a`), Android 15 (API 35).
- **Verification Workflow:**
  1. USB debugging validation: `flutter run -d 2511885a`
  2. Validate light and dark mode appearance matching website aesthetics.
  3. Validate gesture navigation, keyboard auto-scroll, safe area padding, and orientation handling.
  4. Test live backend connectivity against `https://scamshield-backend-f0wc.onrender.com`.

---

## 9. Phase 0 Gate Sign-off
Phase 0 audit is complete. All observations are verified against live code, active tests, and connected hardware.  
**Execution is paused.** Awaiting explicit user approval before proceeding to **Phase 1**.
