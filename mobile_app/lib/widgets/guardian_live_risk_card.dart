import 'package:flutter/material.dart';

import '../models/guardian_analysis_models.dart';
import '../services/guardian_local_heuristic_engine.dart';
import '../services/guardian_protection_service.dart';
import '../services/guardian_transcription_service.dart';
import 'guardian_protection_panel.dart';

class GuardianRiskMeter extends StatelessWidget {
  const GuardianRiskMeter({
    super.key,
    required this.score,
    required this.level,
  });

  final int score;
  final String level;

  static const Color lowColor = Color(0xFF2E7D32);
  static const Color mediumColor = Color(0xFFF57C00);
  static const Color highColor = Color(0xFFE65100);
  static const Color criticalColor = Color(0xFFD32F2F);

  Color _tierColor(String tier) {
    switch (tier.toUpperCase()) {
      case 'CRITICAL':
        return criticalColor;
      case 'HIGH':
        return highColor;
      case 'MEDIUM':
        return mediumColor;
      case 'LOW':
      default:
        return lowColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalizedScore = score.clamp(0, 100);
    final currentTierColor = _tierColor(level);

    return Semantics(
      label: 'Risk meter showing $normalizedScore out of 100, $level risk tier',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Segmented Bar with Needle Marker
          LayoutBuilder(
            builder: (context, constraints) {
              final totalWidth = constraints.maxWidth;
              final needleX = (normalizedScore / 100.0) * totalWidth;

              return Column(
                children: [
                  // Animated Needle / Indicator
                  SizedBox(
                    height: 14,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: needleX, end: needleX),
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Positioned(
                              left: (value - 6).clamp(0.0, totalWidth - 12),
                              top: 0,
                              child: Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 16,
                                color: currentTierColor,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // 4 Segment Bars
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 8,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 30, // 0 - 29 (LOW)
                            child: Container(color: lowColor),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: 30, // 30 - 59 (MEDIUM)
                            child: Container(color: mediumColor),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: 20, // 60 - 79 (HIGH)
                            child: Container(color: highColor),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            flex: 20, // 80 - 100 (CRITICAL)
                            child: Container(color: criticalColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),

          // Tier Range Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTierLabel('LOW', '0–29', level == 'LOW', lowColor, theme),
              _buildTierLabel('MEDIUM', '30–59', level == 'MEDIUM', mediumColor, theme),
              _buildTierLabel('HIGH', '60–79', level == 'HIGH', highColor, theme),
              _buildTierLabel('CRITICAL', '80–100', level == 'CRITICAL', criticalColor, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTierLabel(
    String name,
    String range,
    bool isActive,
    Color color,
    ThemeData theme,
  ) {
    return Column(
      children: [
        Text(
          name,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
            color: isActive ? color : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
        Text(
          range,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}

class GuardianLiveRiskCard extends StatefulWidget {
  const GuardianLiveRiskCard({
    super.key,
    required this.snapshot,
    this.isCallActive = false,
    this.transcriptSegments,
    this.onRetryAnalysis,
    this.onDismissCallEnded,
    this.protectionService,
    this.callerNumber,
  });

  final GuardianLiveAnalysisSnapshot? snapshot;
  final bool isCallActive;
  final List<TranscriptSegment>? transcriptSegments;
  final VoidCallback? onRetryAnalysis;
  final VoidCallback? onDismissCallEnded;
  final GuardianProtectionService? protectionService;
  final String? callerNumber;

  @override
  State<GuardianLiveRiskCard> createState() => _GuardianLiveRiskCardState();
}

class _GuardianLiveRiskCardState extends State<GuardianLiveRiskCard> {
  bool _expandedIndicators = false;
  bool _expandedReasoning = false;
  bool _expandedEvidence = false;
  int _previousScore = 0;

  @override
  void initState() {
    super.initState();
    _previousScore = widget.snapshot?.result?.riskScore ?? 0;
  }

  @override
  void didUpdateWidget(covariant GuardianLiveRiskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldResult = oldWidget.snapshot?.result;
    final newResult = widget.snapshot?.result;
    if (oldResult != null && newResult != null && oldResult.riskScore != newResult.riskScore) {
      _previousScore = oldResult.riskScore;
    }
  }

  Color _riskColor(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFD32F2F);
      case 'HIGH':
        return const Color(0xFFE65100);
      case 'MEDIUM':
        return const Color(0xFFF57C00);
      case 'LOW':
      default:
        return const Color(0xFF2E7D32);
    }
  }

  Color _riskBackgroundColor(String level, bool isDark) {
    switch (level.toUpperCase()) {
      case 'CRITICAL':
        return isDark ? const Color(0xFF381212) : const Color(0xFFFFEBEE);
      case 'HIGH':
        return isDark ? const Color(0xFF3D1B0A) : const Color(0xFFFFF3E0);
      case 'MEDIUM':
        return isDark ? const Color(0xFF382305) : const Color(0xFFFFF8E1);
      case 'LOW':
      default:
        return isDark ? const Color(0xFF0F2E1B) : const Color(0xFFE8F5E9);
    }
  }

  String _warningHeadline(String level, String category) {
    switch (level.toUpperCase()) {
      case 'CRITICAL':
        return 'High-risk scam indicators detected.';
      case 'HIGH':
        return 'Suspicious conversation detected.';
      case 'MEDIUM':
        return 'Potentially suspicious conversation detected.';
      case 'LOW':
      default:
        return 'No significant scam indicators detected.';
    }
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final s = local.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _resolveSafeAction(GuardianLiveAnalysisResult result) {
    final lang = result.language;
    final actionsMap = result.safeActions;
    if (actionsMap != null && lang != 'en') {
      final translations = actionsMap['translations'];
      if (translations is Map) {
        final list = translations[lang];
        if (list is List && list.isNotEmpty) {
          final joined = list.whereType<String>().join('\n');
          if (joined.isNotEmpty) return joined;
        }
      }
    }
    if (result.safeAction.isNotEmpty) {
      return result.safeAction;
    }
    return 'Verify the caller independently through official public contacts before sharing any information.';
  }

  Widget _buildNetworkStatusBadge(
    GuardianNetworkStatus status,
    ThemeData theme,
    ColorScheme colors,
  ) {
    IconData icon;
    String label;
    Color badgeColor;

    switch (status) {
      case GuardianNetworkStatus.noNetwork:
        icon = Icons.wifi_off_rounded;
        label = 'No Internet';
        badgeColor = colors.error;
        break;
      case GuardianNetworkStatus.backendUnreachable:
        icon = Icons.cloud_off_rounded;
        label = 'Backend Unreachable';
        badgeColor = const Color(0xFFE65100);
        break;
      case GuardianNetworkStatus.analysisFailed:
        icon = Icons.error_outline_rounded;
        label = 'Analysis Failed';
        badgeColor = colors.error;
        break;
      case GuardianNetworkStatus.online:
        icon = Icons.cloud_done_rounded;
        label = 'Online';
        badgeColor = const Color(0xFF2E7D32);
        break;
      case GuardianNetworkStatus.unknown:
        icon = Icons.help_outline_rounded;
        label = 'Checking';
        badgeColor = colors.onSurfaceVariant;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: badgeColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalHeuristicSection({
    required GuardianLocalHeuristicResult? heuristic,
    required ThemeData theme,
    required ColorScheme colors,
    required bool isDark,
  }) {
    if (heuristic == null) return const SizedBox.shrink();

    final hasMatches = heuristic.hasMatches;
    final alertColor =
        hasMatches ? const Color(0xFFD32F2F) : colors.outlineVariant;
    final bgColor = hasMatches
        ? (isDark ? const Color(0xFF381212) : const Color(0xFFFFEBEE))
        : (isDark
            ? const Color(0xFF1E1E1E)
            : colors.surfaceContainerHighest.withValues(alpha: 0.4));

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: alertColor.withValues(alpha: hasMatches ? 0.6 : 0.4),
          width: hasMatches ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasMatches
                    ? Icons.warning_amber_rounded
                    : Icons.info_outline_rounded,
                size: 16,
                color: hasMatches ? alertColor : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                'LOCAL HEURISTIC — OFFLINE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: hasMatches ? alertColor : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (hasMatches) ...[
            Text(
              heuristic.warningHeadline,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: alertColor,
              ),
            ),
            if (heuristic.matchedPhrases.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: heuristic.matchedPhrases.map((phrase) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: alertColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '"$phrase"',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: alertColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: alertColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      heuristic.safeAction,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Local heuristic evaluation on device. Does not include AI reasoning or RAG verification.',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ] else ...[
            Text(
              GuardianLocalHeuristicResult.noMatchNotice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Full AI analysis requires backend connectivity.',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final snapshot = widget.snapshot;
    final state = snapshot?.state ?? 'AI_IDLE';
    final result = snapshot?.result;
    final isAnalyzing = snapshot?.isAnalyzing ?? false;
    final isCallEnded = snapshot?.isCallEnded == true || state == 'CALL_ENDED';

    // 1. Idle State
    if (state == 'AI_IDLE' && result == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colors.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.shield_outlined, size: 20, color: colors.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Live AI analysis ready. Will analyze conversation once supported speech is transcribed.',
                style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      );
    }

    // 2. Waiting or Analyzing State (before first result)
    if (result == null && (state == 'AI_WAITING_FOR_TRANSCRIPT' || state == 'AI_ANALYZING')) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    state == 'AI_ANALYZING'
                        ? 'Analyzing conversation…'
                        : 'Listening for conversation',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'MONITORING',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              snapshot?.message ??
                  'Listening for conversation to analyze for suspicious patterns…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    // 3. Unavailable or Error State (when no previous result exists)
    if (result == null && (state == 'AI_UNAVAILABLE' || state == 'AI_ERROR')) {
      final netStatus =
          snapshot?.networkStatus ?? GuardianNetworkStatus.unknown;
      final title = netStatus == GuardianNetworkStatus.noNetwork
          ? 'Offline — No Internet Connection'
          : netStatus == GuardianNetworkStatus.backendUnreachable
              ? 'Offline — Backend Unreachable'
              : 'Live AI Analysis Unavailable';

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.errorContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.error.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  netStatus == GuardianNetworkStatus.noNetwork
                      ? Icons.wifi_off_rounded
                      : netStatus == GuardianNetworkStatus.backendUnreachable
                          ? Icons.cloud_off_rounded
                          : Icons.info_outline,
                  size: 20,
                  color: colors.error,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.error,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        snapshot?.message ??
                            'Live AI analysis is temporarily unavailable. Full AI reasoning requires backend connectivity.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      if (snapshot?.queuedCount != null &&
                          snapshot!.queuedCount > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${snapshot.queuedCount} analysis request(s) queued for reconnection.',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                _buildNetworkStatusBadge(netStatus, theme, colors),
              ],
            ),
            if (snapshot?.localHeuristicResult != null) ...[
              _buildLocalHeuristicSection(
                heuristic: snapshot!.localHeuristicResult,
                theme: theme,
                colors: colors,
                isDark: isDark,
              ),
            ],
            if (widget.onRetryAnalysis != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onRetryAnalysis,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry analysis'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    // 4. Live Risk Result Card (Active Call or Call Ended Final Snapshot)
    final riskColor = _riskColor(result!.riskLevel);
    final riskBg = _riskBackgroundColor(result.riskLevel, isDark);
    final isMeaningfulRisk = result.riskLevel == 'MEDIUM' ||
        result.riskLevel == 'HIGH' ||
        result.riskLevel == 'CRITICAL';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: riskBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withValues(alpha: 0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: riskColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isCallEnded ? 'Final Risk Assessment' : 'Risk Assessment',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                if ((state == 'AI_UNAVAILABLE' ||
                        state == 'AI_ERROR' ||
                        snapshot?.networkStatus ==
                            GuardianNetworkStatus.noNetwork ||
                        snapshot?.networkStatus ==
                            GuardianNetworkStatus.backendUnreachable) &&
                    !isCallEnded) ...[
                  Icon(
                    snapshot?.networkStatus == GuardianNetworkStatus.noNetwork
                        ? Icons.wifi_off_rounded
                        : Icons.cloud_off_rounded,
                    size: 13,
                    color: colors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Updates paused',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (snapshot?.queuedCount != null &&
                      snapshot!.queuedCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${snapshot.queuedCount} queued)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  if (widget.onRetryAnalysis != null) ...[
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: widget.onRetryAnalysis,
                      child: Text(
                        'Retry',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                ] else if (isAnalyzing && !isCallEnded) ...[
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(riskColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Updating',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: riskColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    result.scamCategory,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Risk Score Display with Animated Counter
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${result.riskLevel} RISK',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: riskColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      result.classification == 'SCAM'
                          ? 'Suspicious activity detected'
                          : result.classification == 'SUSPICIOUS'
                              ? 'Caution recommended'
                              : 'Normal conversation',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Semantics(
                  label: 'Risk score ${result.riskScore} out of 100',
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: _previousScore.toDouble(),
                      end: result.riskScore.toDouble(),
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '${value.round()}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: riskColor,
                            ),
                          ),
                          Text(
                            ' / 100',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Visual Risk Meter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: GuardianRiskMeter(
              score: result.riskScore,
              level: result.riskLevel,
            ),
          ),
          const SizedBox(height: 12),
          if ((state == 'AI_UNAVAILABLE' ||
                  state == 'AI_ERROR' ||
                  snapshot?.networkStatus == GuardianNetworkStatus.noNetwork ||
                  snapshot?.networkStatus ==
                      GuardianNetworkStatus.backendUnreachable) &&
              !isCallEnded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.errorContainer.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: colors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      snapshot?.networkStatus == GuardianNetworkStatus.noNetwork
                          ? Icons.wifi_off_rounded
                          : Icons.info_outline,
                      size: 14,
                      color: colors.error,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        snapshot?.networkStatus ==
                                GuardianNetworkStatus.noNetwork
                            ? 'Offline (no internet). Showing last confirmed assessment (potentially stale).'
                            : snapshot?.networkStatus ==
                                    GuardianNetworkStatus.backendUnreachable
                                ? 'Backend unreachable. Showing last confirmed assessment (potentially stale).'
                                : 'Live updates temporarily paused. Showing last confirmed assessment.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.error,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (snapshot?.localHeuristicResult != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _buildLocalHeuristicSection(
                  heuristic: snapshot!.localHeuristicResult,
                  theme: theme,
                  colors: colors,
                  isDark: isDark,
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],

          // Live Warning Card (for MEDIUM, HIGH, CRITICAL)
          if (isMeaningfulRisk) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      result.riskLevel == 'CRITICAL'
                          ? Icons.gpp_bad_rounded
                          : Icons.warning_amber_rounded,
                      size: 20,
                      color: riskColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _warningHeadline(result.riskLevel, result.scamCategory),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: riskColor,
                            ),
                          ),
                          if (result.classification == 'SCAM') ...[
                            const SizedBox(height: 2),
                            Text(
                              'High-risk scam patterns identified in active conversation.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Detected Indicators with Expand/Collapse Chips
          if (result.detectedIndicators.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Detected indicators',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 5,
                    children: [
                      ..._buildIndicatorChips(result.detectedIndicators, riskColor, colors, theme),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],

          // Why This Result? (Concise Explanation + Read More)
          if (result.reasoning.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why?',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      result.reasoning,
                      maxLines: _expandedReasoning || result.reasoning.length < 120 ? null : 2,
                      overflow: _expandedReasoning || result.reasoning.length < 120
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                  ),
                  if (result.reasoning.length >= 120) ...[
                    const SizedBox(height: 2),
                    GestureDetector(
                      onTap: () => setState(() => _expandedReasoning = !_expandedReasoning),
                      child: Text(
                        _expandedReasoning ? 'Show less' : 'Read more >',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: riskColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],

          // Supporting Evidence Summary with Expandable Previews
          if (result.supportingEvidence.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Supporting evidence',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _expandedEvidence = !_expandedEvidence),
                        child: Text(
                          _expandedEvidence ? 'Collapse' : 'Details >',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${result.supportingEvidence.length} relevant scam pattern(s) identified in knowledge base',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final ev in result.supportingEvidence.take(_expandedEvidence ? 5 : 2)) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.pattern_rounded, size: 14, color: riskColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  ev.title.isNotEmpty ? ev.title : ev.category,
                                  maxLines: _expandedEvidence ? 2 : 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: riskColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${(ev.similarityScore * 100).round()}% match',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: riskColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_expandedEvidence && (ev.description.isNotEmpty || ev.source.isNotEmpty)) ...[
                            const SizedBox(height: 4),
                            if (ev.description.isNotEmpty)
                              Text(
                                ev.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            if (ev.source.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                'Source: ${ev.source}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Supporting evidence',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    result.evidenceStatus == 'RETRIEVAL_UNAVAILABLE'
                        ? 'Advisory evidence retrieval is temporarily unavailable.'
                        : isMeaningfulRisk
                            ? 'No direct fraud advisory match found; assessment based on conversational and linguistic patterns.'
                            : 'No known scam pattern matches found in current advisory knowledge base.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ],

          // Live Transcript Preview (if segments provided)
          if (widget.transcriptSegments != null && widget.transcriptSegments!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.subtitles_outlined, size: 13, color: colors.onSurfaceVariant),
                        const SizedBox(width: 5),
                        Text(
                          'Live transcript preview',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    for (final seg in widget.transcriptSegments!.reversed.take(2).toList().reversed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '"${seg.text}"',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],

          // Analysis Verification & Timestamp
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
            child: Row(
              children: [
                Icon(
                  result.processingStatus == 'COMPLETED_WITH_LIMITATIONS'
                      ? Icons.info_outline
                      : Icons.check_circle_outline,
                  size: 13,
                  color: colors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    result.processingStatus == 'COMPLETED_WITH_LIMITATIONS'
                        ? 'Basic analysis (AI reasoning limited) · ${_formatTime(result.timestamp)}'
                        : 'AI verified (${result.modelVersion.isNotEmpty ? result.modelVersion : 'v5'}) · ${_formatTime(result.timestamp)}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant.withValues(alpha: 0.75),
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Recommended Safe Guidance ("What you should do")
          if (result.safeAction.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.65),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.security_rounded,
                    size: 16,
                    color: riskColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What you should do',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: riskColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _resolveSafeAction(result),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colors.onSurface,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Protection Actions Panel (M9.8)
          if (widget.protectionService != null && !isCallEnded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: GuardianProtectionPanel(
                result: result,
                protectionService: widget.protectionService!,
                isCallActive: widget.isCallActive,
                callerNumber: widget.callerNumber,
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Call Ended Dismissal Action
          if (isCallEnded && widget.onDismissCallEnded != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: widget.onDismissCallEnded,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Dismiss call risk'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildIndicatorChips(
    List<String> indicators,
    Color riskColor,
    ColorScheme colors,
    ThemeData theme,
  ) {
    final displayList = _expandedIndicators ? indicators : indicators.take(3).toList();
    final hasOverflow = !_expandedIndicators && indicators.length > 3;

    final chips = <Widget>[];
    for (final indicator in displayList) {
      chips.add(
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: riskColor.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            indicator,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (hasOverflow) {
      chips.add(
        InkWell(
          onTap: () => setState(() => _expandedIndicators = true),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: riskColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '+${indicators.length - 3} more',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: riskColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: riskColor),
              ],
            ),
          ),
        ),
      );
    } else if (_expandedIndicators && indicators.length > 3) {
      chips.add(
        InkWell(
          onTap: () => setState(() => _expandedIndicators = false),
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Show less',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: colors.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
    }

    return chips;
  }
}
