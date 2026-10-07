import 'package:flutter/material.dart';

import '../../models/call_history_models.dart';

class CallSummaryScreen extends StatefulWidget {
  const CallSummaryScreen({
    required this.call,
    this.onBack,
    super.key,
  });

  final CallHistoryDetail call;
  final VoidCallback? onBack;

  @override
  State<CallSummaryScreen> createState() => _CallSummaryScreenState();
}

class _CallSummaryScreenState extends State<CallSummaryScreen> {
  bool _expandedReasoning = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final call = widget.call;
    final riskColor = call.riskColor(colors);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Summary'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            _buildRiskHeader(context, call, colors, riskColor),
            const SizedBox(height: 18),
            if (call.analysisStatus == 'AUDIO_UNAVAILABLE' ||
                call.audioStatus == 'AUDIO_UNAVAILABLE')
              _buildUnavailableNotice(
                context,
                title: 'Audio analysis unavailable',
                description:
                    'Guardian detected the call, but supported call audio was unavailable. No AI risk assessment was generated.',
                icon: Icons.mic_off_outlined,
                color: colors.onSurfaceVariant,
              )
            else if (call.transcriptionStatus == 'TRANSCRIPTION_UNAVAILABLE')
              _buildUnavailableNotice(
                context,
                title: 'Transcription unavailable',
                description:
                    'The call was protected, but speech-to-text could not be completed. No transcript-based risk assessment was generated.',
                icon: Icons.closed_caption_disabled_outlined,
                color: colors.onSurfaceVariant,
              )
            else if (call.analysisStatus == 'ANALYSIS_UNAVAILABLE')
              _buildUnavailableNotice(
                context,
                title: 'Analysis unavailable',
                description:
                    'ScamShield could not complete AI analysis for this call.',
                icon: Icons.info_outline,
                color: colors.onSurfaceVariant,
              ),
            if (call.riskReasoning != null && call.riskReasoning!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildWhyThisResultSection(context, call, colors),
            ],
            if (call.detectedIndicators.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildIndicatorsSection(context, call, colors),
            ],
            if (call.supportingEvidence.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSupportingEvidenceSection(context, call, colors),
            ],
            const SizedBox(height: 16),
            _buildProtectionActionsSection(context, call, colors),
            if (call.safeAction != null && call.safeAction!.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildSafeActionSection(context, call, colors),
            ],
            const SizedBox(height: 16),
            _buildCallDetailsSection(context, call, colors),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskHeader(
    BuildContext context,
    CallHistoryDetail call,
    ColorScheme colors,
    Color riskColor,
  ) {
    final isUnavailable = call.analysisStatus == 'AUDIO_UNAVAILABLE' ||
        call.analysisStatus == 'ANALYSIS_UNAVAILABLE' ||
        call.audioStatus == 'AUDIO_UNAVAILABLE';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnavailable
              ? colors.outlineVariant
              : riskColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isUnavailable ? colors.shadow : riskColor).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                label: isUnavailable
                    ? 'Status: Unavailable'
                    : '${call.finalRiskLevel} RISK — ${call.finalRiskScore} out of 100',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isUnavailable
                        ? colors.surfaceContainerHighest
                        : riskColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    isUnavailable ? 'PROTECTED CALL' : '${call.finalRiskLevel} RISK',
                    style: TextStyle(
                      color: isUnavailable ? colors.onSurfaceVariant : riskColor,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              if (!isUnavailable)
                Text(
                  '${call.finalRiskScore} / 100',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: riskColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            call.scamCategory.isNotEmpty ? call.scamCategory : 'Unknown Caller',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.schedule_rounded, size: 16, color: colors.onSurfaceVariant),
              const SizedBox(width: 5),
              Text(
                '${call.formattedDuration}  •  ${call.formattedEndedAt()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableNotice(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWhyThisResultSection(
    BuildContext context,
    CallHistoryDetail call,
    ColorScheme colors,
  ) {
    final text = call.riskReasoning!.trim();
    final isLong = text.length > 200;
    final displayText = isLong && !_expandedReasoning
        ? '${text.substring(0, 197)}...'
        : text;

    return _SectionCard(
      title: 'Why this result?',
      icon: Icons.psychology_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: colors.onSurface,
                ),
          ),
          if (isLong)
            InkWell(
              onTap: () => setState(() => _expandedReasoning = !_expandedReasoning),
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _expandedReasoning ? 'Read less' : 'Read more',
                  style: TextStyle(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIndicatorsSection(
    BuildContext context,
    CallHistoryDetail call,
    ColorScheme colors,
  ) {
    return _SectionCard(
      title: 'Detected indicators',
      icon: Icons.checklist_rounded,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: call.detectedIndicators.map((indicator) {
          return Chip(
            visualDensity: VisualDensity.compact,
            label: Text(indicator),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.onSurfaceVariant,
            ),
            backgroundColor: colors.surfaceContainerHighest.withValues(alpha: 0.6),
            side: BorderSide(color: colors.outlineVariant),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSupportingEvidenceSection(
    BuildContext context,
    CallHistoryDetail call,
    ColorScheme colors,
  ) {
    return _SectionCard(
      title: 'Supporting evidence',
      icon: Icons.menu_book_outlined,
      child: Column(
        children: call.supportingEvidence.map((evidence) {
          final title = evidence['title']?.toString() ??
              evidence['category']?.toString() ??
              'Scam pattern';
          final relevance = evidence['relevance']?.toString() ??
              evidence['similarity']?.toString() ??
              'Matching pattern';
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              children: [
                Icon(Icons.shield_outlined, size: 18, color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      Text(
                        relevance,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProtectionActionsSection(
    BuildContext context,
    CallHistoryDetail call,
    ColorScheme colors,
  ) {
    if (call.protectionActions.isEmpty) {
      return _SectionCard(
        title: 'Protection outcome',
        icon: Icons.health_and_safety_outlined,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 18,
                color: Color(0xFF14804A),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  call.finalRiskLevel == 'LOW'
                      ? 'Call analyzed safely with no scam intervention required'
                      : 'Live scam warning and safety guidance provided to user',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _SectionCard(
      title: 'Protection actions',
      icon: Icons.health_and_safety_outlined,
      child: Column(
        children: call.protectionActions.map((actionMap) {
          final action = actionMap['action']?.toString() ?? 'ACTION';
          final result = actionMap['result']?.toString() ?? 'EXECUTED';
          final isSuccess = result == 'SUCCESS';
          final isUnsupported = result == 'UNSUPPORTED';

          final label = switch (action) {
            'END_CALL' => isSuccess ? 'Call ended by user' : 'Call ending was unavailable',
            'BLOCK_CALLER' => isSuccess ? 'Caller blocked' : 'Caller blocking was unavailable',
            'VERIFY_BEFORE_SHARING' => 'Verify before sharing guidance shown',
            'REPORT_CALL' => isSuccess ? 'Call reported to database' : 'Call report attempted',
            'WARNING_SHOWN' => 'Warning displayed to user',
            _ => action.replaceAll('_', ' ').toLowerCase(),
          };

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  isSuccess
                      ? Icons.check_circle_outline
                      : isUnsupported
                          ? Icons.warning_amber_rounded
                          : Icons.info_outline,
                  size: 18,
                  color: isSuccess
                      ? const Color(0xFF14804A)
                      : isUnsupported
                          ? const Color(0xFFC27500)
                          : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSafeActionSection(
    BuildContext context,
    CallHistoryDetail call,
    ColorScheme colors,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF14804A).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF14804A).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: Color(0xFF14804A), size: 20),
              SizedBox(width: 8),
              Text(
                'Safer Next Step',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Color(0xFF14804A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            call.safeAction!.trim(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.45,
                  color: colors.onSurface,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCallDetailsSection(
    BuildContext context,
    CallHistoryDetail call,
    ColorScheme colors,
  ) {
    return _SectionCard(
      title: 'Call details',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _DetailRow(label: 'Duration', value: call.formattedDuration),
          const Divider(height: 16),
          _DetailRow(
            label: 'Started',
            value: call.startedAt != null
                ? _formatTimestamp(call.startedAt!)
                : 'Not recorded',
          ),
          const Divider(height: 16),
          _DetailRow(label: 'Ended', value: _formatTimestamp(call.endedAt)),
          const Divider(height: 16),
          _DetailRow(
            label: 'Analysis status',
            value: _formatStatus(call.analysisStatus),
          ),
          const Divider(height: 16),
          _DetailRow(
            label: 'Audio status',
            value: _formatStatus(call.audioStatus),
          ),
          const Divider(height: 16),
          _DetailRow(
            label: 'Transcription status',
            value: _formatStatus(call.transcriptionStatus),
          ),
        ],
      ),
    );
  }

  static String _formatTimestamp(DateTime dt) {
    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final suffix = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  static String _formatStatus(String status) {
    return switch (status.toUpperCase()) {
      'COMPLETED' => 'Completed',
      'AVAILABLE' => 'Available',
      'AUDIO_UNAVAILABLE' => 'Unavailable',
      'TRANSCRIPTION_UNAVAILABLE' => 'Unavailable',
      'ANALYSIS_UNAVAILABLE' => 'Unavailable',
      _ => status.replaceAll('_', ' ').toLowerCase(),
    };
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
        ),
      ],
    );
  }
}
