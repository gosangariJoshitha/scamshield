package com.scamshield.scamshield_guardian

import android.Manifest
import android.annotation.SuppressLint
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.provider.Settings
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.ViewConfiguration
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import kotlin.math.abs

/**
 * FloatingGuardianService implements the Floating Sentinel Button as a
 * quick-access Protection ON/OFF entry point and background reliability monitor.
 *
 * Core Capabilities:
 * 1. Quick-Access Protection Control:
 *    - Allows users to turn ON Sentinel Protection directly from other apps if forgotten.
 *    - Dynamic tap action based on actual state (State A: OFF, State B: ON, State C: Missing Permission,
 *      State D: Unavailable, State E: Active Call).
 * 2. Long-Press Gesture:
 *    - Long pressing the circular bubble immediately launches the full ScamShield app.
 * 3. Compact Dimensions & Usability:
 *    - 56dp circular bubble with centered shield and real-time status dot.
 *    - Draggable with edge snapping and strict screen-boundary clamping.
 * 4. Safe Disabling:
 *    - Requires clear user confirmation before turning protection OFF to prevent accidental deactivation.
 * 5. In-Call Audio Guidance & Zero Duplicate Call Controls:
 *    - Displays active call status, verified audio route (Speaker vs Earpiece), and speakerphone tip.
 *    - NO duplicate call controls (Hang Up / Speaker buttons removed).
 *    - Closing overlay NEVER disconnects calls or disables background Sentinel service.
 */
