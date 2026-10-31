# ScamShield 2.0 — Screen Architecture & UI Blueprint

**Document:** `SCAMSHIELD_SCREEN_BLUEPRINT.md`  
**Scope:** Complete Screen Inventory, Navigation Flows, Information Architecture & States  
**Status:** Approved Product Blueprint Specification  

---

## 1. Overall Application Structure

ScamShield 2.0 features an intuitive, secure navigation structure centered on **four bottom navigation destinations** and a dedicated **Profile menu** for secondary settings and community insights.

```mermaid
graph TD
    A[Public Landing Page] -->|Get Started| B[User Signup (FIXED)]
    A -->|Sign In| C[User Login (FIXED)]
    A -->|Admin Access| D[Admin Login (FIXED)]
    B -->|Verified| E[Home Dashboard]
    C -->|Authenticated| E
    D -->|Admin Authenticated| F[Admin Portal]

    subgraph "Authenticated User Core (4 Bottom Tabs)"
        E[Tab 1: Home Dashboard]
        G[Tab 2: Analyze Submission]
        H[Tab 3: Sentinel Call Protection]
        I[Tab 4: History & Activity]
    end

    G -->|Submit Text / Media / Doc / Audio| J[Analysis Result Screen]
    I -->|Select Analysis| J
    I -->|Select Call| K[Call Summary Detail Screen]
    H -->|Call Finalized| K

    subgraph "Profile Menu (Top-Right Action)"
        L[Profile & Account Details]
        M[Community Insights]
        N[Settings]
        O[Privacy & Protection Center]
        P[Help & Support]
        Q[Logout]
    end

    E -.->|Profile Menu| L
    E -.->|Profile Menu| M
    E -.->|Profile Menu| N
    E -.->|Profile Menu| O
    E -.->|Profile Menu| P
    E -.->|Profile Menu| Q
```

---

## 2. Public & Authentication Screens

### Screen 01: Landing Page (Public Redesign)
* **Status:** Redesigned in Phase 02.
* **Purpose:** Create an immediate, high-trust first impression with clear security messaging and direct entry into authentication.
* **Component Hierarchy:**
  1. **Brand Header:** ScamShield logo mark, wordmark, and clean `ThemeModeToggle` (Light/Dark).
  2. **Hero Section:**
     - Eyebrow: `AI-POWERED THREAT DETECTION`
     - Headline: `Detect suspicious activity. Understand the risk. Take safer action.`
     - Supporting copy: Enterprise-grade fraud protection across text messages, screenshots, documents, audio, and live calls.
  3. **Primary Action Callouts:**
     - `Get Started` button (navigates to User Signup).
     - `Sign In` button (navigates to User Login).
     - `Analyze Something` button (prompts sign-in before analysis).
  4. **Compact Feature Grid:**
     - 4 core capabilities: Real-time SMS/Link verification, Document analysis, Screenshot analysis, Sentinel call protection.
  5. **Security & Privacy Banner:**
     - Clear privacy statement: Zero audio storage, ephemeral speech analysis, no OTP logging.
  6. **Admin Gateway:** Discreet administrator sign-in footer link.

### Screen 02: User Login (FIXED)
* **Status:** **STRICTLY PRESERVED.** No visual or structural modifications.
* **Inputs:** Email, Password, Remember Me toggle.
* **2FA Challenge:** Supports 6-digit one-time code verification challenge if required.
* **Actions:** Sign In, Switch to Signup, Forgot Password.
* **Endpoints:** `POST /api/auth/login`, `POST /api/auth/login/verify`.

### Screen 03: User Signup (FIXED)
* **Status:** **STRICTLY PRESERVED.** No visual or structural modifications.
* **Inputs:** Full Name, Email, Password, Confirm Password, Terms & Privacy checkbox.
* **Verification Flow:** 6-digit email confirmation code modal/view.
* **Actions:** Create Account, Switch to Login.
* **Endpoints:** `POST /api/auth/signup`, `POST /api/auth/verify-email`.

### Screen 04: Admin Login (FIXED)
* **Status:** **STRICTLY PRESERVED.** Role-isolated login for administrators with 2FA support.
* **Endpoints:** `POST /api/auth/admin/login`, `POST /api/auth/login/verify`.

### Screen 05: Password Reset
* **Status:** Preserved existing functional workflow.
* **Flow:** Enter email -> receive challenge code -> set new password with verification code.
* **Endpoints:** `POST /api/auth/forgot-password`, `POST /api/auth/reset-password`.

---

## 3. Core Application Screens (4 Bottom Tabs)

