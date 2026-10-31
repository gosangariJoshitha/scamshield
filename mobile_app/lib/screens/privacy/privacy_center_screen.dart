import 'package:flutter/material.dart';

import '../../native/call_bridge.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

class PrivacyCenterScreen extends StatefulWidget {
  const PrivacyCenterScreen({
    this.callBridge,
    this.authService,
    this.onAccountDeleted,
    super.key,
  });

  final CallBridge? callBridge;
  final AuthService? authService;
  final VoidCallback? onAccountDeleted;

  @override
  State<PrivacyCenterScreen> createState() => _PrivacyCenterScreenState();
}

class _PrivacyCenterScreenState extends State<PrivacyCenterScreen> {
  late final CallBridge _callBridge = widget.callBridge ?? CallBridge();
  CallGuardianStatus? _guardianStatus;
  bool _dataSharingEnabled = false;
  bool _usageAnalyticsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadDevicePermissions();
  }

  Future<void> _loadDevicePermissions() async {
    try {
      final status = await _callBridge.getCallGuardianStatus();
      if (!mounted) return;
      setState(() => _guardianStatus = status);
    } catch (_) {
      // Running in unit test or platform layer mock
    }
  }

  void _showAppPermissions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        final status = _guardianStatus;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                  'Android App Permissions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Real-time permission states on this device:',
                  style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                _PermissionStateRow(
                  icon: Icons.phone_in_talk_rounded,
                  title: 'Phone State (READ_PHONE_STATE)',
                  description: 'Required to detect active and incoming call events.',
                  granted: status?.phoneStatePermissionGranted ?? false,
                ),
                const SizedBox(height: 12),
                _PermissionStateRow(
                  icon: Icons.notifications_active_rounded,
                  title: 'Notifications (POST_NOTIFICATIONS)',
                  description: 'Required for Sentinel foreground service and threat alerts.',
                  granted: status?.notificationsPermissionGranted ?? false,
                ),
                const SizedBox(height: 12),
                _PermissionStateRow(
                  icon: Icons.mic_rounded,
                  title: 'Microphone (RECORD_AUDIO)',
                  description: 'Optional. Enables in-call live speech-to-text analysis.',
                  granted: status?.audioPermissionGranted ?? false,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _callBridge.openAppSettings();
                  },
                  icon: const Icon(Icons.settings_outlined),
                  label: const Text('Open System App Settings'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDataUsage() {
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
          maxChildSize: 0.88,
          minChildSize: 0.4,
          builder: (context, scrollController) {
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                  'Data Usage & Processing Flow',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                const _InfoCard(
                  title: 'No Audio Storage',
                  description:
                      'Live call audio chunks are processed in ephemeral memory during the call. They are never written to disk or persistently saved on servers.',
                ),
                const SizedBox(height: 10),
                const _InfoCard(
                  title: 'Content Analysis',
                  description:
                      'Messages, URLs, and image OCR text submitted for analysis are stored in your private history. You can review or clear your analysis history at any time.',
                ),
                const SizedBox(height: 10),
                const _InfoCard(
                  title: 'Credentials & Passwords',
                  description:
                      'Passwords and tokens are hashed using bcrypt. Sensitive credentials and OTP codes are strictly excluded from diagnostics and system telemetry.',
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAccountSecurity() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    bool changing = false;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Account Security'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change Password',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: currentPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password (min 8 chars)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: changing || widget.authService == null
                    ? null
                    : () async {
                        if (currentPassCtrl.text.isEmpty || newPassCtrl.text.length < 8) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter valid passwords (minimum 8 characters).'),
                            ),
                          );
                          return;
                        }
                        setDialogState(() => changing = true);
                        try {
                          await widget.authService!.changePassword(
                            currentPassword: currentPassCtrl.text,
                            newPassword: newPassCtrl.text,
                          );
                          if (!context.mounted) return;
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password updated successfully.')),
                          );
                        } catch (e) {
                          setDialogState(() => changing = false);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed: $e')),
                          );
                        }
                      },
                child: Text(changing ? 'Updating…' : 'Update Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'Warning: This action is permanent and irreversible. Your account, analysis history, and call protection summaries will be permanently deleted from ScamShield servers.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              nav.pop();
              if (widget.authService != null) {
                try {
                  await widget.authService!.deleteAccount();
                  if (!mounted) return;
                  widget.onAccountDeleted?.call();
                  nav.popUntil((route) => route.isFirst);
                } catch (e) {
                  if (!mounted) return;
                  messenger.showSnackBar(
                    SnackBar(content: Text('Account deletion failed: $e')),
                  );
                }
              }
            },
            child: const Text('Permanently Delete'),
          ),
        ],
      ),
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
        title: const Text('Privacy & Security'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: [
            // 1. Header Card (Panel 3 visual reference)
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
                    child: Icon(Icons.shield_outlined, color: colors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your privacy matters',
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We protect your data and ensure secure analysis of your content and calls.',
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
            const SizedBox(height: 24),

            // Section 1: Data & Permissions
            Text(
              'DATA & PERMISSIONS',
              style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
            ),
            const SizedBox(height: 10),

            _PrivacyTile(
              icon: Icons.mic_none_rounded,
              title: 'App Permissions',
              subtitle: 'Microphone, notifications, etc.',
              isDark: isDark,
              onTap: _showAppPermissions,
            ),
            const SizedBox(height: 10),

            _PrivacyTile(
              icon: Icons.data_usage_rounded,
              title: 'Data Usage',
              subtitle: 'What data we collect and how we use it',
              isDark: isDark,
              onTap: _showDataUsage,
            ),
            const SizedBox(height: 10),

            _PrivacyTile(
              icon: Icons.lock_outline_rounded,
              title: 'Account Security',
              subtitle: 'Password, 2FA, device management',
              isDark: isDark,
              onTap: _showAccountSecurity,
            ),
            const SizedBox(height: 10),

            _PrivacyTile(
              icon: Icons.delete_outline_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently remove your account',
              isDark: isDark,
              onTap: _confirmDeleteAccount,
            ),
            const SizedBox(height: 24),

            // Section 2: Privacy Controls
            Text(
              'PRIVACY CONTROLS',
              style: theme.textTheme.labelSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
            ),
            const SizedBox(height: 10),

            Material(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.send_outlined, color: colors.primary, size: 20),
                    ),
                    title: const Text(
                      'Data Sharing',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    subtitle: const Text(
                      'Help us improve (optional)',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    value: _dataSharingEnabled,
                    onChanged: (val) {
                      setState(() => _dataSharingEnabled = val);
                    },
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.bar_chart_rounded, color: colors.primary, size: 20),
                    ),
                    title: const Text(
                      'Usage Analytics',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    subtitle: const Text(
                      'Anonymous app usage data',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    value: _usageAnalyticsEnabled,
                    onChanged: (val) {
                      setState(() => _usageAnalyticsEnabled = val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Footer Note
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
                children: [
                  Icon(Icons.lock_rounded, color: colors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'We never share your personal data with third parties without your consent.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
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

class _PrivacyTile extends StatelessWidget {
  const _PrivacyTile({
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

class _PermissionStateRow extends StatelessWidget {
  const _PermissionStateRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colors.primary, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: granted
                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                          : colors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      granted ? 'Granted' : 'Denied',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: granted ? const Color(0xFF10B981) : colors.error,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Text(description, style: TextStyle(fontSize: 12.5, color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}
