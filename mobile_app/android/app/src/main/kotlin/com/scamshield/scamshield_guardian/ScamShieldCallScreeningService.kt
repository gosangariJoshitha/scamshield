package com.scamshield.scamshield_guardian

import android.os.Build
import android.telecom.Call
import android.telecom.CallScreeningService
import java.util.UUID

class ScamShieldCallScreeningService : CallScreeningService() {
    override fun onScreenCall(callDetails: Call.Details) {
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
}
