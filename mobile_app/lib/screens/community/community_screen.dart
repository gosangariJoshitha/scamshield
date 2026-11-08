import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/community_report_model.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../theme/app_colors.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({
    this.communityService,
    this.user,
    super.key,
  });

  final CommunityService? communityService;
  final User? user;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

enum _CommunityTab { posts, patterns, tips, qa }

class _CommunityScreenState extends State<CommunityScreen> {
  _CommunityTab _selectedTab = _CommunityTab.posts;
  List<CommunityReportModel> _reports = [];
  bool _loading = false;
  String? _error;
  String _selectedCategory = 'All';
  String _statusFilter = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Phishing',
    'UPI Fraud',
    'Impersonation',
    'Job Scam',
    'Courier / Delivery',
  ];

  late final CommunityService _service;

  @override
  void initState() {
    super.initState();
    final auth = AuthService(api: ApiService());
    _service = widget.communityService ??
        CommunityService(
          api: ApiService(),
          authService: auth,
        );
    _loadReports();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadReports() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await _service.getCommunityReports();
      if (!mounted) return;
      setState(() {
        _reports = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _openReportScam() {
    final contentCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String reportCategory = 'Phishing';
    bool submitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colors = Theme.of(context).colorScheme;
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Report a Scam',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Submit suspicious scam patterns or messages to help protect the community.',
                      style: TextStyle(
                          fontSize: 13, color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: reportCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'Phishing',
                            child: Text('Phishing SMS / Link')),
                        DropdownMenuItem(
                            value: 'UPI Fraud',
                            child: Text('UPI / Payment Fraud')),
                        DropdownMenuItem(
                            value: 'Impersonation',
                            child: Text('Bank / Govt Impersonation')),
                        DropdownMenuItem(
                            value: 'Job Scam',
                            child: Text('Fake Job / Task Scam')),
                        DropdownMenuItem(
                            value: 'Courier / Delivery',
                            child: Text('Fake Courier / Customs')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => reportCategory = val);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: contentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Scam Content or Caller Info',
                        hintText:
                            'e.g. "Dear customer, your electricity will be disconnected tonight..."',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Additional Context (Optional)',
                        hintText:
                            'How did they reach you? What did they request?',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),
                    FilledButton.icon(
                      onPressed: submitting
                          ? null
                          : () async {
                              if (contentCtrl.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Please enter scam content')),
                                );
                                return;
                              }
                              setSheetState(() => submitting = true);
                              try {
                                final newReport = await _service
                                    .submitReport(
                                  content: contentCtrl.text.trim(),
                                  category: reportCategory,
                                  description: descCtrl.text.trim(),
                                );
                                if (!context.mounted) return;
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Thank you! Your scam report was successfully submitted.'),
                                  ),
                                );
                                setState(() {
                                  _reports.insert(0, newReport);
                                  _selectedTab = _CommunityTab.posts;
                                });
                              } catch (e) {
                                setSheetState(() => submitting = false);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Submission failed: $e')),
                                );
                              }
                            },
                      icon: submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(submitting
                          ? 'Submitting…'
                          : 'Submit Community Report'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openPostDetail(CommunityReportModel report) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CommunityPostDetailScreen(
          report: report,
          communityService: _service,
        ),
      ),
    );
  }

  List<CommunityReportModel> get _filteredReports {
    return _reports.where((r) {
      if (_selectedCategory != 'All' &&
          !r.category.toLowerCase().contains(_selectedCategory.toLowerCase())) {
        return false;
      }
      if (_statusFilter == 'Verified' &&
          r.status.toUpperCase() != 'VERIFIED') {
        return false;
      }
      if (_statusFilter == 'My Reports') {
        if (widget.user != null) {
          if (r.userId != null && r.userId == widget.user!.id) {
            // Matched by genuine user ID
          } else {
            final currentUserName = widget.user!.fullName.trim().toLowerCase();
            if (currentUserName.isEmpty ||
                !r.reporterName.trim().toLowerCase().contains(currentUserName)) {
              return false;
            }
          }
        } else {
          return false;
        }
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesContent = r.content.toLowerCase().contains(q);
        final matchesDesc =
            r.description?.toLowerCase().contains(q) ?? false;
        final matchesCat = r.category.toLowerCase().contains(q);
        final matchesReporter = r.reporterName.toLowerCase().contains(q);
        return matchesContent || matchesDesc || matchesCat || matchesReporter;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Community',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? AppColors.textMainDark : const Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReports,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openReportScam,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Report Scam'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadReports,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            children: [
              // 1. Banner Card ('Stronger together', 'Report. Share. Protect.')
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.primary
                            .withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.group_outlined,
                          color: colors.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stronger together',
                            style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Report. Share. Protect.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Verified scam reports and safety intelligence.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 2. Action Tiles Bar (Preserving exact tests & offering full navigation)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ActionChip(
                      label: 'Report a Scam',
                      icon: Icons.campaign_rounded,
                      selected: false,
                      isPrimaryAction: true,
                      onTap: _openReportScam,
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      label: 'Community Posts',
                      icon: Icons.feed_outlined,
                      selected: _selectedTab == _CommunityTab.posts,
                      onTap: () =>
                          setState(() => _selectedTab = _CommunityTab.posts),
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      label: 'Scam Patterns',
                      icon: Icons.psychology_alt_outlined,
                      selected: _selectedTab == _CommunityTab.patterns,
                      onTap: () => setState(
                          () => _selectedTab = _CommunityTab.patterns),
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      label: 'Safety Tips',
                      icon: Icons.lightbulb_outline_rounded,
                      selected: _selectedTab == _CommunityTab.tips,
                      onTap: () =>
                          setState(() => _selectedTab = _CommunityTab.tips),
                    ),
                    const SizedBox(width: 8),
                    _ActionChip(
                      label: 'Q&A',
                      icon: Icons.question_answer_outlined,
                      selected: _selectedTab == _CommunityTab.qa,
                      onTap: () =>
                          setState(() => _selectedTab = _CommunityTab.qa),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Tab Body
              if (_selectedTab == _CommunityTab.posts)
                _buildPostsFeed(context, isDark, colors)
              else if (_selectedTab == _CommunityTab.patterns)
                _buildPatternsTab(context, isDark, colors)
              else if (_selectedTab == _CommunityTab.tips)
                _buildSafetyTipsTab(context, isDark, colors)
              else if (_selectedTab == _CommunityTab.qa)
                _buildQaTab(context, isDark, colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostsFeed(
      BuildContext context, bool isDark, ColorScheme colors) {
    final filtered = _filteredReports;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search & Filter Row
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search community reports...',
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
            filled: true,
            fillColor: isDark ? AppColors.darkCard : Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
          ),
          onChanged: (val) => setState(() => _searchQuery = val.trim()),
        ),
        const SizedBox(height: 10),

        // Sub-filter status chips (All, Verified, My Reports)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Reports'),
                selected: _statusFilter == 'All',
                onSelected: (_) => setState(() => _statusFilter = 'All'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Verified Only'),
                selected: _statusFilter == 'Verified',
                onSelected: (_) => setState(() => _statusFilter = 'Verified'),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('My Reports'),
                selected: _statusFilter == 'My Reports',
                onSelected: (_) =>
                    setState(() => _statusFilter = 'My Reports'),
              ),
              const SizedBox(width: 14),
              // Category dropdown chip
              PopupMenuButton<String>(
                tooltip: 'Select Category',
                initialValue: _selectedCategory,
                onSelected: (cat) => setState(() => _selectedCategory = cat),
                child: Chip(
                  avatar: const Icon(Icons.filter_list_rounded, size: 16),
                  label: Text('Category: $_selectedCategory'),
                ),
                itemBuilder: (context) => _categories
                    .map((cat) => PopupMenuItem(value: cat, child: Text(cat)))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // List Status Handlers
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Fetching verified community reports...',
                      style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          )
        else if (_error != null)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Icon(Icons.error_outline_rounded,
                    color: colors.onErrorContainer, size: 28),
                const SizedBox(height: 8),
                Text('Could not load posts',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colors.onErrorContainer)),
                const SizedBox(height: 4),
                Text(_error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12, color: colors.onErrorContainer)),
                const SizedBox(height: 12),
                FilledButton(
                    onPressed: _loadReports, child: const Text('Retry')),
              ],
            ),
          )
        else if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 36),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.feed_outlined,
                    size: 40, color: colors.onSurfaceVariant),
                const SizedBox(height: 12),
                const Text(
                  'No community reports submitted yet. Be the first to share a scam alert!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13.5),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: _openReportScam,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Report a Scam'),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (context, index) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final r = filtered[index];
              return _ReportCard(
                report: r,
                isDark: isDark,
                onTap: () => _openPostDetail(r),
              );
            },
          ),
      ],
    );
  }

  Widget _buildPatternsTab(
      BuildContext context, bool isDark, ColorScheme colors) {
    return const Column(
      children: [
        _PatternCard(
          title: 'UPI Reverse Payment Scam',
          category: 'UPI Fraud',
          description:
              'Scammer claims they want to buy your listed item and sends a payment request instead of sending money, asking you to "Enter UPI PIN to receive money". Remember: You NEVER enter UPI PIN to receive money.',
        ),
        SizedBox(height: 10),
        _PatternCard(
          title: 'Electricity Bill Disconnection',
          category: 'Impersonation',
          description:
              'SMS threatening power cut tonight due to unpaid bill, with a personal mobile number. Official power utilities never ask you to call personal numbers or download remote access apps.',
        ),
        SizedBox(height: 10),
        _PatternCard(
          title: 'Fake Courier Parcel / Customs',
          category: 'Extortion',
          description:
              'Robocall claiming your package has drugs or contraband intercepted by customs. They transfer the call to fake police asking for Skype calls and money transfers.',
        ),
        SizedBox(height: 10),
        _PatternCard(
          title: 'Part-Time Rating / YouTube Likes Job',
          category: 'Task Scam',
          description:
              'Offers ₹2,000-5,000 daily for liking videos or rating hotels on Google Maps. Initial small payouts lure victims before demanding thousands in "prepaid task investments".',
        ),
      ],
    );
  }

  Widget _buildSafetyTipsTab(
      BuildContext context, bool isDark, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: const Column(
        children: [
          _TipTile(
            icon: Icons.lock_clock_rounded,
            title: 'Never Share OTP or PIN',
            tip:
                'No legitimate bank, police officer, or telecom agent will ever ask for your OTP, UPI PIN, or CVV.',
          ),
          SizedBox(height: 14),
          _TipTile(
            icon: Icons.phone_disabled_rounded,
            title: 'Hang Up & Verify Independently',
            tip:
                'If an unknown caller creates panic about frozen accounts, hang up and call the official bank number printed on your debit card.',
          ),
          SizedBox(height: 14),
          _TipTile(
            icon: Icons.file_download_off_rounded,
            title: 'Never Install APKs or AnyDesk',
            tip:
                'Never install .apk files sent on WhatsApp or remote desktop tools (AnyDesk, TeamViewer) at a caller\'s request.',
          ),
          SizedBox(height: 14),
          _TipTile(
            icon: Icons.link_off_rounded,
            title: 'Inspect Shortened URLs',
            tip:
                'Avoid clicking tinyurl, bit.ly, or suspicious domains mimicking government portals or banks.',
          ),
        ],
      ),
    );
  }

  Widget _buildQaTab(BuildContext context, bool isDark, ColorScheme colors) {
    return const Column(
      children: [
        _QaCard(
          question: 'How do I know if an incoming call is a scam?',
          answer:
              'Sentinel analyzes active call context in real time. If the caller creates urgency, claims to be police/CBI, or demands money transfers, Sentinel alerts you with high-urgency notifications.',
        ),
        SizedBox(height: 10),
        _QaCard(
          question: 'Are my community reports anonymous?',
          answer:
              'Reports display your account first name and verified badges. Sensitive personal credentials, phone numbers, or passwords should never be included in report descriptions.',
        ),
        SizedBox(height: 10),
        _QaCard(
          question: 'How are scam reports verified?',
          answer:
              'Scam reports undergo automated AI correlation with our knowledge base and review by ScamShield trust analysts before receiving Verified status.',
        ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isPrimaryAction = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isPrimaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isPrimaryAction) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return FilterChip(
      avatar: Icon(icon,
          size: 16, color: selected ? colors.onPrimary : colors.primary),
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide(
        color: selected
            ? colors.primary
            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({
    required this.report,
    required this.isDark,
    required this.onTap,
  });

  final CommunityReportModel report;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    Color statusColor;
    switch (report.status.toUpperCase()) {
      case 'VERIFIED':
        statusColor = const Color(0xFF10B981);
        break;
      case 'PENDING':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'ESCALATED':
        statusColor = colors.error;
        break;
      default:
        statusColor = colors.primary;
    }

    return Material(
      color: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.category,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (report.status.toUpperCase() == 'VERIFIED') ...[
                          Icon(Icons.verified_rounded, size: 12, color: statusColor),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          report.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: colors.primary.withValues(alpha: 0.15),
                        child: Text(
                          report.reporterName.isNotEmpty
                              ? report.reporterName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        report.reporterName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                report.content,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (report.description != null &&
                  report.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  report.description!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 13, color: colors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(
                    '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 16, color: colors.primary),
                    ],
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

class CommunityPostDetailScreen extends StatelessWidget {
  const CommunityPostDetailScreen({
    required this.report,
    this.communityService,
    super.key,
  });

  final CommunityReportModel report;
  final CommunityService? communityService;

  void _copyContent(BuildContext context) {
    Clipboard.setData(ClipboardData(text: report.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scam content copied to clipboard.')),
    );
  }

  Future<void> _reportInappropriate(BuildContext context) async {
    String selectedReason = 'Spam or Deceptive content';
    final customReasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Report Inappropriate Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Flag this community post if it contains offensive language, personal confidential information, or spam.',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedReason,
                decoration: const InputDecoration(
                  labelText: 'Violation Category',
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Spam or Deceptive content',
                    child: Text('Spam or Deceptive content'),
                  ),
                  DropdownMenuItem(
                    value: 'Harassment or Offensive language',
                    child: Text('Harassment or Offensive language'),
                  ),
                  DropdownMenuItem(
                    value: 'Personal / Confidential data',
                    child: Text('Personal / Confidential data'),
                  ),
                  DropdownMenuItem(
                    value: 'Malicious links or Malware',
                    child: Text('Malicious links or Malware'),
                  ),
                  DropdownMenuItem(
                    value: 'Other violation',
                    child: Text('Other violation'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedReason = val);
                  }
                },
              ),
              if (selectedReason == 'Other violation') ...[
                const SizedBox(height: 10),
                TextField(
                  controller: customReasonController,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    labelText: 'Specify reason',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final reason = selectedReason == 'Other violation' &&
                        customReasonController.text.trim().isNotEmpty
                    ? customReasonController.text.trim()
                    : selectedReason;
                Navigator.of(ctx).pop(reason);
              },
              child: const Text('Flag Report'),
            ),
          ],
        ),
      ),
    );

    if (result == null || result.trim().isEmpty) return;
    if (!context.mounted) return;

    final service = communityService ??
        CommunityService(
          api: ApiService(),
          authService: AuthService(api: ApiService()),
        );

    try {
      final success = await service.flagReport(
        reportId: report.id,
        reason: result,
      );
      if (!context.mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Thank you. This report has been flagged for moderation review.'),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      final msg = e.toString().toLowerCase().contains('already flagged')
          ? 'You have already flagged this report for moderator review.'
          : 'Failed to flag report: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;

    Color statusColor;
    switch (report.status.toUpperCase()) {
      case 'VERIFIED':
        statusColor = const Color(0xFF10B981);
        break;
      case 'PENDING':
        statusColor = const Color(0xFFF59E0B);
        break;
      case 'ESCALATED':
        statusColor = colors.error;
        break;
      default:
        statusColor = colors.primary;
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Report Details'),
        actions: [
          IconButton(
            tooltip: 'Copy scam text',
            icon: const Icon(Icons.copy_rounded),
            onPressed: () => _copyContent(context),
          ),
          IconButton(
            tooltip: 'Flag post',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => _reportInappropriate(context),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Status & Category Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          report.category,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          report.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '#${report.id}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(Icons.person_pin_rounded,
                          size: 18, color: colors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Reported by ${report.reporterName}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Text(
                        '${report.createdAt.day}/${report.createdAt.month}/${report.createdAt.year}',
                        style: TextStyle(
                            fontSize: 12, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scam Content Section
            Text(
              'SCAM CONTENT / MESSAGE',
              style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF192630) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: SelectableText(
                report.content,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description / Context
            if (report.description != null &&
                report.description!.isNotEmpty) ...[
              Text(
                'ADDITIONAL CONTEXT',
                style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Text(
                  report.description!,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: colors.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Evidence Section (if available)
            if (report.evidence != null && report.evidence!.isNotEmpty) ...[
              Text(
                'EVIDENCE & REFERENCES',
                style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                ),
                child: Text(
                  report.evidence!,
                  style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Source Analysis Badge (if linked)
            if (report.analysisId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link_rounded, size: 18, color: colors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Linked to Analysis #${report.analysisId}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Comments / Discussion Policy Notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : colors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 20, color: colors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Moderated Discussion',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Community discussion is restricted to verified moderators to maintain threat intelligence integrity and prevent spam.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Actions: Flag or Copy
            OutlinedButton.icon(
              onPressed: () => _reportInappropriate(context),
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text('Report Inappropriate Content'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({
    required this.title,
    required this.category,
    required this.description,
  });

  final String title;
  final String category;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                      fontSize: 11,
                      color: colors.primary,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(
                fontSize: 12.5,
                color: colors.onSurfaceVariant,
                height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  const _TipTile({
    required this.icon,
    required this.title,
    required this.tip,
  });

  final IconData icon;
  final String title;
  final String tip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.primaryContainer.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: colors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 3),
              Text(
                tip,
                style: TextStyle(
                    fontSize: 12.5,
                    color: colors.onSurfaceVariant,
                    height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QaCard extends StatelessWidget {
  const _QaCard({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded,
                  size: 18, color: colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              answer,
              style: TextStyle(
                  fontSize: 12.5,
                  color: colors.onSurfaceVariant,
                  height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
