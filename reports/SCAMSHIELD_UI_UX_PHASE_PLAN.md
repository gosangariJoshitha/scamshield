# ScamShield Mobile Application — UI/UX Redesign & Implementation Phase Plan
**Document Type:** Phased Design System & Architectural Implementation Plan  
**Target:** Flutter Android Application (`mobile_app/`)  
**Design Reference:** Finalized Official Website (`https://scamshield-psi-seven.vercel.app/`)  
**Date:** October 25, 2026  

---

## 1. Design Vision & Philosophy
Transform ScamShield into a mobile-first, enterprise-grade cybersecurity SaaS application that commands trust, clarity, and authority.

### Visual Foundations from the Reference Website:
- **Primary Cyber Accent:** Cyan `#06B6D4` (Light `#22D3EE`, Hover `#0891B2`)
- **Dark Theme (Primary Surface):** Midnight Navy `#0B1120`, Dark Card `#111827`, Muted Slate `#334155`
- **Light Theme:** Cool Gray `#F1F5F9`, Pure White `#FFFFFF`, Border `#E2E8F0`
- **Semantic Risk Tokens:**
  - Critical / High Risk: `#EF4444` (Dark), `#DC2626` (Light), Background tint `#FEF2F2`
  - Warning / Medium Risk: `#FBBF24` (Dark), `#F59E0B` (Light), Background tint `#FFFBEB`
  - Safe / Genuine: `#22C55E` (Dark), `#16A34A` (Light), Background tint `#F0FDF4`
  - Informational / AI: `#38BDF8` (Dark), `#0284C7` (Light)
- **Typography:** Modern sans-serif hierarchy (Inter / Outfit style) with bold section titles, letter-spaced micro-labels, and high-contrast readability.

---

## 2. Reusable Design System Component Architecture (Phase 1 Target)

```
mobile_app/lib/theme/
├── app_colors.dart         <-- Unified light/dark tokens matching website (#06B6D4, #0B1120)
├── app_typography.dart     <-- Scale: display, headline, title, body, label micro-caps
├── app_spacing.dart        <-- Standardized padding, radius, elevation (4, 8, 12, 16, 20, 24, 32)
└── app_theme.dart          <-- Material 3 ThemeData with refined component themes

mobile_app/lib/widgets/common/
├── cyber_button.dart       <-- Filled, Outlined, Danger, Ghost with pressed & loading states
├── cyber_card.dart         <-- Glass-bordered card container with subtle shadow & hover
├── risk_badge.dart         <-- Pill badges (High Risk, Medium Risk, Safe, Inconclusive)
├── metric_tile.dart        <-- Clean numeric metric card with change indicator
├── skeleton_loader.dart    <-- Shimmer loading placeholder for async data
├── empty_state_view.dart   <-- High-polish empty view with icon, title, action button
└── error_retry_view.dart   <-- Non-blocking inline error card with retry trigger
```

---

## 3. Comprehensive Phase-by-Phase Roadmap

### Phase 1 — Mobile Design Foundation and Landing Experience
- **Focus:** Establish core design tokens (`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`) and rebuild `LandingScreen` for mobile-first engagement.
- **Landing Screen Adaptations:**
  - Hero header with AI badge ("AI-Powered Scam Protection").
  - Clear value proposition: "Don't Just Detect Scams. Understand Them."
  - Interactive "Example Threat Card" highlighting KYC Bank Scam, Risk 87/100, Urgency Tactic, and Safe Action.
  - Step-by-Step Security Pipeline: Input ➔ Extract ➔ Detect ➔ Verify ➔ Explain ➔ Protect.
  - Channels Strip: SMS, WhatsApp, Email, Image, PDF, Voice Audio.
  - Clear mobile-optimized CTAs: "Analyze Something" and "Sign In".
- **Boundaries:** Zero changes to frozen authentication screens (`AuthenticationScreen`).

### Phase 2 — Home Dashboard & Genuine Security Overview
- **Focus:** Clean modularization of `home_screen.dart`.
- **Elements:**
  - Real metrics row from `GET /api/analysis/dashboard` (Total, Scams Detected, Safe, High Risk).
  - Quick action grid: Text, Screenshot, PDF, Audio.
  - Live Call Guardian status card with real device telemetry.
  - Recent 5 analyses list with tap-through to results.
  - Zero fake statistics; honest zero-state for new users.

### Phase 3 — Multimodal Analysis Input Experience
- **Focus:** Upgrade `analyze_screen.dart` with seamless tabbed input for Text, Image, PDF, and Audio.
- **Validations:** Real-time character counts, file-type filtering, file size ceilings (10MB Image, 20MB PDF, 25MB Audio).
- **Feedback:** Upload progress indicator with non-blocking error recovery.

### Phase 4 — Analysis Results, Evidence, and Safe Actions
- **Focus:** Transform `analysis_result_screen.dart` into an explainable security intelligence report.
- **Sections:**
  - Risk gauge & classification header.
  - Detected scam indicators pill tags.
  - Retrieved knowledge-base evidence matches with similarity percentage.
  - AI reasoning card ("Why this result?").
  - Actionable next steps banner ("Recommended Safe Action").
  - Limitation disclosures if incomplete data.

### Phase 5 — Analysis History, Search, and Filtering
- **Focus:** Refactor `history_screen.dart` analysis tab.
- **Features:** Search by text content, filter by risk level (`ALL`, `HIGH`, `MEDIUM`, `LOW`), pull-to-refresh, empty states.

### Phase 6 — Live Call Guardian & Audio Pipeline
- **Focus:** Deep audit and UI transparency of the live call monitoring flow.
- **Key Realities:**
  - Clear disclosure: Microphone acoustic capture (speakerphone recommended for remote caller audibility).
  - Explicit multi-state indicator: Armed ➔ Call Detected ➔ Microphone Streaming ➔ Transcribing ➔ Heuristic Evaluating.
  - Controlled buffering to prevent memory leaks during extended phone calls.
  - Strict privacy: No audio or full transcript retained permanently without consent.

### Phase 7 — Call History & Call Summary Details
- **Focus:** Refine `call_summary_screen.dart` and the Call History tab.
- **Features:** Call duration, date, risk score, detected scam categories (e.g., Impersonation, Urgency), and recommendations.

### Phase 8 — Profile, Settings, Privacy, and Security
- **Focus:** Modernize `profile_screen.dart`, `settings_screen.dart`, and `privacy_center_screen.dart`.
- **Features:** Real account info, theme persistence, permissions guidance, honest data retention disclosures.

### Phase 9 — Secondary Features & Community Entry Points
- **Focus:** Review community navigation. Provide clear, honest "Coming Soon" messaging rather than dummy feeds.

### Phase 10 — Authentication Integration & Session Lifecycle Verification
- **Focus:** Ensure rock-solid token storage, automatic logout on 401/403, and graceful session expiration notices.
- **Boundaries:** Authentication screen UI remains completely frozen.

### Phase 11 — End-to-End QA, Performance & Release Readiness
- **Focus:** Comprehensive automated test runs, static analysis, memory profiling, and physical Android 15 device validation.
- **Deliverables:** `SCAMSHIELD_FINAL_QA_REPORT.md` and `SCAMSHIELD_RELEASE_READINESS_REPORT.md`.

---

## 4. Acceptance Criteria & Gates
Each phase must:
1. Pass `flutter analyze` with 0 errors and 0 warnings.
2. Pass all relevant automated unit/widget tests.
3. Be validated on the connected OnePlus Android 15 physical device (`CPH2467`).
4. Stop at its explicit gate to receive user sign-off before proceeding.
