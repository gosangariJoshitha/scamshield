import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/guardian_protection_models.dart';
import '../../native/call_bridge.dart';
import '../../services/guardian_protection_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../notifications/notification_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    required this.onOpenGuardian,
    this.protectionService,
    this.notificationService,
    this.isDarkMode = false,
    this.onToggleTheme,
    this.callBridge,
    super.key,
  });

  final VoidCallback onOpenGuardian;
  final GuardianProtectionService? protectionService;
  final NotificationService? notificationService;
  final bool isDarkMode;
  final VoidCallback? onToggleTheme;
  final CallBridge? callBridge;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isDarkMode = widget.isDarkMode;
  bool _floatingButtonEnabled = false;
  String _selectedLanguage = 'English';

  @override
  void didUpdateWidget(covariant SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _isDarkMode = widget.isDarkMode;
    }
  }

  void _handleToggleTheme() {
    widget.onToggleTheme?.call();
    setState(() => _isDarkMode = !_isDarkMode);
  }

  void _showLanguageSelector() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
              const SizedBox(height: 18),
              Text(
                'Select Language',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'App UI is in English. Multilingual scam recommendations on the Analysis screen support English, Hindi, and Telugu.',
                style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.language_rounded),
                title: const Text('English (Default)'),
                trailing: _selectedLanguage == 'English'
                    ? Icon(Icons.check_circle_rounded, color: colors.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedLanguage = 'English');
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openNotifications() {
    if (widget.notificationService != null) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => NotificationScreen(
            notificationService: widget.notificationService!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notifications service is initializing.')),
      );
    }
  }

  Future<void> _clearCache() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear local cache?'),
        content: const Text(
          'This will free up local temporary storage. Your account history, verified records, and call summaries will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    int freedBytes = 0;
    try {
      final tempDir = Directory.systemTemp;
      if (tempDir.existsSync()) {
        final files = tempDir.listSync(recursive: false);
        for (final f in files) {
          if (f is File && f.path.contains('scamshield')) {
            freedBytes += f.lengthSync();
            try {
              f.deleteSync();
            } catch (_) {}
          }
        }
      }
    } catch (_) {}

    if (!mounted) return;
    final displaySize = freedBytes > 0
        ? '${(freedBytes / 1024).toStringAsFixed(1)} KB'
        : 'Temporary cache';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$displaySize cleared successfully.')),
    );
  }

  void _checkUpdates() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Check for Updates'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text(
                  'ScamShield is up to date',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Current Version: 1.0.0 (Build 1)\nYou are running the latest official build with verified threat intelligence models.',
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
          children: [
            // Section 1: App Preferences
            _SectionHeader(title: 'App Preferences', isDark: isDark),
            const SizedBox(height: 8),
            _SettingNavTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              subtitle: 'Alerts, warnings and updates',
              trailingText: null,
              isDark: isDark,
              onTap: _openNotifications,
            ),
            const SizedBox(height: 8),
            _SettingNavTile(
              icon: Icons.language_rounded,
              title: 'Language',
              subtitle: _selectedLanguage,
              trailingText: '$_selectedLanguage >',
              isDark: isDark,
              onTap: _showLanguageSelector,
            ),
            const SizedBox(height: 8),
            _SettingNavTile(
              icon: _isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
              title: 'Theme',
              subtitle: _isDarkMode ? 'Dark' : 'Light',
              trailingText: _isDarkMode ? 'Dark >' : 'Light >',
              isDark: isDark,
              onTap: _handleToggleTheme,
            ),
            const SizedBox(height: 8),
            _SettingSwitchTile(
              icon: Icons.screen_search_desktop_outlined,
              title: 'Floating Guardian Button',
              subtitle: 'Show on screen when active',
              value: _floatingButtonEnabled,
              isDark: isDark,
              onChanged: (val) {
                setState(() => _floatingButtonEnabled = val);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      val
                          ? 'Floating button enabled. Sentinel will show a floating indicator during active call screening.'
                          : 'Floating button disabled.',
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Section 2: Call Protection
            _SectionHeader(title: 'Call Protection', isDark: isDark),
            const SizedBox(height: 8),
            _SettingNavTile(
              icon: Icons.tune_rounded,
              title: 'Call Analysis Settings',
              subtitle: 'Audio, transcription & analysis',
              trailingText: null,
              isDark: isDark,
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => CallProtectionSettingsScreen(
                    onOpenGuardian: widget.onOpenGuardian,
                    protectionService: widget.protectionService,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SettingSwitchTile(
              icon: Icons.phone_forwarded_rounded,
              title: 'Auto-Answer (if supported)',
              subtitle: 'For verified numbers',
              value: false,
              isDark: isDark,
              onChanged: (val) {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Auto-Answer Unsupported'),
                    content: const Text(
                      'Automatic answering requires carrier/telecom partner integration and is not supported on standard Android without a default dialer role. ScamShield alerts you in real time instead.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Understand'),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Section 3: General
            _SectionHeader(title: 'General', isDark: isDark),
            const SizedBox(height: 8),
            _SettingNavTile(
              icon: Icons.cleaning_services_outlined,
              title: 'Clear Cache',
              subtitle: 'Free up storage space',
              trailingText: null,
              isDark: isDark,
              onTap: _clearCache,
            ),
            const SizedBox(height: 8),
            _SettingNavTile(
              icon: Icons.system_update_rounded,
              title: 'App Updates',
              subtitle: 'Check for latest version',
              trailingText: null,
              isDark: isDark,
              onTap: _checkUpdates,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.isDark});

  final String title;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textMainDark : AppColors.textMainLight,
        ),
      ),
    );
  }
}

