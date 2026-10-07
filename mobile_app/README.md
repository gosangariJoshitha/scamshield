# ScamShield Android

The Android foundation opens with a ScamShield landing page, then provides
backend-connected signup and login before the authenticated home dashboard.
New accounts use the existing FastAPI signup and email-verification endpoints.
The Guardian tab offers explicit Android call-screening role onboarding and
opt-in call-state monitoring; live-call content analysis and call control are
not implemented.
The authenticated shell provides Home, Analyze, Guardian, and History bottom
navigation, plus top-level theme and a profile menu. The dashboard reads
per-user totals from `/api/analysis/dashboard` and recent records from
`/api/analysis/history`. Text, image, PDF, and audio analysis use the existing
FastAPI analysis endpoints; history rows open the corresponding analysis
result. If there are no records, the app displays a real zero/empty state.
The Guardian tab has an opt-in Android call-detection foundation. The user can
separately request Android's Call Screening role; ScamShield does not silently
change system roles. On Android versions that expose that role, the registered
`CallScreeningService` reports incoming/outgoing screening callbacks and always
allows the call without network or AI work. When the user enables Guardian and
grants Phone State and notification permissions, the foreground service reports
telephony state transitions, which are normalized into call sessions and sent
over a native event stream. Caller numbers and names are not collected. The
latest event is retained locally for UI recreation while the process stays
alive. Persisted `RINGING` or `ACTIVE` state is discarded on process restart so
an interrupted session cannot appear as a new ongoing call; terminal events
remain available. Android/OEM call behavior still requires physical-device
verification; callback availability does not certify that every call lifecycle
is observed on every device. Audio protection is a separate, optional
device-microphone feature described under M9.4 below; it is not direct cellular
call-audio access. M9.5 adds source-gated transcription, but the current
microphone-only Android producer is rejected, so no live chunks are uploaded
and no call audio is transcribed or analyzed on this device. No calls are
blocked or ended. The separate Settings preference only saves a future floating
Protect-button preference. Community and Help & Support show honest unavailable
guidance rather than fake mobile workflows.
Login and account creation share one screen with a Login / Sign Up switch.
Sign-up validates the account fields and requires acknowledgement of the
Terms and Privacy Policy before calling the existing backend endpoints.
Forgot Password requests and applies the existing email reset-code flow.

The authentication screen also offers administrator sign-in. Admin
authentication uses the existing admin endpoint and required email
verification, validates the admin role, and opens the native in-app Admin
Portal. Its session token is stored securely under a separate key from the
user session; signing into one portal clears the other portal's session.
Administrator navigation and dashboard data remain inside the Android app;
no external admin website is launched.
The native portal connects Overview, Human Review, Community, Knowledge Base,
Users, Monitoring, and Settings to the existing admin APIs. Lists support
server-side search, filters, and pagination. Reviews can be assigned and
decided with recorded notes; community reports can be verified, rejected,
resolved, escalated, or converted to knowledge drafts after verification.
Knowledge drafts can be edited, published/indexed, reindexed, or archived.
User details include recent analysis activity and account enable/disable
controls. Monitoring uses `/api/admin/health`, and Settings shows recent audit
events. Admin-only changes remain enforced by backend authorization; indexing
success is shown only after the backend confirms it.
Android uses one native splash composition containing the ScamShield logo,
product name, and protection tagline. Flutter holds its first frame until the
saved theme and session are restored, then opens the Landing page, user
Dashboard, or native Admin Portal directly. Native splash colors follow the
Android system light/dark setting.

## Configure and run

The emulator default is `http://10.0.2.2:8000/api`. Start the existing backend,
then run from this directory:

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

For a physical Android device, use the USB launcher below for local development.
It verifies the API and automatically configures ADB reverse forwarding before
starting Flutter, so the phone can use the development computer's localhost.
For a remotely hosted backend, set `API_BASE_URL` to its HTTPS URL instead.

Use HTTPS for non-debug builds. Cleartext HTTP is allowed only by the Android
debug manifest for local development. No backend secrets or credentials belong
in the mobile app.

