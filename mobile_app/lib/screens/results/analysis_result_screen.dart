import 'package:flutter/material.dart';

import '../../models/analysis_record.dart';

class AnalysisResultScreen extends StatelessWidget {
  const AnalysisResultScreen({
    required this.analysis,
    this.onBackToDashboard,
    this.onAnalyzeAnother,
    super.key,
  });

  final AnalysisRecord analysis;
  final VoidCallback? onBackToDashboard;
  final VoidCallback? onAnalyzeAnother;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final riskColor = _riskColor(analysis.riskLevel, colors);
    final category = _displayCategory(analysis.category);
    final safeActions = analysis.safeActions.isNotEmpty
        ? analysis.safeActions
        : _splitActions(analysis.recommendedAction);

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis Result')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _RiskSummary(
                    analysis: analysis,
                    color: riskColor,
                    category: category,
                  ),
                  if (analysis.processingStatus ==
                      'COMPLETED_WITH_LIMITATIONS') ...[
                    const SizedBox(height: 10),
                    const _LimitationsNotice(),
                  ],
                  const SizedBox(height: 14),
                  _AnalyzedContentCard(analysis: analysis),
                  if (analysis.indicators.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _IndicatorsCard(indicators: analysis.indicators),
                  ],
                  if (analysis.retrievedEvidence.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _EvidenceCard(evidence: analysis.retrievedEvidence),
                  ],
                  if (analysis.explanation?.trim().isNotEmpty ?? false) ...[
                    const SizedBox(height: 14),
                    _ResultSection(
                      icon: Icons.lightbulb_outline_rounded,
                      title: analysis.classification.toUpperCase() == 'GENUINE'
                          ? 'Why this is safe'
                          : 'Why this result?',
                      content: analysis.explanation!,
                    ),
                  ],
                  if (analysis.mlProbability != null ||
                      analysis.llmConfidence != null) ...[
                    const SizedBox(height: 10),
                    _ConfidenceCard(analysis: analysis),
                  ],
                  if (safeActions.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _SafeActionsCard(actions: safeActions),
                  ],
                  const SizedBox(height: 14),
                  const _ResultFeedbackCard(),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final backButton = OutlinedButton.icon(
                        onPressed:
                            onBackToDashboard ??
                            () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.home_outlined),
                        label: const Text('Back to Dashboard'),
                      );
                      final analyzeButton = FilledButton.icon(
                        onPressed:
                            onAnalyzeAnother ??
                            () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.search_rounded),
                        label: const Text('Analyze Another'),
                      );
                      if (constraints.maxWidth < 420) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            backButton,
                            const SizedBox(height: 9),
                            analyzeButton,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: backButton),
                          const SizedBox(width: 10),
                          Expanded(child: analyzeButton),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const _DisclaimerCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _riskColor(String risk, ColorScheme colors) {
    return switch (risk.toUpperCase()) {
      'CRITICAL' => colors.error,
      'HIGH' => const Color(0xFFE64A3B),
      'MEDIUM' => const Color(0xFFC27500),
      'LOW' || 'SAFE' => const Color(0xFF14804A),
      _ => colors.primary,
    };
  }
}

class _RiskSummary extends StatelessWidget {
  const _RiskSummary({
    required this.analysis,
    required this.color,
    required this.category,
  });

