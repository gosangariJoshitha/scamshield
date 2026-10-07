package com.scamshield.scamshield_guardian

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.telephony.PhoneStateListener
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat

class CallStateGuardianService : Service() {
    private var telephonyManager: TelephonyManager? = null
    private var telephonyCallback: TelephonyCallback? = null
    @Suppress("DEPRECATION")
    private var phoneStateListener: PhoneStateListener? = null

    override fun onCreate() {
        super.onCreate()
        activeService = this
        isRunning = true
        GuardianAudioPipeline.setStatusListener { updateState(callState) }
        updateState("IDLE")
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            getSharedPreferences(GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_AUDIO_PROTECTION_ENABLED, false)
                .apply()
            GuardianAudioPipeline.stop()
            stopMonitoring()
            stopForeground(STOP_FOREGROUND_REMOVE)
            stopSelf()
            return START_NOT_STICKY
        }
        if (!hasPhoneStatePermission() || !guardianEnabled()) {
            stopMonitoring()
            stopSelf()
            return START_NOT_STICKY
        }
        if (!startForegroundSafely()) return START_NOT_STICKY
        registerCallStateListener()
        return START_STICKY
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        GuardianAudioPipeline.setStatusListener(null)
        GuardianAudioPipeline.stop()
        stopMonitoring()
        if (activeService === this) activeService = null
        isRunning = false
        super.onDestroy()
    }

    private fun startForegroundSafely(): Boolean {
        return try {
            createNotificationChannel()
            val notification = buildNotification()
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                var serviceTypes = ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                if (audioProtectionEnabled() &&
                    ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECORD_AUDIO,
                    ) == PackageManager.PERMISSION_GRANTED
                ) {
                    serviceTypes = serviceTypes or
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                }
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    serviceTypes,
                )
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R &&
                audioProtectionEnabled()
            ) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            serviceError = null
            true
        } catch (_: SecurityException) {
            failToStart("Android denied the foreground-service permission.")
            false
        } catch (_: IllegalStateException) {
            failToStart("Android did not allow Guardian to start in the current state.")
            false
        }
    }

    private fun failToStart(message: String) {
        isRunning = false
        serviceError = message
        getSharedPreferences(GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_AUDIO_PROTECTION_ENABLED, false)
            .putBoolean(KEY_GUARDIAN_ENABLED, false)
            .apply()
        GuardianAudioPipeline.stop()
        updateState("UNAVAILABLE")
        stopSelf()
    }

    private fun registerCallStateListener() {
        val manager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            ?: run {
                updateState("UNAVAILABLE")
                return
            }
        telephonyManager = manager
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val callback = object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                    override fun onCallStateChanged(state: Int) {
                        GuardianCallEvents.updateFromTelephony(this@CallStateGuardianService, state)
                        updateState(stateLabel(state))
                    }
                }
                telephonyCallback = callback
                manager.registerTelephonyCallback(mainExecutor, callback)
            } else {
                @Suppress("DEPRECATION")
                val listener = object : PhoneStateListener() {
                    override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                        GuardianCallEvents.updateFromTelephony(
                            this@CallStateGuardianService,
                            state,
                        )
                        updateState(stateLabel(state))
                    }
                }
                phoneStateListener = listener
                @Suppress("DEPRECATION")
                manager.listen(listener, PhoneStateListener.LISTEN_CALL_STATE)
            }
            GuardianCallEvents.updateFromTelephony(this, manager.callState)
            updateState(stateLabel(manager.callState))
        } catch (_: SecurityException) {
            serviceError = "Phone-state permission was revoked."
            updateState("PERMISSION_REQUIRED")
            stopSelf()
        } catch (_: UnsupportedOperationException) {
            serviceError = "This device does not support call-state callbacks."
            updateState("UNAVAILABLE")
        }
    }

    private fun stopMonitoring() {
        telephonyCallback?.let { callback ->
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                telephonyManager?.unregisterTelephonyCallback(callback)
            }
        }
        telephonyCallback = null
        phoneStateListener?.let { listener ->
            @Suppress("DEPRECATION")
            telephonyManager?.listen(listener, PhoneStateListener.LISTEN_NONE)
        }
        phoneStateListener = null
        telephonyManager = null
        if (!guardianEnabled()) updateState("IDLE")
        isRunning = false
    }

    private fun hasPhoneStatePermission(): Boolean =
        ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_PHONE_STATE,
        ) == PackageManager.PERMISSION_GRANTED

    private fun guardianEnabled(): Boolean =
        getSharedPreferences(GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
            .getBoolean(KEY_GUARDIAN_ENABLED, false)

    private fun updateState(state: String) {
        callState = state
        if (state == "IN_CALL" &&
            audioProtectionEnabled() &&
            GuardianAudioPipeline.snapshot().state == "IDLE"
        ) {
            GuardianAudioPipeline.start(this, GuardianCallEvents.currentSessionId(this))
        } else if (state != "IN_CALL" &&
            GuardianAudioPipeline.snapshot().state != "IDLE"
        ) {
            GuardianAudioPipeline.stop()
        }
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
        val telephonySupported =
            packageManager.hasSystemFeature(PackageManager.FEATURE_TELEPHONY)
        val phonePermissionGranted = hasPhoneStatePermission()
        val audio = GuardianAudioPipeline.snapshot()
        GuardianStatusEvents.publish(
            mapOf(
                "available" to true,
                "supported" to telephonySupported,
                "phoneStatePermissionGranted" to phonePermissionGranted,
                "notificationsPermissionGranted" to notificationsPermissionGranted(),
                "enabled" to guardianEnabled(),
                "serviceRunning" to isRunning,
                "callState" to callState,
                "serviceError" to serviceError.orEmpty(),
                "callScreeningAvailable" to callScreeningAvailable,
                "callScreeningEnabled" to callScreeningEnabled,
                "incomingCallDetection" to callScreeningEnabled,
                "outgoingCallDetection" to (
                    callScreeningEnabled &&
                        Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q
                    ),
                "activeCallStateDetection" to
                    (telephonySupported && phonePermissionGranted),
                "audioPermissionGranted" to
                    (ContextCompat.checkSelfPermission(
                        this,
                        Manifest.permission.RECORD_AUDIO,
                    ) == PackageManager.PERMISSION_GRANTED),
                "audioProtectionEnabled" to audioProtectionEnabled(),
                "audioCaptureAvailable" to
                    (audio.state == "AUDIO_READY" || audio.state == "AUDIO_STREAMING"),
                "audioState" to audio.state,
                "audioSource" to audio.source,
                "audioRoute" to audio.route,
                "audioReason" to audio.reason,
                "audioChunksCreated" to audio.chunksCreated,
                "audioChunksDropped" to audio.chunksDropped,
            ),
        )
        if (isRunning) {
            getSystemService(NotificationManager::class.java)
                .notify(NOTIFICATION_ID, buildNotification())
        }
    }

    private fun notificationsPermissionGranted(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.POST_NOTIFICATIONS,
            ) == PackageManager.PERMISSION_GRANTED

    private fun buildNotification(): Notification {
        val launchIntent = Intent(this, MainActivity::class.java)
            .setFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("ScamShield Guardian is active")
            .setContentText(notificationText())
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            NOTIFICATION_CHANNEL_ID,
            "Call protection status",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Visible status while the user-enabled call-state monitor is active."
        }
        getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
    }

    private fun notificationText(): String {
        if (!audioProtectionEnabled()) {
            return "Call-state monitoring only · microphone not in use"
        }
        if (callState != "IN_CALL") {
            return "Microphone capture only during detected active calls"
        }
        return when (GuardianAudioPipeline.snapshot().state) {
            "AUDIO_INITIALIZING" -> "Active call · preparing device microphone"
            "AUDIO_READY" -> "Active call · device microphone ready"
            "AUDIO_STREAMING" -> "Active call · device microphone input flowing"
            "AUDIO_UNAVAILABLE" -> "Active call · microphone capture unavailable"
            else -> "Active call · microphone capture not started"
        }
    }

    private fun stateLabel(state: Int): String = when (state) {
        TelephonyManager.CALL_STATE_IDLE -> "IDLE"
        TelephonyManager.CALL_STATE_RINGING -> "RINGING"
        TelephonyManager.CALL_STATE_OFFHOOK -> "IN_CALL"
        else -> "UNKNOWN"
    }

    companion object {
        const val ACTION_START = "com.scamshield.guardian.START"
        const val ACTION_STOP = "com.scamshield.guardian.STOP"
        private const val GUARDIAN_PREFERENCES = "scamshield_guardian"
        private const val KEY_GUARDIAN_ENABLED = "guardian_enabled"
        private const val KEY_AUDIO_PROTECTION_ENABLED = "audio_protection_enabled"
        private const val TAG = "ScamShieldGuardian"
        private const val NOTIFICATION_CHANNEL_ID = "scamshield_guardian_status"
        private const val NOTIFICATION_ID = 902

        @Volatile
        var isRunning: Boolean = false
            private set

        @Volatile
        var callState: String = "UNKNOWN"
            private set

        @Volatile
        var serviceError: String? = null
            private set

        @Volatile
        private var activeService: CallStateGuardianService? = null

        fun setAudioProtectionEnabled(enabled: Boolean): Boolean =
            activeService?.updateAudioProtection(enabled) == true
    }

    private fun audioProtectionEnabled(): Boolean =
        getSharedPreferences(GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
            .getBoolean(KEY_AUDIO_PROTECTION_ENABLED, false)

    private fun updateAudioProtection(enabled: Boolean): Boolean {
        if (enabled &&
            (!guardianEnabled() ||
                ContextCompat.checkSelfPermission(
                    this,
                    Manifest.permission.RECORD_AUDIO,
                ) != PackageManager.PERMISSION_GRANTED)
        ) {
            return false
        }
        getSharedPreferences(GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_AUDIO_PROTECTION_ENABLED, enabled)
            .apply()
        if (!updateForegroundAudioType(enabled)) {
            getSharedPreferences(GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
                .edit()
                .putBoolean(KEY_AUDIO_PROTECTION_ENABLED, false)
                .apply()
            GuardianAudioPipeline.markUnavailable(
                "Android did not allow the microphone foreground-service mode.",
            )
            updateForegroundAudioType(false)
            updateState(callState)
            return false
        }
        if (enabled && callState == "IN_CALL") {
            GuardianAudioPipeline.start(this, GuardianCallEvents.currentSessionId(this))
        } else if (!enabled) {
            GuardianAudioPipeline.stop()
        }
        updateState(callState)
        return true
    }

    private fun updateForegroundAudioType(enableMicrophone: Boolean): Boolean {
        return try {
            val notification = buildNotification()
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE -> {
                    val serviceTypes =
                        if (enableMicrophone) {
                            ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE or
                                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE
                        } else {
                            ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
                        }
                    startForeground(NOTIFICATION_ID, notification, serviceTypes)
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.R && enableMicrophone ->
                    startForeground(
                        NOTIFICATION_ID,
                        notification,
                        ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
                    )
                else -> startForeground(NOTIFICATION_ID, notification)
            }
            true
        } catch (error: SecurityException) {
            Log.w(TAG, "Android denied the Guardian microphone service mode.", error)
            false
        } catch (error: IllegalStateException) {
            Log.w(TAG, "Android rejected the Guardian microphone service mode.", error)
            false
        }
    }

}

object GuardianStatusEvents {
    @Volatile
    private var listener: ((Map<String, Any>) -> Unit)? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    fun setListener(callback: ((Map<String, Any>) -> Unit)?) {
        listener = callback
    }

    fun publish(status: Map<String, Any>) {
        mainHandler.post { listener?.invoke(status) }
    }
}
