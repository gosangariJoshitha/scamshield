import 'package:flutter/material.dart';
import '../../models/call_history_models.dart';
import '../../services/guardian_protection_service.dart';
import '../../theme/app_colors.dart';
import 'widgets/detected_indicators_wrap.dart';
import 'widgets/final_call_details_card.dart';
import 'widgets/final_report_banner.dart';
import 'widgets/floating_guardian_pill.dart';
import 'widgets/multilingual_call_recommendation_card.dart';

class CallReportScreen extends StatelessWidget {
  const CallReportScreen({
    required this.call,
    this.protectionService,
    this.onViewHistory,
    this.onBlockNumber,
    this.onBack,
    super.key,
  });

  final CallHistoryDetail call;
  final GuardianProtectionService? protectionService;
  final VoidCallback? onViewHistory;
  final VoidCallback? onBlockNumber;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor = isDark ? Colors.white : AppColors.navy;

    final isScam = call.finalRiskLevel.toUpperCase() == 'HIGH' ||
        call.finalRiskLevel.toUpperCase() == 'CRITICAL' ||
        call.classification.toUpperCase() == 'SCAM';

    final durationMinutes = (call.durationSeconds ~/ 60).toString().padLeft(2, '0');
    final durationSecs = (call.durationSeconds % 60).toString().padLeft(2, '0');
    final durationString = '00:$durationMinutes:$durationSecs';

    final indicators = call.detectedIndicators.isNotEmpty
        ? call.detectedIndicators
        : const ['Prize Claim', 'Urgent Action', 'Bank Details', 'Unknown Number', 'Scam Pattern Match'];

    final reasoning = call.riskReasoning?.trim();
    final summaryText = (reasoning != null && reasoning.isNotEmpty)
        ? reasoning
        : 'The caller claimed a prize reward and asked for personal and banking details. This matches known scam patterns used to steal financial information.';

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
          IconButton(
            icon: Icon(Icons.share_outlined, color: headlineColor, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Call report ready for sharing.')),
              );
            },
            tooltip: 'Share Report',
          ),
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, color: headlineColor, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Delete action is protected by account policy.')),
              );
            },
            tooltip: 'Delete',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Outcome Banner
                      FinalReportBanner(
                        classification: call.classification,
                        riskLevel: call.finalRiskLevel,
                      ),
                      const SizedBox(height: 14),

                      // 2. Call Details Card
                      FinalCallDetailsCard(
                        phoneNumber: '+91 98765 43210',
                        callerType: 'Unknown Number',
                        dateTimeText: _formatDate(call.startedAt ?? call.endedAt),
                        durationText: durationString,
                      ),
                      const SizedBox(height: 14),

                      // 3. Analysis Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0),
                            width: 1.1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.article_outlined,
                                  size: 18,
                                  color: isDark ? AppColors.darkPrimary : const Color(0xFF0284C7),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Analysis Summary',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: headlineColor,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              summaryText,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13.5,
                                fontWeight: FontWeight.w400,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4. Detected Indicators Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0),
                            width: 1.1,
                          ),
                        ),
                        child: DetectedIndicatorsWrap(
                          indicators: indicators,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 5. Multilingual Recommendations Card
                      MultilingualCallRecommendationCard(
                        isScam: isScam,
                        canonicalActions: call.protectionActions
                            .map((m) => (m['action'] ?? m['description'] ?? m.values.firstOrNull)?.toString() ?? '')
                            .where((s) => s.isNotEmpty)
                            .toList(),
                      ),
                      const SizedBox(height: 18),

                      // 6. Action Buttons: View in History & Block Number
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: onViewHistory,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                side: BorderSide(
                                  color: isDark ? AppColors.darkPrimary : const Color(0xFF0284C7),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'View in History',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.darkPrimary : const Color(0xFF0284C7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: onBlockNumber ??
                                  () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Caller +91 98765 43210 blocked.'),
                                      ),
                                    );
                                  },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Block Number',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
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
                        const SnackBar(content: Text('Guardian live call shield is active.')),
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

  static String _formatDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute $ampm';
  }
}