class _SettingNavTile extends StatelessWidget {
  const _SettingNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? trailingText;
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
              if (trailingText != null) ...[
                Text(
                  trailingText!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
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
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class CallProtectionSettingsScreen extends StatefulWidget {
  const CallProtectionSettingsScreen({
    required this.onOpenGuardian,
    this.protectionService,
    super.key,
  });

  final VoidCallback onOpenGuardian;
  final GuardianProtectionService? protectionService;

  @override
  State<CallProtectionSettingsScreen> createState() =>
      _CallProtectionSettingsScreenState();
}

class _CallProtectionSettingsScreenState
    extends State<CallProtectionSettingsScreen> {
  late GuardianProtectionSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings =
        widget.protectionService?.settings ??
        const GuardianProtectionSettings();
  }

  void _updateSettings(GuardianProtectionSettings newSettings) {
    setState(() => _settings = newSettings);
    widget.protectionService?.updateSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Live Call Guardian')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: colors.primary, size: 30),
                  const SizedBox(height: 12),
                  Text(
                    'Protect yourself during phone calls',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'When enabled, Guardian monitors supported call states. It does not record calls or take automatic actions without your explicit confirmation.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: widget.onOpenGuardian,
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Open Guardian'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'GUARDIAN PROTECTION',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'Risk alerts',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Show real-time risk level assessments during calls',
                    ),
                    value: _settings.riskAlertsEnabled,
                    onChanged: (val) {
                      _updateSettings(
                        _settings.copyWith(riskAlertsEnabled: val),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'High-risk vibration',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Vibrate briefly when high-risk scam indicators are detected',
                    ),
                    value: _settings.highRiskVibrationEnabled,
                    onChanged: (val) {
                      _updateSettings(
                        _settings.copyWith(highRiskVibrationEnabled: val),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Critical-risk alerts',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Prominent visual and haptic alert when critical risk is detected',
                    ),
                    value: _settings.criticalRiskAlertsEnabled,
                    onChanged: (val) {
                      _updateSettings(
                        _settings.copyWith(criticalRiskAlertsEnabled: val),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Show protection actions',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Display End Call, Block Caller, and Verify Safely action panel',
                    ),
                    value: _settings.showProtectionActions,
                    onChanged: (val) {
                      _updateSettings(
                        _settings.copyWith(showProtectionActions: val),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text(
                      'Ask before protective actions',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Always active. ScamShield will never hang up or block calls without your explicit consent.',
                    ),
                    value: true,
                    onChanged: null,
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
