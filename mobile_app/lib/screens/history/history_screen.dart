import 'package:flutter/material.dart';

import '../../models/analysis_record.dart';
import '../../models/call_history_models.dart';
import '../../services/analysis_service.dart';
import '../../services/api_service.dart';
import '../../services/call_history_service.dart';
import '../results/analysis_result_screen.dart';
import '../../widgets/skeleton_loaders.dart';
import 'call_summary_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    required this.analysisService,
    required this.onSessionExpired,
    this.callHistoryService,
    this.onBackToDashboard,
    this.onAnalyzeAnother,
    this.onOpenGuardian,
    super.key,
  });

  final AnalysisService analysisService;
  final CallHistoryService? callHistoryService;
  final Future<void> Function() onSessionExpired;
  final VoidCallback? onBackToDashboard;
  final VoidCallback? onAnalyzeAnother;
  final VoidCallback? onOpenGuardian;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final CallHistoryService _callHistoryService;

  bool _loading = true;
  String? _error;
  List<AnalysisRecord> _analyses = const [];

  bool _loadingCalls = false;
  String? _callsError;
  List<CallHistoryItem> _calls = const [];
  String _selectedRiskFilter = 'ALL';

  _HistoryKind _kind = _HistoryKind.analysis;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _callHistoryService = widget.callHistoryService ??
        CallHistoryService(
          api: widget.analysisService.api,
          tokenProvider: widget.analysisService.tokenProvider,
        );
    _load();
  }

  Future<void> _load() async {
    if (_kind == _HistoryKind.analysis) {
      await _loadAnalyses();
    } else {
      await _loadCalls();
    }
  }

  Future<void> _loadAnalyses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final analyses = await widget.analysisService.loadHistory();
      if (mounted) setState(() => _analyses = analyses);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await widget.onSessionExpired();
        return;
      }
      if (mounted) setState(() => _error = 'Unable to load your history.');
    } catch (_) {
      if (mounted) setState(() => _error = 'Unable to load your history.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCalls() async {
    setState(() {
      _loadingCalls = true;
      _callsError = null;
    });
    try {
      final filter = _selectedRiskFilter == 'ALL' ? null : _selectedRiskFilter;
      final response = await _callHistoryService.loadCallHistory(riskLevel: filter);
      if (mounted) setState(() => _calls = response.items);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await widget.onSessionExpired();
        return;
      }
      if (mounted) setState(() => _callsError = 'Unable to load call history.');
    } catch (_) {
      if (mounted) setState(() => _callsError = 'Unable to load call history.');
    } finally {
      if (mounted) setState(() => _loadingCalls = false);
    }
  }

  Future<void> _openCallDetail(CallHistoryItem item) async {
    try {
      final detail = await _callHistoryService.getCallSummary(item.sessionId);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CallSummaryScreen(
            call: detail,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await widget.onSessionExpired();
        return;
      }
      // If full detail fetch fails, fall back to basic detail constructed from item
      if (!mounted) return;
      final fallbackDetail = CallHistoryDetail(
        id: item.id,
        sessionId: item.sessionId,
        startedAt: item.startedAt,
        endedAt: item.endedAt,
        durationSeconds: item.durationSeconds,
        finalRiskScore: item.finalRiskScore,
        finalRiskLevel: item.finalRiskLevel,
        classification: item.classification,
        scamCategory: item.scamCategory,
        analysisStatus: item.analysisStatus,
        transcriptionStatus: item.transcriptionStatus,
        audioStatus: item.audioStatus,
        guardianEnabled: true,
        guardianStatus: 'ENABLED',
        riskReasoning: 'Detailed summary could not be retrieved from server.',
      );
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CallSummaryScreen(
            call: fallbackDetail,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open call summary.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Text(
              _kind == _HistoryKind.analysis ? 'Analysis History' : 'Call History',
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 5),
            Text(
              _kind == _HistoryKind.analysis
                  ? 'View results from your past ScamShield analyses.'
                  : 'View protected call summaries and risk assessments.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 18),
            SegmentedButton<_HistoryKind>(
              segments: const [
                ButtonSegment(
                  value: _HistoryKind.analysis,
                  label: Text('Analysis'),
                  icon: Icon(Icons.manage_search_rounded),
                ),
                ButtonSegment(
                  value: _HistoryKind.calls,
                  label: Text('Calls'),
                  icon: Icon(Icons.call_outlined),
                ),
              ],
              selected: {_kind},
              onSelectionChanged: (selection) {
                final newKind = selection.first;
                setState(() => _kind = newKind);
                if (newKind == _HistoryKind.calls && _calls.isEmpty && !_loadingCalls) {
                  _loadCalls();
                } else if (newKind == _HistoryKind.analysis && _analyses.isEmpty && !_loading) {
                  _loadAnalyses();
                }
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: _kind == _HistoryKind.analysis
                    ? 'Search analyses by category, risk, text...'
                    : 'Search calls by category, risk level...',
                hintStyle: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
            const SizedBox(height: 16),
            if (_kind == _HistoryKind.calls) ...[
              _buildRiskFilterChips(context),
              const SizedBox(height: 14),
              if (_loadingCalls)
                const HistoryListSkeleton(count: 3)
              else if (_callsError != null)
                _HistoryError(message: _callsError!, onRetry: _loadCalls)
              else () {
                final filtered = _searchQuery.isEmpty
                    ? _calls
                    : _calls.where((call) {
                        final q = _searchQuery;
                        return call.scamCategory.toLowerCase().contains(q) ||
                            call.classification.toLowerCase().contains(q) ||
                            call.finalRiskLevel.toLowerCase().contains(q);
                      }).toList();

                if (filtered.isEmpty) {
                  if (_searchQuery.isNotEmpty) {
                    return _SearchNoResults(
                      query: _searchQuery,
                      onClear: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    );
                  }
                  return _CallHistoryEmpty(onOpenGuardian: widget.onOpenGuardian);
                }

                return Column(
                  children: filtered.map(
                    (call) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _CallHistoryCard(
                        call: call,
                        onTap: () => _openCallDetail(call),
                      ),
                    ),
                  ).toList(),
                );
              }()
            ] else ...[
              if (_loading)
                const HistoryListSkeleton(count: 3)
              else if (_error != null)
                _HistoryError(message: _error!, onRetry: _loadAnalyses)
              else () {
                final filtered = _searchQuery.isEmpty
                    ? _analyses
                    : _analyses.where((analysis) {
                        final q = _searchQuery;
                        return analysis.category.toLowerCase().contains(q) ||
                            analysis.classification.toLowerCase().contains(q) ||
                            analysis.riskLevel.toLowerCase().contains(q) ||
                            analysis.content.toLowerCase().contains(q);
                      }).toList();

                if (filtered.isEmpty) {
                  if (_searchQuery.isNotEmpty) {
                    return _SearchNoResults(
                      query: _searchQuery,
                      onClear: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    );
                  }
                  return _HistoryEmpty(onAnalyze: widget.onAnalyzeAnother);
                }

                return Column(
                  children: filtered.map(
                    (analysis) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _HistoryTile(
                        analysis: analysis,
                        onTap: () => Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => AnalysisResultScreen(
                              analysis: analysis,
                              onBackToDashboard: widget.onBackToDashboard,
                              onAnalyzeAnother: widget.onAnalyzeAnother,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ).toList(),
                );
              }()
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRiskFilterChips(BuildContext context) {
    const filters = ['ALL', 'CRITICAL', 'HIGH', 'MEDIUM', 'LOW'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedRiskFilter == filter;
          final label = filter == 'ALL' ? 'All' : '${filter[0]}${filter.substring(1).toLowerCase()}';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(label),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedRiskFilter = filter);
                  _loadCalls();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

enum _HistoryKind { analysis, calls }

class _CallHistoryEmpty extends StatelessWidget {
  const _CallHistoryEmpty({this.onOpenGuardian});

  final VoidCallback? onOpenGuardian;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.call_outlined, color: colors.primary, size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            'No protected calls yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'ScamShield Guardian call summaries will appear here after protected calls.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
          ),
          if (onOpenGuardian != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onOpenGuardian,
              icon: const Icon(Icons.shield_outlined),
              label: const Text('Open Guardian'),
            ),
          ],
        ],
      ),
    );
  }
}

class _CallHistoryCard extends StatelessWidget {
  const _CallHistoryCard({required this.call, required this.onTap});

  final CallHistoryItem call;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final riskColor = call.riskColor(colors);
    final isUnavailable = call.analysisStatus == 'AUDIO_UNAVAILABLE' ||
        call.analysisStatus == 'ANALYSIS_UNAVAILABLE' ||
        call.audioStatus == 'AUDIO_UNAVAILABLE';

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant),
      ),
      elevation: 0,
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    label: isUnavailable
                        ? 'Status: Protected call'
                        : '${call.finalRiskLevel} RISK — ${call.finalRiskScore} out of 100',
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUnavailable
                            ? colors.surfaceContainerHighest
                            : riskColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isUnavailable ? 'PROTECTED CALL' : '${call.finalRiskLevel} RISK',
                        style: TextStyle(
                          color: isUnavailable ? colors.onSurfaceVariant : riskColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                  if (!isUnavailable)
                    Text(
                      '${call.finalRiskScore}/100',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: riskColor,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                call.scamCategory.isNotEmpty ? call.scamCategory : 'Unknown Caller',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${call.formattedDuration}   •   ${call.formattedEndedAt()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.analysis, required this.onTap});

  final AnalysisRecord analysis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final riskColor = switch (analysis.riskLevel.toUpperCase()) {
      'HIGH' || 'CRITICAL' => colors.error,
      'MEDIUM' => const Color(0xFFC27500),
      _ => const Color(0xFF14804A),
    };
    final filename = analysis.originalFilename?.trim();
    final category = analysis.category.trim();
    final preview = filename != null && filename.isNotEmpty
        ? filename
        : category.isNotEmpty && category.toLowerCase() != 'unknown'
        ? '${_formatHistoryCategory(category)} detected'
        : '${analysis.inputType.toUpperCase()} analysis';
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: riskColor.withValues(alpha: 0.12),
          child: Icon(_inputIcon(analysis.inputType), color: riskColor),
        ),
        title: Text(
          preview.isEmpty ? 'Analysis ${analysis.id}' : preview,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${analysis.inputType.toUpperCase()} · ${_formatDate(analysis.createdAt)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              analysis.riskLevel,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: riskColor, fontWeight: FontWeight.w800),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

String _formatHistoryCategory(String category) => category
    .replaceAll(RegExp(r'[_-]+'), ' ')
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .map((word) {
      final normalized = word.toLowerCase();
      if (const {'ai', 'kyc', 'otp', 'upi', 'sms'}.contains(normalized)) {
        return normalized.toUpperCase();
      }
      return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
    })
    .join(' ');

class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty({this.onAnalyze});

  final VoidCallback? onAnalyze;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 54),
      child: Column(
        children: [
          Icon(
            Icons.history_rounded,
            size: 46,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 13),
          Text(
            'No analyses yet.',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            'Analyze a suspicious message, image, PDF, or audio file to get started.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (onAnalyze != null) ...[
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onAnalyze,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Analyze now'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SearchNoResults extends StatelessWidget {
  const _SearchNoResults({required this.query, required this.onClear});

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 44, color: colors.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'No matching results',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'No records found matching "$query".',
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.onSurfaceVariant, fontSize: 13),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_rounded, size: 16),
            label: const Text('Clear search'),
          ),
        ],
      ),
    );
  }
}

class _HistoryError extends StatelessWidget {
  const _HistoryError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ],
    );
  }
}

IconData _inputIcon(String type) => switch (type.toLowerCase()) {
  'image' => Icons.image_outlined,
  'pdf' => Icons.picture_as_pdf_outlined,
  'audio' => Icons.graphic_eq_rounded,
  _ => Icons.chat_bubble_outline_rounded,
};

String _formatDate(DateTime date) {
  final local = date.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day} ${_month(local.month)} ${local.year}, $hour:$minute $suffix';
}

String _month(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];
