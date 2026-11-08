package com.scamshield.scamshield_guardian

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject
import java.util.regex.Pattern

class ScamShieldNotificationListenerService : NotificationListenerService() {

    companion object {
        private const val TAG = "ScamShieldNotifShield"
        const val PREFS_NOTIFICATION_SHIELD = "scamshield_notification_shield_prefs"
        const val KEY_SHIELD_ENABLED = "sms_shield_enabled"
        const val KEY_DETECTED_THREATS = "detected_sms_threats"
        const val CHANNEL_ID = "scamshield_sms_alerts"
        const val ACTION_SMS_THREAT_DETECTED = "com.scamshield.scamshield_guardian.SMS_THREAT_DETECTED"

        private val TARGET_PACKAGES = setOf(
            "com.google.android.apps.messaging",
            "com.android.mms",
            "com.samsung.android.messaging",
            "com.motorola.messaging",
            "com.oneplus.mms",
            "com.coloros.mms",
            "com.whatsapp",
            "com.whatsapp.w4b",
            "org.telegram.messenger",
            "com.truecaller"
        )

        private val URL_PATTERN = Pattern.compile(
            """(?i)\b(?:https?://|www\.|bit\.ly/|tinyurl\.com/|t\.co/|is\.gd/|ngrok|\b\w+\.(?:xyz|top|icu|link|apk|online|site|club|app))\S+"""
        )

        // Threat Categories and Patterns
        private val THREAT_RULES = listOf(
            ThreatRule(
                category = "Bank / KYC Impersonation",
                pattern = Pattern.compile(
                    """(?i)(?:pan\s*card|kyc\s*(?:expire|mandatory|update|verify)|account\s*(?:blocked|suspended|deactivated|frozen)|yono|sbi\s*rewards|hdfc\s*netbanking)"""
                ),
                defaultReason = "Fake banking urgency attempting to harvest credentials or OTP."
            ),
            ThreatRule(
                category = "Electricity / Utility Disconnection",
                pattern = Pattern.compile(
                    """(?i)(?:electricity|power|bijli)\s*(?:bill\s*unpaid|will\s*be\s*disconnect(?:ed)?|cut\s*off|tonight\s*at\s*\d+)"""
                ),
                defaultReason = "Threat of utility disconnection with fake payment/contact link."
            ),
            ThreatRule(
                category = "Lottery / Work-From-Home Scam",
                pattern = Pattern.compile(
                    """(?i)(?:congratulations.*(?:won|winner)|kbc\s*lottery|earn\s*(?:₹|\$)?\d+\s*daily|youtube\s*like\s*task|part[- ]time\s*job\s*daily\s*income)"""
                ),
                defaultReason = "Unsolicited lottery or fraudulent prepaid task offer."
            ),
            ThreatRule(
                category = "Dangerous Sideloaded APK",
                pattern = Pattern.compile(
                    """(?i)(?:download\s*apk|install\s*(?:our\s*)?app|update\s*via\s*link|\.apk\b)"""
                ),
                defaultReason = "Requesting sideload of an unverified Android APK package."
            ),
            ThreatRule(
                category = "UPI PIN / OTP Extortion",
                pattern = Pattern.compile(
                    """(?i)(?:enter\s*upi\s*pin\s*to\s*receive|send\s*(?:your\s*)?otp|forward\s*this\s*sms)"""
                ),
                defaultReason = "Deceptive attempt to solicit your secret UPI PIN or OTP."
            )
        )
    }

    private data class ThreatRule(
        val category: String,
        val pattern: Pattern,
        val defaultReason: String
    )

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return

        val packageName = sbn.packageName ?: return
        if (packageName == applicationContext.packageName) return // Ignore own notifications

        // Check if user enabled SMS Notification Shield
        val prefs = getSharedPreferences(PREFS_NOTIFICATION_SHIELD, Context.MODE_PRIVATE)
        val isEnabled = prefs.getBoolean(KEY_SHIELD_ENABLED, true)
        if (!isEnabled) return

        // Check if package is an SMS or messaging app
        val isTargetApp = TARGET_PACKAGES.contains(packageName) ||
                packageName.contains("mms") ||
                packageName.contains("messaging")

        if (!isTargetApp) return

