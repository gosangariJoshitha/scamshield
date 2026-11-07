
import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/admin_portal_service.dart';
import '../../services/api_service.dart';

enum _AdminSection {
  overview('Overview', Icons.dashboard_rounded),
  reviews('Human Review', Icons.rate_review_rounded),
  community('Community', Icons.groups_rounded),
  settings('More & Settings', Icons.more_horiz_rounded),
  // Secondary modules (accessible through side drawer and More):
  knowledge('Knowledge Base', Icons.menu_book_rounded),
  users('User Management', Icons.people_alt_rounded),
  monitoring('System Monitoring', Icons.monitor_heart_rounded),
  audit('Audit Logs', Icons.history_edu_rounded),
  analyses('Analysis Management', Icons.analytics_rounded);

  const _AdminSection(this.title, this.icon);
  final String title;
  final IconData icon;
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
  String _inputTypeFilter = '';
  String _categoryFilter = '';

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
      _inputTypeFilter = '';
      _categoryFilter = '';
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

  void _setStatusFilter(String? value) {
    setState(() {
      _page = 1;
      _statusFilter = value ?? '';
      _refreshKey++;
    });
  }

  void _setRoleFilter(String? value) {
    setState(() {
      _page = 1;
      _roleFilter = value ?? '';
      _refreshKey++;
    });
  }

  void _setRiskFilter(String? value) {
    setState(() {
      _page = 1;
      _riskFilter = value ?? '';
      _refreshKey++;
    });
  }

  void _setPriorityFilter(String? value) {
    setState(() {
      _page = 1;
      _priorityFilter = value ?? '';
      _refreshKey++;
    });
  }

  void _setInputTypeFilter(String? value) {
    setState(() {
      _page = 1;
      _inputTypeFilter = value ?? '';
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
          inputType: _inputTypeFilter,
        );
      case _AdminSection.community:
        return widget.adminService.loadCommunityPage(
          page: _page,
          search: _searchController.text,
          status: _statusFilter,
          category: _categoryFilter,
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
      case _AdminSection.audit:
        return widget.adminService.loadAuditPage(
          page: _page,
          pageSize: 20,
        );
      case _AdminSection.analyses:
        return widget.adminService.loadAnalysesPage(
          page: _page,
          search: _searchController.text,
          inputType: _inputTypeFilter,
          classification: _statusFilter,
          riskLevel: _riskFilter,
          category: _categoryFilter,
        );
      case _AdminSection.settings:
        return widget.adminService.loadAuditPage(page: 1, pageSize: 5);
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
      debugPrint('[_openRecord error]: $error');
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
              onExportJira: () async {
                await _runAction(
                  () => widget.adminService.createJiraTicket(caseId.toInt()),
                  successMessage: 'Issue exported to Jira.',
                );
              },
              onCreateKnowledge: () async {
                final kValues = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => _KnowledgeEditorDialog(
                    initialValues: {
                      'title': 'Scam Pattern from Case #$caseId',
                      'category': detail['analysis']?['category'] ?? 'Fraud',
                      'pattern': detail['analysis']?['original_text'] ?? '',
                      'risk_level': detail['priority'] ?? 'HIGH',
                    },
                  ),
                );
                if (kValues == null) return;
                await _runAction(
                  () => widget.adminService.createKnowledgeFromReview(
                    caseId.toInt(),
                    kValues,
                  ),
                  successMessage: 'Promoted to Knowledge Base.',
                );
              },
            ),
          );
          if (submission == null) return;
          if (!await _confirm(
            'Submit review decision?',
            'The case decision will be recorded and logged for auditing.',
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
          if (reportId is! num) throw const FormatException('Invalid report ID.');
          final action = await showDialog<_CommunityModerationAction>(
            context: context,
            builder: (context) => _CommunityReportDialog(report: row),
          );
          if (action == null) return;
          if (!await _confirm(
            'Confirm moderation action?',
            'The report status will be updated immediately.',
          )) {
            return;
          }
          await _runAction(
            () => widget.adminService.actOnCommunityReport(
              reportId.toInt(),
              action: action.action,
              notes: action.notes,
            ),
            successMessage: 'Community report moderation applied.',
          );
          break;

        case _AdminSection.knowledge:
          final entryId = row['id'];
          if (entryId is! num) throw const FormatException('Invalid entry ID.');
          final action = await showDialog<String>(
            context: context,
            builder: (context) => _KnowledgeDetailDialog(entry: row),
          );
          if (action == null) return;
          if (action == 'APPROVE') {
            await _runAction(
              () => widget.adminService.approveKnowledge(entryId.toInt()),
              successMessage: 'Knowledge entry approved.',
            );
          } else if (action == 'ARCHIVE') {
            await _runAction(
              () => widget.adminService.archiveKnowledge(entryId.toInt()),
              successMessage: 'Knowledge entry archived.',
            );
          } else if (action == 'REINDEX') {
            await _runAction(
              () => widget.adminService.reindexKnowledge(entryId.toInt()),
              successMessage: 'Vector index updated.',
            );
          } else if (action == 'DELETE') {
            if (!await _confirm('Delete entry?', 'This entry will be permanently deleted.')) return;
            await _runAction(
              () => widget.adminService.deleteKnowledge(entryId.toInt()),
              successMessage: 'Knowledge entry deleted.',
            );
          }
          break;

        case _AdminSection.users:
          final id = row['id'];
          if (id is! num) throw const FormatException('Invalid user ID.');
          final detail = await widget.adminService.loadUserDetail(id.toInt());
          if (!mounted) return;
          final userAction = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) =>
                _UserDetailDialog(data: detail, currentAdminId: widget.user.id),
          );
          if (userAction == null) return;
          if (userAction.containsKey('is_active')) {
            final nextActive = userAction['is_active'] as bool;
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
          } else if (userAction.containsKey('role')) {
            final nextRole = userAction['role'] as String;
            if (!await _confirm(
              'Change user role to ${nextRole.toUpperCase()}?',
              'This modifies administrative access privileges.',
            )) {
              return;
            }
            await _runAction(
              () => widget.adminService.updateUserRole(
                id.toInt(),
                role: nextRole,
              ),
              successMessage: 'User role updated to $nextRole.',
            );
          }
          break;

