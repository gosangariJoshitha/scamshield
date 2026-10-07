import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/admin_portal_service.dart';
import '../../services/api_service.dart';

enum _AdminSection {
  overview,
  reviews,
  community,
  knowledge,
  users,
  monitoring,
  settings,
}

class AdminPortalScreen extends StatefulWidget {
  const AdminPortalScreen({
    required this.user,
    required this.adminService,
    required this.onLogout,
    required this.onSessionExpired,
    required this.isDarkMode,
    required this.onToggleTheme,
    super.key,
  });

  final User user;
  final AdminPortalService adminService;
  final Future<void> Function() onLogout;
  final Future<void> Function() onSessionExpired;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<AdminPortalScreen> createState() => _AdminPortalScreenState();
}

class _AdminPortalScreenState extends State<AdminPortalScreen> {
  _AdminSection _section = _AdminSection.overview;
  int _refreshKey = 0;
  bool _handlingExpiredSession = false;
  final TextEditingController _searchController = TextEditingController();
  int _page = 1;
  String _statusFilter = '';
  String _roleFilter = '';
  String _riskFilter = '';
  String _priorityFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _select(_AdminSection section) {
    setState(() {
      _section = section;
      _page = 1;
      _searchController.clear();
      _statusFilter = '';
      _roleFilter = '';
      _riskFilter = '';
      _priorityFilter = '';
      _refreshKey++;
    });
  }

  void _reload({int? page}) {
    setState(() {
      _page = page ?? _page;
      _refreshKey++;
    });
  }

  void _setSearch(String value) {
    setState(() {
      _page = 1;
      _searchController.text = value;
      _refreshKey++;
    });
  }

  void _setFilter(String? value) {
    setState(() {
      _page = 1;
      switch (_section) {
        case _AdminSection.users:
          _roleFilter = value ?? '';
          break;
        case _AdminSection.reviews:
          _statusFilter = value ?? '';
          break;
        default:
          _statusFilter = value ?? '';
      }
      _refreshKey++;
    });
  }

  void _setStatusFilter(String? value) {
    setState(() {
      _page = 1;
      _statusFilter = value ?? '';
      _refreshKey++;
    });
  }

  Future<void> _handleError(Object error) async {
    if (error is ApiException &&
        (error.statusCode == 401 || error.statusCode == 403) &&
        !_handlingExpiredSession) {
      _handlingExpiredSession = true;
      await widget.onSessionExpired();
    }
  }

  Future<Object?> _loadSection() {
    switch (_section) {
      case _AdminSection.overview:
        return widget.adminService.loadOverview();
      case _AdminSection.reviews:
        return widget.adminService.loadReviewPage(
          page: _page,
          search: _searchController.text,
          status: _statusFilter,
          riskLevel: _riskFilter,
          priority: _priorityFilter,
        );
      case _AdminSection.community:
        return widget.adminService.loadCommunityPage(
          page: _page,
          search: _searchController.text,
          status: _statusFilter,
        );
      case _AdminSection.knowledge:
        return widget.adminService.loadKnowledgePage(
          page: _page,
          search: _searchController.text,
          status: _statusFilter,
        );
      case _AdminSection.users:
        return widget.adminService.loadUsersPage(
          page: _page,
          search: _searchController.text,
          role: _roleFilter,
          status: _statusFilter,
        );
      case _AdminSection.monitoring:
        return widget.adminService.loadMonitoring();
      case _AdminSection.settings:
        return widget.adminService.loadAuditPage();
    }
  }

