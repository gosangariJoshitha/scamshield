# ScamShield 2.0 — 10-Phase Implementation Roadmap & Governance

**Document:** `SCAMSHIELD_PHASE_PLAN.md`  
**Execution Model:** Single-Phase Isolation | User Gate Approval Required  
**Device Verification:** Physical Android Smartphone (e.g. OnePlus Android 15)  
**Status:** Phase 00 Complete — Awaiting Approval for Phase 01 Master Prompt  

---

## 1. Governance & Execution Protocol

Every phase strictly adheres to the following sequential protocol:

```text
┌─────────────────────────────────────────────────────────────┐
│ 1. USER ISSUES APPROVED PHASE MASTER PROMPT                │
├─────────────────────────────────────────────────────────────┤
│ 2. AGENT INSPECTS PHASE-SPECIFIC CODE & ARCHITECTURE        │
├─────────────────────────────────────────────────────────────┤
│ 3. AGENT IMPLEMENTS CODE ONLY FOR THE DESIGNATED PHASE      │
├─────────────────────────────────────────────────────────────┤
│ 4. AGENT RUNS AUTOMATED TESTS & FLUTTER ANALYZER            │
├─────────────────────────────────────────────────────────────┤
│ 5. AGENT GENERATES PHASE AUDIT REPORT & LOGS                │
├─────────────────────────────────────────────────────────────┤
│ 6. USER BUILDS/INSTALLS & VERIFIES ON PHYSICAL ANDROID PHONE│
├─────────────────────────────────────────────────────────────┤
│ 7. ANY DEFECTS FIXED IN-PLACE WITHIN SAME PHASE             │
├─────────────────────────────────────────────────────────────┤
│ 8. USER CONFIRMS PHASE ACCEPTANCE (EXPLICIT APPROVAL)       │
├─────────────────────────────────────────────────────────────┤
│ 9. NEXT PHASE BEGINS ONLY AFTER STEP 8                     │
└─────────────────────────────────────────────────────────────┘
```

> [!IMPORTANT]
> No phase is considered complete simply because the code compiles or tests pass. Visual fidelity, touch responsiveness, theme transitions, and native behavior must be validated on a physical Android device.

---

## 2. Detailed 10-Phase Roadmap

### Phase 00: Complete Audit & Blueprint Freeze
* **Focus:** Repository inspection, screen inventory, data source mapping, zero-mock validation, baseline test verification, generation of master planning documents.
* **Deliverables:**
  - `SCAMSHIELD_MOBILE_AUDIT.md`
  - `SCAMSHIELD_DESIGN_SYSTEM.md`
  - `SCAMSHIELD_SCREEN_BLUEPRINT.md`
  - `SCAMSHIELD_API_DATA_MAP.md`
  - `SCAMSHIELD_PHASE_PLAN.md`
* **Source Code Changes:** None (Frozen).
* **Acceptance:** User reviews and approves Phase 00 deliverables.

---

### Phase 01: Design System & Shared Components
* **Focus:** Centralized visual design foundation in `mobile_app/lib/theme/` and `mobile_app/lib/widgets/common/`.
* **Scope:**
  - Add Inter font assets / integration and configure `app_typography.dart`.
  - Implement official ScamShield 2.0 color palette in `app_colors.dart`:
    - Light: Primary `#086B73`, Navy `#102A43`, Aqua `#A8EDF3`, Background `#F4F7FA`, Surface `#FFFFFF`, Text `#17212B`.
    - Dark: Primary `#65D4D8`, Background `#101820`, Surface `#192630`, Raised `#22343F`, Main Text `#F1F5F9`, Muted Text `#B4C2CC`.
    - Semantic Risk: Low `#21845A`, Medium `#B7791F`, High `#D65A31`, Critical `#B42332`.
  - Configure `app_spacing.dart` (4px grid tokens, 16-20px card radii, 50-56px button height).
  - Implement full Material 3 ThemeData in `app_theme.dart` (Light and Dark).
  - Build reusable components: `ScamShieldCard`, `RiskBadge`, `PrimaryButton`, `SecondaryButton`, `SkeletonLoader`, `ThemeModeToggle`.
* **Automated Tests:**
  - Color token contract tests.
  - Typography scale & font family tests.
  - Component rendering tests in both Light and Dark mode.
* **Physical Device Verification:**
  - Verify high contrast readability, dark mode surface distinction, and button touch sizes on Android.

---

### Phase 02: Landing Page
* **Focus:** Public landing screen redesign matching the approved minimal, premium security style.
* **Scope:**
  - Brand header with `ScamShieldBrandMark` and `ThemeModeToggle`.
  - Hero section with strong headline, eyebrow, and clear value proposition.
  - Primary CTA buttons: `Get Started` and `Sign In` cleanly navigating to the fixed `AuthenticationScreen`.
  - `Analyze Something` button triggering sign-in prompt.
  - Compact 4-feature capability overview.
  - Security and privacy trust reassurance.
  - Preserve fixed authentication screens (`User Login`, `User Signup`, `Admin Login`).
* **Automated Tests:**
  - Widget tests validating landing layout, hero elements, and navigation callbacks to fixed auth screens.
* **Physical Device Verification:**
  - Scroll fluidity, theme toggle transition, layout on small (320-360dp) vs large screens.

---

### Phase 03: Home Dashboard
* **Focus:** Centralized security overview dashboard with real backend data integration.
* **Scope:**
  - Greeting using authenticated profile (`User.fullName`).
  - Real Sentinel status indicator reflecting actual Android call protection state.
  - Prominent "Analyze" action.
  - Four quick-action cards (Text/URL, Image, PDF, Audio).
  - Verified statistics from `/api/analysis/dashboard` (`total_analyses`, `scams_detected`, `safe_messages`, `high_risk`).
  - Recent analysis list from `/api/analysis/history` with real risk badges.
  - Clean skeleton shimmer loaders during fetch and error card with retry.
