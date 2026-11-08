package com.scamshield.scamshield_guardian

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.UUID

class ScamShieldCallScreeningService : CallScreeningService() {
    companion object {
        private const val TAG = "ScamShieldCallScreening"
        const val PREFS_BLACKLIST = "scamshield_screening_blacklist"
        const val KEY_BLOCKED_NUMBERS = "blocked_numbers"
        const val NOTIFICATION_CHANNEL_ID = "scamshield_screening_alerts"
        const val NOTIFICATION_ID = 3001
    }

    override fun onScreenCall(callDetails: Call.Details) {
        val handle = callDetails.handle
        val rawNumber = handle?.schemeSpecificPart ?: ""
        val cleanNumber = rawNumber.replace(Regex("[^0-9+]"), "")

        val prefs = getSharedPreferences(PREFS_BLACKLIST, Context.MODE_PRIVATE)
        val blockedSet = prefs.getStringSet(KEY_BLOCKED_NUMBERS, emptySet()) ?: emptySet()

        val isBlocked = cleanNumber.isNotEmpty() && (
            blockedSet.contains(cleanNumber) ||
            blockedSet.any { it.isNotEmpty() && (cleanNumber.endsWith(it) || it.endsWith(cleanNumber)) }
        )

        if (isBlocked) {
            Log.w(TAG, "Pre-Call Screening intercepted and rejected blacklisted scam caller: $cleanNumber")
            val response = CallResponse.Builder()
                .setDisallowCall(true)
                .setRejectCall(true)
                .setSkipCallLog(false)
                .setSkipNotification(false)
                .build()
            respondToCall(callDetails, response)
            notifyBlockedCall(if (rawNumber.isNotEmpty()) rawNumber else cleanNumber)
            return
        }

        // Normal call passed through - begin live protection monitoring
        respondToCall(
            callDetails,
            CallResponse.Builder()
                .setDisallowCall(false)
                .setRejectCall(false)
                .setSkipCallLog(false)
                .setSkipNotification(false)
                .build(),
        )
        val direction = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            when (callDetails.callDirection) {
                Call.Details.DIRECTION_INCOMING -> "INCOMING"
                Call.Details.DIRECTION_OUTGOING -> "OUTGOING"
                else -> "UNKNOWN"
            }
        } else {
            "UNKNOWN"
        }
        GuardianCallEvents.beginRinging(
            this,
            direction,
            UUID.randomUUID().toString(),
            "CALL_RINGING",
        )
    }

    private fun notifyBlockedCall(phoneNumber: String) {
        try {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val channel = NotificationChannel(
                    NOTIFICATION_CHANNEL_ID,
                    "ScamShield Pre-Call Screening",
                    NotificationManager.IMPORTANCE_HIGH
                ).apply {
                    description = "Alerts when incoming fraudulent calls are screened and blocked"
                }
                manager.createNotificationChannel(channel)
            }

            val launchIntent = Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("action", "BLOCKED_CALL_SUMMARY")
                putExtra("phoneNumber", phoneNumber)
            }
            val pendingIntent = PendingIntent.getActivity(
                this,
                NOTIFICATION_ID,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
            )

            val displayNum = if (phoneNumber.isNotEmpty()) phoneNumber else "Unknown Caller"
            val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle("🛡️ Scam Call Blocked by ScamShield")
                .setContentText("Rejected incoming call from $displayNum (Verified Fraud Threat).")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .build()

            manager.notify(NOTIFICATION_ID, notification)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to display blocked call notification", e)
        }
    }
}
