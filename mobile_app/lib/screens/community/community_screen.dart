import 'package:flutter/material.dart';

import '../../models/community_report_model.dart';
import '../../services/community_service.dart';
import '../../theme/app_colors.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({
    this.communityService,
    super.key,
  });

  final CommunityService? communityService;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  void _openReportScam() {
    final contentCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedCategory = 'Phishing';
    bool submitting = false;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                      style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                  items: const [
                    DropdownMenuItem(value: 'Phishing', child: Text('Phishing SMS / Link')),
                    DropdownMenuItem(value: 'UPI Fraud', child: Text('UPI / Payment Fraud')),
                    DropdownMenuItem(value: 'Impersonation', child: Text('Bank / Govt Impersonation')),
                    DropdownMenuItem(value: 'Job Scam', child: Text('Fake Job / Task Scam')),
                    DropdownMenuItem(value: 'Courier / Delivery', child: Text('Fake Courier / Customs')),
                  ],
                  onChanged: (val) {
                    if (val != null) setSheetState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: contentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Scam Content or Caller Info',
                    hintText: 'e.g. "Dear customer, your electricity will be disconnected tonight..."',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Additional Context (Optional)',
                    hintText: 'How did they reach you? What did they request?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: submitting || widget.communityService == null
                      ? null
                      : () async {
                          if (contentCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter scam content')),
                            );
                            return;
                          }
                          setSheetState(() => submitting = true);
                          try {
                            await widget.communityService!.submitReport(
                              content: contentCtrl.text.trim(),
                              category: selectedCategory,
                              description: descCtrl.text.trim(),
                            );
                            if (!context.mounted) return;
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Thank you! Your scam report was successfully submitted.'),
                              ),
                            );
                          } catch (e) {
                            setSheetState(() => submitting = false);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Submission failed: $e')),
                            );
                          }
                        },
                  icon: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(submitting ? 'Submitting…' : 'Submit Community Report'),
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

  void _showCommunityPosts() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _CommunityPostsSheet(communityService: widget.communityService);
      },
    );
  }

  void _showScamPatterns() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                const SizedBox(height: 18),
                Text(
                  'Common Scam Patterns',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                const _PatternCard(
                  title: 'UPI Reverse Payment Scam',
                  category: 'UPI Fraud',
                  description:
                      'Scammer claims they want to buy your listed item and sends a payment request instead of sending money, asking you to "Enter UPI PIN to receive money". Remember: You NEVER enter UPI PIN to receive money.',
                ),
                const SizedBox(height: 12),
                const _PatternCard(
                  title: 'Electricity Bill Disconnection',
                  category: 'Impersonation',
                  description:
                      'SMS threatening power cut tonight due to unpaid bill, with a personal mobile number. Official power utilities never ask you to call personal numbers or download remote access apps.',
                ),
                const SizedBox(height: 12),
                const _PatternCard(
                  title: 'Fake Courier Parcel / Customs',
                  category: 'Extortion',
                  description:
                      'Robocall claiming your package has drugs or contraband intercepted by customs. They transfer the call to fake police asking for Skype calls and money transfers.',
                ),
                const SizedBox(height: 12),
                const _PatternCard(
                  title: 'Part-Time Rating / YouTube Likes Job',
                  category: 'Task Scam',
                  description:
                      'Offers ₹2,000-5,000 daily for liking videos or rating hotels on Google Maps. Initial small payouts lure victims before demanding thousands in "prepaid task investments".',
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSafetyTips() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                const SizedBox(height: 18),
                Text(
                  'Essential Safety Tips',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                const _TipTile(
                  icon: Icons.lock_clock_rounded,
                  title: 'Never Share OTP or PIN',
                  tip: 'No legitimate bank, police officer, or telecom agent will ever ask for your OTP, UPI PIN, or CVV.',
                ),
                const SizedBox(height: 12),
                const _TipTile(
                  icon: Icons.phone_disabled_rounded,
                  title: 'Hang Up & Verify Independently',
                  tip: 'If an unknown caller creates panic about frozen accounts, hang up and call the official bank number printed on your debit card.',
                ),
                const SizedBox(height: 12),
                const _TipTile(
                  icon: Icons.file_download_off_rounded,
                  title: 'Never Install APKs or AnyDesk',
                  tip: 'Never install .apk files sent on WhatsApp or remote desktop tools (AnyDesk, TeamViewer) at a caller\'s request.',
                ),
                const SizedBox(height: 12),
                const _TipTile(
                  icon: Icons.link_off_rounded,
                  title: 'Inspect Shortened URLs',
                  tip: 'Avoid clicking tinyurl, bit.ly, or suspicious domains mimicking government portals or banks.',
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showQA() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
                const SizedBox(height: 18),
                Text(
                  'Community Q&A',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                const ExpansionTile(
                  title: Text(
                    'What happens when I submit a scam report?',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Your report is validated by our backend and added to community intelligence. Emerging scam phrases help update detection patterns so other users receive timely warnings.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const ExpansionTile(
                  title: Text(
                    'Is my personal identity revealed to others?',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'No. Reports display your display name or "Community member". Phone numbers, sensitive credentials, and email addresses are never published.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const ExpansionTile(
                  title: Text(
                    'Can I report a suspicious phone number?',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Text(
                        'Yes! Enter the caller number and what scam pretext was claimed in the report form under Category "Bank / Govt Impersonation".',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Community'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: [
            // Top Banner Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.people_outline_rounded, color: colors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
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
                        const SizedBox(height: 4),
                        Text(
                          'Share scam experiences, learn from others and help build a safer community.',
                          style: TextStyle(
                            fontSize: 12.5,
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
            const SizedBox(height: 22),

            // Navigation Items
            _CommunityTile(
              icon: Icons.campaign_outlined,
              title: 'Report a Scam',
              subtitle: 'Share suspicious calls, messages or links',
              isDark: isDark,
              onTap: _openReportScam,
            ),
            const SizedBox(height: 12),

            _CommunityTile(
              icon: Icons.dynamic_feed_rounded,
              title: 'Community Posts',
              subtitle: 'View latest scam alerts and discussions',
              isDark: isDark,
              onTap: _showCommunityPosts,
            ),
            const SizedBox(height: 12),

            _CommunityTile(
              icon: Icons.radar_rounded,
              title: 'Scam Patterns',
              subtitle: 'Learn about common scam techniques',
              isDark: isDark,
              onTap: _showScamPatterns,
            ),
            const SizedBox(height: 12),

            _CommunityTile(
              icon: Icons.verified_user_outlined,
              title: 'Safety Tips',
              subtitle: 'Get practical tips to stay safe',
              isDark: isDark,
              onTap: _showSafetyTips,
            ),
            const SizedBox(height: 12),

            _CommunityTile(
              icon: Icons.forum_outlined,
              title: 'Q&A',
              subtitle: 'Ask questions and get answers',
              isDark: isDark,
              onTap: _showQA,
            ),
            const SizedBox(height: 28),

            // Bottom Brand Banner (Report. Share. Protect.)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : colors.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.report_problem_outlined, color: colors.primary, size: 24),
                      const SizedBox(width: 14),
                      Icon(Icons.share_outlined, color: colors.primary, size: 24),
                      const SizedBox(width: 14),
                      Icon(Icons.shield_outlined, color: colors.primary, size: 24),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Report. Share. Protect.',
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: colors.primary,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your experience can help others avoid scams.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityPostsSheet extends StatefulWidget {
  const _CommunityPostsSheet({this.communityService});

  final CommunityService? communityService;

  @override
  State<_CommunityPostsSheet> createState() => _CommunityPostsSheetState();
}

class _CommunityPostsSheetState extends State<_CommunityPostsSheet> {
  bool _loading = true;
  String? _error;
  List<CommunityReportModel> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.communityService == null) {
      setState(() {
        _loading = false;
        _error = 'Community service is currently unavailable.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await widget.communityService!.getCommunityReports();
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.45,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Community Posts',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: _load,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _buildList(context, scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildList(BuildContext context, ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Could not load posts',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_reports.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No community reports submitted yet. Be the first to share a scam alert!',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _reports.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final r = _reports[index];
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      r.reporterName,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.content,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                if (r.description != null && r.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    r.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CommunityTile extends StatelessWidget {
  const _CommunityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
              ),
            ],
          ),
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  category,
                  style: TextStyle(fontSize: 11, color: colors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant, height: 1.35),
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
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 3),
              Text(
                tip,
                style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant, height: 1.35),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