  void _showResult(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  Future<bool> _confirm(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _runAction(
    Future<Object?> Function() action, {
    required String successMessage,
  }) async {
    try {
      await action();
      if (!mounted) return;
      _showResult(successMessage);
      _reload();
    } catch (error) {
      await _handleError(error);
      if (mounted) {
        _showResult(
          error is ApiException
              ? error.message
              : 'The action could not be completed. Please try again.',
          isError: true,
        );
      }
    }
  }

  Future<void> _createKnowledge() async {
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _KnowledgeEditorDialog(),
    );
    if (values == null) return;
    await _runAction(
      () => widget.adminService.createKnowledge(values),
      successMessage: 'Draft saved to the knowledge base.',
    );
  }

  Future<void> _openRecord(Map<String, dynamic> row) async {
    try {
      switch (_section) {
        case _AdminSection.reviews:
          final caseId = row['id'];
          if (caseId is! num) throw const FormatException('Invalid case ID.');
          if (row['status'] == 'PENDING' || row['status'] == 'ASSIGNED') {
            await widget.adminService.startReview(caseId.toInt());
          }
          final detail = await widget.adminService.loadReviewDetail(
            caseId.toInt(),
          );
          if (!mounted) return;
          final submission = await showDialog<_ReviewSubmission>(
            context: context,
            builder: (context) => _ReviewDetailDialog(
              detail: detail,
              canDecide: const {
                'IN_REVIEW',
                'NEEDS_INFORMATION',
              }.contains(detail['status']),
            ),
          );
          if (submission == null) return;
          if (!await _confirm(
            'Submit review decision?',
            'This decision will be recorded in the case history.',
          )) {
            return;
          }
          await _runAction(
            () => widget.adminService.submitReviewDecision(
              caseId.toInt(),
              decision: submission.decision,
              notes: submission.notes,
            ),
            successMessage: 'Review decision recorded.',
          );
          break;
        case _AdminSection.community:
          final reportId = row['id'];
          if (reportId is! num) {
            throw const FormatException('Invalid report ID.');
          }
          final choice = await showDialog<_CommunityActionChoice>(
            context: context,
            builder: (context) => _CommunityReportDialog(report: row),
          );
          if (choice == null) return;
          if (!await _confirm(
            'Apply ${_humanize(choice.action.toLowerCase())}?',
            'This moderation action will update the report and its audit history.',
          )) {
            return;
          }
          await _runAction(
            () => widget.adminService.actOnCommunityReport(
              reportId.toInt(),
              action: choice.action,
              notes: choice.notes,
            ),
            successMessage: choice.action == 'CONVERT_TO_KNOWLEDGE'
                ? 'A knowledge draft was created from the verified report.'
                : 'Community report updated.',
          );
          break;
        case _AdminSection.knowledge:
          final id = row['id'];
          if (id is! num) {
            throw const FormatException('Invalid knowledge entry ID.');
          }
          final action = await showDialog<_KnowledgeAction>(
            context: context,
            builder: (context) => _KnowledgeActionsDialog(entry: row),
          );
          if (action == null || !mounted) return;
          if (action.kind == 'edit') {
            final values = await showDialog<Map<String, dynamic>>(
              context: context,
              builder: (context) => _KnowledgeEditorDialog(entry: row),
            );
            if (values == null || !mounted) return;
            await _runAction(
              () => widget.adminService.updateKnowledge(id.toInt(), values),
              successMessage: 'Knowledge entry updated.',
            );
          } else if (action.kind == 'publish') {
            if (!await _confirm(
              'Publish and index this entry?',
              'It will become available to the analysis knowledge service.',
            )) {
              return;
            }
            await _runAction(
              () => widget.adminService.approveKnowledge(id.toInt()),
              successMessage: 'Entry published and indexed successfully.',
            );
          } else if (action.kind == 'reindex') {
            if (!await _confirm(
              'Reindex this entry?',
              'The existing knowledge entry will be submitted to the search index again.',
            )) {
              return;
            }
            await _runAction(
              () => widget.adminService.reindexKnowledge(id.toInt()),
              successMessage: 'Entry reindexed successfully.',
            );
          } else if (action.kind == 'archive') {
            if (!await _confirm(
              'Archive this entry?',
              'It will be removed from the active knowledge index.',
            )) {
              return;
            }
            await _runAction(
              () => widget.adminService.archiveKnowledge(id.toInt()),
              successMessage: 'Knowledge entry archived.',
            );
          }
          break;
        case _AdminSection.users:
          final id = row['id'];
          if (id is! num) throw const FormatException('Invalid user ID.');
          final detail = await widget.adminService.loadUserDetail(id.toInt());
          if (!mounted) return;
          final nextActive = await showDialog<bool>(
            context: context,
            builder: (context) =>
                _UserDetailDialog(data: detail, currentAdminId: widget.user.id),
          );
          if (nextActive == null) return;
          final target = detail['user'];
          final targetId = target is Map ? target['id'] : null;
          if (targetId == widget.user.id && !nextActive) {
            _showResult(
              'You cannot disable your own admin account.',
              isError: true,
            );
            return;
          }
          if (!await _confirm(
            nextActive ? 'Enable this account?' : 'Disable this account?',
            'The account status will be updated immediately.',
          )) {
            return;
          }
          await _runAction(
            () => widget.adminService.updateUserStatus(
              id.toInt(),
              isActive: nextActive,
            ),
            successMessage: nextActive
                ? 'User account enabled.'
                : 'User account disabled.',
          );
          break;
        default:
          break;
      }
    } catch (error) {
      await _handleError(error);
      if (mounted) {
        _showResult(
          error is ApiException
              ? error.message
              : 'Could not load record details. Please try again.',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.user.role != 'admin' || !widget.user.isActive) {
      return const Scaffold(
        body: Center(child: Text('Administrator access is required.')),
      );
    }

    final wide = MediaQuery.sizeOf(context).width >= 840;
    return Scaffold(
      appBar: AppBar(
        leading: wide
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.shield_rounded),
              )
            : null,
        title: Text(_section.title),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => setState(() => _refreshKey++),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: widget.isDarkMode
                ? 'Switch to light theme'
                : 'Switch to dark theme',
            onPressed: widget.onToggleTheme,
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              tooltip: 'Administrator profile',
              onSelected: (value) async {
                if (value == 'logout') await widget.onLogout();
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  enabled: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.user.fullName),
                      Text(
                        widget.user.email,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'logout',
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.logout_rounded),
                    title: Text('Sign out'),
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 18,
                child: Text(_initials(widget.user.fullName)),
              ),
            ),
          ),
        ],
      ),
      drawer: wide
          ? null
          : Drawer(
              child: SafeArea(
                child: _SectionList(
                  selected: _section,
                  user: widget.user,
                  onSelected: (section) {
                    Navigator.of(context).pop();
                    _select(section);
                  },
                  onLogout: widget.onLogout,
                ),
              ),
            ),
      body: Row(
        children: [
          if (wide)
            SizedBox(
              width: 260,
              child: _SectionList(
                selected: _section,
                user: widget.user,
                onSelected: _select,
                onLogout: widget.onLogout,
              ),
            ),
          Expanded(
            child: FutureBuilder<Object?>(
              key: ValueKey('$_section-$_refreshKey'),
              future: _loadSection(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  _handleError(snapshot.error!);
                  return _LoadError(
                    message: 'Could not load this section. Check your connection and try again.',
                    onRetry: () => _reload(),
                  );
                }
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _SectionContent(
                  section: _section,
                  data: snapshot.data,
                  user: widget.user,
                  isDarkMode: widget.isDarkMode,
                  onToggleTheme: widget.onToggleTheme,
                  onLogout: widget.onLogout,
                  onSelect: _select,
                  onOpenRecord: _openRecord,
                  onCreateKnowledge: _createKnowledge,
                  onSearch: _setSearch,
                  searchController: _searchController,
                  onFilter: _setFilter,
                  onStatusFilter: _setStatusFilter,
                  onRiskFilter: (value) {
                    setState(() {
                      _page = 1;
                      _riskFilter = value ?? '';
                      _refreshKey++;
                    });
                  },
                  onPriorityFilter: (value) {
                    setState(() {
                      _page = 1;
                      _priorityFilter = value ?? '';
                      _refreshKey++;
                    });
                  },
                  statusFilter: _statusFilter,
                  roleFilter: _roleFilter,
                  riskFilter: _riskFilter,
                  priorityFilter: _priorityFilter,
                  page: _page,
                  onPageChanged: (page) => _reload(page: page),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: switch (_section) {
                _AdminSection.overview => 0,
                _AdminSection.reviews => 1,
                _AdminSection.community => 2,
                _ => 3,
              },
              onDestinationSelected: (index) => _select(
                [
                  _AdminSection.overview,
                  _AdminSection.reviews,
                  _AdminSection.community,
                  _AdminSection.settings,
                ][index],
              ),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Overview',
                ),
                NavigationDestination(
                  icon: Icon(Icons.rate_review_outlined),
                  selectedIcon: Icon(Icons.rate_review_rounded),
                  label: 'Reviews',
                ),
                NavigationDestination(
                  icon: Icon(Icons.groups_outlined),
                  selectedIcon: Icon(Icons.groups_rounded),
                  label: 'Community',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_rounded),
                  label: 'More',
                ),
              ],
            ),
    );
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.selected,
    required this.user,
    required this.onSelected,
    required this.onLogout,
  });

  final _AdminSection selected;
  final User user;
  final ValueChanged<_AdminSection> onSelected;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 14),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: Color(0xFF087E8B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ScamShield Admin',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                for (final section in _AdminSection.values)
                  ListTile(
                    selected: selected == section,
                    leading: Icon(section.icon),
                    title: Text(section.title),
                    onTap: () => onSelected(section),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: CircleAvatar(child: Text(_initials(user.fullName))),
            title: Text(
              user.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: const Text('Administrator'),
            trailing: IconButton(
              tooltip: 'Sign out',
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionContent extends StatelessWidget {
  const _SectionContent({
    required this.section,
    required this.data,
    required this.user,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
    required this.onSelect,
    required this.onOpenRecord,
    required this.onCreateKnowledge,
    required this.onSearch,
    required this.searchController,
    required this.onFilter,
    required this.onStatusFilter,
    required this.onRiskFilter,
    required this.onPriorityFilter,
    required this.statusFilter,
    required this.roleFilter,
    required this.riskFilter,
    required this.priorityFilter,
    required this.page,
    required this.onPageChanged,
  });

  final _AdminSection section;
  final Object? data;
  final User user;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onLogout;
  final ValueChanged<_AdminSection> onSelect;
  final ValueChanged<Map<String, dynamic>> onOpenRecord;
  final VoidCallback onCreateKnowledge;
  final ValueChanged<String> onSearch;
  final TextEditingController searchController;
  final ValueChanged<String?> onFilter;
  final ValueChanged<String?> onStatusFilter;
  final ValueChanged<String?> onRiskFilter;
  final ValueChanged<String?> onPriorityFilter;
  final String statusFilter;
  final String roleFilter;
  final String riskFilter;
  final String priorityFilter;
  final int page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (section == _AdminSection.overview) {
      return _OverviewContent(
        data: data is Map<String, dynamic> ? data! as Map<String, dynamic> : {},
        onSelect: onSelect,
      );
    }
    if (section == _AdminSection.monitoring) {
      return _MonitoringContent(
        data: data is Map<String, dynamic> ? data! as Map<String, dynamic> : {},
      );
    }
    if (section == _AdminSection.settings) {
      return _SettingsContent(
        user: user,
        isDarkMode: isDarkMode,
        onToggleTheme: onToggleTheme,
        onLogout: onLogout,
        onSelect: onSelect,
        auditPage: data is AdminPage ? data! as AdminPage : null,
      );
    }
    return _RecordsContent(
      section: section,
      pageData: data is AdminPage ? data! as AdminPage : null,
      onOpenRecord: onOpenRecord,
      onCreateKnowledge: onCreateKnowledge,
      onSearch: onSearch,
      searchController: searchController,
      onFilter: onFilter,
      onStatusFilter: onStatusFilter,
      onRiskFilter: onRiskFilter,
      onPriorityFilter: onPriorityFilter,
      statusFilter: statusFilter,
      roleFilter: roleFilter,
      riskFilter: riskFilter,
      priorityFilter: priorityFilter,
      page: page,
      onPageChanged: onPageChanged,
    );
  }
}

class _OverviewContent extends StatelessWidget {
  const _OverviewContent({required this.data, required this.onSelect});

  final Map<String, dynamic> data;
  final ValueChanged<_AdminSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final activity = data['analysisActivity'];
    final activityRows = activity is List
        ? activity.whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];
    final metrics = <({String label, String key, _AdminSection section})>[
      (
        label: 'Analyses',
        key: 'totalAnalyses',
        section: _AdminSection.monitoring,
      ),
      (
        label: 'Scams detected',
        key: 'scamsDetected',
        section: _AdminSection.monitoring,
      ),
      (label: 'High risk', key: 'highRisk', section: _AdminSection.monitoring),
      (
        label: 'Pending reviews',
        key: 'pendingReviews',
        section: _AdminSection.reviews,
      ),
      (
        label: 'Community reports',
        key: 'communityReports',
        section: _AdminSection.community,
      ),
      (
        label: 'Verified knowledge',
        key: 'verifiedKnowledge',
        section: _AdminSection.knowledge,
      ),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Command center',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          'Live totals from the ScamShield service. Analysis totals cover the last '
          '${adminValue(data['period_days'])} days.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: columns == 1
                  ? constraints.maxWidth < 380
                        ? 2.6
                        : 3.2
                  : 2.3,
              children: [
                for (final metric in metrics)
                  _MetricCard(
                    label: metric.label,
                    value: adminValue(data[metric.key]),
                    icon: metric.section.icon,
                    onTap: () => onSelect(metric.section),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        _Panel(
          title: 'Analysis activity',
          subtitle: activityRows.isEmpty
              ? 'No activity data was returned for this period.'
              : 'Daily analysis volume reported by the service.',
          child: activityRows.isEmpty
              ? const _EmptyState(
                  icon: Icons.bar_chart_rounded,
                  message: 'Activity data is not available.',
                )
              : _ActivityBars(rows: activityRows),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Review queue',
          subtitle: 'Recent cases returned by the dashboard service.',
          trailing: TextButton(
            onPressed: () => onSelect(_AdminSection.reviews),
            child: const Text('Open queue'),
          ),
          child: _RecentItems(
            data['recentReviews'],
            emptyMessage: 'No recent review cases were returned.',
            titleField: 'reporter',
            details: (row) =>
                'Case ${adminValue(row['id'])} · ${adminValue(row['status'])} · '
                '${adminValue(row['risk_level'])}',
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Recent analyses',
          subtitle: 'Latest records included in the current overview.',
          child: _RecentItems(
            data['recentAnalyses'],
            emptyMessage: 'No recent analyses were returned.',
            titleField: 'user',
            details: (row) =>
                '${adminValue(row['input_type'])} · '
                '${adminValue(row['classification'])} · '
                '${adminValue(row['risk_level'])}',
          ),
        ),
      ],
    );
  }
}

class _RecordsContent extends StatelessWidget {
  const _RecordsContent({
    required this.section,
    required this.pageData,
    required this.onOpenRecord,
    required this.onCreateKnowledge,
    required this.onSearch,
    required this.searchController,
    required this.onFilter,
    required this.onStatusFilter,
    required this.onRiskFilter,
    required this.onPriorityFilter,
    required this.statusFilter,
    required this.roleFilter,
    required this.riskFilter,
    required this.priorityFilter,
    required this.page,
    required this.onPageChanged,
  });

  final _AdminSection section;
  final AdminPage? pageData;
  final ValueChanged<Map<String, dynamic>> onOpenRecord;
  final VoidCallback onCreateKnowledge;
  final ValueChanged<String> onSearch;
  final TextEditingController searchController;
  final ValueChanged<String?> onFilter;
  final ValueChanged<String?> onStatusFilter;
  final ValueChanged<String?> onRiskFilter;
  final ValueChanged<String?> onPriorityFilter;
  final String statusFilter;
  final String roleFilter;
  final String riskFilter;
  final String priorityFilter;
  final int page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final pageData = this.pageData;
    final rows = pageData?.items ?? const <Map<String, dynamic>>[];
    final emptyMessage = switch (section) {
      _AdminSection.reviews => 'There are no human-review cases to show.',
      _AdminSection.community => 'There are no community reports to show.',
      _AdminSection.knowledge => 'The knowledge base has no entries to show.',
      _AdminSection.users => 'There are no users to show.',
      _ => 'No records are available.',
    };
    final columns = switch (section) {
      _AdminSection.reviews => [
        'id',
        'status',
        'priority',
        'risk_level',
        'reporter',
      ],
      _AdminSection.community => ['id', 'category', 'status', 'reporter'],
      _AdminSection.knowledge => ['title', 'category', 'status', 'risk_level'],
      _AdminSection.users => ['full_name', 'email', 'role', 'is_active'],
      _ => const <String>[],
    };
    final filters = switch (section) {
      _AdminSection.reviews => const [
        ('All statuses', ''),
        ('Pending', 'PENDING'),
        ('Assigned', 'ASSIGNED'),
        ('In review', 'IN_REVIEW'),
        ('Needs information', 'NEEDS_INFORMATION'),
        ('Verified', 'VERIFIED'),
        ('Closed', 'CLOSED'),
      ],
      _AdminSection.community => const [
        ('All statuses', ''),
        ('Pending', 'Pending'),
        ('Verified', 'VERIFIED'),
        ('Rejected', 'REJECTED'),
        ('Needs information', 'NEEDS_INFORMATION'),
        ('Resolved', 'RESOLVED'),
        ('Escalated', 'ESCALATED'),
      ],
      _AdminSection.knowledge => const [
        ('All statuses', ''),
        ('Draft', 'DRAFT'),
        ('Approved', 'APPROVED'),
        ('Active', 'ACTIVE'),
        ('Archived', 'INACTIVE'),
      ],
      _AdminSection.users => const [
        ('All roles', ''),
        ('Users', 'user'),
        ('Administrators', 'admin'),
      ],
      _ => const <(String, String)>[],
    };
    final selectedFilter = section == _AdminSection.users
        ? roleFilter
        : statusFilter;
    final reviewRiskFilters = const [
      ('All risk', ''),
      ('Low', 'LOW'),
      ('Medium', 'MEDIUM'),
      ('High', 'HIGH'),
      ('Critical', 'CRITICAL'),
    ];
    final reviewPriorityFilters = const [
      ('All priorities', ''),
      ('Low priority', 'LOW'),
      ('Medium priority', 'MEDIUM'),
      ('High priority', 'HIGH'),
      ('Urgent', 'URGENT'),
    ];
    final userStatusFilters = const [
      ('All account statuses', ''),
      ('Active', 'ACTIVE'),
      ('Disabled', 'DISABLED'),
    ];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                section.title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (section == _AdminSection.knowledge)
              FilledButton.icon(
                onPressed: onCreateKnowledge,
                icon: const Icon(Icons.add_rounded),
                label: const Text('New draft'),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${pageData?.total ?? 0} record${pageData?.total == 1 ? '' : 's'} · '
          'page $page of ${pageData?.totalPages ?? 1}',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final search = TextField(
              controller: searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: onSearch,
              decoration: InputDecoration(
                labelText: 'Search ${section.title.toLowerCase()}',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Search',
                  onPressed: () => onSearch(searchController.text),
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            );
            Widget dropdown(
              String label,
              String selected,
              List<(String, String)> options,
              ValueChanged<String?> onChanged,
            ) => SizedBox(
              width: constraints.maxWidth < 600 ? constraints.maxWidth : 190,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: selected,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  for (final option in options)
                    DropdownMenuItem(value: option.$2, child: Text(option.$1)),
                ],
                onChanged: onChanged,
              ),
            );
            final controls = <Widget>[
              SizedBox(
                width: constraints.maxWidth < 600 ? constraints.maxWidth : 360,
                child: search,
              ),
              if (filters.isNotEmpty)
                dropdown(
                  section == _AdminSection.users ? 'Role' : 'Status',
                  selectedFilter,
                  filters,
                  onFilter,
                ),
              if (section == _AdminSection.users)
                dropdown(
                  'Account status',
                  statusFilter,
                  userStatusFilters,
                  onStatusFilter,
                ),
              if (section == _AdminSection.reviews) ...[
                dropdown('Risk', riskFilter, reviewRiskFilters, onRiskFilter),
                dropdown(
                  'Priority',
                  priorityFilter,
                  reviewPriorityFilters,
                  onPriorityFilter,
                ),
              ],
            ];
            return Wrap(spacing: 12, runSpacing: 12, children: controls);
          },
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          _EmptyState(icon: section.icon, message: emptyMessage)
        else
          ...rows.map(
            (row) => _RecordCard(
              row: row,
              columns: columns,
              section: section,
              onOpen: () => onOpenRecord(row),
            ),
          ),
        if ((pageData?.totalPages ?? 1) > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
                child: const Text('Previous'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text('$page / ${pageData?.totalPages ?? 1}'),
              ),
              OutlinedButton(
                onPressed: page < (pageData?.totalPages ?? 1)
                    ? () => onPageChanged(page + 1)
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.row,
    required this.columns,
    required this.section,
    required this.onOpen,
  });

  final Map<String, dynamic> row;
  final List<String> columns;
  final _AdminSection section;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final heading =
        row['title'] ??
        row['full_name'] ??
        row['email'] ??
        (row['id'] == null ? null : 'Record ${row['id']}');
    final subheading = columns
        .where((key) => key != 'title' && key != 'full_name' && key != 'email')
        .map((key) => '${_humanize(key)}: ${adminValue(row[key])}')
        .join('  ·  ');
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading is String ? heading : 'Record',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subheading.isEmpty
                  ? 'No additional details reported.'
                  : subheading,
            ),
            if (row['content_preview'] is String) ...[
              const SizedBox(height: 8),
              Text(
                row['content_preview'] as String,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: onOpen,
                icon: Icon(switch (section) {
                  _AdminSection.reviews => Icons.fact_check_outlined,
                  _AdminSection.community => Icons.gavel_outlined,
                  _AdminSection.knowledge => Icons.edit_outlined,
                  _AdminSection.users => Icons.manage_accounts_outlined,
                  _ => Icons.open_in_new_rounded,
                }),
                label: Text(switch (section) {
                  _AdminSection.reviews => 'Review case',
                  _AdminSection.community => 'Moderate report',
                  _AdminSection.knowledge => 'Manage entry',
                  _AdminSection.users => 'View account',
                  _ => 'Open',
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonitoringContent extends StatelessWidget {
  const _MonitoringContent({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'System monitoring',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        const Text('Service health and recorded processing metrics.'),
        const SizedBox(height: 16),
        for (final entry in data.entries)
          Card(
            child: ListTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: Text(_humanize(entry.key)),
              subtitle: Text(_monitorValue(entry.value)),
            ),
          ),
        if (data.isEmpty)
          const _EmptyState(
            icon: Icons.monitor_heart_outlined,
            message: 'Monitoring returned no data.',
          ),
      ],
    );
  }
}

class _SettingsContent extends StatelessWidget {
  const _SettingsContent({
    required this.user,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
    required this.onSelect,
    required this.auditPage,
  });

  final User user;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onLogout;
  final ValueChanged<_AdminSection> onSelect;
  final AdminPage? auditPage;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Workspace',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: CircleAvatar(child: Text(_initials(user.fullName))),
            title: Text(user.fullName),
            subtitle: Text('${user.email} · ${user.role}'),
          ),
        ),
        Card(
          child: SwitchListTile(
            secondary: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
            title: const Text('Dark theme'),
            value: isDarkMode,
            onChanged: (_) => onToggleTheme(),
          ),
        ),
        for (final section in [
          _AdminSection.knowledge,
          _AdminSection.users,
          _AdminSection.monitoring,
        ])
          Card(
            child: ListTile(
              leading: Icon(section.icon),
              title: Text(section.title),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => onSelect(section),
            ),
          ),
        const SizedBox(height: 12),
        Text(
          'Recent audit activity',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${auditPage?.total ?? 0} recorded admin actions.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (auditPage == null || auditPage!.items.isEmpty)
          const _EmptyState(
            icon: Icons.history_rounded,
            message: 'No audit activity has been recorded.',
          )
        else
          for (final event in auditPage!.items)
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(adminValue(event['action'])),
                subtitle: Text(
                  '${adminValue(event['actor'])} · '
                  '${adminValue(event['resource_type'])} '
                  '${adminValue(event['resource_id'])} · '
                  '${adminValue(event['created_at'])}',
                ),
                trailing: Text(adminValue(event['result'])),
              ),
            ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out of admin portal'),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(subtitle),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ActivityBars extends StatelessWidget {
  const _ActivityBars({required this.rows});

  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final recent = rows.length > 14 ? rows.sublist(rows.length - 14) : rows;
    final maxCount = recent
        .map((row) => row['count'])
        .whereType<num>()
        .fold<num>(0, (max, count) => count > max ? count : max);
    return SizedBox(
      height: 144,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final row in recent)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Tooltip(
                  message:
                      '${adminValue(row['date'])}: ${adminValue(row['count'])}',
                  child: Container(
                    height: maxCount == 0
                        ? 4
                        : 8 +
                              112 *
                                  ((row['count'] is num
                                          ? row['count'] as num
                                          : 0) /
                                      maxCount),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentItems extends StatelessWidget {
  const _RecentItems(
    this.value, {
    required this.emptyMessage,
    required this.titleField,
    required this.details,
  });

  final Object? value;
  final String emptyMessage;
  final String titleField;
  final String Function(Map<String, dynamic>) details;

  @override
  Widget build(BuildContext context) {
    final rows = value is List
        ? (value as List).whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];
    if (rows.isEmpty) return _EmptyState(message: emptyMessage);
    return Column(
      children: [
        for (final row in rows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.receipt_long_outlined),
            title: Text(adminValue(row[titleField])),
            subtitle: Text(details(row)),
            isThreeLine: true,
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              size: 34,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 44),
              const SizedBox(height: 12),
              Text(
                'Could not load this admin data',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewSubmission {
  const _ReviewSubmission({required this.decision, required this.notes});

  final String decision;
  final String notes;
}

class _ReviewDetailDialog extends StatefulWidget {
  const _ReviewDetailDialog({required this.detail, required this.canDecide});

  final Map<String, dynamic> detail;
  final bool canDecide;

  @override
  State<_ReviewDetailDialog> createState() => _ReviewDetailDialogState();
}

class _ReviewDetailDialogState extends State<_ReviewDetailDialog> {
  final _notesController = TextEditingController();
  String _decision = 'CONFIRMED_SCAM';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysis = widget.detail['analysis'] is Map
        ? Map<String, dynamic>.from(widget.detail['analysis'] as Map)
        : const <String, dynamic>{};
    final events = widget.detail['events'] is List
        ? (widget.detail['events'] as List)
              .whereType<Map<String, dynamic>>()
              .toList()
        : const <Map<String, dynamic>>[];
    final requiresNotes =
        _decision == 'UNCERTAIN' || _decision == 'INSUFFICIENT_INFORMATION';
    return AlertDialog(
      title: Text('Review case ${adminValue(widget.detail['id'])}'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailLine('Status', widget.detail['status']),
              _DetailLine('Priority', widget.detail['priority']),
              _DetailLine('Risk', analysis['risk_level']),
              _DetailLine('Classification', analysis['classification']),
              _DetailLine('Input type', analysis['input_type']),
              const SizedBox(height: 8),
              Text(
                'Submitted content',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              SelectableText(
                adminValue(analysis['original_text'] ?? analysis['content']),
              ),
              if (analysis['explanation'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Explainable analysis summary',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(adminValue(analysis['explanation'])),
              ],
              if (analysis['recommended_action'] != null) ...[
                const SizedBox(height: 8),
                _DetailLine(
                  'Recommended safe action',
                  analysis['recommended_action'],
                ),
              ],
              if (events.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Case history',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                for (final event in events)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(adminValue(event['event_type'])),
                    subtitle: Text(
                      '${adminValue(event['actor'])} · '
                      '${adminValue(event['created_at'])}\n'
                      '${adminValue(event['notes'])}',
                    ),
                  ),
              ],
              if (widget.canDecide) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _decision,
                  decoration: const InputDecoration(
                    labelText: 'Decision',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'CONFIRMED_SCAM',
                      child: Text('Confirmed scam'),
                    ),
                    DropdownMenuItem(
                      value: 'CONFIRMED_GENUINE',
                      child: Text('Confirmed genuine'),
                    ),
                    DropdownMenuItem(
                      value: 'UNCERTAIN',
                      child: Text('Uncertain'),
                    ),
                    DropdownMenuItem(
                      value: 'INSUFFICIENT_INFORMATION',
                      child: Text('Insufficient information'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _decision = value);
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _notesController,
                  onChanged: (_) => setState(() {}),
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: requiresNotes
                        ? 'Reviewer notes (required)'
                        : 'Reviewer notes',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (widget.canDecide)
          FilledButton(
            onPressed: requiresNotes && _notesController.text.trim().isEmpty
                ? null
                : () => Navigator.pop(
                    context,
                    _ReviewSubmission(
                      decision: _decision,
                      notes: _notesController.text.trim(),
                    ),
                  ),
            child: const Text('Submit decision'),
          ),
      ],
    );
  }
}

class _CommunityActionChoice {
  const _CommunityActionChoice({required this.action, required this.notes});

  final String action;
  final String notes;
}

class _CommunityReportDialog extends StatefulWidget {
  const _CommunityReportDialog({required this.report});

  final Map<String, dynamic> report;

  @override
  State<_CommunityReportDialog> createState() => _CommunityReportDialogState();
}

class _CommunityReportDialogState extends State<_CommunityReportDialog> {
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final verified = widget.report['status'] == 'VERIFIED';
    final actions = <(String, String)>[
      ('VERIFY', 'Verify report'),
      ('REJECT', 'Reject report'),
      ('NEEDS_INFORMATION', 'Request information'),
      ('ESCALATE', 'Escalate report'),
      ('RESOLVE', 'Resolve report'),
      if (verified) ('CONVERT_TO_KNOWLEDGE', 'Create knowledge draft'),
    ];
    return AlertDialog(
      title: Text('Community report ${adminValue(widget.report['id'])}'),
      content: SizedBox(
        width: 540,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailLine('Status', widget.report['status']),
              _DetailLine('Category', widget.report['category']),
              _DetailLine('Reporter', widget.report['reporter']),
              const SizedBox(height: 8),
              Text(
                adminValue(widget.report['content']),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (widget.report['description'] != null) ...[
                const SizedBox(height: 8),
                Text(adminValue(widget.report['description'])),
              ],
              if (widget.report['evidence'] != null) ...[
                const SizedBox(height: 8),
                _DetailLine('Evidence', widget.report['evidence']),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Moderator notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final action in actions)
                    OutlinedButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _CommunityActionChoice(
                          action: action.$1,
                          notes: _notesController.text.trim(),
                        ),
                      ),
                      child: Text(action.$2),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _KnowledgeAction {
  const _KnowledgeAction(this.kind);

  final String kind;
}

class _KnowledgeActionsDialog extends StatelessWidget {
  const _KnowledgeActionsDialog({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    final status = entry['status'];
    final actions = <(String, String)>[
      ('edit', 'Edit entry'),
      if (status == 'DRAFT' || status == 'PENDING')
        ('publish', 'Publish and index'),
      if (status == 'APPROVED' || status == 'ACTIVE') ('reindex', 'Reindex'),
      if (status != 'INACTIVE') ('archive', 'Archive'),
    ];
    return AlertDialog(
      title: Text(adminValue(entry['title'])),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status: ${adminValue(status)}\n\n'
            '${adminValue(entry['description'])}\n\n'
            'Source: ${adminValue(entry['source'])}',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final action in actions)
                OutlinedButton(
                  onPressed: () =>
                      Navigator.pop(context, _KnowledgeAction(action.$1)),
                  child: Text(action.$2),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _KnowledgeEditorDialog extends StatefulWidget {
  const _KnowledgeEditorDialog({this.entry});

  final Map<String, dynamic>? entry;

  @override
  State<_KnowledgeEditorDialog> createState() => _KnowledgeEditorDialogState();
}

class _KnowledgeEditorDialogState extends State<_KnowledgeEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _pattern;
  late final TextEditingController _category;
  late final TextEditingController _description;
  late final TextEditingController _indicators;
  late final TextEditingController _example;
  late final TextEditingController _safeAction;
  late final TextEditingController _source;
  late String _riskLevel;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry ?? const <String, dynamic>{};
    _title = TextEditingController(text: entry['title']?.toString() ?? '');
    _pattern = TextEditingController(text: entry['pattern']?.toString() ?? '');
    _category = TextEditingController(
      text: entry['category']?.toString() ?? '',
    );
    _description = TextEditingController(
      text: entry['description']?.toString() ?? '',
    );
    final indicators = entry['indicators'];
    _indicators = TextEditingController(
      text: indicators is List ? indicators.join(', ') : '',
    );
    _example = TextEditingController(text: entry['example']?.toString() ?? '');
    _safeAction = TextEditingController(
      text: entry['safe_action']?.toString() ?? '',
    );
    _source = TextEditingController(
      text: entry['source']?.toString() ?? 'Admin',
    );
    final risk = entry['risk_level']?.toString().toUpperCase();
    _riskLevel = const {'LOW', 'MEDIUM', 'HIGH', 'CRITICAL'}.contains(risk)
        ? risk!
        : 'HIGH';
  }

  @override
  void dispose() {
    for (final controller in [
      _title,
      _pattern,
      _category,
      _description,
      _indicators,
      _example,
      _safeAction,
      _source,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.entry == null
            ? 'Create knowledge draft'
            : 'Edit knowledge entry',
      ),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _title,
                  validator: _required,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextFormField(
                  controller: _pattern,
                  validator: _required,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Pattern / content',
                  ),
                ),
                TextFormField(
                  controller: _category,
                  validator: _required,
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _riskLevel,
                  decoration: const InputDecoration(labelText: 'Risk level'),
                  items: const [
                    DropdownMenuItem(value: 'LOW', child: Text('Low')),
                    DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                    DropdownMenuItem(value: 'HIGH', child: Text('High')),
                    DropdownMenuItem(
                      value: 'CRITICAL',
                      child: Text('Critical'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => _riskLevel = value);
                  },
                ),
                TextFormField(
                  controller: _description,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextFormField(
                  controller: _indicators,
                  decoration: const InputDecoration(
                    labelText: 'Indicators (comma-separated)',
                  ),
                ),
                TextFormField(
                  controller: _example,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Example'),
                ),
                TextFormField(
                  controller: _safeAction,
                  validator: _required,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Safe action'),
                ),
                TextFormField(
                  controller: _source,
                  decoration: const InputDecoration(labelText: 'Source'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, <String, dynamic>{
              'title': _title.text.trim(),
              'pattern': _pattern.text.trim(),
              'category': _category.text.trim(),
              'risk_level': _riskLevel,
              'description': _description.text.trim(),
              'indicators': _indicators.text
                  .split(',')
                  .map((value) => value.trim())
                  .where((value) => value.isNotEmpty)
                  .toList(),
              'example': _example.text.trim(),
              'safe_action': _safeAction.text.trim(),
              'source': _source.text.trim().isEmpty
                  ? 'Admin'
                  : _source.text.trim(),
            });
          },
          child: const Text('Save draft'),
        ),
      ],
    );
  }
}

class _UserDetailDialog extends StatelessWidget {
  const _UserDetailDialog({required this.data, required this.currentAdminId});

  final Map<String, dynamic> data;
  final int currentAdminId;

  @override
  Widget build(BuildContext context) {
    final user = data['user'] is Map
        ? Map<String, dynamic>.from(data['user'] as Map)
        : const <String, dynamic>{};
    final recent = data['recent_analyses'] is List
        ? (data['recent_analyses'] as List)
              .whereType<Map<String, dynamic>>()
              .toList()
        : const <Map<String, dynamic>>[];
    final active = user['is_active'] == true;
    final self = user['id'] == currentAdminId;
    return AlertDialog(
      title: Text(adminValue(user['full_name'])),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _DetailLine('Email', user['email']),
              _DetailLine('Role', user['role']),
              _DetailLine('Status', active ? 'Active' : 'Disabled'),
              _DetailLine('Created', user['created_at']),
              _DetailLine('Analysis count', data['analysis_count']),
              const SizedBox(height: 10),
              Text(
                'Recent analyses',
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (recent.isEmpty)
                const Text('No recent analyses.')
              else
                for (final analysis in recent)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${adminValue(analysis['classification'])} · '
                      '${adminValue(analysis['risk_level'])}',
                    ),
                    subtitle: Text(
                      '${adminValue(analysis['input_type'])} · '
                      '${adminValue(analysis['created_at'])}',
                    ),
                  ),
              if (self)
                const Text('Your own admin account cannot be disabled.'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        FilledButton.tonal(
          onPressed: self && active
              ? null
              : () => Navigator.pop(context, !active),
          child: Text(active ? 'Disable account' : 'Enable account'),
        ),
      ],
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.label, this.value);

  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Text('$label: ${adminValue(value)}'),
  );
}

extension on _AdminSection {
  String get title => switch (this) {
    _AdminSection.overview => 'Overview',
    _AdminSection.reviews => 'Human Review',
    _AdminSection.community => 'Community',
    _AdminSection.knowledge => 'Knowledge Base',
    _AdminSection.users => 'Users',
    _AdminSection.monitoring => 'Monitoring',
    _AdminSection.settings => 'Settings',
  };

  IconData get icon => switch (this) {
    _AdminSection.overview => Icons.dashboard_outlined,
    _AdminSection.reviews => Icons.rate_review_outlined,
    _AdminSection.community => Icons.groups_outlined,
    _AdminSection.knowledge => Icons.menu_book_outlined,
    _AdminSection.users => Icons.people_outline_rounded,
    _AdminSection.monitoring => Icons.monitor_heart_outlined,
    _AdminSection.settings => Icons.settings_outlined,
  };
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _humanize(String value) => value
    .replaceAll('_', ' ')
    .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}');

String _monitorValue(Object? value) {
  if (value == null) return 'Not reported';
  if (value is Map) {
    return value.entries
        .map(
          (entry) =>
              '${_humanize(entry.key.toString())}: ${adminValue(entry.value)}',
        )
        .join(' · ');
  }
  if (value is List) return '${value.length} items reported';
  return adminValue(value);
}