class FloatingGuardianService : Service() {
    companion object {
        private const val TAG = "FloatingGuardianService"
        const val ACTION_SHOW = "com.scamshield.action.SHOW_FLOATING_GUARDIAN"
        const val ACTION_UPDATE = "com.scamshield.action.UPDATE_FLOATING_GUARDIAN"
        const val ACTION_HIDE = "com.scamshield.action.HIDE_FLOATING_GUARDIAN"
        const val ACTION_EXPAND = "com.scamshield.action.EXPAND_FLOATING_GUARDIAN"
        const val ACTION_COLLAPSE = "com.scamshield.action.COLLAPSE_FLOATING_GUARDIAN"

        const val EXTRA_STATE = "extra_state"
        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_SCORE = "extra_score"
        const val EXTRA_CATEGORY = "extra_category"
        const val EXTRA_SNIPPET = "extra_snippet"

        const val STATE_NORMAL = "NORMAL"
        const val STATE_CALL_DETECTED = "CALL_DETECTED"
        const val STATE_MONITORING = "MONITORING"
        const val STATE_SUSPICIOUS = "SUSPICIOUS"
        const val STATE_CRITICAL = "CRITICAL"
        const val STATE_PERMISSION_REQUIRED = "PERMISSION_REQUIRED"
        const val STATE_DISABLED = "DISABLED"
        const val STATE_UNAVAILABLE = "UNAVAILABLE"

        private const val NOTIFICATION_CHANNEL_ID = "scamshield_floating_overlay_channel"
        private const val NOTIFICATION_ID = 2002

        var isShowing: Boolean = false
            private set

        private var activeService: FloatingGuardianService? = null

        fun show(
            context: Context,
            state: String = STATE_NORMAL,
            title: String? = null,
            riskScore: Int? = null,
            category: String? = null,
            snippet: String? = null
        ) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(context)) {
                Log.w(TAG, "Cannot show floating guardian: SYSTEM_ALERT_WINDOW permission not granted.")
                return
            }
            val intent = Intent(context, FloatingGuardianService::class.java).apply {
                action = ACTION_SHOW
                putExtra(EXTRA_STATE, state)
                putExtra(EXTRA_TITLE, title)
                if (riskScore != null) putExtra(EXTRA_SCORE, riskScore)
                if (category != null) putExtra(EXTRA_CATEGORY, category)
                if (snippet != null) putExtra(EXTRA_SNIPPET, snippet)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun update(
            state: String,
            title: String? = null,
            riskScore: Int? = null,
            category: String? = null,
            snippet: String? = null
        ) {
            val service = activeService
            if (service != null && isShowing) {
                service.applyState(state, title, riskScore, category, snippet)
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
    private var overlayRoot: View? = null
    private var layoutParams: WindowManager.LayoutParams? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    // Real-time State
    private var currentState = STATE_NORMAL
    private var currentTitle: String? = null
    private var currentScore: Int? = null
    private var currentCategory: String? = null
    private var currentSnippet: String? = null
    private var isExpanded: Boolean = false
    private var isConfirmingTurnOff: Boolean = false
    private var enablingInProgress: Boolean = false

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
                val category = intent?.getStringExtra(EXTRA_CATEGORY)
                val snippet = intent?.getStringExtra(EXTRA_SNIPPET)
                startAsForeground()
                createOrRebuildOverlay(state, title, score, category, snippet)
            }
            ACTION_UPDATE -> {
                val state = intent?.getStringExtra(EXTRA_STATE) ?: currentState
                val title = intent?.getStringExtra(EXTRA_TITLE) ?: currentTitle
                val score = if (intent?.hasExtra(EXTRA_SCORE) == true) intent.getIntExtra(EXTRA_SCORE, 0) else currentScore
                val category = intent?.getStringExtra(EXTRA_CATEGORY) ?: currentCategory
                val snippet = intent?.getStringExtra(EXTRA_SNIPPET) ?: currentSnippet
                applyState(state, title, score, category, snippet)
            }
            ACTION_EXPAND -> {
                isExpanded = true
                isConfirmingTurnOff = false
                rebuildOverlayView()
            }
            ACTION_COLLAPSE -> {
                isExpanded = false
                isConfirmingTurnOff = false
                rebuildOverlayView()
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
                "ScamShield Floating Sentinel",
                NotificationManager.IMPORTANCE_LOW,
            ).apply {
                description = "Displays floating Sentinel protection indicator during calls"
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
            .setContentTitle("ScamShield Sentinel Active")
            .setContentText("Tap overlay to view live call protection.")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    private fun createOrRebuildOverlay(state: String, title: String?, score: Int?, category: String?, snippet: String?) {
        currentState = state
        currentTitle = title
        currentScore = score
        currentCategory = category
        currentSnippet = snippet
        rebuildOverlayView()
    }

    private fun applyState(state: String, title: String?, score: Int?, category: String?, snippet: String?) {
        currentState = state
        currentTitle = title
        currentScore = score
        currentCategory = category
        currentSnippet = snippet
        rebuildOverlayView()
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun rebuildOverlayView() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
            Log.w(TAG, "Cannot create overlay: SYSTEM_ALERT_WINDOW permission missing.")
            return
        }

        val wm = windowManager ?: return
        val displayMetrics = resources.displayMetrics
        val density = displayMetrics.density
        val screenWidth = displayMetrics.widthPixels
        val screenHeight = displayMetrics.heightPixels

        val viewWidthPx = if (isExpanded) (270 * density).toInt() else (56 * density).toInt()
        val viewHeightPx = if (isExpanded) WindowManager.LayoutParams.WRAP_CONTENT else (56 * density).toInt()

        val prevX = layoutParams?.x ?: (screenWidth - viewWidthPx - (16 * density).toInt())
        val prevY = layoutParams?.y ?: (screenHeight / 3)

        val clampedX = prevX.coerceIn(0, (screenWidth - viewWidthPx).coerceAtLeast(0))
        val clampedY = prevY.coerceIn(0, (screenHeight - (if (isExpanded) 380 * density else 56 * density).toInt()).coerceAtLeast(0))

        if (overlayRoot != null) {
            try {
                wm.removeView(overlayRoot)
            } catch (_: Exception) {}
            overlayRoot = null
        }

        val windowType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        layoutParams = WindowManager.LayoutParams(
            viewWidthPx,
            viewHeightPx,
            windowType,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT,
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = clampedX
            y = clampedY
        }

        val container: View = if (isExpanded) {
            buildExpandedHudView(density, screenWidth, screenHeight)
        } else {
            buildMiniCircularButton(density, screenWidth, screenHeight)
        }

        try {
            wm.addView(container, layoutParams)
            overlayRoot = container
            isShowing = true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to add floating overlay view", e)
        }
    }

    /**
     * Collapsed State:
     * - 56dp circular draggable button with centered shield and dynamic status dot.
     * - Single tap: dynamic primary action based on protection state.
     * - Long press: immediately opens ScamShield full application.
     * - Dragging clamped to screen bounds with smooth edge snapping.
     */
    @SuppressLint("ClickableViewAccessibility")
    private fun buildMiniCircularButton(density: Float, screenWidth: Int, screenHeight: Int): FrameLayout {
        val sizePx = (56 * density).toInt()

        val root = FrameLayout(this).apply {
            layoutParams = WindowManager.LayoutParams(sizePx, sizePx)
            elevation = 16f * density
        }

        val circleView = FrameLayout(this).apply {
            val bg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#0B132B")) // Midnight Slate
                val strokeColor = when (deriveActualState()) {
                    STATE_CRITICAL -> Color.parseColor("#EF4444")
                    STATE_SUSPICIOUS -> Color.parseColor("#F97316")
                    STATE_MONITORING -> Color.parseColor("#10B981")
                    STATE_CALL_DETECTED -> Color.parseColor("#F59E0B")
                    STATE_PERMISSION_REQUIRED -> Color.parseColor("#F59E0B")
                    STATE_DISABLED -> Color.parseColor("#64748B")
                    else -> Color.parseColor("#10B981")
                }
                setStroke((2f * density).toInt(), strokeColor)
            }
            background = bg
        }

        val shieldIcon = TextView(this).apply {
            text = "🛡️"
            textSize = 22f
            gravity = Gravity.CENTER
        }
        val iconLp = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT,
            Gravity.CENTER
        )
        circleView.addView(shieldIcon, iconLp)
        root.addView(circleView, FrameLayout.LayoutParams(sizePx, sizePx))

        // Status Dot
        val dotSize = (12 * density).toInt()
        val statusDot = View(this).apply {
            val dotBg = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                val dotColor = when (deriveActualState()) {
                    STATE_CRITICAL -> Color.parseColor("#EF4444")
                    STATE_SUSPICIOUS -> Color.parseColor("#F97316")
                    STATE_MONITORING -> Color.parseColor("#10B981")
                    STATE_CALL_DETECTED -> Color.parseColor("#F59E0B")
                    STATE_PERMISSION_REQUIRED -> Color.parseColor("#F59E0B")
                    STATE_DISABLED -> Color.parseColor("#64748B")
                    STATE_UNAVAILABLE -> Color.parseColor("#475569")
                    else -> Color.parseColor("#10B981") // Protected Green
                }
                setColor(dotColor)
                setStroke((1.5f * density).toInt(), Color.WHITE)
            }
            background = dotBg
        }
        val dotLp = FrameLayout.LayoutParams(dotSize, dotSize).apply {
            gravity = Gravity.TOP or Gravity.END
            topMargin = (3 * density).toInt()
            marginEnd = (3 * density).toInt()
        }
        root.addView(statusDot, dotLp)