To run on a USB-connected phone, start the backend on the computer, connect and
authorize the phone, then run this from `mobile_app`:

```powershell
.\run_on_phone.ps1
```

The launcher checks `/api/health`, selects the only connected phone, applies
`adb reverse tcp:8000 tcp:8000`, verifies the mapping, and runs Flutter with
`API_BASE_URL=http://127.0.0.1:8000/api`. If multiple devices are connected,
pass the target serial with `-DeviceId`. Use `-CheckOnly` to verify the backend,
device, and forwarding without starting Flutter. Run the launcher again after
reconnecting USB or restarting ADB; this reapplies the forwarding rule before
the app is started.

The current local debug APK is built for USB development with
`API_BASE_URL=http://127.0.0.1:8000/api`; do not publish it as a public
download because that address is only reachable through this development
setup. Before publishing, rebuild with the deployed HTTPS API URL, then add
that APK to the website's public download assets.

## M9.1 checks

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

Flutter stores the JWT with `flutter_secure_storage`. User sign-in follows the
existing `/api/auth/login`, optional `/api/auth/login/verify`, and
`/api/auth/me` contracts. Account creation and email verification use
`/api/auth/signup` and `/api/auth/verify-email`.
API requests time out after 30 seconds, including while reading the response
body. A timeout does not replace configuring an API URL reachable from the
device; admin sign-in also waits for the email verification code before opening
the admin portal.
Password recovery uses `/api/auth/forgot-password` and
`/api/auth/reset-password`; reset responses do not reveal whether an email
belongs to an active account.
Admin sign-in uses `/api/auth/admin/login` and the same
`/api/auth/login/verify` challenge endpoint, then verifies the account role
through `/api/auth/me`. Dashboard totals come from `/api/analysis/dashboard`;
history and recent analysis rows are scoped to the authenticated user by the
existing backend. Text, image, PDF, and audio submissions use the existing
`/api/analysis/text`, `/api/analysis/image`, `/api/analysis/pdf`, and
`/api/analysis/audio` routes. The native splash artwork has light and dark
variants and matches the app's configured background colors.

## M9.2 Android call-state foundation

The `com.scamshield/native` bridge reads actual telephony support, runtime
permission state, Guardian enabled state, foreground-service state, and the
current call state. The Guardian tab first shows an in-app disclosure, then
requests Android Phone State and (on Android 13+) Notifications permissions.
The user can stop monitoring from the same switch; the Android foreground
service notification also explains that only call state is monitored.

The service uses Android's foreground-service `specialUse` type where required
by Android 14+, with its purpose explicitly declared in the manifest. It is
started only from the user's visible enable action. This foundation does not
survive a reboot by design and does not implement audio capture, transcription,
Whisper, live AI/RAG analysis, call blocking/termination, or call history.
Permission and call-state behavior must be verified on a cellular Android
device; Flutter tests and APK compilation alone do not validate OEM behavior.

## M9.3 Android call detection

The app registers a `CallScreeningService` protected by
`BIND_SCREENING_SERVICE`. Android 10+ role availability and role ownership are
reported from `RoleManager`; the user must press **ENABLE CALL SCREENING** and
confirm the Android system prompt. The screening callback maps the direction
provided by `Call.Details` where Android supplies it and responds immediately
with an allow-call response. It does not perform network, AI, or audio work.
Outgoing direction is reported only when Android provides the callback through
the selected call-screening role. Older Android versions report role-based
screening as unavailable.

An `EventChannel` carries unique session IDs, direction, normalized ringing /
active / ended events, timestamps, and their native source. Telephony call-state
callbacks provide the active/ended transitions only while the user-enabled
Guardian service is running; screening callbacks alone do not guarantee an
active/end callback. The UI shows actual capability/role status and a duration
for active sessions; it does not show risk or AI analysis. This does not make
ScamShield a default dialer and adds no microphone permission. Call screening
role selection, incoming/outgoing calls, service lifecycle, lock screen, and
background behavior must be verified on Android 15 hardware before M9.3 can be
marked ready.

