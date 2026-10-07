package com.scamshield.scamshield_guardian

import android.content.Context
import android.telephony.TelephonyManager
import org.json.JSONObject
import java.util.UUID

object GuardianCallEvents {
    private const val PREFERENCES = "scamshield_guardian_calls"
    private const val KEY_LATEST_EVENT = "latest_call_event"
    private const val KEY_SESSION_ID = "session_id"
    private const val KEY_DIRECTION = "direction"
    private const val KEY_STATE = "state"
    private const val KEY_LAST_SCREENING_CALLBACK_AT = "last_screening_callback_at"
    private const val KEY_LAST_EVENT_TIMESTAMP = "last_event_timestamp"

    @Volatile
    private var listener: ((Map<String, Any>) -> Unit)? = null

    private var sessionId: String? = null
    private var direction = "UNKNOWN"
    private var state = "IDLE"
    private var lastScreeningCallbackAt = 0L
    private var lastEventTimestamp = 0L
    private var restored = false

    @Synchronized
    fun beginRinging(context: Context, callDirection: String, id: String, event: String) {
        restore(context)
        val now = System.currentTimeMillis()
        if (state == "ACTIVE") return
        if (state == "RINGING" &&
            direction == callDirection &&
            now - lastScreeningCallbackAt < SCREENING_DUPLICATE_WINDOW_MS
        ) {
            return
        }
        lastScreeningCallbackAt = now
        sessionId = id
        direction = callDirection
        state = "RINGING"
        publish(context, event)
    }

    @Synchronized
    fun updateFromTelephony(context: Context, callState: Int) {
        restore(context)
        when (callState) {
            TelephonyManager.CALL_STATE_RINGING -> {
                if (state == "IDLE" || state == "ENDED") {
                    sessionId = UUID.randomUUID().toString()
                    direction = "UNKNOWN"
                    state = "RINGING"
                    publish(context, "CALL_RINGING")
                }
            }
            TelephonyManager.CALL_STATE_OFFHOOK -> {
                if (state == "IDLE" || state == "ENDED") {
                    sessionId = UUID.randomUUID().toString()
                    direction = "UNKNOWN"
                }
                if (state != "ACTIVE") {
                    state = "ACTIVE"
                    publish(context, "CALL_ACTIVE")
                }
            }
            TelephonyManager.CALL_STATE_IDLE -> {
                if (state == "RINGING" || state == "ACTIVE") {
                    state = "ENDED"
                    publish(context, "CALL_ENDED")
                }
            }
        }
    }

    fun setListener(callback: ((Map<String, Any>) -> Unit)?) {
        listener = callback
    }

    @Synchronized
    fun currentSessionId(context: Context): String? {
        restore(context)
        return if (state == "RINGING" || state == "ACTIVE") sessionId else null
    }

    fun latest(context: Context): Map<String, Any>? {
        restore(context)
        val serialized = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
            .getString(KEY_LATEST_EVENT, null) ?: return null
        val json = JSONObject(serialized)
        return json.keys().asSequence().associateWith { key -> json.get(key) }
    }

    private fun publish(context: Context, event: String) {
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        lastEventTimestamp = maxOf(System.currentTimeMillis(), lastEventTimestamp + 1)
        val payload = mapOf(
            "event" to event,
            "sessionId" to (sessionId ?: UUID.randomUUID().toString()),
            "direction" to direction,
            "state" to state,
            "timestamp" to lastEventTimestamp,
            "source" to if (event == "CALL_RINGING" && direction != "UNKNOWN") {
                "TELECOM_SCREENING"
            } else {
                "TELEPHONY_STATE"
            },
        )
        val json = JSONObject(payload).toString()
        preferences.edit()
            .putString(KEY_LATEST_EVENT, json)
            .putString(KEY_SESSION_ID, sessionId)
            .putString(KEY_DIRECTION, direction)
            .putString(KEY_STATE, state)
            .putLong(KEY_LAST_SCREENING_CALLBACK_AT, lastScreeningCallbackAt)
            .putLong(KEY_LAST_EVENT_TIMESTAMP, lastEventTimestamp)
            .apply()
        listener?.invoke(payload)
    }

    private fun restore(context: Context) {
        if (restored) return
        val preferences = context.getSharedPreferences(PREFERENCES, Context.MODE_PRIVATE)
        sessionId = preferences.getString(KEY_SESSION_ID, null)
        direction = preferences.getString(KEY_DIRECTION, "UNKNOWN") ?: "UNKNOWN"
        state = preferences.getString(KEY_STATE, "IDLE") ?: "IDLE"
        lastScreeningCallbackAt = preferences.getLong(KEY_LAST_SCREENING_CALLBACK_AT, 0L)
        lastEventTimestamp = preferences.getLong(KEY_LAST_EVENT_TIMESTAMP, 0L)
        if (state == "RINGING" || state == "ACTIVE") {
            sessionId = null
            direction = "UNKNOWN"
            state = "IDLE"
            preferences.edit()
                .remove(KEY_LATEST_EVENT)
                .remove(KEY_SESSION_ID)
                .putString(KEY_DIRECTION, direction)
                .putString(KEY_STATE, state)
                .apply()
        }
        restored = true
    }

    private const val SCREENING_DUPLICATE_WINDOW_MS = 1500L
}
