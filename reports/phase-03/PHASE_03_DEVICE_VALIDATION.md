# Phase 03 Physical Device Validation Checklist

**Target Device:** OnePlus CPH2467 (Android 15)  
**App:** ScamShield 2.0 (`mobile_app/`)  
**Backend:** `https://scamshield-backend-f0wc.onrender.com`  
**Reference Document:** `home and analysis page.jpeg` (Screen 1: Home Dashboard)  

---

## Instructions for Physical Device Testing

Hot reload (`r`) or hot restart (`R`) the running Flutter application in the active terminal, or run:
```bash
flutter run -d <device-id>
```

---

## 1. Landing Page CTA Responsiveness Checklist

- [ ] **Get Started Button Tap:**
  - Tap `Get Started →` in the Hero section or closing section.
  - Observe immediate tactile splash feedback (`InkRipple`).
  - Observe button showing spinner alongside `Opening Sign Up...`.
  - Confirm the User Signup screen opens without delay.
- [ ] **Login Button Tap:**
  - Tap `Login` in the Hero section or closing section.
  - Observe button showing spinner alongside `Opening Login...`.
  - Confirm the User Login screen opens without delay.
- [ ] **Rapid Double-Tap Protection:**
  - Tap repeatedly on either button; confirm only a single authentication screen is pushed.

---

## 2. Home Dashboard Visual Hierarchy & Branding

- [ ] **Header:**
  - Verify original ScamShield launcher icon (`assets/scamshield_launcher.png`) in 40×40 container.
  - Verify `ScamShield` wordmark and `AI-POWERED SCAM PROTECTION` subtitle.
  - Verify notification bell and profile avatar initial/icon.
- [ ] **Personalized Greeting:**
  - Verify greeting matches logged-in user: `Hello, {YourFirstName} 👋`.
  - Verify supporting text: `Stay alert and stay safe with ScamShield.`.
- [ ] **Sentinel Protection Status Card:**
  - When Sentinel service is active: verify vibrant green card with shield checkmark, `You're Protected`, and `AI protection is active. Keep checking suspicious content.`.
  - When Sentinel is off: verify warning status with prompt to open Sentinel.
  - Tap the card; verify it navigates directly to the Sentinel screen.

---

## 3. Real Data Metrics & Recent Activity

- [ ] **Overall Stats:**
  - Verify 4 columns: `Messages Analyzed`, `Calls Checked`, `Images Scanned`, `Documents Analyzed`.
  - Verify numbers reflect actual database counts (or `0` if no scans have been performed yet).
  - Verify screenshot sample numbers (`24`, `8`, `6`, `2`) are NOT present.
- [ ] **Quick Actions:**
  - Tap `Analyze Message` → verifies Analyze screen opens with Text tab active.
  - Tap `Call Protection` → verifies Sentinel screen opens.
  - Tap `Image & Document` → verifies Analyze screen opens with Image tab active.
  - Tap `Analyze Audio` → verifies Analyze screen opens with Audio tab active.
- [ ] **Recent Activity Feed:**
  - If analyses exist: verify risk pills (`High Risk` red, `Suspicious` amber, `Safe` green) and local timestamps.
  - If no analyses exist: verify clean empty state `No activity yet` / `Your completed analyses will appear here.`.
  - Tap `View All` → verifies History tab opens.
- [ ] **Stay Informed Card:**
  - Tap the lightbulb card; verify educational scam safety modal dialog appears.

---

## 4. Theme & Accessibility

- [ ] **Theme Switching:**
  - Toggle light/dark mode via Settings or system drawer.
  - Verify `#F4F7FA` light background vs `#101820` dark background.
  - Verify card surfaces (`#FFFFFF` in light, `#192630` in dark) and border contrast.
- [ ] **Scrolling & Responsiveness:**
  - Scroll from top to bottom; verify smooth 60/120fps scrolling with zero RenderFlex overflow warnings.
  - Pull down to refresh; verify dashboard reloads real backend data cleanly.
- [ ] **Frozen Surfaces Check:**
  - Verify Login, Signup, Admin Portal, and Analyze screens remain 100% intact.
