package com.scamshield.scamshield_guardian

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.app.role.RoleManager
import android.os.Vibrator
import android.os.VibratorManager
import android.os.VibrationEffect
import android.telecom.TelecomManager
import android.provider.BlockedNumberContract
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var pendingPermissionResult: MethodChannel.Result? = null
    private var pendingAudioPermissionResult: MethodChannel.Result? = null
    private var eventSink: EventChannel.EventSink? = null
    private var audioEventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.scamshield/native",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getPlatformInfo" -> result.success(
                    mapOf(
                        "platform" to "Android",
                        "sdkInt" to Build.VERSION.SDK_INT,
                        "release" to Build.VERSION.RELEASE,
                    ),
                )
                "isNativeLayerAvailable" -> result.success(true)
                "getCallGuardianStatus" -> result.success(guardianStatus())
                "getAudioCapability" -> result.success(audioCapability())
                "getAudioState" -> result.success(GuardianAudioPipeline.snapshot().toMap())
                "requestAudioPermission" -> requestAudioPermission(result)
                "setAudioPipelineEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled")
                    if (enabled == null) {
                        result.error("INVALID_ARGUMENT", "enabled is required.", null)
                    } else {
                        setAudioPipelineEnabled(enabled, result)
                    }
                }
                "takeNextAudioChunk" -> result.success(GuardianAudioPipeline.takeNextChunk())
                "getLatestCallEvent" -> {
                    try {
                        result.success(GuardianCallEvents.latest(this))
                    } catch (error: org.json.JSONException) {
                        Log.e(TAG, "Unable to decode stored Guardian call event.", error)
                        result.error(
                            "INVALID_STORED_CALL_EVENT",
                            "Stored Guardian call event could not be read.",
                            null,
                        )
                    }
                }
                "requestCallScreeningRole" -> requestCallScreeningRole(result)
                "requestGuardianPermissions" -> requestGuardianPermissions(result)
                "setGuardianEnabled" -> {
                    val enabled = call.argument<Boolean>("enabled")
                    if (enabled == null) {
                        result.error("INVALID_ARGUMENT", "enabled is required.", null)
                    } else {
                        setGuardianEnabled(enabled, result)
                    }
                }
                "openAppSettings" -> {
                    startActivity(
                        Intent(
                            android.provider.Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                            android.net.Uri.parse("package:$packageName"),
                        ),
                    )
                    result.success(null)
                }
                "getProtectionCapabilities" -> result.success(getProtectionCapabilities())
                "requestEndCall" -> {
                    val sessionId = call.argument<String>("sessionId")
                    requestEndCall(sessionId, result)
                }
                "requestBlockCaller" -> {
                    val sessionId = call.argument<String>("sessionId")
                    val phoneNumber = call.argument<String>("phoneNumber")
                    requestBlockCaller(sessionId, phoneNumber, result)
                }
                "openBlockedNumbersSettings" -> {
                    openBlockedNumbersSettings(result)
                }
                "triggerHapticAlert" -> {
                    val intensity = call.argument<String>("intensity") ?: "HIGH"
                    triggerHapticAlert(intensity, result)
                }
                else -> result.notImplemented()
            }
        }
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.scamshield/native/guardianEvents",
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                eventSink = events
                GuardianStatusEvents.setListener { status ->
                    runOnUiThread { eventSink?.success(status) }
                }
                events.success(guardianStatus())
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                GuardianStatusEvents.setListener(null)
            }
        })
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.scamshield/native/callEvents",
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                GuardianCallEvents.setListener { event -> events.success(event) }
                try {
                    GuardianCallEvents.latest(this@MainActivity)?.let(events::success)
                } catch (error: org.json.JSONException) {
                    Log.e(TAG, "Unable to decode stored Guardian call event.", error)
                    events.error(
                        "INVALID_STORED_CALL_EVENT",
                        "Stored Guardian call event could not be read.",
                        null,
                    )
                }
            }

            override fun onCancel(arguments: Any?) {
                GuardianCallEvents.setListener(null)
            }
        })
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.scamshield/native/audioEvents",
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
                audioEventSink = events
                GuardianAudioPipeline.setChunkListener { event ->
                    runOnUiThread { audioEventSink?.success(event) }
                }
            }

            override fun onCancel(arguments: Any?) {
                audioEventSink = null
                GuardianAudioPipeline.setChunkListener(null)
            }
        })
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_GUARDIAN_PERMISSIONS) {
            pendingPermissionResult?.success(guardianStatus())
            pendingPermissionResult = null
        }
        if (requestCode == REQUEST_AUDIO_PERMISSION) {
            pendingAudioPermissionResult?.success(audioPermissionState())
            pendingAudioPermissionResult = null
        }
    }

    override fun onResume() {
        super.onResume()
        publishGuardianStatus()
    }

    private fun requestGuardianPermissions(result: MethodChannel.Result) {
        if (pendingPermissionResult != null) {
            result.error("REQUEST_IN_PROGRESS", "A permission request is already active.", null)
            return
        }
        val requested = buildList {
            add(Manifest.permission.READ_PHONE_STATE)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }
        val missing = requested.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }
        if (missing.isEmpty()) {
            result.success(guardianStatus())
            return
        }
        pendingPermissionResult = result
        ActivityCompat.requestPermissions(
            this,
            missing.toTypedArray(),
            REQUEST_GUARDIAN_PERMISSIONS,
        )
    }

    private fun requestAudioPermission(result: MethodChannel.Result) {
        if (pendingAudioPermissionResult != null) {
            result.error("REQUEST_IN_PROGRESS", "A microphone permission request is already active.", null)
            return
        }
        if (ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.RECORD_AUDIO,
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            result.success(audioPermissionState())
            return
        }
        pendingAudioPermissionResult = result
        getSharedPreferences(GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_AUDIO_PERMISSION_REQUESTED, true)
            .apply()
        ActivityCompat.requestPermissions(
            this,
            arrayOf(Manifest.permission.RECORD_AUDIO),
            REQUEST_AUDIO_PERMISSION,
        )
    }

    private fun setAudioPipelineEnabled(enabled: Boolean, result: MethodChannel.Result) {
        if (enabled) {
            if (ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.RECORD_AUDIO,
                ) != PackageManager.PERMISSION_GRANTED
            ) {
                result.error(
                    "PERMISSION_REQUIRED",
                    "Microphone permission is required for audio protection.",
                    audioPermissionState(),
                )
                return
            }
            if (guardianStatus()["enabled"] != true ||
                !CallStateGuardianService.isRunning
            ) {
                result.error(
                    "GUARDIAN_REQUIRED",
                    "Enable Guardian before audio protection.",
                    guardianStatus(),
                )
                return
            }
        }
        if (!enabled && !CallStateGuardianService.isRunning) {
            getSharedPreferences(GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_AUDIO_PROTECTION_ENABLED, false)
                .apply()
            GuardianAudioPipeline.stop()
            result.success(guardianStatus())
            return
        }
        val updated = CallStateGuardianService.setAudioProtectionEnabled(enabled)
        if (!updated) {
            result.error(
                "AUDIO_SERVICE_UNAVAILABLE",
                "Android could not update the audio foreground service.",
                guardianStatus(),
            )
            return
        }
        result.success(guardianStatus())
    }

    private fun setGuardianEnabled(enabled: Boolean, result: MethodChannel.Result) {
        val preferences = getSharedPreferences(GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
        if (!enabled) {
            preferences.edit()
                .putBoolean(KEY_GUARDIAN_ENABLED, false)
                .putBoolean(KEY_AUDIO_PROTECTION_ENABLED, false)
                .apply()
            GuardianAudioPipeline.stop()
            startService(
                Intent(this, CallStateGuardianService::class.java)
                    .setAction(CallStateGuardianService.ACTION_STOP),
            )
            publishGuardianStatus()
            result.success(guardianStatus())
            return
        }
        val status = guardianStatus()
        if (status["supported"] != true) {
            result.error("UNSUPPORTED_DEVICE", "Phone call-state monitoring is not available on this device.", status)
            return
        }
        if (status["phoneStatePermissionGranted"] != true ||
            status["notificationsPermissionGranted"] != true
        ) {
            result.error("PERMISSION_REQUIRED", "Grant phone-state and notification permissions before enabling Guardian.", status)
            return
        }

        preferences.edit().putBoolean(KEY_GUARDIAN_ENABLED, true).apply()
        try {
            val serviceIntent = Intent(this, CallStateGuardianService::class.java)
                .setAction(CallStateGuardianService.ACTION_START)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                ContextCompat.startForegroundService(this, serviceIntent)
            } else {
                startService(serviceIntent)
            }
            publishGuardianStatus()
            result.success(guardianStatus())
        } catch (error: SecurityException) {
            preferences.edit().putBoolean(KEY_GUARDIAN_ENABLED, false).apply()
            result.error("SERVICE_START_FAILED", "Android did not allow Guardian to start.", error.message)
        } catch (error: IllegalStateException) {
            preferences.edit().putBoolean(KEY_GUARDIAN_ENABLED, false).apply()
            result.error("SERVICE_START_FAILED", "Guardian could not start while the app was in the background.", error.message)
        }
    }

    private fun requestCallScreeningRole(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error(
                "ROLE_UNAVAILABLE",
                "Android call-screening role setup requires Android 10 or later.",
                null,
            )
            return
        }
        val roleManager = getSystemService(RoleManager::class.java)
        if (roleManager == null ||
            !roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)
        ) {
            result.error(
                "ROLE_UNAVAILABLE",
                "Call screening is not available on this device.",
                null,
            )
            return
        }
        if (roleManager.isRoleHeld(RoleManager.ROLE_CALL_SCREENING)) {
            result.success(guardianStatus())
            return
        }
        try {
            startActivityForResult(
                roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING),
                REQUEST_CALL_SCREENING_ROLE,
            )
            result.success(guardianStatus())
        } catch (error: SecurityException) {
            result.error(
                "ROLE_REQUEST_FAILED",
                "Android denied the call-screening role request.",
                error.message,
            )
        } catch (error: android.content.ActivityNotFoundException) {
            result.error(
                "ROLE_REQUEST_FAILED",
                "Android could not open the call-screening role prompt.",
                error.message,
            )
        }
    }

    private fun guardianStatus(): Map<String, Any> {
        val phonePermissionGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_PHONE_STATE,
        ) == PackageManager.PERMISSION_GRANTED
        val notificationsPermissionGranted =
            Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.POST_NOTIFICATIONS,
                ) == PackageManager.PERMISSION_GRANTED
        val supported = packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)
        val callScreeningAvailable: Boolean
        val callScreeningEnabled: Boolean
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = getSystemService(RoleManager::class.java)
            callScreeningAvailable =
                roleManager?.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING) == true
            callScreeningEnabled =
                callScreeningAvailable &&
                    roleManager?.isRoleHeld(RoleManager.ROLE_CALL_SCREENING) == true
        } else {
            callScreeningAvailable = false
            callScreeningEnabled = false
        }
        val enabled = getSharedPreferences(GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
            .getBoolean(KEY_GUARDIAN_ENABLED, false)
        val audio = GuardianAudioPipeline.snapshot()
        val audioPermissionGranted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO,
        ) == PackageManager.PERMISSION_GRANTED
        val audioProtectionEnabled = getSharedPreferences(
            GUARDIAN_PREFERENCES,
            Context.MODE_PRIVATE,
        ).getBoolean(KEY_AUDIO_PROTECTION_ENABLED, false)
        return mapOf(
            "available" to true,
            "supported" to supported,
            "phoneStatePermissionGranted" to phonePermissionGranted,
            "notificationsPermissionGranted" to notificationsPermissionGranted,
            "enabled" to enabled,
            "serviceRunning" to CallStateGuardianService.isRunning,
            "callState" to CallStateGuardianService.callState,
            "serviceError" to CallStateGuardianService.serviceError.orEmpty(),
            "callScreeningAvailable" to callScreeningAvailable,
            "callScreeningEnabled" to callScreeningEnabled,
            "incomingCallDetection" to callScreeningEnabled,
            "outgoingCallDetection" to (
                callScreeningEnabled &&
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
                ),
            "activeCallStateDetection" to (supported && phonePermissionGranted),
            "audioPermissionGranted" to audioPermissionGranted,
            "audioProtectionEnabled" to audioProtectionEnabled,
            "audioCaptureAvailable" to (audio.state == "AUDIO_READY" ||
                audio.state == "AUDIO_STREAMING"),
            "audioState" to audio.state,
            "audioSource" to audio.source,
            "audioRoute" to audio.route,
            "audioReason" to audio.reason,
            "audioChunksCreated" to audio.chunksCreated,
            "audioChunksDropped" to audio.chunksDropped,
        )
    }

    private fun audioCapability(): Map<String, Any?> {
        val microphonePresent =
            packageManager.hasSystemFeature(PackageManager.FEATURE_MICROPHONE)
        val telephonySupported =
            packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)
        val permission = audioPermissionState()
        val supported = microphonePresent && telephonySupported
        return mapOf(
            "supported" to supported,
            "source" to if (microphonePresent) "DEVICE_MICROPHONE" else null,
            "permissionStatus" to permission["permissionStatus"],
            "reason" to when {
                !microphonePresent -> "This device does not report a microphone."
                !telephonySupported -> "This device does not report telephony support."
                permission["permissionGranted"] != true ->
                    "Microphone permission is required before capture can be attempted."
                else ->
                    "Uses device microphone input only. Use speakerphone manually if you want nearby call audio picked up; access to the other party is not guaranteed."
            },
            "sampleRateHz" to GuardianAudioPipeline.SAMPLE_RATE_HZ,
            "channels" to GuardianAudioPipeline.CHANNEL_COUNT,
            "encoding" to GuardianAudioPipeline.ENCODING,
            "chunkDurationMs" to GuardianAudioPipeline.CHUNK_DURATION_MS,
            "maxBufferedChunks" to GuardianAudioPipeline.MAX_BUFFERED_CHUNKS,
        )
    }

    private fun audioPermissionState(): Map<String, Any> {
        val granted = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.RECORD_AUDIO,
        ) == PackageManager.PERMISSION_GRANTED
        val requestedBefore = getSharedPreferences(GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
            .getBoolean(KEY_AUDIO_PERMISSION_REQUESTED, false)
        val permanentlyDenied =
            !granted &&
                requestedBefore &&
                !ActivityCompat.shouldShowRequestPermissionRationale(
                    this,
                    Manifest.permission.RECORD_AUDIO,
                )
        return mapOf(
            "permissionGranted" to granted,
            "permissionStatus" to when {
                granted -> "GRANTED"
                permanentlyDenied -> "DENIED_PERMANENTLY"
                else -> "DENIED"
            },
        )
    }

    private fun publishGuardianStatus() {
        eventSink?.success(guardianStatus())
    }

    private fun getProtectionCapabilities(): Map<String, Any?> {
        val telecom = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
        val hasAnswerPhone = ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ANSWER_PHONE_CALLS
        ) == PackageManager.PERMISSION_GRANTED
        val canEndCallSupported = Build.VERSION.SDK_INT >= Build.VERSION_CODES.P && telecom != null
        val canEndCallReason = when {
            !canEndCallSupported -> "Programmatic call termination is not supported on this Android version or device."
            !hasAnswerPhone -> "Call termination requires ANSWER_PHONE_CALLS permission. You can end the call using your phone controls."
            else -> "Programmatic call termination supported via TelecomManager."
        }

        val canBlockSupported = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            try {
                BlockedNumberContract.canCurrentUserBlockNumbers(this)
            } catch (_: Throwable) {
                false
            }
        } else {
            false
        }
        val canBlockReason = if (canBlockSupported) {
            "Direct caller blocking requires default phone app role. You can block this number from your phone's call settings."
        } else {
            "Caller blocking is unavailable on this device configuration."
        }

        val vibrator = getVibratorService()
        val hasVibrator = vibrator?.hasVibrator() ?: false

        return mapOf(
            "canEndCall" to mapOf(
                "supported" to (canEndCallSupported && hasAnswerPhone),
                "reason" to canEndCallReason,
                "requiresPermission" to true,
                "requiresUserConfirmation" to true,
                "permissionGranted" to hasAnswerPhone,
            ),
            "canBlockCaller" to mapOf(
                "supported" to false,
                "reason" to canBlockReason,
                "requiresPermission" to true,
                "requiresUserConfirmation" to true,
                "canOpenSettings" to true,
            ),
            "canVibrate" to mapOf(
                "supported" to hasVibrator,
                "reason" to if (hasVibrator) "Haptic vibration alert supported for high/critical warnings." else "Device does not support vibration.",
                "requiresPermission" to false,
                "requiresUserConfirmation" to false,
            ),
            "canVerifySafely" to mapOf(
                "supported" to true,
                "reason" to "Independent bank & authority verification guidance available.",
                "requiresPermission" to false,
                "requiresUserConfirmation" to false,
            ),
            "canReport" to mapOf(
                "supported" to true,
                "reason" to "Community scam report submission available.",
                "requiresPermission" to false,
                "requiresUserConfirmation" to true,
            ),
        )
    }

    private fun requestEndCall(sessionId: String?, result: MethodChannel.Result) {
        val latest = GuardianCallEvents.latest(this)
        val activeEvent = latest?.get("event") as? String
        val activeSessionId = latest?.get("sessionId") as? String

        if (activeEvent != "CALL_ACTIVE") {
            result.success(
                mapOf(
                    "success" to false,
                    "supported" to false,
                    "reason" to "Call is no longer active.",
                    "errorCode" to "CALL_NOT_ACTIVE"
                )
            )
            return
        }

        if (sessionId != null && activeSessionId != null && sessionId != activeSessionId) {
            result.success(
                mapOf(
                    "success" to false,
                    "supported" to false,
                    "reason" to "Call session has changed.",
                    "errorCode" to "SESSION_MISMATCH"
                )
            )
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.ANSWER_PHONE_CALLS) != PackageManager.PERMISSION_GRANTED) {
                result.success(
                    mapOf(
                        "success" to false,
                        "supported" to false,
                        "reason" to "Your device does not allow ScamShield to end this call automatically without ANSWER_PHONE_CALLS permission. You can end the call using your phone controls.",
                        "errorCode" to "PERMISSION_REQUIRED"
                    )
                )
                return
            }

            val telecom = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            try {
                @Suppress("DEPRECATION")
                val ended = telecom?.endCall() ?: false
                if (ended) {
                    result.success(
                        mapOf(
                            "success" to true,
                            "supported" to true,
                            "reason" to "Call ended via TelecomManager."
                        )
                    )
                } else {
                    result.success(
                        mapOf(
                            "success" to false,
                            "supported" to true,
                            "reason" to "Telecom service did not terminate the call. You can end the call using your phone controls.",
                            "errorCode" to "END_CALL_REJECTED"
                        )
                    )
                }
            } catch (_: SecurityException) {
                result.success(
                    mapOf(
                        "success" to false,
                        "supported" to false,
                        "reason" to "Your device does not allow ScamShield to end this call automatically. You can end the call using your phone controls.",
                        "errorCode" to "SECURITY_EXCEPTION"
                    )
                )
            } catch (_: Throwable) {
                result.success(
                    mapOf(
                        "success" to false,
                        "supported" to false,
                        "reason" to "Call termination failed on this device. You can end the call using your phone controls.",
                        "errorCode" to "UNEXPECTED_ERROR"
                    )
                )
            }
        } else {
            result.success(
                mapOf(
                    "success" to false,
                    "supported" to false,
                    "reason" to "Your device does not allow ScamShield to end this call automatically. You can end the call using your phone controls.",
                    "errorCode" to "UNSUPPORTED_API"
                )
            )
        }
    }

    private fun requestBlockCaller(sessionId: String?, phoneNumber: String?, result: MethodChannel.Result) {
        if (phoneNumber.isNullOrBlank()) {
            result.success(
                mapOf(
                    "success" to false,
                    "supported" to false,
                    "reason" to "Caller phone number is not available. You can block this number from your phone's call history.",
                    "errorCode" to "NO_PHONE_NUMBER",
                    "canOpenSettings" to true,
                )
            )
            return
        }

        result.success(
            mapOf(
                "success" to false,
                "supported" to false,
                "reason" to "Caller blocking isn't available directly from third-party apps on this device. You can block this number from your phone's call settings.",
                "errorCode" to "SYSTEM_DIALER_REQUIRED",
                "canOpenSettings" to true,
            )
        )
    }

    private fun openBlockedNumbersSettings(result: MethodChannel.Result) {
        try {
            val telecom = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q && telecom != null) {
                val intent = telecom.createManageBlockedNumbersIntent()
                startActivity(intent)
                result.success(mapOf("success" to true))
                return
            }
        } catch (_: Throwable) {}

        try {
            val intent = Intent(Intent.ACTION_VIEW).apply {
                type = "vnd.android.cursor.dir/calls"
            }
            startActivity(intent)
            result.success(mapOf("success" to true))
        } catch (_: Throwable) {
            try {
                startActivity(Intent(android.provider.Settings.ACTION_SETTINGS))
                result.success(mapOf("success" to true))
            } catch (_: Throwable) {
                result.success(mapOf("success" to false, "reason" to "Could not open settings."))
            }
        }
    }

    private fun triggerHapticAlert(intensity: String, result: MethodChannel.Result) {
        val vibrator = getVibratorService()
        if (vibrator == null || !vibrator.hasVibrator()) {
            result.success(mapOf("success" to false, "reason" to "No vibrator available."))
            return
        }

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                when (intensity.uppercase()) {
                    "CRITICAL" -> {
                        val timings = longArrayOf(0, 120, 80, 150)
                        val amplitudes = intArrayOf(0, 255, 0, 255)
                        vibrator.vibrate(VibrationEffect.createWaveform(timings, amplitudes, -1))
                    }
                    "HIGH" -> {
                        vibrator.vibrate(VibrationEffect.createOneShot(100, VibrationEffect.DEFAULT_AMPLITUDE))
                    }
                    else -> {
                        vibrator.vibrate(VibrationEffect.createOneShot(50, 100))
                    }
                }
            } else {
                @Suppress("DEPRECATION")
                when (intensity.uppercase()) {
                    "CRITICAL" -> vibrator.vibrate(longArrayOf(0, 120, 80, 150), -1)
                    "HIGH" -> vibrator.vibrate(100)
                    else -> vibrator.vibrate(50)
                }
            }
            result.success(mapOf("success" to true))
        } catch (e: Throwable) {
            result.success(mapOf("success" to false, "reason" to e.message))
        }
    }

    private fun getVibratorService(): Vibrator? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val vibratorManager = getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            vibratorManager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    companion object {
        private const val TAG = "ScamShieldGuardian"
        private const val REQUEST_GUARDIAN_PERMISSIONS = 9612
        private const val REQUEST_CALL_SCREENING_ROLE = 9613
        private const val REQUEST_AUDIO_PERMISSION = 9614
        private const val GUARDIAN_PREFERENCES = "scamshield_guardian"
        private const val KEY_GUARDIAN_ENABLED = "guardian_enabled"
        private const val KEY_AUDIO_PERMISSION_REQUESTED = "audio_permission_requested"
        private const val KEY_AUDIO_PROTECTION_ENABLED = "audio_protection_enabled"
    }
}
