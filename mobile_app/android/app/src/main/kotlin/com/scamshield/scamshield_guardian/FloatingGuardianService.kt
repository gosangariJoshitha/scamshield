package com.scamshield.scamshield_guardian

import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.app.NotificationCompat
import kotlin.math.abs

class FloatingGuardianService : Service() {
    companion object {
        private const val TAG = "FloatingGuardianService"
        const val ACTION_SHOW = "com.scamshield.action.SHOW_FLOATING_GUARDIAN"
        const val ACTION_UPDATE = "com.scamshield.action.UPDATE_FLOATING_GUARDIAN"
        const val ACTION_HIDE = "com.scamshield.action.HIDE_FLOATING_GUARDIAN"

        const val EXTRA_STATE = "extra_state"
        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_SCORE = "extra_score"

        const val STATE_NORMAL = "NORMAL"
        const val STATE_CALL_DETECTED = "CALL_DETECTED"
        const val STATE_MONITORING = "MONITORING"
        const val STATE_SUSPICIOUS = "SUSPICIOUS"
        const val STATE_CRITICAL = "CRITICAL"

        private const val NOTIFICATION_CHANNEL_ID = "scamshield_floating_overlay_channel"
        private const val NOTIFICATION_ID = 2002

        var isShowing: Boolean = false
            private set

        private var activeService: FloatingGuardianService? = null

        fun show(context: Context, state: String = STATE_NORMAL, title: String? = null, riskScore: Int? = null) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
                Log.w(TAG, "Cannot show floating guardian: SYSTEM_ALERT_WINDOW permission not granted.")
                return
            }
            val intent = Intent(context, FloatingGuardianService::class.java).apply {
                action = ACTION_SHOW
                putExtra(EXTRA_STATE, state)
                putExtra(EXTRA_TITLE, title)
                if (riskScore != null) putExtra(EXTRA_SCORE, riskScore)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun update(state: String, title: String? = null, riskScore: Int? = null) {
            val service = activeService
            if (service != null && isShowing) {
                service.applyState(state, title, riskScore)
            }
        }

        fun hide(context: Context) {
            val intent = Intent(context, FloatingGuardianService::class.java).apply {
                action = ACTION_HIDE
            }
            context.startService(intent)
        }
    }

    private var windowManager: WindowManager? = null
    private var overlayView: LinearLayout? = null
    private var statusTextView: TextView? = null
    private var iconView: TextView? = null
    private var layoutParams: WindowManager.LayoutParams? = null

    private var currentState = STATE_NORMAL
    private var currentTitle: String? = null
    private var currentScore: Int? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        activeService = this
        windowManager = getSystemService(Context.WINDOW_SERVICE) as? WindowManager
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: ACTION_SHOW
        when (action) {
            ACTION_SHOW -> {
                val state = intent?.getStringExtra(EXTRA_STATE) ?: STATE_NORMAL
                val title = intent?.getStringExtra(EXTRA_TITLE)
                val score = if (intent?.hasExtra(EXTRA_SCORE) == true) intent.getIntExtra(EXTRA_SCORE, 0) else null
                startAsForeground()
                createOrUpdateOverlay(state, title, score)
            }
            ACTION_UPDATE -> {
                val state = intent?.getStringExtra(EXTRA_STATE) ?: currentState
                val title = intent?.getStringExtra(EXTRA_TITLE) ?: currentTitle
                val score = if (intent?.hasExtra(EXTRA_SCORE) == true) intent.getIntExtra(EXTRA_SCORE, 0) else currentScore
                createOrUpdateOverlay(state, title, score)
            }
            ACTION_HIDE -> {
                removeOverlay()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        removeOverlay()
        if (activeService === this) {
            activeService = null
        }
        isShowing = false
        super.onDestroy()
    }

    private fun startAsForeground() {
        val notification = buildForegroundNotification()
        startForeground(NOTIFICATION_ID, notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "ScamShield Floating Guardian",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Shows live call floating protection overlay button"
                setShowBadge(false)
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager?.createNotificationChannel(channel)
        }
    }

    private fun buildForegroundNotification(): Notification {
        val openAppIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or (if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0),
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("ScamShield Floating Guardian Active")
            .setContentText("Tap overlay to open call protection.")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun createOrUpdateOverlay(state: String, title: String?, score: Int?) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Log.w(TAG, "Cannot create overlay: SYSTEM_ALERT_WINDOW permission missing.")
            return
        }

        if (overlayView == null) {
            val density = resources.displayMetrics.density
            val wm = windowManager ?: return

            val windowType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_PHONE
            }

            layoutParams = WindowManager.LayoutParams(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT,
                windowType,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT,
            ).apply {
                gravity = Gravity.TOP or Gravity.START
                x = (20 * density).toInt()
                y = (180 * density).toInt()
            }

            val container = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                gravity = Gravity.CENTER_VERTICAL
                setPadding((14 * density).toInt(), (10 * density).toInt(), (16 * density).toInt(), (10 * density).toInt())
                elevation = 16f * density
            }

            val icon = TextView(this).apply {
                textSize = 18f
                text = "🛡️"
                gravity = Gravity.CENTER
            }
            iconView = icon
            container.addView(icon)

