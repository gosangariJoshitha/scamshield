# ScamShield 2.0 — Sentinel Privacy Policy & Android Platform Limitations

## 1. Truthful Android Platform Limitations (Android 15 / API 35 Focus)

ScamShield operates strictly within the lawful, secure, and privacy-conscious boundaries of the Android Operating System. The application reports its true physical state to the user at all times rather than simulating fake success or promising unsupported capabilities.

### A. Cellular Call Audio Isolation
- **Platform Reality:** Beginning in Android 6.0 and reinforced progressively up to Android 15 (target device: OnePlus CPH2467, API 35), Google explicitly restricts third-party applications from reading incoming and outgoing cellular voice streams via `MediaRecorder.AudioSource.VOICE_CALL` or `VOICE_DOWNLINK`.
- **System Dialers Only:** That capability is reserved exclusively for the active default dialer or system-signed apps.
- **Truthful Alternative Implemented:** ScamShield captures speech via `MediaRecorder.AudioSource.MIC` when:
  1. The user explicitly opts in to microphone audio protection.
  2. The incoming or active call is placed on speakerphone (or hands-free).
- **No Deceptive Fallback:** If the call is on earpiece only, the UI honestly displays:
  `Call active but audio unavailable — switch to speakerphone for live scam analysis.`

### B. Caller Identity & Phone Number Disclosure
- **Telephony Callback Bounds:** On Android 15, `TelephonyCallback.CallStateListener` signals call states (`RINGING`, `OFFHOOK`, `IDLE`) without exposing the incoming phone number unless the user grants sensitive `READ_CALL_LOG` permissions or sets ScamShield as the default call-screening assistant.
- **No Mock Numbers:** In compliance with the Master Prompt, ScamShield never fabricates fake phone numbers or sample caller names. If the caller identity is unexposed by Android, it is labeled truthfully as `"Unknown Number"` or `"Incoming Call"`.

### C. Android 14+ Foreground Service Types
- Modern Android versions require specific `android:foregroundServiceType` declarations in `AndroidManifest.xml` for any background service.
- ScamShield's `CallStateGuardianService` declares:
  ```xml
  android:foregroundServiceType="microphone|specialUse"
  ```
- Android enforces that the microphone may only be accessed while a visible persistent notification with a distinct channel is posted to the notification shade.

### D. Overlay & Floating Button Constraints
- **Permission Required:** Floating warning surface over native call screens requires `ACTION_MANAGE_OVERLAY_PERMISSION` (`android.permission.SYSTEM_ALERT_WINDOW`).
- **Graceful Fallback:** If the user denies or revokes overlay permission, ScamShield does not crash or fake an in-app overlay. It falls back to High-Priority Android Notifications (`NotificationCompat.PRIORITY_HIGH`) with heads-up display.

### E. OEM Battery Optimization & Process Lifecycle
- Devices such as OnePlus (OxygenOS) apply aggressive background killing policies.
- ScamShield informs the user via the Permissions & Access checklist if battery optimization is killing the background observer and offers a direct link to battery exclusion settings.

---

## 2. Privacy Architecture & Data Retention Discipline

ScamShield implements a Zero-Audio-Retention policy:

| Data Type | Retention Window | Storage Medium | Transmitted To |
|:---|:---|:---|:---|
| **Raw PCM Audio** | 5.0 seconds (ephemeral) | Transient RAM buffer | Backend `/guardian/transcription/chunk` |
| **Persisted Audio Files** | None (0 seconds) | Never written to disk | Nowhere |
| **Partial Transcripts** | In-memory during call | Transient State | Backend analysis |
| **Final Transcript Excerpt** | Call duration + report | Ephemeral session memory | Final report view |
| **Scam Indicators & Severity** | Indefinite (user-managed) | PostgreSQL `call_history` | Mobile History Screen |
| **Call Metadata** | Indefinite (user-managed) | PostgreSQL `call_history` | Mobile History Screen |

### Explicit Security Rules
1. **No Silent Audio Capture:** Audio capture cannot start without an active call session detected by Android and user opt-in consent.
2. **Immediate Session Termination:** As soon as the call ends (`CALL_STATE_IDLE`), audio buffers and recording streams are immediately halted and dereferenced.
3. **No Unauthenticated Access:** All API requests require a valid Bearer JWT. The backend resolves `user_id` strictly from the signed token, guaranteeing that user A can never view, update, or finalize user B's calls.
4. **No Sensitive PII in Logs:** Logs never contain phone numbers, authentication tokens, or full transcript text.