### Screen 06: Home Dashboard (Tab 1)
* **Purpose:** The central security overview for the authenticated user.
* **Information Architecture:**
  1. **Greeting & User Identity:** `Hello, [Full Name]` derived from `User.fullName`.
  2. **Sentinel Call Protection Status Card:**
     - Live state of Android Call Guardian: `Protected` (Green) or `Inactive` (Neutral).
     - Call state badge (e.g. `Ready`, `Incoming`, `Active Call`, `Service Paused`).
     - Quick toggle or shortcut to Sentinel tab.
  3. **Prominent "Analyze New Input" Action:**
     - Primary button directing to Analyze tab.
  4. **Four Quick-Action Cards:**
     - **Text / URL:** Paste suspicious message or web link.
     - **Image:** Upload screenshot of chat, invoice, or QR code.
     - **PDF:** Upload document or bank statement.
     - **Audio:** Upload recorded voice memo or voicemail.
  5. **Verified Security Statistics (Real Backend Only):**
     - Total Analyses (`total_analyses`)
     - Scams Flagged (`scams_detected`)
     - Verified Safe (`safe_messages`)
     - High Risk Threats (`high_risk`)
     - *Zero fake charts or invented percentages.*
  6. **Recent Analysis Feed:**
     - Top 3–5 recent items from `GET /api/analysis/history`.
     - Displays input type icon, content snippet, relative timestamp, and authoritative `RiskBadge`.
     - Tapping any item opens the full Analysis Result screen.
  7. **Empty & Error Handling:**
     - If history is empty: Clean empty state (`No analyses yet — submit a message or link above`).
     - If API fails: Error card with retry button.

### Screen 07: Analyze (Tab 2)
* **Purpose:** Multi-modal submission interface supporting 4 distinct input types.
* **Supported Categories:**
  1. **Text & URL:** Multi-line text field, paste shortcut, character count, URL auto-detection.
  2. **Image / Screenshot:** Supported formats (`.jpg`, `.jpeg`, `.png`, `.webp`), max 10MB, image thumbnail preview, remove action.
  3. **PDF / Document:** Supported formats (`.pdf`), max 20MB, file metadata card (name, size in KB/MB), remove action.
  4. **Audio File:** Supported formats (`.mp3`, `.wav`, `.m4a`, `.ogg`, `.flac`), max 25MB, file name, duration indicator.
* **Interaction Rules:**
  - Strict input validation before network transmission.
  - Disable submit button during active upload/processing (`_loading == true`) to prevent duplicate submissions.
  - Show genuine progress indicator (indeterminate spinner, no fake progress bars).
  - On success: Navigate directly to Screen 08 (Analysis Result) and trigger dashboard refresh.
  - On error: Inline dismissible error banner explaining exact issue (e.g., file too large, server timeout).

