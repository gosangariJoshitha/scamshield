# Phase 01 Device Validation & Physical Testing Guide

**Project:** ScamShield 2.0  
**Phase:** Phase 01 — Design System & Shared Components  
**Target Hardware:** Physical Android Device (e.g., OnePlus CPH2467 / Android 15 / API 35)  
**Status:** Ready for Physical Device Verification  

---

## 1. Known Limitations in Phase 01

1. **Screen Adoption:** Phase 01 establishes the foundational design tokens, theme system, and shared components. Screen layouts (Landing, Home Dashboard, Analyze, Results, Sentinel, History, More) will adopt these components in their respective planned phases (Phases 02 through 08).
2. **Pre-existing Screens:** Existing screens remain operational and backward-compatible via `CyberCard = ScamShieldCard` and legacy color aliases.
3. **Authentication Screens:** User Login, User Signup, and Admin Login remain strictly frozen.

---

## 2. Physical Device Verification Checklist

To verify Phase 01 on a physical Android device or emulator:

### Step 1: Run the App on Your Device
From the `mobile_app/` directory:
```bash
flutter run
```
Or if an active session is already running, press `r` (hot reload) or `R` (hot restart) in your terminal.

---

### Step 2: Verification Steps

#### 1. Typography & Inter Font Rendering
- [ ] Observe text elements on screen (app bar, buttons, dialogs).
- [ ] Verify that text renders in the **Inter** typeface (crisp geometric sans-serif) without falling back to basic monospace or unstyled serif.
- [ ] Increase system font size in Android Settings (e.g., to Largest / 1.3x font scale).
- [ ] Verify that text wraps cleanly and does not clip or overflow outside of standard containers.

#### 2. Theme Switching & Color Palette
- [ ] Toggle between Light and Dark mode using the app's theme switch.
- [ ] **Dark Mode:**
  - Verify deep blue/black background (`#101820`).
  - Verify dark card surface (`#192630`) and borders (`#2C3E50`).
  - Verify teal primary accents (`#65D4D8`).
- [ ] **Light Mode:**
  - Verify crisp light background (`#F4F7FA`).
  - Verify white card containers (`#FFFFFF`) with subtle borders (`#D9E2EC`).
  - Verify deep teal primary accents (`#086B73`).

#### 3. Reusable Shared Components
- [ ] **PrimaryButton:**
  - Verify 52px height and accessible touch area.
  - Verify deep teal filled background and white label.
  - Verify tap ripple/feedback.
- [ ] **SecondaryButton:**
  - Verify 52px height and clean outlined border.
- [ ] **ScamShieldCard / CyberCard:**
  - Verify 16px corner radius and 1px border.
  - Verify surface elevation and dark/light contrast.
- [ ] **RiskBadge:**
  - Verify that badges display both icon and label (Low, Medium, High, Critical) with high contrast.

#### 4. Frozen Screens & Safety Boundaries
- [ ] Navigate to Login / Signup / Admin Login.
- [ ] Verify that form fields, validators, and layout remain completely untouched and fully functional.
