import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/analysis_record.dart';
import '../../services/analysis_service.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../results/widgets/multilingual_recommendation_card.dart';
import '../results/widgets/result_banner_card.dart';

class AnalysisDetailsScreen extends StatefulWidget {
  const AnalysisDetailsScreen({
    required this.recordId,
    this.initialRecord,
    this.analysisService,
    this.onAnalyzeAnother,
    this.onBack,
    super.key,
  });

  final int recordId;
  final AnalysisRecord? initialRecord;
  final AnalysisService? analysisService;
  final VoidCallback? onAnalyzeAnother;
  final VoidCallback? onBack;

  @override
  State<AnalysisDetailsScreen> createState() => _AnalysisDetailsScreenState();
}

class _AnalysisDetailsScreenState extends State<AnalysisDetailsScreen> {
  late AnalysisRecord? _record;
  bool _loading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _record = widget.initialRecord;
    // If no initial record or if we have an analysisService, fetch the authoritative record by ID
    if (_record == null || widget.analysisService != null) {
      _fetchRecord();
    }
  }

  Future<void> _fetchRecord() async {
    if (widget.analysisService == null) return;
    setState(() {
      _loading = _record == null;
      _errorMessage = null;
    });

    try {
      final fetched = await widget.analysisService!.getAnalysis(widget.recordId);
      // Validate response corresponds to requested identifier
      if (fetched.id != widget.recordId) {
        throw const ApiException('Record identity mismatch from backend.');
      }
      if (mounted) {
        setState(() {
          _record = fetched;
          _loading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (_record == null) {
            _errorMessage = e.statusCode == 404
                ? 'Analysis record not found.'
                : (e.statusCode == 403 || e.statusCode == 401)
                    ? 'You are not authorized to view this analysis record.'
                    : 'Unable to retrieve analysis details from server.';
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          if (_record == null) {
            _errorMessage = 'Unable to retrieve analysis details.';
          }
        });
      }
    }
  }

  void _copyContent(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Content copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor = isDark ? Colors.white : AppColors.navy;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: headlineColor),
          tooltip: 'Back',
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(
          'Analysis Details',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18.5,
            fontWeight: FontWeight.w700,
            color: headlineColor,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: _buildBody(context, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    if (_loading && _record == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 2.5),
            const SizedBox(height: 14),
            Text(
              'Loading analysis details...',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _record == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 14),
              Text(
                'Record Unavailable',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: _fetchRecord,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final record = _record!;
    return RefreshIndicator(
      onRefresh: _fetchRecord,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Outcome Banner (Scam Detected / Safe / Suspicious)
            ResultBannerCard(analysis: record),

            const SizedBox(height: 14),

            // 2. Content Card with Copy Action
            _buildContentCard(context, record, isDark),

            const SizedBox(height: 14),

            // 3. Details Breakdown Table
            _buildDetailsCard(context, record, isDark),

            const SizedBox(height: 14),

            // 4. Explanation Card
            _buildExplanationCard(context, record, isDark),

            const SizedBox(height: 14),

            // 5. Multilingual Recommendations (English, Hindi, Telugu)
            MultilingualRecommendationCard(analysis: record),

            const SizedBox(height: 18),

            // 6. Bottom Action Buttons (Analyze Similar & Save to History)
            _buildBottomActions(context, record, isDark),
          ],
        ),
      ),
    );
  }

  // Content Card matching panel 3 & 4
  Widget _buildContentCard(BuildContext context, AnalysisRecord record, bool isDark) {
    final cardBg = isDark ? const Color(0xFF131F2A) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);
    final headlineColor = isDark ? Colors.white : AppColors.navy;
    final bodyColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    final contentTypeLabel = switch (record.inputType.toLowerCase()) {
      'image' => 'Image / Screenshot',
      'pdf' => 'PDF / Document',
      'audio' => 'Voice Message / Audio',
      _ => 'Text Message',
    };

    final contentText = record.content.trim().isNotEmpty
        ? record.content.trim()
        : (record.originalFilename ?? 'Analysis #${record.id}');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: Color(0xFF0284C7),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: headlineColor,
                      ),
                    ),
                    Text(
                      contentTypeLabel,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy_rounded, size: 18),
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                tooltip: 'Copy content',
                onPressed: () => _copyContent(contentText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SelectableText(
            contentText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: bodyColor,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // Details Card
  Widget _buildDetailsCard(BuildContext context, AnalysisRecord record, bool isDark) {
    final cardBg = isDark ? const Color(0xFF131F2A) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);
    final headlineColor = isDark ? Colors.white : AppColors.navy;
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final valueColor = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);

    final riskLevel = record.riskLevel.trim().toUpperCase();
    final Color riskDotColor = switch (riskLevel) {
      'CRITICAL' || 'HIGH' => const Color(0xFFEF4444),
      'MEDIUM' => const Color(0xFFF59E0B),
      _ => const Color(0xFF10B981),
    };

    final String riskDisplay = switch (riskLevel) {
      'CRITICAL' => 'Critical',
      'HIGH' => 'High',
      'MEDIUM' => 'Medium',
      'LOW' || 'SAFE' => 'Low',
      _ => record.riskLevel,
    };

    final double? confidence = record.llmConfidence ?? record.mlProbability;
    final String? confidenceText = confidence != null
        ? '${(confidence * 100).round()}%'
        : (record.riskScore > 0 ? '${record.riskScore}%' : null);

    final hasSuspiciousLink = record.indicators.any(
      (ind) => ind.toLowerCase().contains('link') || ind.toLowerCase().contains('url'),
    );
    final String linksDisplay = hasSuspiciousLink
        ? '1 Suspicious Link'
        : 'None';

    final String indicatorsDisplay = record.indicators.isNotEmpty
        ? record.indicators.join(', ')
        : 'None';

    final timeDisplay = _formatDetailsTime(record.createdAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Details',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: headlineColor,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),

          // Risk Level
          _buildRow(
            label: 'Risk Level',
            labelColor: labelColor,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: riskDotColor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  riskDisplay,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 20),

          // Confidence (only when available)
          if (confidenceText != null) ...[
            _buildRow(
              label: 'Confidence',
              labelColor: labelColor,
              child: Text(
                confidenceText,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ),
            const Divider(height: 20),
          ],

          // Detected Links
          _buildRow(
            label: 'Detected Links',
            labelColor: labelColor,
            child: Text(
              linksDisplay,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: hasSuspiciousLink ? const Color(0xFFEF4444) : valueColor,
              ),
            ),
          ),
          const Divider(height: 20),

          // Scam Indicators
          _buildRow(
            label: 'Scam Indicators',
            labelColor: labelColor,
            child: Text(
              indicatorsDisplay,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
          const Divider(height: 20),

          // Analysis Time
          _buildRow(
            label: 'Analysis Time',
            labelColor: labelColor,
            child: Text(
              timeDisplay,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Explanation Card
  Widget _buildExplanationCard(BuildContext context, AnalysisRecord record, bool isDark) {
    final cardBg = isDark ? const Color(0xFF131F2A) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);
    final headlineColor = isDark ? Colors.white : AppColors.navy;
    final bodyColor = isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155);

    final explanation = record.explanation?.trim();
    final text = (explanation != null && explanation.isNotEmpty)
        ? explanation
        : 'This message appears to be from a legitimate source and does not contain any suspicious links, patterns or scam indicators.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: Color(0xFF0284C7),
              ),
              const SizedBox(width: 8),
              Text(
                'Explanation',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                  color: headlineColor,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: bodyColor,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // Bottom action buttons matching panel 3 & 4
  Widget _buildBottomActions(BuildContext context, AnalysisRecord record, bool isDark) {
    final primaryColor = const Color(0xFF0284C7);

    return Row(
      children: [
        // 1. Analyze Similar
        Expanded(
          child: OutlinedButton.icon(
            onPressed: widget.onAnalyzeAnother ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.sync_rounded, size: 18, color: Color(0xFF0284C7)),
            label: const Text(
              'Analyze Similar',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0284C7),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: primaryColor.withValues(alpha: 0.8), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // 2. Save to History (Informs user that record is already persisted automatically)
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Analysis #${record.id} is automatically preserved in your History.',
                    style: const TextStyle(fontFamily: 'Inter'),
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            icon: const Icon(Icons.bookmark_border_rounded, size: 18, color: Color(0xFF0284C7)),
            label: const Text(
              'Save to History',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0284C7),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(color: primaryColor.withValues(alpha: 0.8), width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow({
    required String label,
    required Color labelColor,
    required Widget child,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(child: child),
      ],
    );
  }

  static String _formatDetailsTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${local.day} ${months[local.month - 1]} ${local.year}, ${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}
