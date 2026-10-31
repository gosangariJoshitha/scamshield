import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../native/call_bridge.dart';
import '../../services/auth_service.dart';
import '../../services/community_service.dart';
import '../../services/guardian_protection_service.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/brand_mark.dart';
import '../about/about_screen.dart';
import '../community/community_screen.dart';
import '../help/help_support_screen.dart';
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
  bool _loggingOut = false;
  String? _errorMessage;

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
    final user = widget.user;

    final displayName = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : 'User';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('More'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          children: [
            // 1. Profile Header Row (Avatar, "Hello,", Name, "Stay safe. Stay informed.")
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: colors.primary.withValues(alpha: isDark ? 0.25 : 0.15),
                  child: Text(
                    displayName[0].toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: colors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello,',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                        ),
                      ),
                      Text(
                        displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
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
              ],
            ),
            const SizedBox(height: 20),

            // 2. ScamShield Brand Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkCardElevated
                    : colors.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  const ScamShieldBrandMark(size: 38),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ScamShield',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Smarter protection. Safer you.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 3. Navigation Cards
            _MoreNavCard(
              icon: Icons.settings_outlined,
              title: 'Settings',
              subtitle: 'App preferences & notifications',
              isDark: isDark,
              onTap: _openSettings,
            ),
            const SizedBox(height: 10),

            _MoreNavCard(
              icon: Icons.shield_outlined,
              title: 'Privacy & Security',
              subtitle: 'Data, permissions & account safety',
              isDark: isDark,
              onTap: _openPrivacySecurity,
            ),
            const SizedBox(height: 10),

            _MoreNavCard(
              icon: Icons.group_outlined,
              title: 'Community',
              subtitle: 'Share, learn & stay informed',
              isDark: isDark,
              onTap: _openCommunity,
            ),
            const SizedBox(height: 10),

            _MoreNavCard(
              icon: Icons.help_outline_rounded,
              title: 'Help & Support',
              subtitle: 'Get help and contact us',
              isDark: isDark,
              onTap: _openHelpSupport,
            ),
            const SizedBox(height: 10),

            _MoreNavCard(
              icon: Icons.info_outline_rounded,
              title: 'About',
              subtitle: 'App version & more',
              isDark: isDark,
              onTap: _openAbout,
            ),
            const SizedBox(height: 20),

            // 4. Differentiated Logout Card (Red tinted card)
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: redColor.withValues(alpha: isDark ? 0.2 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: loggingOut
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: redColor),
                      )
                    : Icon(Icons.logout_rounded, color: redColor, size: 22),
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
