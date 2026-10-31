# Phase 02 Device Validation: Physical Android Verification

**Project:** ScamShield 2.0  
**Phase:** Phase 02 — Landing Page Redesign Only  
**Target Hardware:** OnePlus CPH2467 (`android-arm64`, Android 15 / API 35)  
**Status:** Hot Restart Ready • Verification Checklist Provided  

---

## 1. Physical Device Environment

- **Target Device:** OnePlus CPH2467 (`2511885a`)
- **OS Level:** Android 15 (API 35)
- **Active Session:** An interactive `flutter run` terminal session is currently active and attached to this device.
- **Update Method:** Press **`R`** (hot restart) in the active terminal to load the redesigned Landing Page onto the device.

---

## 2. Interactive Verification Checklist for User

- [ ] **Section A: Brand Header**
  - Verify original ScamShield launcher icon (`assets/scamshield_launcher.png`) displays crisply.
  - Verify bold title `ScamShield` and subtitle `AI-POWERED SCAM PROTECTION`.
  - Tap capsule `ThemeModeToggle` in the top right: Confirm smooth transition between Light mode and Dark mode.

- [ ] **Section B: Hero Security Illustration & Headline**
  - Verify central cyan/teal shield with white checkmark and glowing halo.
  - Verify 4 floating capability chips (`Messages`, `Calls`, `Images`, `PDF & Docs`) around the shield.
  - Verify headline: `"Don't Just Detect Scams.\nUnderstand Them."` with `"Understand Them."` in primary teal.
  - Verify supporting copy: `"Analyze suspicious messages, calls, images, documents and more with AI — and stay one step ahead."`

- [ ] **Section C: Primary Action Buttons**
  - Verify 52px high filled teal `Get Started →` button.
  - Verify 52px high secondary outlined `Login` button.
  - Tap `Get Started →`: Confirm immediate transition to User Signup screen. Press back to return.
  - Tap `Login`: Confirm immediate transition to User Login screen. Press back to return.

- [ ] **Section D: Quick Capability Shortcuts**
  - Verify 4 cards in a row: `Messages`, `Calls`, `Images`, `PDF & Docs`.
  - Tap any card: Verify informational floating SnackBar appears informing user of capability.

- [ ] **Section E: Trusted Protection Strip**
  - Verify micro-header `"TRUSTED PROTECTION"` with subtle divider lines.
  - Verify 3 pillars: `AI-Powered Analysis`, `Your Data Stays Private`, `Safer Digital Communities`.

- [ ] **Section F: Feature Overview ("Why Choose ScamShield?")**
  - Scroll down to feature section.
  - Verify 4 feature cards: `Message Analysis`, `Call Protection (Sentinel)`, `Image & Document Scan`, `AI-Powered Insights`.
  - Verify `"Your Privacy Comes First"` card with 4 checked commitments.

- [ ] **Section G: "Built for a Safer Digital You" & Closing Actions**
  - Verify headline with highlighted `"Digital You"`.
  - Verify 3 capability pills: `Messages`, `Calls`, `Documents`.
  - Verify intelligence highlight card with 3 indicator dots.
  - Verify closing `Get Started →` and `Login` buttons.

- [ ] **Section H: Minimal Footer**
  - Verify copyright and legal links (Privacy, Terms, Help, Contact) without overflow.
  - Tap **`Admin Sign-in`**: Verify it navigates directly to the Admin Portal sign-in screen.