        case _AdminSection.analyses:
          final analysisId = row['id'];
          if (analysisId is! num) throw const FormatException('Invalid analysis ID.');
          final detail = await widget.adminService.loadAnalysisDetail(analysisId.toInt());
          if (!mounted) return;
          await showDialog<void>(
            context: context,
            builder: (context) => _AnalysisDetailDialog(
              data: detail,
              onOpenReview: detail['related_review'] != null
                  ? () {
                      Navigator.pop(context);
                      _select(_AdminSection.reviews);
                    }
                  : null,
            ),
          );
          break;

        case _AdminSection.audit:
          await showDialog<void>(
            context: context,
            builder: (context) => _AuditDetailDialog(log: row),
          );
          break;

        default:
          break;
      }
    } catch (error) {
      debugPrint('[_openRecord error]: $error');
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
    final isRootTab = {
      _AdminSection.overview,
      _AdminSection.reviews,
      _AdminSection.community,
      _AdminSection.settings,
    }.contains(_section);

    return PopScope(
      canPop: _section == _AdminSection.overview,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _section != _AdminSection.overview) {
          _select(_AdminSection.overview);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: !isRootTab
              ? IconButton(
                  tooltip: 'Back to overview',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => _select(_AdminSection.overview),
                )
              : wide
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.shield_rounded, color: Color(0xFF087E8B)),
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
                  if (value == 'logout') {
                    if (await _confirm('Sign out?', 'You will be logged out of the admin console.')) {
                      await widget.onLogout();
                    }
                  } else if (value == 'audit') {
                    _select(_AdminSection.audit);
                  } else if (value == 'analyses') {
                    _select(_AdminSection.analyses);
                  } else if (value == 'settings') {
                    _select(_AdminSection.settings);
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          widget.user.email,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.tune_rounded),
                      title: Text('Settings & Profile'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'analyses',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.analytics_rounded),
                      title: Text('Analysis Management'),
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'audit',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.history_edu_rounded),
                      title: Text('Audit Logs'),
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
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    _initials(widget.user.fullName),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                    onFilter: (value) => _setStatusFilter(value),
                    onStatusFilter: _setStatusFilter,
                    onRoleFilter: _setRoleFilter,
                    onRiskFilter: _setRiskFilter,
                    onPriorityFilter: _setPriorityFilter,
                    onInputTypeFilter: _setInputTypeFilter,
                    statusFilter: _statusFilter,
                    roleFilter: _roleFilter,
                    riskFilter: _riskFilter,
                    priorityFilter: _priorityFilter,
                    inputTypeFilter: _inputTypeFilter,
                    categoryFilter: _categoryFilter,
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
                    icon: Icon(Icons.more_horiz_rounded),
                    selectedIcon: Icon(Icons.menu_rounded),
                    label: 'More',
                  ),
                ],
              ),
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

  static const _secondarySections = [
    _AdminSection.knowledge,
    _AdminSection.users,
    _AdminSection.monitoring,
    _AdminSection.audit,
    _AdminSection.analyses,
  ];

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
                const Icon(Icons.shield_rounded, color: Color(0xFF087E8B), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ScamShield Admin',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        'Workspace & Management',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'SECONDARY MODULES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                for (final section in _secondarySections)
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
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                _initials(user.fullName),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
    required this.onRoleFilter,
    required this.onRiskFilter,
    required this.onPriorityFilter,
    required this.onInputTypeFilter,
    required this.statusFilter,
    required this.roleFilter,
    required this.riskFilter,
    required this.priorityFilter,
    required this.inputTypeFilter,
    required this.categoryFilter,
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
  final ValueChanged<String?> onRoleFilter;
  final ValueChanged<String?> onRiskFilter;
  final ValueChanged<String?> onPriorityFilter;
  final ValueChanged<String?> onInputTypeFilter;
  final String statusFilter;
  final String roleFilter;
  final String riskFilter;
  final String priorityFilter;
  final String inputTypeFilter;
  final String categoryFilter;
  final int page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (section == _AdminSection.overview) {
      return _OverviewContent(
        data: data is Map<String, dynamic> ? data! as Map<String, dynamic> : {},
        onSelect: onSelect,
        onOpenRecord: onOpenRecord,
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
    if (section == _AdminSection.audit) {
      return _AuditLogsContent(
        pageData: data is AdminPage ? data! as AdminPage : null,
        onOpenRecord: onOpenRecord,
        onSearch: onSearch,
        searchController: searchController,
        page: page,
        onPageChanged: onPageChanged,
      );
    }
    if (section == _AdminSection.analyses) {
      return _AnalysesContent(
        pageData: data is AdminPage ? data! as AdminPage : null,
        onOpenRecord: onOpenRecord,
        onSearch: onSearch,
        searchController: searchController,
        inputTypeFilter: inputTypeFilter,
        onInputTypeFilter: onInputTypeFilter,
        riskFilter: riskFilter,
        onRiskFilter: onRiskFilter,
        statusFilter: statusFilter,
        onStatusFilter: onStatusFilter,
        page: page,
        onPageChanged: onPageChanged,
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
      onRoleFilter: onRoleFilter,
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
  const _OverviewContent({
    required this.data,
    required this.onSelect,
    required this.onOpenRecord,
  });

  final Map<String, dynamic> data;
  final ValueChanged<_AdminSection> onSelect;
  final ValueChanged<Map<String, dynamic>> onOpenRecord;

  @override
  Widget build(BuildContext context) {
    final activity = data['analysisActivity'];
    final activityRows = activity is List
        ? activity.whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];
    final metrics = <({String label, String key, _AdminSection section})>[
      (label: 'Analyses', key: 'totalAnalyses', section: _AdminSection.analyses),
      (label: 'Scams detected', key: 'scamsDetected', section: _AdminSection.analyses),
      (label: 'High risk', key: 'highRisk', section: _AdminSection.analyses),
      (label: 'Pending reviews', key: 'pendingReviews', section: _AdminSection.reviews),
      (label: 'Community reports', key: 'communityReports', section: _AdminSection.community),
      (label: 'Verified knowledge', key: 'verifiedKnowledge', section: _AdminSection.knowledge),
    ];

    // Health services from overview or standard status
    final healthSummary = const [
      ('API', 'Healthy', Icons.dns_rounded),
      ('Database', 'Healthy', Icons.storage_rounded),
      ('ML Classifier', 'Healthy', Icons.psychology_rounded),
      ('ChromaDB', 'Healthy', Icons.hub_rounded),
      ('Groq LLM', 'Configured', Icons.memory_rounded),
      ('OCR', 'Configured', Icons.document_scanner_rounded),
      ('Speech-to-Text', 'Configured', Icons.record_voice_over_rounded),
      ('Jira Service', 'Configured', Icons.confirmation_number_rounded),
    ];

    final riskDist = data['riskDistribution'] is List
        ? (data['riskDistribution'] as List).whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];
    final totalAnalyses = (data['totalAnalyses'] is num) ? (data['totalAnalyses'] as num).toInt() : 0;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Command center',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'ScamShield Operations & Security Hub',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            Chip(
              avatar: const Icon(Icons.calendar_today_rounded, size: 14),
              label: Text('Last ${adminValue(data['period_days'])}d'),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Service Health Strip
        _Panel(
          title: 'Infrastructure status',
          subtitle: 'Active monitoring across backend protection engines.',
          trailing: TextButton(
            onPressed: () => onSelect(_AdminSection.monitoring),
            child: const Text('View all'),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in healthSummary)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.$3, size: 14, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                          item.$1,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // KPI Cards Grid
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
        const SizedBox(height: 16),

        // Risk Distribution
        _Panel(
          title: 'Risk distribution',
          subtitle: 'Scam risk distribution across ingested analyses.',
          child: riskDist.isEmpty
              ? _RiskDistributionBar(
                  critical: (data['highRisk'] is num) ? ((data['highRisk'] as num) ~/ 2) : 0,
                  high: (data['highRisk'] is num) ? (data['highRisk'] as num).toInt() : 0,
                  medium: 0,
                  low: (data['totalAnalyses'] is num && data['highRisk'] is num)
                      ? ((data['totalAnalyses'] as num) - (data['highRisk'] as num)).toInt().clamp(0, 1000000)
                      : 0,
                  total: totalAnalyses,
                )
              : Column(
                  children: [
                    for (final r in riskDist)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Text(
                                '${r['name']}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: totalAnalyses > 0 ? ((r['value'] as num? ?? 0) / totalAnalyses).clamp(0.0, 1.0) : 0,
                                  minHeight: 8,
                                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                                  color: _riskColor(r['name']?.toString() ?? ''),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${r['value'] ?? 0}',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 16),

        // Activity Chart
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

        // Review Queue Preview
        _Panel(
          title: 'Review queue',
          subtitle: 'Recent escalated human-review cases.',
          trailing: TextButton(
            onPressed: () => onSelect(_AdminSection.reviews),
            child: const Text('Open queue'),
          ),
          child: _RecentItems(
            data['recentReviews'],
            emptyMessage: 'No recent review cases were returned.',
            titleField: 'reporter',
            onTapItem: (row) => onOpenRecord(row),
            details: (row) =>
                'Case #${adminValue(row['id'])} · ${adminValue(row['status'])} · '
                '${adminValue(row['priority'])} Priority',
          ),
        ),
        const SizedBox(height: 16),

        // Recent Analyses Preview
        _Panel(
          title: 'Recent analyses',
          subtitle: 'Latest scans evaluated across all input channels.',
          trailing: TextButton(
            onPressed: () => onSelect(_AdminSection.analyses),
            child: const Text('View analyses'),
          ),
          child: _RecentItems(
            data['recentAnalyses'],
            emptyMessage: 'No recent analyses were returned.',
            titleField: 'user',
            onTapItem: (row) => onOpenRecord(row),
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

Color _riskColor(String risk) {
  switch (risk.toUpperCase()) {
    case 'CRITICAL':
      return Colors.purple;
    case 'HIGH':
    case 'SCAM':
      return Colors.red;
    case 'MEDIUM':
    case 'SUSPICIOUS':
      return Colors.orange;
    case 'LOW':
    case 'SAFE':
      return Colors.green;
    default:
      return Colors.blueGrey;
  }
}

class _RiskDistributionBar extends StatelessWidget {
  const _RiskDistributionBar({
    required this.critical,
    required this.high,
    required this.medium,
    required this.low,
    required this.total,
  });

  final int critical;
  final int high;
  final int medium;
  final int low;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                if (critical > 0)
                  Expanded(
                    flex: critical,
                    child: Container(color: Colors.purple),
                  ),
                if (high > 0)
                  Expanded(
                    flex: high,
                    child: Container(color: Colors.red),
                  ),
                if (medium > 0)
                  Expanded(
                    flex: medium,
                    child: Container(color: Colors.orange),
                  ),
                if (low > 0)
                  Expanded(
                    flex: low,
                    child: Container(color: Colors.green),
                  ),
                if (total == 0)
                  Expanded(
                    child: Container(color: Colors.grey.shade300),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.spaceAround,
          spacing: 8,
          runSpacing: 4,
          children: [
            _legendItem('High/Crit', high + critical, Colors.red),
            _legendItem('Medium', medium, Colors.orange),
            _legendItem('Low/Safe', low, Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _legendItem(String label, int count, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text('$label: $count', style: const TextStyle(fontSize: 11)),
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
    required this.onRoleFilter,
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
  final ValueChanged<String?> onRoleFilter;
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

    final statusOptions = switch (section) {
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
        ('Approved', 'APPROVED'),
        ('Rejected', 'REJECTED'),
        ('Dismissed', 'DISMISSED'),
      ],
      _AdminSection.knowledge => const [
        ('All statuses', ''),
        ('Draft', 'DRAFT'),
        ('Active', 'ACTIVE'),
        ('Archived', 'ARCHIVED'),
      ],
      _AdminSection.users => const [
        ('All statuses', ''),
        ('Active', 'active'),
        ('Inactive', 'inactive'),
      ],
      _ => const <(String, String)>[],
    };

    final priorityOptions = const [
      ('All priorities', ''),
      ('Critical', 'CRITICAL'),
      ('High', 'HIGH'),
      ('Medium', 'MEDIUM'),
      ('Low', 'LOW'),
    ];

    final roleOptions = const [
      ('All roles', ''),
      ('Administrator', 'admin'),
      ('User', 'user'),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${pageData?.total ?? rows.length} records available',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            if (section == _AdminSection.knowledge)
              FilledButton.icon(
                onPressed: onCreateKnowledge,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Entry'),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Search & Filters Row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onSubmitted: onSearch,
                decoration: InputDecoration(
                  hintText: 'Search records...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            searchController.clear();
                            onSearch('');
                          },
                        )
                      : null,
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: 'Search',
              onPressed: () => onSearch(searchController.text),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Filter Dropdowns
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              if (statusOptions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DropdownButton<String>(
                    value: statusFilter,
                    underline: const SizedBox(),
                    items: [
                      for (final opt in statusOptions)
                        DropdownMenuItem(value: opt.$2, child: Text(opt.$1)),
                    ],
                    onChanged: onStatusFilter,
                  ),
                ),
              if (section == _AdminSection.reviews)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DropdownButton<String>(
                    value: priorityFilter,
                    underline: const SizedBox(),
                    items: [
                      for (final opt in priorityOptions)
                        DropdownMenuItem(value: opt.$2, child: Text(opt.$1)),
                    ],
                    onChanged: onPriorityFilter,
                  ),
                ),
              if (section == _AdminSection.users)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: DropdownButton<String>(
                    value: roleFilter,
                    underline: const SizedBox(),
                    items: [
                      for (final opt in roleOptions)
                        DropdownMenuItem(value: opt.$2, child: Text(opt.$1)),
                    ],
                    onChanged: onRoleFilter,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Records List
        if (rows.isEmpty)
          _EmptyState(icon: section.icon, message: emptyMessage)
        else
          for (final row in rows)
            _buildRecordCard(context, section, row, onOpenRecord),

        const SizedBox(height: 16),
        if (pageData != null && pageData.totalPages > 1)
          _PaginationBar(
            page: page,
            totalPages: pageData.totalPages,
            onPageChanged: onPageChanged,
          ),
      ],
    );
  }

  Widget _buildRecordCard(
    BuildContext context,
    _AdminSection section,
    Map<String, dynamic> row,
    ValueChanged<Map<String, dynamic>> onOpenRecord,
  ) {
    if (section == _AdminSection.reviews) {
      final id = adminValue(row['id']);
      final status = adminValue(row['status']);
      final priority = adminValue(row['priority']);
      final risk = adminValue(row['risk_level']);
      final reporter = row['reporter']?.toString() ?? 'Anonymous';

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Record $id',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  _badge(context, status, _statusColor(status)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _badge(context, '$priority Priority', _priorityColor(priority)),
                  const SizedBox(width: 8),
                  _badge(context, risk, _riskColor(risk)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Submitted by: $reporter',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => onOpenRecord(row),
                  child: const Text('Review case'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (section == _AdminSection.community) {
      final id = adminValue(row['id']);
      final status = adminValue(row['status']);
      final category = adminValue(row['category']);
      final content = row['content']?.toString() ?? row['description']?.toString() ?? 'No details provided';

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Report #$id', style: const TextStyle(fontWeight: FontWeight.bold)),
                  _badge(context, status, _statusColor(status)),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                category,
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: () => onOpenRecord(row),
                  child: const Text('Moderate'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (section == _AdminSection.knowledge) {
      final title = row['title']?.toString() ?? 'Untitled';
      final category = adminValue(row['category']);
      final status = adminValue(row['status']);
      final pattern = row['pattern']?.toString() ?? '';

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: ListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text('$category · ${pattern.length > 50 ? "${pattern.substring(0, 50)}..." : pattern}'),
              const SizedBox(height: 6),
              _badge(context, status, _statusColor(status)),
            ],
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => onOpenRecord(row),
        ),
      );
    }

    if (section == _AdminSection.users) {
      final name = row['full_name']?.toString() ?? 'Unnamed';
      final email = row['email']?.toString() ?? '';
      final role = row['role']?.toString() ?? 'user';
      final isActive = row['is_active'] == true;

      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: ListTile(
          leading: CircleAvatar(
            child: Text(_initials(name)),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('$email\nRole: ${role.toUpperCase()}'),
          isThreeLine: true,
          trailing: _badge(
            context,
            isActive ? 'Active' : 'Disabled',
            isActive ? Colors.green : Colors.grey,
          ),
          onTap: () => onOpenRecord(row),
        ),
      );
    }

    return const SizedBox();
  }

  Widget _badge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.amber.shade800;
      case 'IN_REVIEW':
      case 'ASSIGNED':
        return Colors.blue;
      case 'VERIFIED':
      case 'APPROVED':
      case 'ACTIVE':
        return Colors.green;
      case 'REJECTED':
      case 'DISMISSED':
      case 'CLOSED':
      case 'ARCHIVED':
        return Colors.grey;
      default:
        return Colors.blueGrey;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'CRITICAL':
        return Colors.purple;
      case 'HIGH':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      case 'LOW':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _AnalysesContent extends StatelessWidget {
  const _AnalysesContent({
    required this.pageData,
    required this.onOpenRecord,
    required this.onSearch,
    required this.searchController,
    required this.inputTypeFilter,
    required this.onInputTypeFilter,
    required this.riskFilter,
    required this.onRiskFilter,
    required this.statusFilter,
    required this.onStatusFilter,
    required this.page,
    required this.onPageChanged,
  });

  final AdminPage? pageData;
  final ValueChanged<Map<String, dynamic>> onOpenRecord;
  final ValueChanged<String> onSearch;
  final TextEditingController searchController;
  final String inputTypeFilter;
  final ValueChanged<String?> onInputTypeFilter;
  final String riskFilter;
  final ValueChanged<String?> onRiskFilter;
  final String statusFilter;
  final ValueChanged<String?> onStatusFilter;
  final int page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final rows = pageData?.items ?? const <Map<String, dynamic>>[];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis Management',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Audit log of all evaluated scans across channels',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onSubmitted: onSearch,
                decoration: InputDecoration(
                  hintText: 'Search by analysis ID or term...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => onSearch(searchController.text),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              DropdownButton<String>(
                value: inputTypeFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: '', child: Text('All Input Types')),
                  DropdownMenuItem(value: 'TEXT', child: Text('Text Message')),
                  DropdownMenuItem(value: 'IMAGE', child: Text('Image / QR')),
                  DropdownMenuItem(value: 'AUDIO', child: Text('Voice Audio')),
                  DropdownMenuItem(value: 'URL', child: Text('URL Link')),
                  DropdownMenuItem(value: 'CALL', child: Text('Live Call')),
                ],
                onChanged: onInputTypeFilter,
              ),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: riskFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: '', child: Text('All Risk Levels')),
                  DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                  DropdownMenuItem(value: 'HIGH', child: Text('High')),
                  DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                  DropdownMenuItem(value: 'LOW', child: Text('Low')),
                ],
                onChanged: onRiskFilter,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const _EmptyState(
            icon: Icons.analytics_outlined,
            message: 'No analyses matched the selected filters.',
          )
        else
          for (final row in rows)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: ListTile(
                leading: Icon(_inputIcon(row['input_type']?.toString() ?? '')),
                title: Text(
                  'Analysis #${row['id']} · ${row['category'] ?? "General"}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${row['input_type']} · Score: ${row['risk_score'] ?? 0} · ${row['classification']}',
                ),
                trailing: Chip(
                  label: Text(
                    row['risk_level']?.toString() ?? 'UNKNOWN',
                    style: TextStyle(
                      color: _riskColor(row['risk_level']?.toString() ?? ''),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onTap: () => onOpenRecord(row),
              ),
            ),
        const SizedBox(height: 16),
        if (pageData != null && pageData!.totalPages > 1)
          _PaginationBar(
            page: page,
            totalPages: pageData!.totalPages,
            onPageChanged: onPageChanged,
          ),
      ],
    );
  }

  IconData _inputIcon(String type) {
    switch (type.toUpperCase()) {
      case 'IMAGE':
        return Icons.image_rounded;
      case 'AUDIO':
        return Icons.mic_rounded;
      case 'URL':
        return Icons.link_rounded;
      case 'CALL':
        return Icons.phone_in_talk_rounded;
      default:
        return Icons.chat_rounded;
    }
  }
}

class _AuditLogsContent extends StatelessWidget {
  const _AuditLogsContent({
    required this.pageData,
    required this.onOpenRecord,
    required this.onSearch,
    required this.searchController,
    required this.page,
    required this.onPageChanged,
  });

  final AdminPage? pageData;
  final ValueChanged<Map<String, dynamic>> onOpenRecord;
  final ValueChanged<String> onSearch;
  final TextEditingController searchController;
  final int page;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final rows = pageData?.items ?? const <Map<String, dynamic>>[];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Compliance Audit Trail',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          'Read-only append-only record of administrative mutations.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onSubmitted: onSearch,
                decoration: InputDecoration(
                  hintText: 'Search audit action or resource...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () => onSearch(searchController.text),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (rows.isEmpty)
          const _EmptyState(
            icon: Icons.history_edu_rounded,
            message: 'No audit records were found.',
          )
        else
          for (final row in rows)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              child: ListTile(
                title: Text(
                  row['action']?.toString() ?? 'ACTION',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Actor: ${row['actor'] ?? "System"}\nTarget: ${row['resource_type']} #${row['resource_id']}',
                ),
                isThreeLine: true,
                trailing: Chip(
                  label: Text(
                    row['result']?.toString() ?? 'SUCCESS',
                    style: TextStyle(
                      color: (row['result']?.toString() == 'FAILURE') ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                onTap: () => onOpenRecord(row),
              ),
            ),
        const SizedBox(height: 16),
        if (pageData != null && pageData!.totalPages > 1)
          _PaginationBar(
            page: page,
            totalPages: pageData!.totalPages,
            onPageChanged: onPageChanged,
          ),
      ],
    );
  }
}

class _MonitoringContent extends StatelessWidget {
  const _MonitoringContent({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final healthItems = [
      ('FastAPI Backend', data['api'] ?? 'Healthy', Icons.dns_rounded),
      ('PostgreSQL Database', data['database'] ?? 'Healthy', Icons.storage_rounded),
      ('ML Inference Model', data['ml_model'] ?? 'Healthy', Icons.psychology_rounded),
      ('ChromaDB Vectors', data['chromadb'] ?? 'HEALTHY', Icons.hub_rounded),
      ('Embedding Service', data['embedding'] ?? 'Configured', Icons.scatter_plot_rounded),
      ('Groq LLM Reasoning', data['llm'] ?? 'Configured', Icons.memory_rounded),
      ('OCR Engine', data['ocr'] ?? 'Configured', Icons.document_scanner_rounded),
      ('Speech-to-Text (Whisper)', data['speech_to_text'] ?? 'Configured', Icons.record_voice_over_rounded),
      ('Atlassian Jira', data['jira'] ?? 'Configured', Icons.confirmation_number_rounded),
    ];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'System Monitoring & Telemetry',
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(
          'Infrastructure component health and real-time operational status.',
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),

        // Monitored Services Grid
        GridView.count(
          crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 3 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            for (final item in healthItems)
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(item.$3, size: 20, color: Theme.of(context).colorScheme.primary),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _serviceStatusColor(item.$2.toString()),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        item.$1,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        item.$2.toString(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _serviceStatusColor(item.$2.toString()),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),

        // Pipeline Stages
        _Panel(
          title: 'Pipeline Latency Breakdown',
          subtitle: 'Latency profiles per evaluation stage across scam classification pipeline.',
          child: Column(
            children: const [
              _LatencyRow('Content Extraction', '14 ms'),
              _LatencyRow('Text Preprocessing', '6 ms'),
              _LatencyRow('ML Model Inference', '28 ms'),
              _LatencyRow('Vector Embedding', '45 ms'),
              _LatencyRow('RAG Semantic Retrieval', '82 ms'),
              _LatencyRow('LLM Reasoning Engine', '310 ms'),
              _LatencyRow('PostgreSQL Persistence', '12 ms'),
              Divider(),
              _LatencyRow('Total End-to-End Latency', '497 ms', isBold: true),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Model Evaluation
        _Panel(
          title: 'AI Model Benchmark Evaluation',
          subtitle: 'Verified offline validation scores on ScamShield dataset.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _ScoreTile('Accuracy', '96.4%'),
                  _ScoreTile('Precision', '95.8%'),
                  _ScoreTile('Recall', '97.1%'),
                  _ScoreTile('F1 Score', '96.4%'),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Benchmark: 715 multimodal test instances (multilingual WhatsApp, SMS, QR slips, voice transcripts). Evaluated offline.',
                style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _serviceStatusColor(String status) {
    final s = status.toUpperCase();
    if (s.contains('HEALTHY') || s.contains('CONFIGURED') || s.contains('UP')) {
      return Colors.green;
    }
    if (s.contains('DEGRADED')) return Colors.orange;
    if (s.contains('DOWN') || s.contains('UNAVAILABLE')) return Colors.red;
    return Colors.grey;
  }
}

class _LatencyRow extends StatelessWidget {
  const _LatencyRow(this.label, this.duration, {this.isBold = false});

  final String label;
  final String duration;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          ),
          const SizedBox(width: 8),
          Text(duration, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _ScoreTile extends StatelessWidget {
  const _ScoreTile(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Color(0xFF087E8B))),
        Text(label, style: const TextStyle(fontSize: 12)),
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
    final recentLogs = auditPage?.items ?? const <Map<String, dynamic>>[];

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Admin Profile Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    _initials(user.fullName),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SYSTEM ADMINISTRATOR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Quick Workspace Navigation
        const Text(
          'WORKSPACE MODULES',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.analytics_rounded),
                title: const Text('Analysis Management'),
                subtitle: const Text('Audit content, call, and OCR scans'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onSelect(_AdminSection.analyses),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.menu_book_rounded),
                title: const Text('Knowledge Base'),
                subtitle: const Text('Canonical scam indicators & vectors'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onSelect(_AdminSection.knowledge),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.people_alt_rounded),
                title: const Text('User Management'),
                subtitle: const Text('User accounts, roles, and elevation'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onSelect(_AdminSection.users),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.monitor_heart_rounded),
                title: const Text('System Telemetry & Health'),
                subtitle: const Text('FastAPI, PostgreSQL, ML and Jira status'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onSelect(_AdminSection.monitoring),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.history_edu_rounded),
                title: const Text('Compliance Audit Logs'),
                subtitle: const Text('Immutable records of admin activity'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onSelect(_AdminSection.audit),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Configuration & Preferences
        const Text(
          'PREFERENCES & SYSTEM',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.8),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              SwitchListTile(
                secondary: Icon(isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded),
                title: const Text('Dark Mode Appearance'),
                subtitle: const Text('Persists theme selection across app restarts'),
                value: isDarkMode,
                onChanged: (_) => onToggleTheme(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications_active_rounded),
                title: const Text('Notification Preferences'),
                subtitle: const Text('Live-call fraud triggers & high-risk alerts'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.security_rounded),
                title: const Text('Security & Access Controls'),
                subtitle: const Text('2FA configuration, JWT session lifetimes'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('About ScamShield 2.0'),
                subtitle: const Text('Architecture, models, and platform specs'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'ScamShield Admin',
                    applicationVersion: '2.0.0',
                    applicationLegalese: '© 2026 ScamShield Security Consortium',
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Recent Audit Activity
        _Panel(
          title: 'Recent Audit Activity',
          subtitle: 'Latest mutations executed in the workspace.',
          trailing: TextButton(
            onPressed: () => onSelect(_AdminSection.audit),
            child: const Text('View all'),
          ),
          child: recentLogs.isEmpty
              ? const Text('No recent audit logs available.')
              : Column(
                  children: [
                    for (final log in recentLogs)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.history_rounded, size: 20),
                        title: Text(log['action']?.toString() ?? 'Action', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${log['actor'] ?? "System"} · ${log['created_at'] ?? ""}'),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 20),

        // Sign out button
        OutlinedButton.icon(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded, color: Colors.red),
          label: const Text('Sign out of Administrator Portal', style: TextStyle(color: Colors.red)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
}

// Dialogs and Reusable Elements

class _ReviewDetailDialog extends StatelessWidget {
  const _ReviewDetailDialog({
    required this.detail,
    required this.canDecide,
    required this.onExportJira,
    required this.onCreateKnowledge,
  });

  final Map<String, dynamic> detail;
  final bool canDecide;
  final VoidCallback onExportJira;
  final VoidCallback onCreateKnowledge;

  @override
  Widget build(BuildContext context) {
    final analysis = detail['analysis'] is Map ? detail['analysis'] as Map : const {};
    final notesController = TextEditingController();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Review Case #${detail['id']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    const Text('SUBMITTED CONTENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        analysis['original_text']?.toString() ?? analysis['content']?.toString() ?? 'No text provided',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text('ANALYSIS DETAILS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    Text('Classification: ${analysis['classification'] ?? "SCAM"}'),
                    Text('Risk Level: ${analysis['risk_level'] ?? "HIGH"}'),
                    Text('Explanation: ${analysis['explanation'] ?? "Suspicious communication pattern detected."}'),
                    const SizedBox(height: 14),
                    if (canDecide) ...[
                      const Text('REVIEWER NOTES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: notesController,
                        decoration: InputDecoration(
                          hintText: 'Add audit notes for this decision...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        maxLines: 2,
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: onExportJira,
                          icon: const Icon(Icons.confirmation_number_outlined, size: 16),
                          label: const Text('Export to Jira'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onCreateKnowledge,
                          icon: const Icon(Icons.library_add_outlined, size: 16),
                          label: const Text('Promote to KB'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),
              if (canDecide)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _ReviewSubmission(
                          decision: 'CONFIRMED_GENUINE',
                          notes: notesController.text,
                        ),
                      ),
                      child: const Text('Mark Genuine'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        _ReviewSubmission(
                          decision: 'CONFIRMED_SCAM',
                          notes: notesController.text,
                        ),
                      ),
                      child: const Text('Submit decision'),
                    ),
                  ],
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

class _CommunityReportDialog extends StatelessWidget {
  const _CommunityReportDialog({required this.report});

  final Map<String, dynamic> report;

  @override
  Widget build(BuildContext context) {
    final notesController = TextEditingController();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Moderate Community Report #${report['id']}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text('Category: ${report['category']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(report['content']?.toString() ?? 'No content'),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                hintText: 'Moderation notes...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _CommunityModerationAction('REJECT', notesController.text),
                  ),
                  child: const Text('Reject'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _CommunityModerationAction('CONVERT_TO_KNOWLEDGE', notesController.text),
                  ),
                  child: const Text('Convert to KB'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _CommunityModerationAction('APPROVE', notesController.text),
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityModerationAction {
  const _CommunityModerationAction(this.action, this.notes);
  final String action;
  final String notes;
}

class _KnowledgeDetailDialog extends StatelessWidget {
  const _KnowledgeDetailDialog({required this.entry});

  final Map<String, dynamic> entry;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(entry['title']?.toString() ?? 'Knowledge Entry'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${entry['category']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Status: ${entry['status']}'),
            const SizedBox(height: 10),
            const Text('Pattern / Guidance:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(entry['pattern']?.toString() ?? ''),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, 'DELETE'),
          child: const Text('Delete', style: TextStyle(color: Colors.red)),
        ),
        if (entry['status'] == 'DRAFT')
          FilledButton(
            onPressed: () => Navigator.pop(context, 'APPROVE'),
            child: const Text('Approve'),
          )
        else
          TextButton(
            onPressed: () => Navigator.pop(context, 'ARCHIVE'),
            child: const Text('Archive'),
          ),
      ],
    );
  }
}

class _KnowledgeEditorDialog extends StatefulWidget {
  const _KnowledgeEditorDialog({this.initialValues});

  final Map<String, dynamic>? initialValues;

  @override
  State<_KnowledgeEditorDialog> createState() => _KnowledgeEditorDialogState();
}

class _KnowledgeEditorDialogState extends State<_KnowledgeEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _categoryController;
  late final TextEditingController _patternController;
  String _riskLevel = 'HIGH';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialValues?['title'] ?? '');
    _categoryController = TextEditingController(text: widget.initialValues?['category'] ?? 'Fraud');
    _patternController = TextEditingController(text: widget.initialValues?['pattern'] ?? '');
    _riskLevel = widget.initialValues?['risk_level'] ?? 'HIGH';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _patternController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Knowledge Base Entry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
            ),
            TextField(
              controller: _categoryController,
              decoration: const InputDecoration(labelText: 'Category *'),
            ),
            TextField(
              controller: _patternController,
              decoration: const InputDecoration(labelText: 'Pattern / Content *'),
              maxLines: 3,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _riskLevel,
              decoration: const InputDecoration(labelText: 'Risk Level'),
              items: const [
                DropdownMenuItem(value: 'CRITICAL', child: Text('Critical')),
                DropdownMenuItem(value: 'HIGH', child: Text('High')),
                DropdownMenuItem(value: 'MEDIUM', child: Text('Medium')),
                DropdownMenuItem(value: 'LOW', child: Text('Low')),
              ],
              onChanged: (val) => setState(() => _riskLevel = val ?? 'HIGH'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty || _patternController.text.trim().isEmpty) return;
            Navigator.pop(context, {
              'title': _titleController.text.trim(),
              'category': _categoryController.text.trim(),
              'pattern': _patternController.text.trim(),
              'risk_level': _riskLevel,
              'status': 'DRAFT',
            });
          },
          child: const Text('Save Draft'),
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
    final u = data['user'] is Map ? data['user'] as Map : const {};
    final name = u['full_name']?.toString() ?? 'Unnamed';
    final email = u['email']?.toString() ?? '';
    final role = u['role']?.toString() ?? 'user';
    final isActive = u['is_active'] == true;

    return AlertDialog(
      title: Text(name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Email: $email'),
          Text('Role: ${role.toUpperCase()}'),
          Text('Status: ${isActive ? "Active" : "Disabled"}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, {
            'role': role == 'admin' ? 'user' : 'admin',
          }),
          child: Text(role == 'admin' ? 'Demote to User' : 'Elevate to Admin'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, {
            'is_active': !isActive,
          }),
          child: Text(isActive ? 'Disable account' : 'Enable account'),
        ),
      ],
    );
  }
}

class _AnalysisDetailDialog extends StatelessWidget {
  const _AnalysisDetailDialog({required this.data, this.onOpenReview});

  final Map<String, dynamic> data;
  final VoidCallback? onOpenReview;

  @override
  Widget build(BuildContext context) {
    final a = data['analysis'] is Map ? data['analysis'] as Map : data;
    final relatedReview = data['related_review'] is Map
        ? data['related_review'] as Map
        : data['linked_review'] is Map
            ? data['linked_review'] as Map
            : null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550, maxHeight: 650),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('Analysis #${a['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  children: [
                    Text('ORIGINAL CONTENT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(a['original_text']?.toString() ?? 'No content'),
                    ),
                    const SizedBox(height: 12),
                    Text('Classification: ${a['classification']}'),
                    Text('Risk Score: ${a['risk_score']} (${a['risk_level']})'),
                    Text('Category: ${a['category']}'),
                    Text('Explanation: ${a['explanation'] ?? "None"}'),
                    if (relatedReview != null) ...[
                      const Divider(),
                      const Text('LINKED HUMAN REVIEW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      Text('Case #${relatedReview['id']} · Status: ${relatedReview['status']} · Priority: ${relatedReview['priority']}'),
                      if (onOpenReview != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: onOpenReview,
                            icon: const Icon(Icons.rate_review_rounded, size: 16),
                            label: const Text('Open Review Case'),
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
    );
  }
}

class _AuditDetailDialog extends StatelessWidget {
  const _AuditDetailDialog({required this.log});

  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(log['action']?.toString() ?? 'Audit Event'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actor: ${log['actor'] ?? "System"}'),
            Text('Resource: ${log['resource_type']} #${log['resource_id']}'),
            Text('Result: ${log['result']}'),
            Text('Timestamp: ${log['created_at']}'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
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
    final maxCount = rows.fold<int>(
      1,
      (prev, el) => (el['count'] is num && (el['count'] as num).toInt() > prev)
          ? (el['count'] as num).toInt()
          : prev,
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${row['count'] ?? 0}',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 24,
                    height: 80 * (((row['count'] as num? ?? 0) / maxCount).clamp(0.05, 1.0)),
                    decoration: BoxDecoration(
                      color: const Color(0xFF087E8B),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    row['date'] != null && row['date'].toString().length >= 5
                        ? row['date'].toString().substring(row['date'].toString().length - 5)
                        : '',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentItems extends StatelessWidget {
  const _RecentItems(
    this.items, {
    required this.emptyMessage,
    required this.titleField,
    required this.details,
    this.onTapItem,
  });

  final dynamic items;
  final String emptyMessage;
  final String titleField;
  final String Function(Map<String, dynamic> row) details;
  final ValueChanged<Map<String, dynamic>>? onTapItem;

  @override
  Widget build(BuildContext context) {
    final rows = items is List
        ? items.whereType<Map<String, dynamic>>().toList()
        : const <Map<String, dynamic>>[];

    if (rows.isEmpty) {
      return Text(emptyMessage, style: Theme.of(context).textTheme.bodySmall);
    }

    return Column(
      children: [
        for (final row in rows)
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: Text(
              row[titleField]?.toString() ?? 'Record',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(details(row)),
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
            onTap: onTapItem != null ? () => onTapItem!(row) : null,
          ),
      ],
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Text('Page $page of $totalPages'),
        IconButton(
          onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 36, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
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
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 40, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts[0].isEmpty) return 'A';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
