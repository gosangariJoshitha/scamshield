import 'package:flutter/material.dart';

import '../../models/analysis_record.dart';
import '../../models/call_history_models.dart';
import '../../services/analysis_service.dart';
import '../../services/api_service.dart';
import '../../services/call_history_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/skeleton_loaders.dart';
import 'analysis_details_screen.dart';
import 'call_summary_screen.dart';
import 'widgets/analysis_history_item_card.dart';
import 'widgets/call_history_item_card.dart';
import 'widgets/date_section_header.dart';
import 'widgets/history_filter_pills.dart';
import 'widgets/history_header.dart';
import 'widgets/history_search_bar.dart';
import 'widgets/history_tab_toggle.dart';

enum HistoryKind { analysis, calls }

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

  HistoryKind _kind = HistoryKind.analysis;

  // Analysis State
  bool _loadingAnalyses = true;
  String? _analysesError;
  List<AnalysisRecord> _analyses = const [];
  String _selectedAnalysisFilter = 'All';

  // Calls State
  bool _loadingCalls = false;
  String? _callsError;
  List<CallHistoryItem> _calls = const [];
  String _selectedCallFilter = 'All';

  // Search State
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const List<String> _analysisFilters = [
    'All',
    'Text',
    'Image',
    'Document',
    'Audio',
  ];

  static const List<String> _callFilters = [
    'All',
    'Scam',
    'Safe',
    'Unknown',
    'Critical',
    'High',
    'Medium',
    'Low',
  ];

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (_kind == HistoryKind.analysis) {
      await _loadAnalyses();
    } else {
      await _loadCalls();
    }
  }

  Future<void> _loadAnalyses() async {
    setState(() {
      _loadingAnalyses = true;
      _analysesError = null;
    });
    try {
      final analyses = await widget.analysisService.loadHistory();
      if (mounted) {
        setState(() => _analyses = analyses);
      }
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await widget.onSessionExpired();
        return;
      }
      if (mounted) setState(() => _analysesError = 'Unable to load your history.');
    } catch (_) {
      if (mounted) setState(() => _analysesError = 'Unable to load your history.');
    } finally {
      if (mounted) setState(() => _loadingAnalyses = false);
    }
  }

  Future<void> _loadCalls() async {
    setState(() {
      _loadingCalls = true;
      _callsError = null;
    });
    try {
      final String? riskQuery;
      final upperFilter = _selectedCallFilter.toUpperCase();
      if (upperFilter == 'CRITICAL' ||
          upperFilter == 'HIGH' ||
          upperFilter == 'MEDIUM' ||
          upperFilter == 'LOW') {
        riskQuery = upperFilter;
      } else {
        riskQuery = null;
      }

      final response = await _callHistoryService.loadCallHistory(riskLevel: riskQuery);
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
            callHistoryService: _callHistoryService,
            onBack: () => Navigator.of(context).pop(),
          ),
        ),
      );
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await widget.onSessionExpired();
        return;
      }
      if (!mounted) return;
      // Fallback detail constructed honestly from item if detail route is unreachable
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
            callHistoryService: _callHistoryService,
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

  void _openAnalysisDetail(AnalysisRecord record) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AnalysisDetailsScreen(
          recordId: record.id,
          initialRecord: record,
          analysisService: widget.analysisService,
          onAnalyzeAnother: widget.onAnalyzeAnother,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCallTab = _kind == HistoryKind.calls;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              // 1. Header (Title, Subtitle, Glowing Neon Clock Badge)
              HistoryHeader(isCallTab: isCallTab),

              const SizedBox(height: 16),

              // 2. Tab Switcher Pills ([Analysis History] | [Call History])
              HistoryTabToggle(
                isCallTab: isCallTab,
                onChanged: (toCall) {
                  setState(() {
                    _kind = toCall ? HistoryKind.calls : HistoryKind.analysis;
                  });
                  if (toCall && _calls.isEmpty && !_loadingCalls) {
                    _loadCalls();
                  } else if (!toCall && _analyses.isEmpty && !_loadingAnalyses) {
                    _loadAnalyses();
                  }
                },
              ),

              const SizedBox(height: 14),

              // 3. Search Bar
              HistorySearchBar(
                controller: _searchController,
                hintText: isCallTab
                    ? 'Search by phone number or contact...'
                    : 'Search by keyword, link or content...',
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                onClear: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
              ),

              const SizedBox(height: 12),

              // 4. Category / Filter Pills
              HistoryFilterPills(
                options: isCallTab ? _callFilters : _analysisFilters,
                selectedOption: isCallTab ? _selectedCallFilter : _selectedAnalysisFilter,
                onSelected: (option) {
                  setState(() {
                    if (isCallTab) {
                      _selectedCallFilter = option;
                    } else {
                      _selectedAnalysisFilter = option;
                    }
                  });
                  if (isCallTab) _loadCalls();
                },
              ),

              const SizedBox(height: 10),

              // 5. Grouped List Content
              if (isCallTab) ...[
                _buildCallHistorySection(context),
              ] else ...[
                _buildAnalysisHistorySection(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisHistorySection(BuildContext context) {
    if (_loadingAnalyses) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: HistoryListSkeleton(count: 4),
      );
    }

    if (_analysesError != null) {
      return _HistoryError(message: _analysesError!, onRetry: _loadAnalyses);
    }

    // Filter by category filter pill
    var filtered = _analyses;
    final filter = _selectedAnalysisFilter.toUpperCase();
    if (filter == 'TEXT') {
      filtered = filtered.where((a) => a.inputType.toLowerCase() == 'text').toList();
    } else if (filter == 'IMAGE') {
      filtered = filtered.where((a) => a.inputType.toLowerCase() == 'image').toList();
    } else if (filter == 'DOCUMENT') {
      filtered = filtered.where((a) => a.inputType.toLowerCase() == 'pdf').toList();
    } else if (filter == 'AUDIO') {
      filtered = filtered.where((a) => a.inputType.toLowerCase() == 'audio').toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery;
      filtered = filtered.where((analysis) {
        return analysis.category.toLowerCase().contains(q) ||
            analysis.classification.toLowerCase().contains(q) ||
            analysis.riskLevel.toLowerCase().contains(q) ||
            analysis.content.toLowerCase().contains(q) ||
            (analysis.originalFilename?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

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
      return _AnalysisHistoryEmpty(onAnalyze: widget.onAnalyzeAnother);
    }

    // Group filtered items by date
    final grouped = _groupByDate(filtered, (a) => a.createdAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DateSectionHeader(title: entry.key),
            ...entry.value.map(
              (analysis) => AnalysisHistoryItemCard(
                analysis: analysis,
                onTap: () => _openAnalysisDetail(analysis),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildCallHistorySection(BuildContext context) {
    if (_loadingCalls) {
      return const Padding(
        padding: EdgeInsets.only(top: 10),
        child: HistoryListSkeleton(count: 4),
      );
    }

    if (_callsError != null) {
      return _HistoryError(message: _callsError!, onRetry: _loadCalls);
    }

    // Filter by call filter pill
    var filtered = _calls;
    final filter = _selectedCallFilter.toUpperCase();
    if (filter == 'SCAM') {
      filtered = filtered
          .where((c) =>
              c.classification.toUpperCase() == 'SCAM' ||
              c.finalRiskLevel.toUpperCase() == 'HIGH' ||
              c.finalRiskLevel.toUpperCase() == 'CRITICAL')
          .toList();
    } else if (filter == 'SAFE') {
      filtered = filtered
          .where((c) =>
              c.classification.toUpperCase() == 'SAFE' ||
              c.classification.toUpperCase() == 'GENUINE' ||
              c.finalRiskLevel.toUpperCase() == 'LOW')
          .toList();
    } else if (filter == 'UNKNOWN') {
      filtered = filtered
          .where((c) =>
              c.analysisStatus == 'AUDIO_UNAVAILABLE' ||
              c.analysisStatus == 'ANALYSIS_UNAVAILABLE' ||
              c.analysisStatus == 'INCOMPLETE' ||
              c.classification.toUpperCase() == 'UNKNOWN')
          .toList();
    } else if (filter == 'CRITICAL' ||
        filter == 'HIGH' ||
        filter == 'MEDIUM' ||
        filter == 'LOW') {
      filtered = filtered
          .where((c) => c.finalRiskLevel.toUpperCase() == filter)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery;
      filtered = filtered.where((call) {
        return call.scamCategory.toLowerCase().contains(q) ||
            call.classification.toLowerCase().contains(q) ||
            call.finalRiskLevel.toLowerCase().contains(q) ||
            call.sessionId.toLowerCase().contains(q);
      }).toList();
    }

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

    // Group filtered items by date
    final grouped = _groupByDate(filtered, (c) => c.endedAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DateSectionHeader(title: entry.key),
            ...entry.value.map(
              (call) => CallHistoryItemCard(
                call: call,
                onTap: () => _openCallDetail(call),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  static Map<String, List<T>> _groupByDate<T>(
    List<T> items,
    DateTime Function(T) getTimestamp,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final groups = <String, List<T>>{};
    for (final item in items) {
      final dt = getTimestamp(item).toLocal();
      final itemDay = DateTime(dt.year, dt.month, dt.day);

      final String sectionTitle;
      if (itemDay == today) {
        sectionTitle = 'Today';
      } else if (itemDay == yesterday) {
        sectionTitle = 'Yesterday';
      } else {
        sectionTitle = '${dt.day} ${months[dt.month - 1]} ${dt.year}';
      }
      groups.putIfAbsent(sectionTitle, () => []).add(item);
    }
    return groups;
  }
}

class _AnalysisHistoryEmpty extends StatelessWidget {
  const _AnalysisHistoryEmpty({this.onAnalyze});

  final VoidCallback? onAnalyze;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131F2A) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded, color: Color(0xFF0284C7), size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'No analyses yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Analyze a suspicious message, image, PDF, or audio file to get started.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          if (onAnalyze != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAnalyze,
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Analyze now'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CallHistoryEmpty extends StatelessWidget {
  const _CallHistoryEmpty({this.onOpenGuardian});

  final VoidCallback? onOpenGuardian;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF131F2A) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFF0284C7).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.call_outlined, color: Color(0xFF0284C7), size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'No protected calls yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'ScamShield Sentinel call summaries will appear here after protected calls.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          if (onOpenGuardian != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onOpenGuardian,
              icon: const Icon(Icons.shield_outlined, size: 18),
              label: const Text('Open Sentinel'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0284C7),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 44, color: iconColor),
          const SizedBox(height: 12),
          Text(
            'No matching results',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No records found matching "$query".',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              color: iconColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onClear,
            icon: const Icon(Icons.clear_rounded, size: 16),
            label: const Text('Clear search'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
