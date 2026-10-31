import 'package:flutter/material.dart';

import '../../models/analysis_record.dart';
import '../../models/user.dart';
import '../../native/call_bridge.dart';
import '../../services/analysis_service.dart';
import '../../theme/app_colors.dart';
import 'widgets/cyber_helpline_card.dart';
import 'widgets/overall_stats_card.dart';
import 'widgets/quick_actions_card.dart';
import 'widgets/recent_activity_section.dart';
import 'widgets/security_radar_hero.dart';
import 'widgets/sentinel_status_card.dart';
import 'widgets/stay_informed_card.dart';

/// Phase 03: ScamShield 2.0 Home Dashboard View
///
/// Implements the approved, premium fintech security layout depicted in
/// Screen 1 of the visual reference blueprint (home and analysis page.jpeg).
///
/// Features:
/// A. Personalized Greeting with real authenticated profile display name
/// B. Sentinel Protection Status Card (real CallGuardianStatus state)
/// C. Overall Stats 4-column card (genuine counts, zero mocks)
/// D. Quick Actions (4 verified shortcuts with tactile routing)
/// E. Recent Activity (persisted history records with risk tags + localized timestamps)
/// F. Stay Informed educational advisory card
/// G. Dual theme support (Light and Dark mode)
class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({
    required this.user,
    required this.dashboard,
    required this.loadingDashboard,
    required this.dashboardError,
    required this.guardianStatus,
    required this.onRefresh,
    required this.onOpenAnalyze,
    required this.onOpenGuardian,
    required this.onOpenHistory,
    required this.onOpenAnalysisResult,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onOpenProfile,
    required this.onOpenSettings,
    required this.onLogout,
    this.totalCallsAnalyzed = 0,
    super.key,
  });

  final User user;
  final DashboardData? dashboard;
  final bool loadingDashboard;
  final String? dashboardError;
  final CallGuardianStatus? guardianStatus;
  final int totalCallsAnalyzed;
  final Future<void> Function() onRefresh;
  final void Function(String type) onOpenAnalyze;
  final VoidCallback onOpenGuardian;
  final VoidCallback onOpenHistory;
  final void Function(AnalysisRecord record) onOpenAnalysisResult;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenSettings;
  final Future<void> Function() onLogout;

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  static String _greeting(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Welcome back 👋';
    final parts = trimmed.split(RegExp(r'\s+'));
    final firstName = parts.first;
    return 'Hello, $firstName 👋';
  }

  void _showSafetyTipsDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.lightbulb_outline_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Stay Informed'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _tipItem(
                'Verify urgent payment demands',
                'Scammers often use fake urgency. Always check bank accounts or bills through official apps.',
                isDark,
              ),
              const SizedBox(height: 12),
              _tipItem(
                'Beware of caller impersonation',
                'Law enforcement and banks will never request your OTP, PIN, or remote screen sharing.',
                isDark,
              ),
              const SizedBox(height: 12),
              _tipItem(
                'Scan QR codes and links carefully',
                'Inspect URLs for suspicious character substitutions before entering sensitive information.',
                isDark,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('GOT IT'),
          ),
        ],
      ),
    );
  }

  static Widget _tipItem(String title, String body, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          body,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    List<AnalysisRecord> allAnalyses = const [];
    try {
      allAnalyses = widget.dashboard?.effectiveAllAnalyses ?? const [];
    } catch (_) {
      try {
        allAnalyses = widget.dashboard?.recentAnalyses ?? const [];
      } catch (_) {
        allAnalyses = const [];
      }
    }
    final stats = widget.dashboard?.stats;

    // Truthful, real-data calculation across genuine records:
    int messagesCount =
        allAnalyses.where((r) => r.inputType == 'text' || r.inputType.isEmpty).length;
    if (messagesCount == 0 && stats != null && stats.totalAnalyses > 0 && allAnalyses.isEmpty) {
      messagesCount = stats.totalAnalyses;
    }
    final callsCount = widget.totalCallsAnalyzed;
    final imagesCount =
        allAnalyses.where((r) => r.inputType == 'image').length;
    final documentsCount = allAnalyses.where((r) =>
        r.inputType == 'document' ||
        r.inputType == 'file' ||
        r.inputType == 'pdf').length;

    final scamsDetected = stats?.scamsDetected ??
        allAnalyses.where((r) => r.classification.toUpperCase() == 'SCAM' || r.riskLevel.toUpperCase() == 'HIGH').length;
    final safeCount = stats?.safeMessages ??
        allAnalyses.where((r) => r.classification.toUpperCase() == 'SAFE' || r.riskLevel.toUpperCase() == 'LOW').length;
    final highRiskCount = stats?.highRisk ??
        allAnalyses.where((r) => r.riskLevel.toUpperCase() == 'HIGH').length;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      color: isDark ? AppColors.darkPrimary : AppColors.primary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Error Banner (if API request failed)
                  if (widget.dashboardError != null) ...[
                    _DashboardErrorBanner(
                      message: widget.dashboardError!,
                      onRetry: widget.onRefresh,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // SECTION A: Personalized Greeting
                  Text(
                    _greeting(widget.user.fullName),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: headlineColor,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Stay alert and stay safe with ScamShield.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // SECTION A.2: Security Radar & AI Defense Engine Hero Card
                  SecurityRadarHeroCard(
                    guardianStatus: widget.guardianStatus,
                    totalScans: stats?.totalAnalyses ?? allAnalyses.length,
                    scamsDetected: scamsDetected,
                    onOpenSentinel: widget.onOpenGuardian,
                  ),
                  const SizedBox(height: 16),

                  // SECTION B: Sentinel Protection Status Card
                  SentinelStatusCard(
                    status: widget.guardianStatus,
                    onOpenSentinel: widget.onOpenGuardian,
                  ),
                  const SizedBox(height: 16),

                  // SECTION C: Overall Stats 4-Column Card
                  OverallStatsCard(
                    messagesCount: messagesCount,
                    callsCount: callsCount,
                    imagesCount: imagesCount,
                    documentsCount: documentsCount,
                    scamsDetected: scamsDetected,
                    safeCount: safeCount,
                    highRiskCount: highRiskCount,
                    loading: widget.loadingDashboard && stats == null,
                  ),
                  const SizedBox(height: 16),

                  // SECTION D: Quick Actions
                  QuickActionsCard(
                    onAnalyzeMessage: () => widget.onOpenAnalyze('text'),
                    onCallProtection: widget.onOpenGuardian,
                    onImageDocument: () => widget.onOpenAnalyze('image'),
                    onAnalyzeAudio: () => widget.onOpenAnalyze('audio'),
                  ),
                  const SizedBox(height: 16),

                  // SECTION D.2: National Cybercrime Helpline (1930) Emergency Card
                  const CyberHelplineCard(),
                  const SizedBox(height: 16),

                  // SECTION E: Recent Activity
                  RecentActivitySection(
                    recentAnalyses: () {
                      try {
                        return widget.dashboard?.recentAnalyses ?? const <AnalysisRecord>[];
                      } catch (_) {
                        return const <AnalysisRecord>[];
                      }
                    }(),
                    onViewAll: widget.onOpenHistory,
                    onOpenRecord: widget.onOpenAnalysisResult,
                    onAnalyzeFirst: () => widget.onOpenAnalyze('text'),
                    loading: widget.loadingDashboard && widget.dashboard == null,
                  ),
                  const SizedBox(height: 16),

                  // SECTION F: Stay Informed
                  StayInformedCard(
                    onTap: () => _showSafetyTipsDialog(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorBanner extends StatelessWidget {
  const _DashboardErrorBanner({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: Color(0xFFEF4444),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('RETRY'),
          ),
        ],
      ),
    );
  }
}
