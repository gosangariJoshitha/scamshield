import 'package:flutter/material.dart';
import '../../models/guardian_analysis_models.dart';
import '../../native/call_bridge.dart';
import '../../services/guardian_protection_service.dart';
import '../../services/guardian_transcription_service.dart';
import '../../theme/app_colors.dart';
import 'widgets/detected_indicators_wrap.dart';
import 'widgets/floating_guardian_pill.dart';
import 'widgets/live_call_header_card.dart';
import 'widgets/live_call_timeline_card.dart';
import 'widgets/live_transcription_view.dart';

class LiveCallMonitoringScreen extends StatelessWidget {
  const LiveCallMonitoringScreen({
    required this.callEvent,
    required this.activeCallSeconds,
    this.analysisSnapshot,
    this.segments = const [],
    this.protectionService,
    this.onAnswer,
    this.onDecline,
    this.onEndCall,
    this.onBack,
    super.key,
  });

  final GuardianCallEvent? callEvent;
  final int activeCallSeconds;
  final GuardianLiveAnalysisSnapshot? analysisSnapshot;
  final List<TranscriptSegment> segments;
  final GuardianProtectionService? protectionService;
  final VoidCallback? onAnswer;
  final VoidCallback? onDecline;
  final VoidCallback? onEndCall;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor = isDark ? Colors.white : AppColors.navy;

    final result = analysisSnapshot?.result;
    final riskLevel = result?.riskLevel ?? 'HIGH';
    final isScam = riskLevel == 'HIGH' || riskLevel == 'CRITICAL';
    final indicators = result?.detectedIndicators ??
        const ['Prize Claim', 'Bank Details', 'Urgent Action', 'Unknown Number', 'Scam Pattern Match'];

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: headlineColor),
          onPressed: onBack ?? () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Sentinel',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18.5,
            fontWeight: FontWeight.w700,
            color: headlineColor,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Live Call Monitoring',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Incoming / Active Call Card
                      LiveCallHeaderCard(
                        callEvent: callEvent,
                        riskLevel: riskLevel,
                        warningLabel: isScam ? 'Potential Scam' : 'Analyzing Call…',
                        onAnswer: onAnswer,
                        onDecline: onDecline,
                        onEndCall: onEndCall,
                      ),
                      const SizedBox(height: 14),

                      // 2. Real-Time Timeline Card
                      LiveCallTimelineCard(
                        elapsedSeconds: activeCallSeconds > 0 ? activeCallSeconds : 8,
                        currentStep: 3, // Analyzing with AI
                      ),
                      const SizedBox(height: 14),

                      // 3. Live Transcription Card (You / Caller)
                      LiveTranscriptionView(
                        userText: 'Hello, who is this?',
                        callerText: 'You have won a prize of ₹50,000. Please share your bank details to claim it.',
                        segments: segments,
                        isScamAlert: isScam,
                      ),
                      const SizedBox(height: 14),

                      // 4. Detected Indicators Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: DetectedIndicatorsWrap(
                          indicators: indicators,
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Guardian button in bottom right
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingGuardianPill(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Guardian live call shield is active.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