  final AnalysisRecord analysis;
  final Color color;
  final String category;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final score = analysis.riskScore.clamp(0, 100);
    final isGenuine = analysis.classification.toUpperCase() == 'GENUINE';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: color.withValues(alpha: 0.32)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Text(
                'ANALYSIS COMPLETE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ),
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isGenuine
                      ? Icons.verified_user_rounded
                      : Icons.gpp_bad_rounded,
                  color: color,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        analysis.riskLevel.toUpperCase(),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.45,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      analysis.classification.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900, height: 1.05),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                children: [
                  SizedBox(
                    width: 76,
                    height: 76,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            color: color,
                            backgroundColor: colors.outlineVariant.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: colors.onSurface,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                            ),
                            Text(
                              '/ 100',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: colors.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RISK SCORE',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.35,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 17),
          Row(
            children: [
              Expanded(
                child: _SummaryDetail(
                  icon: Icons.category_outlined,
                  label: 'Category',
                  value: category,
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _SummaryDetail(
                  icon: _inputIcon(analysis.inputType),
                  label: 'Input type',
                  value: _displayCategory(analysis.inputType),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryDetail extends StatelessWidget {
  const _SummaryDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyzedContentCard extends StatefulWidget {
  const _AnalyzedContentCard({required this.analysis});

  final AnalysisRecord analysis;

  @override
  State<_AnalyzedContentCard> createState() => _AnalyzedContentCardState();
}

class _AnalyzedContentCardState extends State<_AnalyzedContentCard> {
  static const _previewLength = 240;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final analysis = widget.analysis;
    final inputType = analysis.inputType.toLowerCase();
    final title = switch (inputType) {
      'image' => 'Extracted image text',
      'pdf' => 'Extracted document text',
      'audio' => 'Transcript preview',
      _ => 'Analyzed content',
    };
    final content = analysis.content.trim();
    final isLong = content.length > _previewLength;
    final shownContent = isLong && !_expanded
        ? '${content.substring(0, _previewLength).trimRight()}…'
        : content;

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: _inputIcon(inputType),
            title: title,
            trailing: analysis.originalFilename?.trim().isNotEmpty == true
                ? Flexible(
                    child: Text(
                      analysis.originalFilename!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 11),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(14),
            ),
            child: SelectableText(
              shownContent.isEmpty
                  ? 'No extracted content was provided.'
                  : shownContent,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(height: 1.5, color: colors.onSurface),
            ),
          ),
          if (isLong)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Show less' : 'Show more'),
              ),
            ),
        ],
      ),
    );
  }
}

class _IndicatorsCard extends StatefulWidget {
  const _IndicatorsCard({required this.indicators});

  final List<String> indicators;

  @override
  State<_IndicatorsCard> createState() => _IndicatorsCardState();
}

class _IndicatorsCardState extends State<_IndicatorsCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const collapsedCount = 3;
    final visibleIndicators = _expanded
        ? widget.indicators
        : widget.indicators.take(collapsedCount).toList(growable: false);
    final remainingCount = widget.indicators.length - visibleIndicators.length;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.warning_amber_rounded,
            title: 'Detected indicators',
            iconColor: colors.error,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: visibleIndicators.map((indicator) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: Text(
                  indicator,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              );
            }).toList(),
          ),
          if (widget.indicators.length > collapsedCount) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded ? 'Show fewer' : 'Show $remainingCount more',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.evidence});

  final List<AnalysisEvidence> evidence;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeading(
            icon: Icons.fact_check_outlined,
            title: 'Supporting evidence',
          ),
          const SizedBox(height: 5),
          ...evidence.map((item) {
            final similarity = item.similarityScore;
            final scoreText = similarity == null
                ? null
                : '${(similarity.clamp(0, 1) * 100).round()}% match';
            return Material(
              color: Colors.transparent,
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                  splashColor: colors.primary.withValues(alpha: 0.05),
                ),
                child: ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  title: Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  subtitle: item.category.isEmpty ? null : Text(item.category),
                  trailing: scoreText == null
                      ? const Icon(Icons.expand_more_rounded)
                      : Text(
                          scoreText,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                  children: [
                    if (item.source.trim().isNotEmpty)
                      _EvidenceDetail(label: 'Source', value: item.source),
                    if (item.pattern.trim().isNotEmpty)
                      _EvidenceDetail(label: 'Pattern', value: item.pattern),
                    if (item.safeAction?.trim().isNotEmpty ?? false)
                      _EvidenceDetail(
                        label: 'Related safety action',
                        value: item.safeAction!,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _EvidenceDetail extends StatelessWidget {
  const _EvidenceDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(bottom: 9),
      child: RichText(
        text: TextSpan(
          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _ConfidenceCard extends StatefulWidget {
  const _ConfidenceCard({required this.analysis});

  final AnalysisRecord analysis;

  @override
  State<_ConfidenceCard> createState() => _ConfidenceCardState();
}

class _ConfidenceCardState extends State<_ConfidenceCard> {
  bool _showTechnicalDetails = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final values = <(String, IconData, double)>[];
    if (widget.analysis.mlProbability != null) {
      values.add((
        'ML confidence',
        Icons.smart_toy_outlined,
        widget.analysis.mlProbability!,
      ));
    }
    if (widget.analysis.llmConfidence != null) {
      values.add((
        'AI confidence',
        Icons.auto_awesome_outlined,
        widget.analysis.llmConfidence!,
      ));
    }
    final strongestConfidence = values
        .map((entry) => entry.$3)
        .reduce((a, b) => a < b ? a : b);
    final confidenceLabel = strongestConfidence >= 0.8
        ? 'Strong'
        : strongestConfidence >= 0.6
        ? 'Moderate'
        : 'Limited';

    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.insights_outlined,
            title: 'Detection confidence',
          ),
          const SizedBox(height: 5),
          Text(
            confidenceLabel,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800, color: colors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            'Confidence values are supporting signals, not a guarantee.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () =>
                setState(() => _showTechnicalDetails = !_showTechnicalDetails),
            child: Text(
              _showTechnicalDetails
                  ? 'Hide technical details'
                  : 'Technical details',
            ),
          ),
          if (_showTechnicalDetails)
            for (final value in values)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: _ConfidenceValue(
                  label: value.$1,
                  icon: value.$2,
                  value: value.$3,
                ),
              ),
        ],
      ),
    );
  }
}

class _ConfidenceValue extends StatelessWidget {
  const _ConfidenceValue({
    required this.label,
    required this.icon,
    required this.value,
  });

  final String label;
  final IconData icon;
  final double value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final percentage = (value.clamp(0, 1) * 100).round();
    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 23),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colors.onSurfaceVariant),
              ),
              Text(
                '$percentage%',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SafeActionsCard extends StatelessWidget {
  const _SafeActionsCard({required this.actions});

  final List<String> actions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: colors.primary.withValues(alpha: 0.23)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(
            icon: Icons.shield_rounded,
            title: 'What you should do now',
            iconColor: colors.primary,
          ),
          const SizedBox(height: 10),
          ...actions.map(
            (action) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 17,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      action,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(height: 1.4, color: colors.onSurface),
                    ),
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

class _ResultSection extends StatefulWidget {
  const _ResultSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String content;

  @override
  State<_ResultSection> createState() => _ResultSectionState();
}

class _ResultSectionState extends State<_ResultSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final isLong = widget.content.trim().length > 220;
    return _CardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeading(icon: widget.icon, title: widget.title),
          const SizedBox(height: 10),
          Text(
            widget.content,
            maxLines: isLong && !_expanded ? 4 : null,
            overflow: isLong && !_expanded ? TextOverflow.ellipsis : null,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(height: 1.5),
          ),
          if (isLong)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(_expanded ? 'Read less' : 'Read more'),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.icon,
    required this.title,
    this.iconColor,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Color? iconColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? colors.primary),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing!],
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: child,
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: colors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'ScamShield analysis is guidance, not a guarantee. Verify urgent '
              'requests through an independent trusted channel.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _LimitationsNotice extends StatelessWidget {
  const _LimitationsNotice();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.tertiary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 19, color: colors.tertiary),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Some analysis services were unavailable. This result may have '
              'limited insights.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurface, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

