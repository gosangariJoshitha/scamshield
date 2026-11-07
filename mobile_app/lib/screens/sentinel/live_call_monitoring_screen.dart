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
                      const SizedBox(height: 10),

                      // Speakerphone Requirement Advisory
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.16 : 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.volume_up_rounded, color: Color(0xFF0284C7), size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Speakerphone Required: Turn on speakerphone so incoming conversation can be analyzed in real-time.',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFBAE6FD) : const Color(0xFF0369A1),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

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

                      // 5. Critical Scam Detected Hero Alert (M9 Critical Risk Card)
                      if (result != null && (riskLevel == 'CRITICAL' || result.riskScore >= 80)) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7F1D1D).withValues(alpha: 0.95), // Deep Crimson Red
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFEF4444), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Text('🚨', style: TextStyle(fontSize: 24)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'CRITICAL SCAM DETECTED',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: Colors.white,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        Text(
                                          'RISK SCORE: ${result.riskScore}/100 • IMMEDIATE THREAT',
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFFECACA),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(color: Color(0xFF991B1B), height: 1),
                              const SizedBox(height: 12),
                              const Text(
                                'ScamShield detected high-risk signals:',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFEE2E2),
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...indicators.take(4).map(
                                (ind) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      const Text('🔴', style: TextStyle(fontSize: 11)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          ind.toUpperCase(),
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (result.reasoning.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                const Text(
                                  'WHY THIS IS RISKY:',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFFCA5A5),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  result.reasoning,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12.5,
                                    color: Colors.white,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: onEndCall ?? () {
                                  final sid = callEvent?.sessionId;
                                  if (sid != null && protectionService != null) {
                                    protectionService!.executeEndCall(sessionId: sid);
                                  }
                                },
                                icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 20),
                                label: const Text(
                                  'TERMINATE CALL NOW',
                                  style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  elevation: 6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                          content: Text('Sentinel live call shield is active.'),
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