* **Automated Tests:**
  - Dashboard widget tests verifying dynamic user greeting, real counts, and empty states.
* **Physical Device Verification:**
  - Real data render on physical device, pull-to-refresh responsiveness.

---

### Phase 04: Analyze Submission
* **Focus:** Multimodal input submission across Text, Image, PDF, and Audio.
* **Scope:**
  - Clean 4-segment category selector.
  - Input field with paste shortcut for text and URLs.
  - File picker integration for Image (max 10MB), PDF (max 20MB), and Audio (max 25MB).
  - Form validation, file size limit guards, and duplicate submission locking (`_loading == true`).
  - Indeterminate progress indicator during upload.
  - Integration with `/api/analysis/text`, `/image`, `/pdf`, `/audio`.
  - Seamless navigation to Analysis Result upon completion.
* **Automated Tests:**
  - Validation tests, file size rejection tests, API client multipart tests.
* **Physical Device Verification:**
  - Camera/gallery file picking on Android, PDF selection from Downloads, error toasts on oversized files.

---

### Phase 05: Analysis Results
* **Focus:** Comprehensive, evidence-backed security breakdown.
* **Scope:**
  - Authoritative risk score (0-100), severity label, classification, and threat category.
  - Analyzed input preview with expandable safe viewer.
  - Detected indicators list.
  - Retrieved knowledge evidence cards (pattern snippet, source, similarity percentage).
  - AI reasoning explanation with limitation warning if LLM failed.
  - Recommended safe actions checklist.
  - Back to Dashboard and Analyze Another buttons.
* **Automated Tests:**
  - High, Medium, Low, Critical result layout tests, limitation banner tests.
* **Physical Device Verification:**
  - Color contrast on physical screen, typography hierarchy readability.

---

### Phase 06: History
* **Focus:** Dual-tab persistent history for Content Analyses and Protected Calls.
* **Scope:**
  - Tab A (Analyses) backed by `GET /api/analysis/history`.
  - Tab B (Calls) backed by `GET /api/calls/history`.
  - Severity filter chips (`All`, `Low`, `Medium`, `High`, `Critical`).
  - Search query filtering.
  - Infinite scroll / pagination support.
  - Tap card opens full Analysis Result or Call Summary.
* **Automated Tests:**
  - History filtering, search query matching, empty history view tests.
* **Physical Device Verification:**
  - Smooth list scrolling, pull-to-refresh, detail screen transitions.

---

### Phase 07: Sentinel — Live Call Protection
* **Focus:** Live call protection rebranding from "Guardian" to "Sentinel" with transparent privacy safeguards.
* **Scope:**
  - Rebrand all user-facing strings and identifiers from "Guardian" to "Sentinel".
  - Permission matrix: Phone state, Call screening role, Microphone permission.
  - Explicit consent dialogs before enabling call monitoring or microphone capture.
  - Active call monitoring status, duration timer, and live transcription monitor.
  - Real-time heuristic & backend live analysis risk card.
  - Idempotent call session finalization (`POST /api/calls/finalize`).
  - Call Summary Detail screen (`Screen 11`).
* **Automated Tests:**
  - CallBridge event decoding, session finalization idempotency, permission denial handling tests.
* **Physical Device Verification:**
  - Test real incoming / outgoing phone call on Android, verify notification and FGS lifecycle.

---

### Phase 08: Profile & Secondary Features
* **Focus:** Profile menu, account management, settings, privacy, and community insights.
* **Scope:**
  - Relocate Profile to top-right app bar avatar menu.
  - Implement Community Insights screen backed by `GET /api/community/reports` and `POST /api/community/reports`.
  - Settings screen with protection preferences.
  - Privacy & Protection Center detailing ephemeral audio and no-OTP policies.
  - Help & Support with contact information.
  - Secure sign-out with confirmation dialog.
  - Admin Portal screen verification.
* **Automated Tests:**
  - Profile menu action tests, community report fetch/post tests, logout session clearing tests.
* **Physical Device Verification:**
  - Theme switching from profile menu, community report feed scrolling.

---

### Phase 09: Final QA & Release Readiness
* **Focus:** End-to-end regression testing, performance optimization, and release sign-off.
* **Scope:**
  - Complete regression suite across all 185+ unit/widget tests.
  - Static analysis (`flutter analyze`) verification with zero warnings.
  - Android accessibility audit (text scaling, TalkBack semantics, touch targets).
  - Memory leak and background service battery efficiency inspection.
  - Produce final release verification report.
* **Physical Device Verification:**
  - Complete user acceptance journey from Landing -> Auth -> Dashboard -> Analyze -> Sentinel -> History -> Profile.

---

## 3. Definition of Done for ScamShield 2.0

ScamShield 2.0 achieves final release acceptance when:
1. **Design System:** Inter typography and semantic color tokens are applied uniformly in Light and Dark modes.
2. **Navigation:** Exactly 4 bottom tabs (`Home`, `Analyze`, `Sentinel`, `History`) with Profile in the top menu.
3. **Authentication:** User Login, User Signup, and Admin Login remain strictly intact.
4. **Data Integrity:** 100% of operational data originates from the live backend or device state (zero mock data).
5. **Sentinel:** Transparent permissions, ephemeral audio handling, and real-time call protection work seamlessly on Android.
6. **Code Quality:** `flutter analyze` has 0 issues, and all automated tests pass.
7. **Physical Device Acceptance:** Verified and signed off on a physical Android phone by the user.
