# ScamShield — Mobile Phase Handoff & Physical Device Testing Guide

**Date:** October 25, 2026  
**Status:** **AWAITING USER APPROVAL OF WEBSITE & BACKEND BEFORE PHYSICAL TESTING**  
**Repository:** `d:\Projects\ScamShieldAI\mobile_app`  
**Shared Production Backend:** `https://scamshield-backend-f0wc.onrender.com/api`  

---

## 1. Shared Backend Contract Compatibility Status

All backend performance optimizations were executed with strict backward and forward compatibility for the Flutter Android application:

1. **Shared Route Prefix:** Both clients use the canonical `/api` prefix. The backend dual-mounts Guardian routes (`/api/guardian/*` and `/guardian/*`) and calls routes (`/api/calls/*` and `/calls/*`) ensuring zero breaking changes.
2. **Schema & Model Consistency:** The response format for `AnalysisResponse` (`risk_score`, `risk_level`, `classification`, `category`, `explanation`, `recommended_action`, `retrieved_evidence_data`) is 100% identical and unchanged.
3. **Live Call Guardian Architecture:** The consented speakerphone audio capture architecture (M9.6, M9.7, M9.9, M9.10) is fully preserved. No cellular baseband capture was introduced.
4. **Automated Verification:**
   - `flutter analyze` completed with **0 issues found** (12.5s).
   - `flutter test` completed with **166 of 166 tests passing** (57.0s).

---

## 2. Prerequisites for Physical Device Testing

Once you review and approve the website/backend results, follow these instructions to test the app on your physical Android phone:

1. Connect your Android phone to your PC via a USB data cable.
2. Enable **Developer Options** and turn on **USB Debugging** on the phone.
3. Open a terminal and verify the phone is recognized:
   ```powershell
   adb devices
   ```
   *(Ensure your device appears with the status `device`, not `unauthorized`)*.

---

## 3. Exact Commands for Physical Device Testing

### Option A: Run directly against the Render Cloud Backend (Recommended)
```powershell
cd d:\Projects\ScamShieldAI\mobile_app
flutter run --dart-define=API_BASE_URL=https://scamshield-backend-f0wc.onrender.com/api
```

### Option B: Run with USB Reverse against a Local Backend (if testing offline/local)
```powershell
cd d:\Projects\ScamShieldAI\mobile_app
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

---

## 4. Scenarios to Verify on the Phone

### Scenario 1 — Login & Authentication
1. Open the ScamShield app on the phone.
2. Sign in with your verified user account (`gosangarijoshitha@gmail.com`).
3. Confirm that the dashboard loads immediately and the authorization token is saved.

### Scenario 2 — Analyze Submission & Response Timing
1. Tap the **Analyze** tab at the bottom navigation bar.
2. Enter this test text:
   ```
   URGENT: State Bank alert. Your account 4821 is suspended. Complete mandatory KYC immediately at http://sbi-secure-update.in or your card will be deactivated.
   ```
3. Tap **ANALYZE**.
4. Observe the UI:
   - Button shows `ANALYZING…` with a progress indicator.
   - Button is disabled during submission (double-taps are blocked).
   - Results screen renders with Risk Level: **CRITICAL (100)**, Classification: **SCAM**, and recommended safe actions in English/Hindi/Telugu.
   - Measure client-observed duration (target: ~1.5s – 3.5s warm).

### Scenario 3 — Live Call Guardian (Consented Speakerphone)
1. On the home dashboard, tap the **Live Call Guardian** toggle.
2. Accept the required permissions (Microphone, Phone state, Notifications).
3. Confirm the status banner indicates Guardian protection is active.
4. Verify call state transition when an incoming call arrives on speakerphone.

---

## 5. Live Log Capture Command

To stream Android and Flutter application logs during your testing session:

```powershell
adb logcat -v time | Select-String -Pattern "flutter", "ScamShield", "Guardian"
```
