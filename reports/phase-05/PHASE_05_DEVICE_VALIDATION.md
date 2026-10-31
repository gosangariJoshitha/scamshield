# ScamShield 2.0 — Phase 05 Device Validation Guide & Checklist
## Physical Device Testing on OnePlus CPH2467 (Android 15 Target)

**Document ID**: `PHASE_05_DEVICE_VALIDATION.md`  
**Phase**: 05 — Analysis Result Screen  
**Device**: OnePlus CPH2467 (OnePlus 11R 5G)  
**Operating System**: Android 15 (OxygenOS 15 / API Level 35)  
**Date**: October 26, 2026  
**Status**: Ready for Interactive Device Verification  

---

## 1. Prerequisites & Environment Check

Before beginning physical device validation:
1. Ensure the OnePlus CPH2467 is connected via USB debugging or wireless ADB.
2. In the running terminal, trigger a Hot Reload (`r`) or Hot Restart (`R`) to apply all Phase 05 updates immediately.
3. Verify backend connectivity:
   - Backend endpoint: `https://scamshield-backend-f0wc.onrender.com/api`
   - Active network connection on the phone (Wi-Fi or Mobile Data).
4. Authenticate using your active account or test account (`user@scamshield.ai`).

---

## 2. Interactive Device Verification Checklist

Use the following test cases to validate each feature on the physical device. Check each box as you complete verification.

### Section A: Visual Design & Theme Parity (`analysis result page.jpeg`)

- [ ] **TC-01: Light Theme Visual Rendering**
  - Navigate to an analysis result screen in Light Mode.
  - Verify background color is clean soft white/slate (`#F4F7FA`).
  - Verify card surfaces are `#FFFFFF` with subtle, crisp shadows and border outlines (`#E2E8F0`).
  - Verify text hierarchy: Title is dark navy (`#102A43`), body text is `#17212B`, and captions are `#64748B`.
  
- [ ] **TC-02: Dark Theme Visual Rendering**
  - Switch device or app theme to Dark Mode (via Profile or quick settings).
  - Verify dark background is `#101820` and card surface is `#192630` / `#22343F`.
  - Verify headline text is high-contrast light slate (`#F1F5F9`) and secondary text is `#B4C2CC`.
  - Verify the green/red shield banners and glowing sparkles have appropriate dark theme contrast without neon glare.

---

### Section B: Safe / Lower-Risk Result Presentation

- [ ] **TC-03: Safe Banner & Sparkles**
  - Submit a known benign message (e.g., from Sample Scenarios: `"Meeting is rescheduled to 4 PM tomorrow in Conference Room B."`).
  - When the result loads, verify:
    - Radiant pale green banner with gentle rounded corners.
    - Centered circular green shield with verified white checkmark.
    - Two sparkle stars (`✦`) flanking the shield badge.
    - Title: **`Safe`** in bold green typography.
    - Subtitle: **`No known scam indicators were detected.`** (or backend-derived text).

- [ ] **TC-04: Safe Details & Grounded Summary**
  - Verify the **Summary** card displays the backend's actual explanation.
  - In the **Details** card, verify:
    - **Content Type**: Blue badge with message icon (`Text Message`).
    - **Risk Level**: Green dot with label **`Low`**.
    - **Confidence**: Truthful percentage if returned by model (e.g., `92%`), or omitted if null.
    - **Links Detected**: Shows `0` or `No suspicious links`.
    - **Scam Indicators**: Displays `None detected`.
    - **Message Pattern**: Displays `Normal / Legitimate` or general classification.
    - **Why Not Flagged**: Displays verified explanation.

---

### Section C: High-Risk / Scam Detected Result Presentation

- [ ] **TC-05: Scam Detected Banner & High-Risk Alert**
  - Submit a known phishing/prize scam message (e.g., `"You have won a prize of ₹50,000! Click http://bit.ly/claim-now"`).
  - When the result loads, verify:
    - Radiant pale red banner with subtle crimson borders.
    - Glowing red shield with white exclamation alert (`!`).
    - Title: **`Scam Detected`** in bold red typography.
    - Subtitle: **`This message shows multiple scam indicators.`**

- [ ] **TC-06: Scam Details & Indicator Chips**
  - In the **Details** card, verify:
    - **Risk Level**: Red dot with label **`High`** or **`Critical`**.
    - **Links Detected**: Formatted in bold red text (e.g., `1 Suspicious Link`).
    - **Scam Indicators**: Shows real comma-separated indicator list (e.g., `Prize Claim, Urgent Action, Shortened Link`).
    - **Message Pattern**: Identifies pattern (e.g., `Prize Claim`, `Urgent Financial Request`).
    - **Why Flagged**: Displays pipeline explanation regarding why content was flagged.

---

### Section D: Multilingual Safety Recommendations (`analysis app page(lm).jpeg`)