        val extras = sbn.notification.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: "Unknown Sender"
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""

        val fullContent = (if (bigText.length > text.length) bigText else text).trim()
        if (fullContent.length < 8) return

        Log.d(TAG, "Inspecting notification from $packageName ($title): ${fullContent.take(50)}...")

        // Scan for threat rules
        val matchedThreat = evaluateThreat(fullContent)
        if (matchedThreat != null) {
            val hasUrl = URL_PATTERN.matcher(fullContent).find()
            val threatScore = if (hasUrl) 88 else 75
            Log.w(TAG, "🚨 MALICIOUS MESSAGE DETECTED from $title! Category: ${matchedThreat.category}, URL: $hasUrl")

            // 1. Post instant heads-up emergency alert
            showHeadsUpAlert(title, fullContent, matchedThreat.category, matchedThreat.defaultReason, threatScore)

            // 2. Persist threat into local history
            recordDetectedThreat(title, fullContent, matchedThreat.category, matchedThreat.defaultReason, threatScore)

            // 3. Broadcast to MainActivity / Flutter if alive
            val broadcastIntent = Intent(ACTION_SMS_THREAT_DETECTED).apply {
                setPackage(applicationContext.packageName)
                putExtra("sender", title)
                putExtra("content", fullContent)
                putExtra("category", matchedThreat.category)
                putExtra("reason", matchedThreat.defaultReason)
                putExtra("score", threatScore)
            }
            sendBroadcast(broadcastIntent)
        }
    }

    private fun evaluateThreat(content: String): ThreatRule? {
        val hasUrl = URL_PATTERN.matcher(content).find()
        for (rule in THREAT_RULES) {
            if (rule.pattern.matcher(content).find()) {
                return rule
            }
        }
        // If content contains an unverified short link + urgent language
        if (hasUrl && Pattern.compile("""(?i)(urgent|immediate|last\s*day|penalty|action\s*required)""").matcher(content).find()) {
            return ThreatRule(
                category = "Suspicious Link with Urgency Pressure",
                pattern = Pattern.compile(".*"),
                defaultReason = "Urgency pressure combined with an unverified shortened link."
            )
        }
        return null
    }

    private fun showHeadsUpAlert(
        sender: String,
        content: String,
        category: String,
        reason: String,
        score: Int
    ) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "ScamShield Real-Time Message Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "High-priority heads-up warnings for dangerous SMS and WhatsApp scam messages"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 300, 150, 300)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("action", "SHOW_SMS_ALERT")
            putExtra("sender", sender)
            putExtra("content", content)
            putExtra("category", category)
            putExtra("reason", reason)
            putExtra("score", score)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            8001,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0)
        )

        val snippet = if (content.length > 90) content.take(90) + "…" else content

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("🚨 ScamShield Alert: Dangerous Message ($category)")
            .setContentText("From $sender: $reason")
            .setStyle(
                NotificationCompat.BigTextStyle()
                    .bigText("🚨 FRAUD DETECTED from $sender:\n\n\"$snippet\"\n\n⚠️ Indicator: $reason\n\n🛡️ DO NOT tap any links, install APKs, or share OTPs!")
            )
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .build()

        notificationManager.notify(8001, notification)
    }

    private fun recordDetectedThreat(
        sender: String,
        content: String,
        category: String,
        reason: String,
        score: Int
    ) {
        try {
            val prefs = getSharedPreferences(PREFS_NOTIFICATION_SHIELD, Context.MODE_PRIVATE)
            val existingJson = prefs.getString(KEY_DETECTED_THREATS, "[]") ?: "[]"
            val array = JSONArray(existingJson)

            val item = JSONObject().apply {
                put("id", System.currentTimeMillis())
                put("sender", sender)
                put("content", content)
                put("category", category)
                put("reason", reason)
                put("score", score)
                put("timestamp", System.currentTimeMillis())
            }

            // Prepend latest item, keeping maximum 20 threats
            val updated = JSONArray()
            updated.put(item)
            for (i in 0 until minOf(array.length(), 19)) {
                updated.put(array.get(i))
            }

            prefs.edit().putString(KEY_DETECTED_THREATS, updated.toString()).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error saving detected threat", e)
        }
    }
}

