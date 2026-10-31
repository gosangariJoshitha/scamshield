# ScamShield 2.0 — Sentinel Audio Pipeline Specification

## 1. Physical Platform Constraints & Audio Source

### Android 15 (API 35) Restrictions
On modern Android versions (specifically Android 10+ through Android 15 on target devices like the OnePlus CPH2467), the direct cellular voice downlink/uplink stream (`MediaRecorder.AudioSource.VOICE_CALL` / `VOICE_DOWNLINK`) is strictly reserved for system-privileged dialers and accessibility services with pre-granted carrier agreements.

ScamShield does not circumvent platform security or install deceptive accessibility listeners.

### The Truthful Capture Architecture
- **Detection:** `TelephonyCallback.CallStateListener` / `PhoneStateListener` observes `CALL_STATE_RINGING`, `CALL_STATE_OFFHOOK`, and `CALL_STATE_IDLE`.
- **Audio Capture Source:** `MediaRecorder.AudioSource.MIC`.
- **Opt-In Requirement:** During an incoming or active call, audio protection is enabled only when:
  1. The user has granted `RECORD_AUDIO` permission.
  2. The user has toggled "Microphone Audio Protection" ON.
  3. The user takes the call on speakerphone (or hands-free speaker).
- **Truthful Status Display:** If speakerphone is not active or mic capture is restricted by OEM policies, Sentinel displays:
  > `Call active but audio unavailable — switch to speakerphone for live scam analysis.`

---

## 2. Audio Format & Chunking Geometry

```
+─────────────────────────────────────────────────────────────────────────────+
|                         5-Second Audio Chunk Geometry                       |
+─────────────────────────────────────────────────────────────────────────────+
 Format:        Linear PCM 16-bit signed integer Little Endian (pcm_s16le)
 Sample Rate:   16,000 Hz (16 kHz, Whisper native input requirement)
 Channels:      1 (Mono)
 Byte Rate:     16,000 samples/sec * 2 bytes/sample = 32,000 bytes/sec
 Chunk Window:  5.0 seconds
 Chunk Size:    160,000 bytes uncompressed raw PCM
 Base64 Size:   ~213,334 ASCII characters
+─────────────────────────────────────────────────────────────────────────────+
```

### Chunk Payload Definition
Each chunk transmitted from the native Android pipeline (`GuardianAudioPipeline.kt`) through the Flutter bridge (`CallBridge`) to `POST /guardian/transcription/chunk` carries:
1. `session_id`: Canonical UUIDv4 generated at call start.
2. `sequence`: Monotonically increasing integer starting at `1`.
3. `start_time`: Chunk start offset in seconds (e.g., `0.0`, `5.0`, `10.0`).
4. `end_time`: Chunk end offset in seconds (e.g., `5.0`, `10.0`, `15.0`).
5. `audio_base64`: Base64 encoded byte payload.
6. `sample_rate`: `16000`.
7. `channels`: `1`.
8. `audio_format`: `'pcm_s16le'`.
9. `source`: `'SPEAKERPHONE_AUDIO'`.

---

## 3. Backpressure, Queue Bounds & Dropped Chunks

To prevent memory bloat, high CPU churn, and catastrophic lag on mobile networks:
- **Maximum In-Flight Requests:** Exactly 2 concurrent chunks.
- **Queue Bounds:** If a network lag causes the background queue to exceed 2 pending chunks, older non-critical chunks are discarded and the counter `dropped_chunks` increments.
- **Client Latency Guard:** If the backend does not respond within 8.0 seconds, the request aborts with `TRANSCRIPTION_TIMEOUT`, and the client proceeds to the next chunk.
- **Silence Suppression:** The native pipeline calculates Root Mean Square (RMS) audio energy. If energy falls below ambient threshold (silence), chunks are not transmitted to save bandwidth and battery.

---

## 4. Faster-Whisper Server Pipeline

The backend server (`backend/guardian_transcription.py`) ingests raw PCM chunks and executes:
1. **Deduplication Check:** Checks LRU memory cache for `(session_id, sequence)`. If chunk was already transcribed, returns cached `TranscriptSegment`.
2. **Audio Decoding:** Converts base64 bytes to 16kHz float32 NumPy array without writing temporary files to disk.
3. **Model Inference:** Faster-Whisper `base` or `small` int8 quantized model running on CPU/GPU.
4. **Multilingual Code-Switching:** Transcribes English, Hindi, and Telugu speech, returning detected language code.
5. **Session Aggregation:** Concatenates validated transcript segments into the session context for incremental scam analysis.

---

## 5. Security, Privacy & Retention Policy

1. **Zero Raw Audio Storage:** Neither the Android app, Flutter client, nor FastAPI backend writes raw audio chunks to persistent disk. Audio lives exclusively in transient memory buffers during the 5-second processing window.
2. **Immediate Memory Zeroing:** Audio buffers in Kotlin and Python are cleared upon chunk completion.
3. **No Background Eavesdropping:** Capture terminates instantaneously when `TelephonyCallback` fires `CALL_STATE_IDLE` (call ended) or when the user toggles protection OFF.
4. **Account Scoping:** Audio chunk processing is protected by authenticated Bearer JWT tokens. A user cannot submit chunks to another user's session.
