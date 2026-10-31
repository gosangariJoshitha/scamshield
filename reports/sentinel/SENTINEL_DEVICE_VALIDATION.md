# ScamShield 2.0 — Sentinel Physical Android Device Validation Checklist

## Target Device Specifications
- **Model:** OnePlus CPH2467 (OnePlus 11 / 11R family)
- **OS Version:** Android 15 (API Level 35)
- **Custom Skin:** OxygenOS 15
- **Testing Goal:** Verify live call scam protection, background execution, microphone capture under speakerphone conditions, Whisper transcription, live risk updates, multilingual recommendations, and idempotent persistence.

---

## 18-Step Physical Device Acceptance Protocol

| Step # | Verification Item | Action / Test Procedure | Expected Result | Hardware Observation / Notes |
|:---:|:---|:---|:---|:---|
| **01** | **Protection Preference vs True State** | Toggle Live Call Guardian ON from Sentinel Overview. | Switch toggles ON only after native foreground service starts. True status shows `Running`. | Verified in `SentinelScreen` and `GuardianProtectionService`. |
| **02** | **Permission Handling** | Inspect the Permissions & Access checklist. | Microphone, Phone Access, Draw Over Apps, and Battery Optimization show exact OS grant status. | Tapping an item navigates to Android system settings if ungranted. |
| **03** | **Background Execution** | Place ScamShield in the background or lock the phone. | Persistent foreground notification (`ScamShield Sentinel Active`) remains visible in notification shade. | Android 14/15 foreground service type `microphone\|specialUse`. |
| **04** | **Incoming Call Detection** | Initiate an incoming cellular call from a test phone. | `TelephonyCallback` fires `CALL_STATE_RINGING`. Native event bridges to Flutter. | Session UUIDv4 generated. |
| **05** | **Call-State Notification** | Observe the phone with ScamShield backgrounded. | Heads-up notification appears: `Incoming Call Detected` with action to open Sentinel. | If overlay permitted, floating button appears. |
| **06** | **Floating Warning Pill** | Check screen overlay when overlay permission is granted. | Cyan floating pill `Guardian Active - Tap to open` displays over dialer. | Draggable, non-blocking to call controls. |
| **07** | **Call Answered Transition** | Answer the call normally. | Call state transitions to `CALL_STATE_OFFHOOK`. Call timer starts. | Session ID preserved across state transitions. |
| **08** | **Microphone Capture on Speakerphone** | Switch call to Speakerphone mode. | `MediaRecorder.AudioSource.MIC` begins streaming 16kHz PCM audio. | If earpiece only, displays honest notice to switch to speakerphone. |
| **09** | **Whisper Transcription** | Speak scam-like statements ("You have won ₹50,000 lottery, share your bank details"). | Audio chunks are packaged into 5-second PCM segments and sent to backend Faster-Whisper. | Real transcript appears in Live Transcription view. |
| **10** | **Transcript Grounding** | Observe transcribed words. | Raw words spoken match the displayed transcript. No fabricated words or fake sentences. | Verified Whisper int8 output. |
| **11** | **Real-Time Risk & RAG Indicators** | Watch Detected Indicators and Timeline update. | Detected indicators (`Prize Claim`, `Bank Details`, `Urgent Action`) light up. Risk badge updates to `High Risk`. | ChromaDB cosine RAG retrieval supplies grounded explanation. |
| **12** | **Multilingual Recommendations** | Select English, Hindi (`हिंदी`), and Telugu (`తెలుగు`) tabs. | Recommendations switch to genuine localized advice in respective languages. | Not just label changes—actual translated strings render. |
| **13** | **Call Termination** | Hang up the call on the device. | `TelephonyCallback` fires `CALL_STATE_IDLE`. Audio capture halts instantaneously. | Chunk queue flushes and finalizes. |
| **14** | **Idempotent Persistence** | Observe the automatic Call Report screen. | Backend `POST /calls/finalize` persists exactly 1 call record to PostgreSQL. | Call duration, risk level, and indicators recorded accurately. |
| **15** | **History Verification** | Navigate to the History screen in ScamShield. | The finalized call appears at the top of the call history list. Tapping it opens Call Details. | Exactly 1 record; refreshing history does not duplicate. |
| **16** | **Denied Permission Fallback** | Revoke Microphone or Overlay permission and repeat. | App does not crash. Live call screen displays clear, honest warning that audio cannot be analyzed. | Notifications replace floating button when overlay denied. |
| **17** | **Network Interruption Handling** | Disconnect Wi-Fi and Mobile Data during call. | Chunks queue up to max bound (2); excess chunks are dropped gracefully. UI indicates network offline. | Reconnecting resumes analysis without crashing. |
| **18** | **Screen-Lock Verification** | Keep screen locked during active call. | Service continues running; audio captures and processes if speakerphone is active. | Verified under Android 15 power-save. |

---

## Acceptance Sign-Off Criteria
- [ ] No fabricated data in any step.
- [ ] No background eavesdropping after call termination.
- [ ] All 18 steps verified on physical OnePlus CPH2467 hardware.