        // Touch Listener: Single-Tap vs Long-Press + Drag Clamping & Edge Snapping
        root.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0f
            private var initialTouchY = 0f
            private val touchSlop = 8 * density
            private var isLongPress = false
            private val longPressTimeout = ViewConfiguration.getLongPressTimeout().toLong()

            private val longPressRunnable = Runnable {
                isLongPress = true
                Toast.makeText(this@FloatingGuardianService, "Opening ScamShield...", Toast.LENGTH_SHORT).show()
                openFullApp()
            }

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                val lp = layoutParams ?: return false
                val wm = windowManager ?: return false
                when (event.action) {
                    MotionEvent.ACTION_DOWN -> {
                        initialX = lp.x
                        initialY = lp.y
                        initialTouchX = event.rawX
                        initialTouchY = event.rawY
                        isLongPress = false
                        mainHandler.postDelayed(longPressRunnable, longPressTimeout)
                        return true
                    }
                    MotionEvent.ACTION_MOVE -> {
                        val dx = (event.rawX - initialTouchX).toInt()
                        val dy = (event.rawY - initialTouchY).toInt()
                        if (abs(dx) > touchSlop || abs(dy) > touchSlop) {
                            mainHandler.removeCallbacks(longPressRunnable)
                        }
                        val newX = (initialX + dx).coerceIn(0, screenWidth - sizePx)
                        val newY = (initialY + dy).coerceIn(0, screenHeight - sizePx)
                        lp.x = newX
                        lp.y = newY
                        try {
                            wm.updateViewLayout(overlayRoot, lp)
                        } catch (_: Exception) {}
                        return true
                    }
                    MotionEvent.ACTION_UP -> {
                        mainHandler.removeCallbacks(longPressRunnable)
                        val totalDeltaX = abs(event.rawX - initialTouchX)
                        val totalDeltaY = abs(event.rawY - initialTouchY)
                        if (!isLongPress && totalDeltaX < touchSlop && totalDeltaY < touchSlop) {
                            // Single Tap: Dynamic action based on actual protection state
                            handleSingleTapAction()
                        } else if (!isLongPress) {
                            // Drag released: snap to nearest edge
                            val margin = (12 * density).toInt()
                            val targetX = if (lp.x + sizePx / 2 < screenWidth / 2) {
                                margin
                            } else {
                                screenWidth - sizePx - margin
                            }
                            lp.x = targetX.coerceIn(0, screenWidth - sizePx)
                            try {
                                wm.updateViewLayout(overlayRoot, lp)
                            } catch (_: Exception) {}
                        }
                        return true
                    }
                    MotionEvent.ACTION_CANCEL -> {
                        mainHandler.removeCallbacks(longPressRunnable)
                        return true
                    }
                }
                return false
            }
        })

        return root
    }

    /**
     * Single-Tap Dynamic Dispatcher:
     * - State A (Protection OFF): Arm Sentinel protection immediately or prompt permissions.
     * - State B/C/D/E: Expand to informational panel.
     */
    private fun handleSingleTapAction() {
        val actualState = deriveActualState()
        if (actualState == STATE_DISABLED) {
            if (isCallActiveNow() || !hasPhonePermission() || !hasAudioPermission()) {
                isExpanded = true
                rebuildOverlayView()
            } else {
                quickEnableProtectionFlow()
            }
        } else {
            isExpanded = true
            rebuildOverlayView()
        }
    }

    private fun isCallActiveNow(): Boolean {
        return try {
            val tm = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            val state = tm?.callState ?: TelephonyManager.CALL_STATE_IDLE
            state == TelephonyManager.CALL_STATE_OFFHOOK || state == TelephonyManager.CALL_STATE_RINGING
        } catch (_: Exception) {
            false
        }
    }

    private fun autoSpeakerphoneEnabled(): Boolean =
        getSharedPreferences(CallStateGuardianService.GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
            .getBoolean(CallStateGuardianService.KEY_AUTO_SPEAKERPHONE_ENABLED, false)

    private fun quickEnableAndAnalyzeCurrentCall() {
        enablingInProgress = true
        Toast.makeText(this, "Activating Sentinel for active call...", Toast.LENGTH_SHORT).show()
        val success = enableProtection()
        mainHandler.postDelayed({
            enablingInProgress = false
            if (success) {
                GuardianCallEvents.updateFromTelephony(this@FloatingGuardianService, TelephonyManager.CALL_STATE_OFFHOOK)
                val sid = GuardianCallEvents.currentSessionId(this@FloatingGuardianService)
                if (autoSpeakerphoneEnabled()) {
                    CallAudioRouter.setSpeakerphone(this@FloatingGuardianService, true)
                }
                if (hasAudioPermission() && sid != null) {
                    GuardianAudioPipeline.start(this@FloatingGuardianService, sid)
                }
                currentState = STATE_MONITORING
                Toast.makeText(this@FloatingGuardianService, "Live protection active", Toast.LENGTH_SHORT).show()
                openFullApp()
            } else {
                Toast.makeText(this@FloatingGuardianService, "Could not activate protection", Toast.LENGTH_SHORT).show()
            }
            rebuildOverlayView()
        }, 500)
    }

    private fun quickEnableProtectionFlow() {
        enablingInProgress = true
        Toast.makeText(this, "Enabling Sentinel Protection...", Toast.LENGTH_SHORT).show()
        val success = enableProtection()
        mainHandler.postDelayed({
            enablingInProgress = false
            if (success && CallStateGuardianService.isRunning) {
                Toast.makeText(this, "Protection is ON", Toast.LENGTH_SHORT).show()
                currentState = STATE_NORMAL
            } else if (!hasPhonePermission() || !hasAudioPermission()) {
                currentState = STATE_PERMISSION_REQUIRED
            } else {
                currentState = STATE_UNAVAILABLE
            }
            rebuildOverlayView()
        }, 600)
    }

    /**
     * Compact Expanded HUD:
     * - Renders dynamic content based on state (State A: OFF, State B: ON/Standby,
     *   State C: Missing Permission, State D: Unavailable, State E: Active Call).
     */
    @SuppressLint("ClickableViewAccessibility")
    private fun buildExpandedHudView(density: Float, screenWidth: Int, screenHeight: Int): LinearLayout {
        val actualState = deriveActualState()
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding((14 * density).toInt(), (12 * density).toInt(), (14 * density).toInt(), (14 * density).toInt())
            elevation = 20f * density
        }

        val strokeColor = when (actualState) {
            STATE_CRITICAL -> Color.parseColor("#EF4444")
            STATE_SUSPICIOUS -> Color.parseColor("#F97316")
            STATE_MONITORING -> Color.parseColor("#10B981")
            STATE_CALL_DETECTED -> Color.parseColor("#F59E0B")
            STATE_PERMISSION_REQUIRED -> Color.parseColor("#F59E0B")
            STATE_DISABLED -> Color.parseColor("#64748B")
            else -> Color.parseColor("#10B981")
        }

        val bg = GradientDrawable().apply {
            cornerRadius = 18f * density
            setColor(Color.parseColor("#0B132B"))
            setStroke((2 * density).toInt(), strokeColor)
        }
        root.background = bg

        // 1. Header Drag & Close Row
        val header = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
        }

        val titleIcon = TextView(this).apply {
            text = "🛡️"
            textSize = 15f
        }
        header.addView(titleIcon)

        val headerTitle = TextView(this).apply {
            text = " ScamShield Sentinel"
            textSize = 13.5f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.WHITE)
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        }
        header.addView(headerTitle)

        // Close (✕) button: Minimizes back to circular button. NEVER ends call or disables Sentinel.
        val closeBtn = TextView(this).apply {
            text = " ✕ "
            textSize = 14f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#94A3B8"))
            setPadding((8 * density).toInt(), (4 * density).toInt(), (4 * density).toInt(), (4 * density).toInt())
            setOnClickListener {
                isExpanded = false
                isConfirmingTurnOff = false
                rebuildOverlayView()
            }
        }
        header.addView(closeBtn)
        root.addView(header)

        header.setOnTouchListener(object : View.OnTouchListener {
            private var initialX = 0
            private var initialY = 0
            private var initialTouchX = 0f
            private var initialTouchY = 0f

            override fun onTouch(v: View, event: MotionEvent): Boolean {
                val lp = layoutParams ?: return false
                val wm = windowManager ?: return false
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
                        val viewW = (270 * density).toInt()
                        lp.x = (initialX + dx).coerceIn(0, (screenWidth - viewW).coerceAtLeast(0))
                        lp.y = (initialY + dy).coerceIn(0, (screenHeight - (320 * density).toInt()).coerceAtLeast(0))
                        try {
                            wm.updateViewLayout(overlayRoot, lp)
                        } catch (_: Exception) {}
                        return true
                    }
                }
                return false
            }
        })

        // 2. Render State-Specific Content
        when (actualState) {
            STATE_DISABLED -> renderStateDisabled(root, density)
            STATE_PERMISSION_REQUIRED -> renderStatePermissionRequired(root, density)
            STATE_UNAVAILABLE -> renderStateUnavailable(root, density)
            STATE_CALL_DETECTED, STATE_MONITORING, STATE_SUSPICIOUS, STATE_CRITICAL -> renderStateCallActive(root, density)
            else -> renderStateStandby(root, density)
        }

        return root
    }

    private fun renderStateDisabled(root: LinearLayout, density: Float) {
        val callActive = isCallActiveNow()
        val statusRow = createStatusBadgeRow("PROTECTION OFF", Color.parseColor("#64748B"), "Sentinel is disabled", density)
        root.addView(statusRow)

        if (callActive) {
            val callAlertCard = createCardView(density).apply {
                addView(TextView(this@FloatingGuardianService).apply {
                    text = "📞 Active call detected"
                    textSize = 12f
                    typeface = Typeface.DEFAULT_BOLD
                    setTextColor(Color.parseColor("#F59E0B"))
                })
                addView(TextView(this@FloatingGuardianService).apply {
                    text = "Activate protection now to monitor and analyze the remaining conversation."
                    textSize = 11f
                    setTextColor(Color.parseColor("#E2E8F0"))
                    setPadding(0, (4 * density).toInt(), 0, 0)
                })
            }
            root.addView(callAlertCard)

            val enableAndAnalyzeBtn = createActionButton(
                if (enablingInProgress) "Activating Protection..." else "Enable Protection & Analyze Current Call",
                Color.parseColor("#0D9488"),
                density
            ) {
                if (!hasPhonePermission() || !hasAudioPermission()) {
                    openAppPermissionSettings()
                } else {
                    quickEnableAndAnalyzeCurrentCall()
                }
            }
            root.addView(enableAndAnalyzeBtn)
        } else {
            val infoCard = createCardView(density).apply {
                addView(TextView(this@FloatingGuardianService).apply {
                    text = "Turn ON protection to automatically detect and screen suspicious calls."
                    textSize = 11.5f
                    setTextColor(Color.parseColor("#CBD5E1"))
                })
            }
            root.addView(infoCard)

            val enableBtn = createActionButton(
                if (enablingInProgress) "Enabling Protection..." else "Turn ON Protection",
                Color.parseColor("#0D9488"),
                density
            ) {
                if (!hasPhonePermission() || !hasAudioPermission()) {
                    openAppPermissionSettings()
                } else {
                    quickEnableProtectionFlow()
                }
            }
            root.addView(enableBtn)
        }

        // Secondary Action: Open Sentinel
        val openSentinelBtn = TextView(this).apply {
            text = "Open Sentinel"
            textSize = 12f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#94A3B8"))
            gravity = Gravity.CENTER
            setPadding(0, (10 * density).toInt(), 0, (4 * density).toInt())
            setOnClickListener { openFullApp() }
        }
        root.addView(openSentinelBtn)
    }

    private fun renderStateStandby(root: LinearLayout, density: Float) {
        if (isConfirmingTurnOff) {
            renderConfirmTurnOff(root, density)
            return
        }

        val statusRow = createStatusBadgeRow("PROTECTION ON", Color.parseColor("#10B981"), "Call detection active", density)
        root.addView(statusRow)

        val detailsCard = createCardView(density).apply {
            addView(TextView(this@FloatingGuardianService).apply {
                text = "STATUS DETAILS"
                textSize = 9.5f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(Color.parseColor("#38BDF8"))
            })
            addView(TextView(this@FloatingGuardianService).apply {
                text = "• Background service: Running\n• Permissions: Verified\n• Audio readiness: Armed for next call"
                textSize = 11f
                setTextColor(Color.parseColor("#E2E8F0"))
                setPadding(0, (4 * density).toInt(), 0, 0)
            })
        }
        root.addView(detailsCard)

        val actions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, (8 * density).toInt(), 0, 0)
        }

        val openAppBtn = TextView(this).apply {
            text = "Open App"
            textSize = 12f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding((10 * density).toInt(), (8 * density).toInt(), (10 * density).toInt(), (8 * density).toInt())
            val btnBg = GradientDrawable().apply {
                cornerRadius = 8f * density
                setColor(Color.parseColor("#0D9488"))
            }
            background = btnBg
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.2f)
            setOnClickListener { openFullApp() }
        }
        actions.addView(openAppBtn)

        val spacer = View(this).apply {
            layoutParams = LinearLayout.LayoutParams((8 * density).toInt(), 1)
        }
        actions.addView(spacer)

        val pauseBtn = TextView(this).apply {
            text = "Turn OFF"
            textSize = 12f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#CBD5E1"))
            gravity = Gravity.CENTER
            setPadding((8 * density).toInt(), (8 * density).toInt(), (8 * density).toInt(), (8 * density).toInt())
            val btnBg = GradientDrawable().apply {
                cornerRadius = 8f * density
                setColor(Color.parseColor("#334155"))
            }
            background = btnBg
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 0.9f)
            setOnClickListener {
                isConfirmingTurnOff = true
                rebuildOverlayView()
            }
        }
        actions.addView(pauseBtn)
        root.addView(actions)
    }

    private fun renderConfirmTurnOff(root: LinearLayout, density: Float) {
        val warningCard = createCardView(density).apply {
            addView(TextView(this@FloatingGuardianService).apply {
                text = "⚠️ Pause Sentinel Protection?"
                textSize = 12f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(Color.parseColor("#FCA5A5"))
            })
            addView(TextView(this@FloatingGuardianService).apply {
                text = "ScamShield will not monitor incoming calls until protection is re-enabled."
                textSize = 11f
                setTextColor(Color.parseColor("#E2E8F0"))
                setPadding(0, (4 * density).toInt(), 0, 0)
            })
        }
        root.addView(warningCard)

        val actions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(0, (8 * density).toInt(), 0, 0)
        }

        val keepActiveBtn = TextView(this).apply {
            text = "Keep Active"
            textSize = 12f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding((10 * density).toInt(), (8 * density).toInt(), (10 * density).toInt(), (8 * density).toInt())
            val btnBg = GradientDrawable().apply {
                cornerRadius = 8f * density
                setColor(Color.parseColor("#0D9488"))
            }
            background = btnBg
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1.2f)
            setOnClickListener {
                isConfirmingTurnOff = false
                rebuildOverlayView()
            }
        }
        actions.addView(keepActiveBtn)

        val spacer = View(this).apply {
            layoutParams = LinearLayout.LayoutParams((8 * density).toInt(), 1)
        }
        actions.addView(spacer)

        val confirmTurnOffBtn = TextView(this).apply {
            text = "Confirm OFF"
            textSize = 11.5f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#F87171"))
            gravity = Gravity.CENTER
            setPadding((8 * density).toInt(), (8 * density).toInt(), (8 * density).toInt(), (8 * density).toInt())
            val btnBg = GradientDrawable().apply {
                cornerRadius = 8f * density
                setColor(Color.parseColor("#450A0A"))
                setStroke((1 * density).toInt(), Color.parseColor("#DC2626"))
            }
            background = btnBg
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            setOnClickListener {
                disableProtection()
                isConfirmingTurnOff = false
                Toast.makeText(this@FloatingGuardianService, "Protection disabled", Toast.LENGTH_SHORT).show()
                rebuildOverlayView()
            }
        }
        actions.addView(confirmTurnOffBtn)
        root.addView(actions)
    }

    private fun renderStatePermissionRequired(root: LinearLayout, density: Float) {
        val statusRow = createStatusBadgeRow("PERMISSION NEEDED", Color.parseColor("#F59E0B"), "Access required", density)
        root.addView(statusRow)

        val missing = buildList {
            if (!hasPhonePermission()) add("• Phone State (to detect incoming calls)")
            if (!hasAudioPermission()) add("• Microphone (to analyze call speech)")
        }

        val card = createCardView(density).apply {
            addView(TextView(this@FloatingGuardianService).apply {
                text = "REQUIRED PERMISSIONS"
                textSize = 9.5f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(Color.parseColor("#F59E0B"))
            })
            addView(TextView(this@FloatingGuardianService).apply {
                text = missing.joinToString("\n")
                textSize = 11f
                setTextColor(Color.parseColor("#E2E8F0"))
                setPadding(0, (4 * density).toInt(), 0, 0)
            })
        }
        root.addView(card)

        val openSettingsBtn = createActionButton("Open Android Settings", Color.parseColor("#D97706"), density) {
            openAppPermissionSettings()
        }
        root.addView(openSettingsBtn)
    }

    private fun renderStateUnavailable(root: LinearLayout, density: Float) {
        val statusRow = createStatusBadgeRow("UNAVAILABLE", Color.parseColor("#EF4444"), "Service stopped", density)
        root.addView(statusRow)

        val card = createCardView(density).apply {
            addView(TextView(this@FloatingGuardianService).apply {
                text = "Protection is enabled, but the background monitoring service is currently unavailable."
                textSize = 11f
                setTextColor(Color.parseColor("#E2E8F0"))
            })
        }
        root.addView(card)

        val retryBtn = createActionButton("Retry Service Start", Color.parseColor("#0D9488"), density) {
            enableProtection()
            mainHandler.postDelayed({ rebuildOverlayView() }, 500)
        }
        root.addView(retryBtn)
    }

    private fun renderStateCallActive(root: LinearLayout, density: Float) {
        val statusRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, (8 * density).toInt(), 0, (6 * density).toInt())
        }

        val isSpeaker = CallAudioRouter.isSpeakerphoneActive(this)
        val statusPill = TextView(this).apply {
            textSize = 11f
            typeface = Typeface.DEFAULT_BOLD
            setPadding((8 * density).toInt(), (3 * density).toInt(), (8 * density).toInt(), (3 * density).toInt())
            val color = when (currentState) {
                STATE_CRITICAL -> Color.parseColor("#EF4444")
                STATE_SUSPICIOUS -> Color.parseColor("#F97316")
                STATE_MONITORING -> Color.parseColor("#10B981")
                else -> Color.parseColor("#F59E0B")
            }
            background = GradientDrawable().apply {
                cornerRadius = 8f * density
                setColor(color)
            }
            setTextColor(Color.WHITE)
            text = when (currentState) {
                STATE_CRITICAL -> if (currentScore != null) "CRITICAL • $currentScore%" else "CRITICAL"
                STATE_SUSPICIOUS -> if (currentScore != null) "HIGH RISK • $currentScore%" else "HIGH RISK"
                STATE_MONITORING -> "MONITORING CALL"
                else -> "CALL DETECTED"
            }
        }
        statusRow.addView(statusPill)

        val statusSubtitle = TextView(this).apply {
            textSize = 11.5f
            setTextColor(Color.parseColor("#94A3B8"))
            setPadding((8 * density).toInt(), 0, 0, 0)
            text = if (isSpeaker) "🔊 Speaker active" else "📞 Earpiece"
        }
        statusRow.addView(statusSubtitle)
        root.addView(statusRow)

        // Audio & Speakerphone Guidance Card
        val audioCard = createCardView(density).apply {
            addView(TextView(this@FloatingGuardianService).apply {
                text = "AUDIO ANALYSIS"
                textSize = 9.5f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(Color.parseColor("#38BDF8"))
            })
            addView(TextView(this@FloatingGuardianService).apply {
                text = if (!isSpeaker) {
                    "💡 Tip: Enable Speaker for better live call analysis."
                } else if (!currentSnippet.isNullOrBlank()) {
                    "\"$currentSnippet\""
                } else {
                    "Listening to call conversation for fraud patterns..."
                }
                textSize = 11f
                setTextColor(Color.parseColor("#E2E8F0"))
                setPadding(0, (3 * density).toInt(), 0, 0)
            })
        }
        root.addView(audioCard)

        // Threat Details (when present)
        if (currentState == STATE_CRITICAL || currentState == STATE_SUSPICIOUS) {
            val threatCard = createCardView(density).apply {
                val threatBg = GradientDrawable().apply {
                    cornerRadius = 8f * density
                    setColor(Color.parseColor("#450A0A"))
                    setStroke((1 * density).toInt(), Color.parseColor("#EF4444"))
                }
                background = threatBg
                addView(TextView(this@FloatingGuardianService).apply {
                    text = "🚨 ${currentCategory ?: "Potential Scam Detected"}"
                    textSize = 11f
                    typeface = Typeface.DEFAULT_BOLD
                    setTextColor(Color.parseColor("#FCA5A5"))
                })
            }
            root.addView(threatCard)
        }

        // Remote Access Apps check
        val remoteApps = getInstalledRemoteAccessAppNames()
        if (remoteApps.isNotEmpty()) {
            val alertCard = createCardView(density).apply {
                background = GradientDrawable().apply {
                    cornerRadius = 8f * density
                    setColor(Color.parseColor("#450A0A"))
                    setStroke((1 * density).toInt(), Color.parseColor("#EF4444"))
                }
                addView(TextView(this@FloatingGuardianService).apply {
                    text = "🚨 Warning: Remote app (${remoteApps.joinToString(", ")}) detected. Never share OTP or screen access."
                    textSize = 10.5f
                    typeface = Typeface.DEFAULT_BOLD
                    setTextColor(Color.parseColor("#FCA5A5"))
                })
            }
            root.addView(alertCard)
        }

        // Action Button: Open ScamShield
        val openAppBtn = createActionButton("Open ScamShield", Color.parseColor("#0D9488"), density) {
            openFullApp()
        }
        root.addView(openAppBtn)
    }

    private fun createStatusBadgeRow(badgeText: String, badgeColor: Int, subtitle: String, density: Float): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(0, (8 * density).toInt(), 0, (6 * density).toInt())

            val badge = TextView(this@FloatingGuardianService).apply {
                text = badgeText
                textSize = 11f
                typeface = Typeface.DEFAULT_BOLD
                setTextColor(Color.WHITE)
                setPadding((8 * density).toInt(), (3 * density).toInt(), (8 * density).toInt(), (3 * density).toInt())
                background = GradientDrawable().apply {
                    cornerRadius = 8f * density
                    setColor(badgeColor)
                }
            }
            addView(badge)

            val sub = TextView(this@FloatingGuardianService).apply {
                text = subtitle
                textSize = 11.5f
                setTextColor(Color.parseColor("#94A3B8"))
                setPadding((8 * density).toInt(), 0, 0, 0)
            }
            addView(sub)
        }
    }

    private fun createCardView(density: Float): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding((10 * density).toInt(), (8 * density).toInt(), (10 * density).toInt(), (8 * density).toInt())
            val cardBg = GradientDrawable().apply {
                cornerRadius = 10f * density
                setColor(Color.parseColor("#1E293B"))
                setStroke((1 * density).toInt(), Color.parseColor("#334155"))
            }
            background = cardBg
            val lp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                topMargin = (6 * density).toInt()
            }
            layoutParams = lp
        }
    }

    private fun createActionButton(label: String, color: Int, density: Float, onClick: () -> Unit): TextView {
        return TextView(this).apply {
            text = label
            textSize = 12.5f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding((12 * density).toInt(), (9 * density).toInt(), (12 * density).toInt(), (9 * density).toInt())
            background = GradientDrawable().apply {
                cornerRadius = 10f * density
                setColor(color)
            }
            val lp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT).apply {
                topMargin = (10 * density).toInt()
            }
            layoutParams = lp
            setOnClickListener { onClick() }
        }
    }

    private fun deriveActualState(): String {
        if (!isProtectionEnabled()) return STATE_DISABLED
        if (!hasPhonePermission() || !hasAudioPermission()) return STATE_PERMISSION_REQUIRED
        if (CallStateGuardianService.isRunning) {
            val callState = CallStateGuardianService.callState
            return when (callState) {
                "IN_CALL" -> if (currentState == STATE_CRITICAL || currentState == STATE_SUSPICIOUS) currentState else STATE_MONITORING
                "RINGING" -> STATE_CALL_DETECTED
                else -> currentState
            }
        }
        return STATE_UNAVAILABLE
    }

    private fun hasPhonePermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED

    private fun hasAudioPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED

    private fun isProtectionEnabled(): Boolean =
        getSharedPreferences(CallStateGuardianService.GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
            .getBoolean(CallStateGuardianService.KEY_GUARDIAN_ENABLED, false)

    private fun enableProtection(): Boolean {
        if (!hasPhonePermission()) return false
        val prefs = getSharedPreferences(CallStateGuardianService.GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(CallStateGuardianService.KEY_GUARDIAN_ENABLED, true)
            .putBoolean(CallStateGuardianService.KEY_AUDIO_PROTECTION_ENABLED, true)
            .apply()
        val intent = Intent(this, CallStateGuardianService::class.java).apply {
            action = CallStateGuardianService.ACTION_START
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
        return true
    }

    private fun disableProtection() {
        val prefs = getSharedPreferences(CallStateGuardianService.GUARDIAN_PREFERENCES, Context.MODE_PRIVATE)
        prefs.edit()
            .putBoolean(CallStateGuardianService.KEY_GUARDIAN_ENABLED, false)
            .putBoolean(CallStateGuardianService.KEY_AUDIO_PROTECTION_ENABLED, false)
            .apply()
        val intent = Intent(this, CallStateGuardianService::class.java).apply {
            action = CallStateGuardianService.ACTION_STOP
        }
        startService(intent)
    }

    private fun openAppPermissionSettings() {
        val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.fromParts("package", packageName, null)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }
        startActivity(intent)
    }

    private fun getInstalledRemoteAccessAppNames(): List<String> {
        val dangerousPackages = listOf(
            "com.anydesk.anydeskandroid" to "AnyDesk",
            "com.teamviewer.quicksupport.market" to "TeamViewer",
            "com.teamviewer.host.market" to "TeamViewer Host",
            "com.carriez.rustdesk" to "RustDesk",
            "com.sand.airdroid" to "AirDroid"
        )
        val installed = mutableListOf<String>()
        val pm = packageManager
        for ((pkg, name) in dangerousPackages) {
            try {
                pm.getPackageInfo(pkg, 0)
                installed.add(name)
            } catch (_: Exception) {}
        }
        return installed
    }

    private fun openFullApp() {
        val launchIntent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("action", "PROTECT_CALL")
            putExtra("source", "FLOATING_GUARDIAN")
            putExtra("state", currentState)
            if (currentScore != null) putExtra("riskScore", currentScore!!)
            if (currentCategory != null) putExtra("category", currentCategory)
        }
        startActivity(launchIntent)
    }

    private fun removeOverlay() {
        if (overlayRoot != null && windowManager != null) {
            try {
                windowManager?.removeView(overlayRoot)
            } catch (e: Exception) {
                Log.e(TAG, "Error removing floating overlay view", e)
            }
            overlayRoot = null
            isShowing = false
        }
    }
}