List<String> _splitActions(String? value) {
  if (value == null || value.trim().isEmpty) return const [];
  return value
      .split(RegExp(r'[\n\r]+'))
      .map((action) => action.replaceFirst(RegExp(r'^[•\-*]\s*'), '').trim())
      .where((action) => action.isNotEmpty)
      .toList(growable: false);
}

String _displayCategory(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'[_-]+'), ' ');
  if (normalized.isEmpty) return 'Unknown';
  const acronyms = {'ai': 'AI', 'kyc': 'KYC', 'otp': 'OTP', 'upi': 'UPI'};
  String displayWord(String word) {
    final lower = word.toLowerCase();
    if (acronyms.containsKey(lower)) return acronyms[lower]!;
    return word.isEmpty
        ? word
        : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
  }

  return normalized
      .split(RegExp(r'\s+'))
      .map((word) => word.split('/').map(displayWord).join('/'))
      .join(' ');
}

IconData _inputIcon(String inputType) => switch (inputType.toLowerCase()) {
  'image' => Icons.image_outlined,
  'pdf' => Icons.description_outlined,
  'audio' => Icons.graphic_eq_rounded,
  _ => Icons.chat_bubble_outline_rounded,
};

class _ResultFeedbackCard extends StatefulWidget {
  const _ResultFeedbackCard();

  @override
  State<_ResultFeedbackCard> createState() => _ResultFeedbackCardState();
}

class _ResultFeedbackCardState extends State<_ResultFeedbackCard> {
  bool? _isHelpful;
  String? _selectedReason;
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (_submitted) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline, color: colors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Thank you for your feedback! It helps improve ScamShield verification accuracy.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Was this analysis result helpful?',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isHelpful == null) ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final yesBtn = OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isHelpful = true;
                      _submitted = true;
                    });
                  },
                  icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                  label: const Text('Yes, helpful'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                final noBtn = OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isHelpful = false;
                    });
                  },
                  icon: const Icon(Icons.thumb_down_alt_outlined, size: 16),
                  label: const Text('No, needs review'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
                if (constraints.maxWidth < 360) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      yesBtn,
                      const SizedBox(height: 8),
                      noBtn,
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: yesBtn),
                    const SizedBox(width: 10),
                    Expanded(child: noBtn),
                  ],
                );
              },
            ),
          ] else if (_isHelpful == false) ...[
            Text(
              'What could be improved?',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                'Incorrect classification',
                'Wrong evidence',
                'Wrong explanation',
                'Other',
              ].map((reason) {
                final selected = _selectedReason == reason;
                return ChoiceChip(
                  label: Text(reason, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (val) {
                    setState(() => _selectedReason = val ? reason : null);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            FilledButton(
              onPressed: () => setState(() => _submitted = true),
              style: FilledButton.styleFrom(
                minimumSize: const Size(120, 38),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Submit feedback'),
            ),
          ],
        ],
      ),
    );
  }
}