            val text = TextView(this).apply {
                textSize = 13.5f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER_VERTICAL
                setPadding((8 * density).toInt(), 0, 0, 0)
            }
            statusTextView = text
            container.addView(text)

            // Drag & Tap Listener
            container.setOnTouchListener(object : View.OnTouchListener {
                private var initialX = 0
                private var initialY = 0
                private var initialTouchX = 0f
                private var initialTouchY = 0f
                private val touchSlop = 10 * density

                override fun onTouch(v: View, event: MotionEvent): Boolean {
                    val lp = layoutParams ?: return false
                    when (event.action) {
                        MotionEvent.ACTION_DOWN -> {
                            initialX = lp.x
                            initialY = lp.y
                            initialTouchX = event.rawX
                            initialTouchY = event.rawY
                            return true
                        }
                        MotionEvent.ACTION_MOVE -> {
                            val dx = (event.rawX - initialTouchX).toInt()
                            val dy = (event.rawY - initialTouchY).toInt()
                            lp.x = initialX + dx
                            lp.y = initialY + dy
                            try {
                                wm.updateViewLayout(overlayView, lp)
                            } catch (_: Exception) {}
                            return true
                        }
                        MotionEvent.ACTION_UP -> {
                            val totalDeltaX = abs(event.rawX - initialTouchX)
                            val totalDeltaY = abs(event.rawY - initialTouchY)
                            if (totalDeltaX < touchSlop && totalDeltaY < touchSlop) {
                                // Click detected!
                                onOverlayClicked()
                            }
                            return true
                        }
                    }
                    return false
                }
            })

            try {
                wm.addView(container, layoutParams)
                overlayView = container
                isShowing = true
            } catch (e: Exception) {
                Log.e(TAG, "Failed to add floating overlay view", e)
                return
            }
        }

        applyState(state, title, score)
    }

    private fun applyState(state: String, title: String?, score: Int?) {
        currentState = state
        currentTitle = title
        currentScore = score

        val density = resources.displayMetrics.density
        val background = GradientDrawable().apply {
            cornerRadius = 24f * density
        }

        when (state) {
            STATE_CALL_DETECTED -> {
                iconView?.text = "🛡️"
                statusTextView?.text = title ?: "Protect Call"
                statusTextView?.visibility = View.VISIBLE
                background.setColor(Color.parseColor("#EA580C")) // Amber Orange
                background.setStroke((2 * density).toInt(), Color.parseColor("#FED7AA"))
            }
            STATE_MONITORING -> {
                iconView?.text = "🛡️"
                val displayTitle = if (score != null) "LIVE: $score" else (title ?: "LIVE")
                statusTextView?.text = displayTitle
                statusTextView?.visibility = View.VISIBLE
                background.setColor(Color.parseColor("#0284C7")) // Cyan / Blue
                background.setStroke((2 * density).toInt(), Color.parseColor("#BAE6FD"))
            }
            STATE_SUSPICIOUS -> {
                iconView?.text = "⚠️"
                val displayTitle = if (score != null) "HIGH RISK ($score)" else (title ?: "HIGH RISK")
                statusTextView?.text = displayTitle
                statusTextView?.visibility = View.VISIBLE
                background.setColor(Color.parseColor("#DC2626")) // Red
                background.setStroke((2 * density).toInt(), Color.parseColor("#FECACA"))
            }
            STATE_CRITICAL -> {
                iconView?.text = "🚨"
                val displayTitle = if (score != null) "CRITICAL ($score)" else (title ?: "CRITICAL")
                statusTextView?.text = displayTitle
                statusTextView?.visibility = View.VISIBLE
                background.setColor(Color.parseColor("#991B1B")) // Dark Red
                background.setStroke((2.5f * density).toInt(), Color.parseColor("#EF4444"))
            }
            STATE_NORMAL -> {
                iconView?.text = "🛡️"
                if (title != null && title.isNotEmpty()) {
                    statusTextView?.text = title
                    statusTextView?.visibility = View.VISIBLE
                } else {
                    statusTextView?.visibility = View.GONE
                }
                background.setColor(Color.parseColor("#0F172A")) // Dark Slate
                background.setStroke((1.5f * density).toInt(), Color.parseColor("#10B981")) // Emerald border
            }
            else -> {
                iconView?.text = "🛡️"
                statusTextView?.text = title ?: "ScamShield"
                statusTextView?.visibility = View.VISIBLE
                background.setColor(Color.parseColor("#0F172A"))
                background.setStroke((1.5f * density).toInt(), Color.parseColor("#38BDF8"))
            }
        }

        overlayView?.background = background
    }

    private fun onOverlayClicked() {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("action", "PROTECT_CALL")
            putExtra("source", "FLOATING_GUARDIAN")
            putExtra("state", currentState)
        }
        startActivity(launchIntent)
    }

    private fun removeOverlay() {
        if (overlayView != null && windowManager != null) {
            try {
                windowManager?.removeView(overlayView)
            } catch (e: Exception) {
                Log.e(TAG, "Error removing floating overlay view", e)
            }
            overlayView = null
            isShowing = false
        }
    }
}

