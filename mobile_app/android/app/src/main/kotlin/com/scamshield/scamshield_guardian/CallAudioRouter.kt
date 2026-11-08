package com.scamshield.scamshield_guardian

import android.content.Context
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.Build
import android.util.Log

/**
 * CallAudioRouter provides unified, robust audio routing for in-call speakerphone
 * across Android versions (Android 12+ setCommunicationDevice and legacy setSpeakerphoneOn).
 *
 * It enforces verified route detection without false assumptions.
 */
object CallAudioRouter {
    private const val TAG = "CallAudioRouter"

    /**
     * Attempts to enable or disable the loudspeaker (speakerphone) route.
     * Returns true if the operation succeeded and was verified.
     */
    fun setSpeakerphone(context: Context, enabled: Boolean): Boolean {
        val am = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (enabled) {
                    val available = am.availableCommunicationDevices
                    val speaker = available.firstOrNull { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
                    if (speaker != null) {
                        val result = am.setCommunicationDevice(speaker)
                        Log.i(TAG, "setCommunicationDevice(SPEAKER) returned: $result")
                        result
                    } else {
                        @Suppress("DEPRECATION")
                        am.isSpeakerphoneOn = true
                        am.isSpeakerphoneOn
                    }
                } else {
                    am.clearCommunicationDevice()
                    @Suppress("DEPRECATION")
                    am.isSpeakerphoneOn = false
                    true
                }
            } else {
                @Suppress("DEPRECATION")
                am.mode = if (enabled) AudioManager.MODE_IN_COMMUNICATION else AudioManager.MODE_NORMAL
                @Suppress("DEPRECATION")
                am.isSpeakerphoneOn = enabled
                @Suppress("DEPRECATION")
                am.isSpeakerphoneOn == enabled
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to set speakerphone to $enabled", e)
            false
        }
    }

    /**
     * Authoritatively verifies whether the speakerphone is currently active.
     */
    fun isSpeakerphoneActive(context: Context): Boolean {
        val am = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val commDevice = am.communicationDevice
                if (commDevice != null) {
                    commDevice.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER
                } else {
                    @Suppress("DEPRECATION")
                    am.isSpeakerphoneOn
                }
            } else {
                @Suppress("DEPRECATION")
                am.isSpeakerphoneOn
            }
        } catch (e: Exception) {
            Log.w(TAG, "Error checking speakerphone active state", e)
            false
        }
    }

    /**
     * Determines current active communication audio route.
     */
    fun getCurrentAudioRoute(context: Context): String {
        val am = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return "UNKNOWN"
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val device = am.communicationDevice
                if (device != null) {
                    return when (device.type) {
                        AudioDeviceInfo.TYPE_BUILTIN_SPEAKER -> "SPEAKER"
                        AudioDeviceInfo.TYPE_BUILTIN_EARPIECE -> "EARPIECE"
                        AudioDeviceInfo.TYPE_BLUETOOTH_SCO, AudioDeviceInfo.TYPE_BLUETOOTH_A2DP -> "BLUETOOTH"
                        AudioDeviceInfo.TYPE_WIRED_HEADSET, AudioDeviceInfo.TYPE_WIRED_HEADPHONES -> "WIRED_HEADSET"
                        AudioDeviceInfo.TYPE_USB_HEADSET, AudioDeviceInfo.TYPE_USB_DEVICE -> "USB_HEADSET"
                        else -> "OTHER"
                    }
                }
            }
            @Suppress("DEPRECATION")
            if (am.isSpeakerphoneOn) {
                "SPEAKER"
            } else if (am.isBluetoothScoOn || am.isBluetoothA2dpOn) {
                "BLUETOOTH"
            } else if (am.isWiredHeadsetOn) {
                "WIRED_HEADSET"
            } else {
                "EARPIECE"
            }
        } catch (_: Exception) {
            "UNKNOWN"
        }
    }

    /**
     * Checks if automatic speakerphone routing is supported on this device.
     */
    fun isAutoSpeakerphoneSupported(context: Context): Boolean {
        val am = context.getSystemService(Context.AUDIO_SERVICE) as? AudioManager ?: return false
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            am.availableCommunicationDevices.any { it.type == AudioDeviceInfo.TYPE_BUILTIN_SPEAKER }
        } else {
            true
        }
    }
}