### Screen 08: Analysis Result
* **Purpose:** Transparent, evidence-backed security breakdown of analyzed content.
* **Information Hierarchy:**
  1. **Top Risk Banner:**
     - Risk Score (`0–100`) with circular gauge or clean numerical badge.
     - Severity Label (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`).
     - Classification (`GENUINE`, `SUSPICIOUS`, `SCAM`).
     - Threat Category tag (e.g., `Phishing`, `Bank Impersonation`, `Lottery Fraud`).
  2. **Analyzed Input Preview:**
     - Truncated content with "Show full content" expandable viewer for long messages.
     - Safe rendering (defanged links, no automatic link clicking).
  3. **Detected Threat Indicators:**
     - List of specific scam signals detected by NLP/ML (e.g., `Urgency Language`, `Suspicious URL Shortener`, `Request for OTP`).
  4. **Supporting Knowledge Evidence (RAG Pipeline):**
     - Matches from the verified scam knowledge base.
     - Title, matched pattern snippet, source reference, and similarity percentage.
     - *Similarity percentage is explicitly distinguished from scam probability.*
  5. **AI Reasoning & Limitations:**
     - Plain-language explanation of why this conclusion was reached.
     - Limitation notice if any microservice was unavailable (`COMPLETED_WITH_LIMITATIONS`).
  6. **Recommended Safe Actions:**
     - Actionable steps (e.g., `Do not share OTP`, `Block sender`, `Verify directly with bank`).
  7. **Navigation Controls:**
     - `Back to Dashboard` (Tab 0).
     - `Analyze Another` (Tab 1).

### Screen 09: Sentinel — Live Call Protection (Tab 3)
* **Purpose:** Transparent, privacy-preserving live phone call monitoring and threat alerting.
* **Component Inventory:**
  1. **Sentinel Protection Switch:**
     - Master enable/disable toggle with confirmation dialogs explaining permissions.
  2. **Permission & Capability Matrix:**
     - Phone State permission (`READ_PHONE_STATE`).
     - Call Screening role status (`CallScreeningService`).
     - Microphone permission (`RECORD_AUDIO`) for opt-in live audio capture.
     - Foreground Service status (`FOREGROUND_SERVICE_MICROPHONE`).
  3. **Live Call Status Banner:**
     - Current state: `Idle / Monitoring`, `Incoming Call`, `Active Call (01:24)`, `Call Ended`.
     - Active call duration timer.
  4. **Speech-to-Text Transcription Monitor:**
     - Live streaming segments from on-device or Whisper STT.
     - Clear indicator: `Ephemeral audio — discarded immediately after chunk processing`.
  5. **Real-Time Threat Level:**
     - Live risk level dynamically updated via `guardian_live_analysis_service`.
     - Escalation alerts if high-risk phrases (e.g., OTP request, bank suspension threats) are detected.
  6. **Protective Action Guidance:**
     - Immediate guidance displayed: `Do NOT share any 6-digit codes`, `Ask for official callback number`.
  7. **Last Finalized Call Summary Card:**
     - Direct button to view the full persisted summary of the last call.

### Screen 10: History (Tab 4)
* **Purpose:** Account-scoped, persistent audit trail of previous analyses and protected calls.
* **Dual-Tab Architecture:**
  - **Tab A: Content Analyses:** List of submitted texts, images, PDFs, and audio files.
  - **Tab B: Call Records:** List of monitored phone calls with duration, final risk score, and date.
* **Controls & Features:**
  - Risk Level filter chips (`All`, `Low`, `Medium`, `High`, `Critical`).
  - Search field for filtering content snippets or categories.
  - Pull-to-refresh.
  - Tap card to open full Analysis Result (Screen 08) or Call Summary (Screen 11).

### Screen 11: Call Summary Detail
* **Purpose:** Detailed review of a finalized call session.
* **Data Fields:**
  - Session ID, start time, end time, duration.
  - Final risk score, severity, and classification.
  - Scam category identified.
  - Indicators detected during call conversation.
  - RAG evidence patterns matched.
  - Protection actions taken or recommended.
  - Processing integrity indicators (Audio status, transcription status, analysis status).

---

## 4. Profile Menu & Secondary Screens

### Screen 12: Profile Screen
* **Accessible From:** Top-right profile avatar in the app bar.
* **Features:**
  - Authenticated user name, email, account role (`User`).
  - Account status (`Active`, `Verified`).
  - Appearance preference: `Dark Mode` / `Light Mode` switch.
  - Session sign-out button with confirmation dialog.

### Screen 13: Community Insights
* **Accessible From:** Profile Menu -> Community Insights.
* **Features:**
  - List of community-submitted scam reports fetched from `GET /api/community/reports`.
  - Report cards showing category, summary, evidence snippet, reporter handle, and date.
  - "Report a Scam" button opening report submission modal (`POST /api/community/reports`).

### Screen 14: Settings Screen
* **Accessible From:** Profile Menu -> Settings.
* **Features:**
  - Protection preferences: Sentinel auto-start, microphone opt-in toggle.
  - Notification alert preferences.
  - Link to Privacy & Protection Center.

### Screen 15: Privacy & Protection Center
* **Accessible From:** Settings or Profile Menu.
* **Guarantees Presented:**
  - **No Permanent Audio Recording:** Chunks processed in RAM and destroyed.
  - **Ephemeral Transcripts:** Cleared immediately upon call session finalization.
  - **No Credential Logging:** Passwords, OTPs, and card details never written to logs.
  - **Explicit Consent:** App never hangs up or blocks calls autonomously.

### Screen 16: Help & Support
* **Accessible From:** Profile Menu.
* **Features:**
  - FAQ for common scam types and app capabilities.
  - Trust & Safety contact: `security@scamshield.ai`.
  - App version and build details.

---

## 5. Admin Portal Experience

### Screen 17: Admin Portal Screen
* **Access:** Restricted to users authenticated via Admin Login (`role == "admin"`).
* **Capabilities:**
  - **Overview:** System metrics, review case counters, community report counters.
  - **Review Queue:** Review pending scam classifications, assign decisions (`Confirm Scam`, `Mark Safe`).
  - **Community Moderation:** Approve, flag, or archive user-submitted community reports.
  - **Knowledge Base:** Search, create, edit, approve, archive, and trigger vector re-indexing for scam patterns.
  - **User Management:** View user list, inspect verification status, toggle user active/suspended state.
  - **System Monitoring:** Health endpoints (`/admin/health`), database connection status, AI warmup status.
  - **Audit Logs:** Paginated security and administrative action audit trail.

---

## 6. Standard Screen State Specifications

Every network-backed screen must implement all 9 canonical states:

```text
┌─────────────────────────────────────────────────────────────┐
│ 1. INITIAL LOADING    : Skeleton shimmer loaders            │
│ 2. SUCCESS RESPONSE   : Content loaded, smooth rendering    │
│ 3. EMPTY DATASET      : Clean illustration + helpful CTA    │
│ 4. NETWORK UNAVAILABLE: "Check your internet connection"    │
│ 5. TIMEOUT            : "Server took too long. Tap to retry"│
│ 6. BACKEND FAILURE    : 5xx error normalized notice         │
│ 7. EXPIRED SESSION    : Clear session, redirect to login    │
│ 8. PARTIAL RESULT     : Notice for degraded microservice    │
│ 9. REFRESH & RETRY    : Pull-to-refresh & retry action      │
└─────────────────────────────────────────────────────────────┘
```