## M9.4 Android Live Call Guardian audio foundation

Audio protection is an independent opt-in switch that requires Guardian to be
enabled and Android microphone permission. After a separate disclosure and
permission grant, the foreground service starts `AudioRecord` with the device
microphone only while a detected call is active. It uses 16 kHz mono PCM chunks
of five seconds and keeps at most two pending chunks in memory; old queued
chunks are counted and dropped when that limit is reached. Disabling protection,
ending the call, or service teardown clears queued data and releases the
recorder. No audio files are written or audio bytes sent to the backend. The
Flutter handoff exposes chunks for a future consumer; with no consumer, they
are discarded after handoff.

This does not access the other party's cellular audio. The user must enable
speakerphone manually for nearby call playback to potentially reach the
microphone, and Android/OEM routing may still prevent that. Route and chunk
counters are informational only; they do not prove call audio was captured.
This milestone does not include transcription, Whisper, ML/RAG/LLM analysis,
risk scores, warnings, call control, or summaries. Do not mark M9.4 ready until
the microphone foreground-service behavior, explicit permission/denial and
settings recovery, real audio reads, route changes, active-call transitions,
background/lock behavior, long-call chunk bounds, and cleanup have been
verified on supported physical Android devices. Flutter tests and APK
compilation are not substitutes for that device validation.

## M9.5 Whisper transcription

The Guardian tab has a separate, opt-in Live transcription switch and displays
final transcript segments with call-relative timestamps, detected language,
no-speech/status messages, and bounded-buffer drop counts. Consent explains
that supported audio is sent to the configured ScamShield backend for
temporary processing. Whisper model weights load on the first audio request;
`WHISPER_MODEL` accepts `tiny`, `base`, or `small`, with CPU/int8 defaults.
The backend does not persist live PCM chunks or transcripts to an account;
idempotent transcript retry results are held in a bounded in-memory cache for
up to ten minutes and cleared when the app finalizes the session. If cleanup
cannot be confirmed, the bounded cache still expires.

Important source limitation: the current Android audio producer supplies
`DEVICE_MICROPHONE`, not verified cellular `CALL_AUDIO`. Both mobile and
backend reject that source for transcription, so those chunks are never
uploaded and the UI explicitly reports transcription as unavailable. No
transcript is fabricated from ambient microphone audio. M9.5 cannot be marked
production-ready until a supported, verified call-audio producer and its
physical-device behavior are implemented and tested; this milestone does not
add live scam classification, RAG/LLM analysis, risk scores, or call control.

The backend endpoint requires authentication and exact five-second, 16 kHz,
mono PCM16 chunks. The bounded retry cache is process-local; deployments with
multiple workers do not share idempotency state. Confirm deployment model
download, available CPU/RAM, HTTPS, and worker topology before enabling this
feature for a production backend.

## M9.6 Disconnected Guardian analysis foundation

The authenticated `POST /api/guardian/analysis/segment` endpoint accepts
transcript segments only when their declared source is `CALL_AUDIO`. It applies
bounded per-user/session buffering, sequence and content deduplication,
transcript thresholds, and the existing shared ML/RAG/LLM/risk pipeline. It
does not write transcript or result data to user analysis history. Per-session
transcripts and cached responses are held only in process memory and are
removed on finalization or expiry; separate backend workers do not share them.

This endpoint is deliberately not connected to the Android microphone or M9.5
transcription stream, and the app does not show live risk results. A caller can
forge a client-declared `CALL_AUDIO` value; the API source field is not
attestation. Do not connect or describe this as live-call analysis until a
supported, independently verified cellular call-audio source exists and has
been tested on physical devices. When the endpoint is enabled by a client,
transcript text is passed through the configured backend LLM provider, which
may process it under that provider's privacy and retention terms. Configure
OpenRouter or the existing Groq integration on the backend only; never embed
provider credentials in the Android app.

Run the targeted checks from this directory:

```powershell
flutter analyze
flutter test
flutter build apk --debug --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```