- [ ] **TC-07: English Recommendation View**
  - In the **Recommendation** card, verify the 3-pill segmented tab: `[English] [हिंदी] [తెలుగు]`.
  - With `English` selected (default), verify:
    - Active pill is highlighted in primary brand color with bold text.
    - Lightbulb / alert icon is displayed in the card header.
    - Real canonical safety actions appear as clear bullet points.
    - Text wraps cleanly with no clipping.

- [ ] **TC-08: Dynamic Hindi (हिंदी) Recommendation**
  - Tap the **`हिंदी`** pill.
  - Verify instant in-memory tab switch without any loading spinner or network delay.
  - Verify authentic Devanagari script rendering (e.g., `संदिग्ध लिंक पर क्लिक न करें।`, `OTP या पासवर्ड किसी के साथ साझा न करें।`).
  - Verify glyph ligatures and conjunct characters render crisply.

- [ ] **TC-09: Dynamic Telugu (తెలుగు) Recommendation**
  - Tap the **`తెలుగు`** pill.
  - Verify instant in-memory tab switch.
  - Verify authentic Telugu script rendering matching design reference `analysis app page(lm).jpeg` (e.g., `ఈ లింక్‌పై క్లిక్ చేయవద్దు.`, `మీ వ్యక్తిగత సమాచారం, OTP లేదా బ్యాంక్ వివరాలు పంచుకోవద్దు.`).
  - Verify complex vowel markers and sub-base consonants render without clipping or overlap.

- [ ] **TC-10: Honest Fallback on Missing Translation**
  - If viewing a record where the backend returned only English guidance:
    - Tap **`తెలుగు`** or **`हिंदी`**.
    - Verify the screen displays an honest informational banner:
      `ℹ️ Translation in Telugu (తెలుగు) is unavailable for this response. Showing verified English guidance.`
    - Verify the app does **not** silently display English without explanation.

---

### Section E: Navigation & History Persistence

- [ ] **TC-11: Analyze Another Navigation**
  - Tap the **`Analyze Another`** button at the bottom of the result screen.
  - Verify smooth transition back to the Analyze Submission Screen.
  - Verify the input field is reset and ready for new input.
  - Verify previous analysis was not accidentally re-submitted.

- [ ] **TC-12: Automatic Persistence & Save to History Button**
  - Note the Analysis ID displayed in the timestamp or header.
  - Tap the **`Save to History`** button.
  - Verify an immediate SnackBar confirms:
    `Analysis #<ID> is securely stored in your History.`
  - Tap the SnackBar's **`View`** action (or navigate to History tab).
  - Verify the analysis appears at the top of the History list.
  - Verify that opening the record from History **does not** create a duplicate record.

- [ ] **TC-13: System Back & Top Bar Navigation**
  - From the result screen, tap the top App Bar back arrow (`←`).
  - Verify appropriate navigation back to the previous screen (Analyze or History).
  - Test Android system back gesture (swipe from edge).
  - Verify the app does not trigger another analysis request.

---

### Section F: Display Scaling & Accessibility

- [ ] **TC-14: Large Accessibility Font Scale**
  - On the OnePlus CPH2467, go to:
    `Settings > Display & Brightness > Font & display size > Font size (Large / Largest)`.
  - Return to the ScamShield result screen.
  - Verify all text cards, details labels, and recommendation bullets scale legibly without overflowing or cutting off.
  - Verify vertical scrolling remains smooth throughout the entire screen.

- [ ] **TC-15: Long Explanation & Multi-Indicator Layout**
  - Submit or view an analysis with a long multi-sentence summary and 4+ indicators.
  - Verify that lines wrap cleanly within cards.
  - Verify the bottom buttons (`Analyze Another`, `Save to History`) remain accessible at the bottom of the scroll view without being obscured by the Android system navigation bar.

---

## 3. Physical Device Verification Sign-Off Table

| Test Case | Description | Pass / Fail | Notes / Observations |
| :--- | :--- | :---: | :--- |
| **TC-01** | Light Theme Visuals | [ ] | |
| **TC-02** | Dark Theme Visuals | [ ] | |
| **TC-03** | Safe Banner & Sparkles | [ ] | |
| **TC-04** | Safe Details & Summary | [ ] | |
| **TC-05** | Scam Detected Banner | [ ] | |
| **TC-06** | Scam Details & Indicators | [ ] | |
| **TC-07** | English Recommendations | [ ] | |
| **TC-08** | Hindi (हिंदी) Rendering | [ ] | |
| **TC-09** | Telugu (తెలుగు) Rendering | [ ] | |
| **TC-10** | Missing Translation Notice | [ ] | |
| **TC-11** | Analyze Another Action | [ ] | |
| **TC-12** | Save to History / View | [ ] | |
| **TC-13** | Back Navigation Safety | [ ] | |
| **TC-14** | Android Font Scaling | [ ] | |
| **TC-15** | Long Text Wrapping | [ ] | |

**Tester Signature / Reviewer**: `___________________________`  
**Date**: `October 26, 2026`  
