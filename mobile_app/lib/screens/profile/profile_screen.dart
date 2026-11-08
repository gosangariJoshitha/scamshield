import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../native/call_bridge.dart';
import '../../services/admin_portal_service.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../services/guardian_protection_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/brand_mark.dart';
import '../about/about_screen.dart';
import '../community/community_screen.dart';
import '../help/help_support_screen.dart';
import '../login/admin_portal_screen.dart';
import '../privacy/privacy_center_screen.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.user,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
    this.protectionService,
    this.notificationService,
    this.communityService,
    this.callBridge,
    this.authService,
    this.onOpenGuardian,
    super.key,
  });

  final User user;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onLogout;
  final GuardianProtectionService? protectionService;
  final NotificationService? notificationService;
  final CommunityService? communityService;
  final CallBridge? callBridge;
  final AuthService? authService;
  final VoidCallback? onOpenGuardian;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User _currentUser = widget.user;
  bool _loggingOut = false;
  String? _errorMessage;

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user != widget.user) {
      _currentUser = widget.user;
    }
  }

  void _openAccountDetails() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AccountDetailsSheet(
        user: _currentUser,
        isDarkMode: widget.isDarkMode,
        authService: widget.authService,
        onUserUpdated: (updated) {
          setState(() => _currentUser = updated);
        },
        onChangePassword: _openChangePassword,
        onOpenPrivacySecurity: _openPrivacySecurity,
      ),
    );
  }

  void _openChangePassword() {
    final currentPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    bool changing = false;

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPassCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
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
                        if (currentPassCtrl.text.isEmpty ||
                            newPassCtrl.text.length < 8) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please enter valid passwords (minimum 8 characters).'),
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
                            const SnackBar(
                              content: Text('Password updated successfully.'),
                            ),
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

  void _openSettings() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          onOpenGuardian: widget.onOpenGuardian ?? () {},
          protectionService: widget.protectionService,
          notificationService: widget.notificationService,
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
          callBridge: widget.callBridge,
          authService: widget.authService,
          user: _currentUser,
          onUserUpdated: (updated) {
            setState(() => _currentUser = updated);
          },
        ),
      ),
    );
  }

  void _openPrivacySecurity() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => PrivacyCenterScreen(
          callBridge: widget.callBridge,
          authService: widget.authService,
          onAccountDeleted: () {
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
        ),
      ),
    );
  }

  void _openCommunity() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CommunityScreen(
          communityService: widget.communityService,
          user: _currentUser,
        ),
      ),
    );
  }

  void _openHelpSupport() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const HelpSupportScreen(),
      ),
    );
  }

  void _openAbout() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const AboutScreen(),
      ),
    );
  }

  void _openAdminPortal() {
    if (widget.authService == null) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AdminPortalScreen(
          user: _currentUser,
          adminService: AdminPortalService(
            api: widget.authService!.api,
            tokenProvider: () async =>
                (await widget.authService!.getStoredAdminToken()) ??
                (await widget.authService!.getStoredToken()),
          ),
          onLogout: _logout,
          onSessionExpired: _logout,
          isDarkMode: widget.isDarkMode,
          onToggleTheme: widget.onToggleTheme,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final colors = Theme.of(context).colorScheme;
    final isDark = widget.isDarkMode;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.exit_to_app_rounded,
                  color: colors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Log out?',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "You will be signed out from your account. You'll need to log in again to access ScamShield.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text(
                  'Log out',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  foregroundColor: colors.primary,
                  side: BorderSide(color: colors.primary.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _loggingOut = true;
      _errorMessage = null;
    });

    try {
      await widget.onLogout();
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not sign out. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDarkMode;
    final colors = theme.colorScheme;
    final user = _currentUser;

    final displayName = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : 'User';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          children: [
            // 1. Prominent More Title
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 20),
              child: Text(
                'More',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: isDark ? AppColors.textMainDark : const Color(0xFF0F172A),
                ),
              ),
            ),

            // 2. Profile Summary Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openAccountDetails,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: colors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                          child: Text(
                            displayName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: colors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello,',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                                ),
                              ),
                              Text(
                                displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 17,
                                      letterSpacing: -0.3,
                                      color: isDark ? AppColors.textMainDark : const Color(0xFF0F172A),
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Stay safe. Stay informed.',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: isDark ? AppColors.textMutedDark : const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. ScamShield Brand Information Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : const Color(0xFFE0F2FE).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : const Color(0xFFBAE6FD),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const ScamShieldBrandMark(size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ScamShield',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isDark ? AppColors.textMainDark : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Smarter protection. Safer you.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 4. Navigation Cards
            if (_currentUser.role.toLowerCase() == 'admin') ...[
              _MoreNavCard(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Admin Portal',
                subtitle: 'Command center, reviews, users and telemetry.',
                isDark: isDark,
                onTap: _openAdminPortal,
              ),
              const SizedBox(height: 10),
            ],

            _MoreNavCard(
              icon: Icons.person_outline_rounded,
              title: 'Account Details',
              subtitle: 'Profile, email and verification status.',
              isDark: isDark,
              onTap: _openAccountDetails,
            ),
            const SizedBox(height: 10),

            _MoreNavCard(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'App preferences and notifications.',
              isDark: isDark,
              onTap: _openSettings,
            ),
            const SizedBox(height: 10),

            _MoreNavCard(
              icon: Icons.shield_outlined,
              title: 'Privacy & Security',
              subtitle: 'Data, permissions and account safety.',
              isDark: isDark,
              onTap: _openPrivacySecurity,
            ),
            const SizedBox(height: 10),

            _MoreNavCard(
              icon: Icons.group_outlined,
              title: 'Community',
              subtitle: 'Share reports and stay informed.',
              isDark: isDark,
              onTap: _openCommunity,
            ),
            const SizedBox(height: 10),

            _MoreNavCard(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'FAQs, assistance and contact.',
              isDark: isDark,
              onTap: _openHelpSupport,
            ),
            const SizedBox(height: 10),

            _MoreNavCard(
              icon: Icons.info_outline_rounded,
              title: 'About',
              subtitle: 'App version and information.',
              isDark: isDark,
              onTap: _openAbout,
            ),
            const SizedBox(height: 18),

            // 5. Differentiated Logout Card (Red tinted card)
            _LogoutCard(
              isDark: isDark,
              loggingOut: _loggingOut,
              onTap: _loggingOut ? () {} : _logout,
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: colors.onErrorContainer, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MoreNavCard extends StatelessWidget {
  const _MoreNavCard({
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
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: colors.primary, size: 21),
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

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({
    required this.isDark,
    required this.loggingOut,
    required this.onTap,
  });

  final bool isDark;
  final bool loggingOut;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final redColor = colors.error;

    return Material(
      color: isDark
          ? redColor.withValues(alpha: 0.12)
          : redColor.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: redColor.withValues(alpha: isDark ? 0.35 : 0.25),
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
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: redColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loggingOut
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: redColor),
                      )
                    : Icon(Icons.logout_rounded, color: redColor, size: 21),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: redColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sign out from your account',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: redColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: redColor.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _AccountDetailsSheet extends StatefulWidget {
  const _AccountDetailsSheet({
    required this.user,
    required this.isDarkMode,
    this.authService,
    required this.onUserUpdated,
    required this.onChangePassword,
    required this.onOpenPrivacySecurity,
  });

  final User user;
  final bool isDarkMode;
  final AuthService? authService;
  final ValueChanged<User> onUserUpdated;
  final VoidCallback onChangePassword;
  final VoidCallback onOpenPrivacySecurity;

  @override
  State<_AccountDetailsSheet> createState() => _AccountDetailsSheetState();
}

class _AccountDetailsSheetState extends State<_AccountDetailsSheet> {
  late User _user = widget.user;
  bool _updating = false;

  void _editName() {
    final nameCtrl = TextEditingController(text: _user.fullName);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Full Name'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = nameCtrl.text.trim();
              if (newName.isEmpty) return;
              Navigator.of(ctx).pop();
              if (widget.authService == null) {
                final updated = _user.copyWith(fullName: newName);
                setState(() => _user = updated);
                widget.onUserUpdated(updated);
                return;
              }
              setState(() => _updating = true);
              try {
                final updated =
                    await widget.authService!.updateProfile(fullName: newName);
                if (mounted) {
                  setState(() => _user = updated);
                  widget.onUserUpdated(updated);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profile name updated successfully.')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update name: $e')),
                  );
                }
              } finally {
                if (mounted) setState(() => _updating = false);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = widget.isDarkMode;

    final createdAtStr = _user.createdAt != null
        ? '${_user.createdAt!.day}/${_user.createdAt!.month}/${_user.createdAt!.year}'
        : 'Active Member';

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.68,
      maxChildSize: 0.9,
      minChildSize: 0.45,
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
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      colors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                  child: Text(
                    _user.fullName.isNotEmpty
                        ? _user.fullName[0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _user.fullName,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w800, fontSize: 18),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Edit name',
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: _updating ? null : _editName,
                          ),
                        ],
                      ),
                      Text(
                        _user.email,
                        style: TextStyle(
                            fontSize: 13, color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),
            _DetailRow(
              label: 'Account Status',
              value: _user.emailVerified ? 'Verified Account' : 'Pending Verification',
              icon: _user.emailVerified
                  ? Icons.verified_user_rounded
                  : Icons.pending_actions_rounded,
              valueColor: _user.emailVerified
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'User Role',
              value: _user.role.toUpperCase(),
              icon: Icons.admin_panel_settings_outlined,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Two-Factor Authentication',
              value: _user.twoFactorEnabled ? 'Enabled' : 'Disabled',
              icon: Icons.security_rounded,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Email Notifications',
              value: _user.emailNotifications ? 'Enabled' : 'Disabled',
              icon: Icons.notifications_active_outlined,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Community Updates',
              value: _user.communityUpdates ? 'Subscribed' : 'Off',
              icon: Icons.forum_outlined,
            ),
            const SizedBox(height: 12),
            _DetailRow(
              label: 'Member Since',
              value: createdAtStr,
              icon: Icons.calendar_today_rounded,
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onChangePassword();
              },
              icon: const Icon(Icons.lock_reset_rounded),
              label: const Text('Change Account Password'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onOpenPrivacySecurity();
              },
              icon: const Icon(Icons.shield_outlined),
              label: const Text('Open Privacy & Security'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            color: colors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: valueColor ?? Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }
}
