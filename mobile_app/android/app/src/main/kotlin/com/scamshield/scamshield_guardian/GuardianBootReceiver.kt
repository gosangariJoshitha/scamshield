package com.scamshield.scamshield_guardian

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class GuardianBootReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "GuardianBootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        if (action == Intent.ACTION_BOOT_COMPLETED || action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            val prefs = context.getSharedPreferences(CallStateGuardianService.GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
            val isEnabled = prefs.getBoolean(CallStateGuardianService.KEY_GUARDIAN_ENABLED, false)
            Log.i(TAG, "Received $action. Sentinel guardian enabled status: $isEnabled")
            if (isEnabled) {
                try {
                    val serviceIntent = Intent(context, CallStateGuardianService::class.java).apply {
                        this.action = CallStateGuardianService.ACTION_START
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }
                    Log.i(TAG, "Successfully triggered CallStateGuardianService restart.")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to start CallStateGuardianService on boot", e)
                }
            }
        }
    }
}

