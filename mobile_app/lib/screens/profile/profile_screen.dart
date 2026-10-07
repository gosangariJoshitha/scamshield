import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../privacy/privacy_center_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    required this.user,
    required this.isDarkMode,
    required this.onToggleTheme,
    required this.onLogout,
    super.key,
  });

  final User user;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;
  final Future<void> Function() onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loggingOut = false;
  late bool _isDarkMode = widget.isDarkMode;
  String? _errorMessage;

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      _isDarkMode = widget.isDarkMode;
    }
  }

  void _toggleTheme() {
    widget.onToggleTheme();
    setState(() => _isDarkMode = !_isDarkMode);
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out of ScamShield?'),
        content: const Text(
          'You will need to sign in again to access your analysis and call protection history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('LOG OUT'),
          ),
        ],
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

  void _showCommunityStatus() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Community'),
        content: const Text(
          'Community features are coming soon. Community activity is not shown in the mobile app yet.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Center(
              child: CircleAvatar(
                radius: 38,
                backgroundColor: colors.primaryContainer,
                child: Text(
                  widget.user.fullName.trim().isEmpty
                      ? '?'
                      : widget.user.fullName.trim()[0].toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.user.fullName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              widget.user.email,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            _SectionHeader(title: 'ACCOUNT'),
            _InfoTile(
              icon: Icons.verified_user_outlined,
              title: 'Account status',
              value: widget.user.isActive ? 'Active' : 'Inactive',
            ),
            _InfoTile(
              icon: Icons.mark_email_read_outlined,
              title: 'Email verification',
              value: widget.user.emailVerified ? 'Verified' : 'Not verified',
            ),
            const SizedBox(height: 22),
            const _SectionHeader(title: 'SECURITY'),
            _InfoTile(
              icon: Icons.lock_outline,
              title: 'Session security',
              value: 'Your account session is protected on this device',
            ),
            _InfoTile(
              icon: Icons.verified_user_outlined,
              title: 'Two-step verification',
              value: widget.user.twoFactorEnabled ? 'Enabled' : 'Not enabled',
            ),
            const SizedBox(height: 22),
            const _SectionHeader(title: 'PREFERENCES'),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 15),
              secondary: Icon(
                _isDarkMode
                    ? Icons.dark_mode_outlined
                    : Icons.light_mode_outlined,
              ),
              title: const Text('Dark theme'),
              subtitle: const Text('Switch between light and dark appearance'),
              value: _isDarkMode,
              onChanged: (_) => _toggleTheme(),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              tileColor: colors.surface,
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.people_outline,
              title: 'Community',
              subtitle: 'Coming soon',
              onTap: _showCommunityStatus,
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy & Protection',
              subtitle: 'How ScamShield protects your call audio & data',
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => const PrivacyCenterScreen(),
                ),
              ),
            ),
            const SizedBox(height: 26),
            if (_errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: colors.onErrorContainer),
                ),
              ),
            ],
            OutlinedButton.icon(
              onPressed: _loggingOut ? null : _logout,
              icon: _loggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout),
              label: Text(_loggingOut ? 'Signing out…' : 'Log out'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: colors.error,
                side: BorderSide(color: colors.error.withValues(alpha: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 9),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      leading: Icon(icon, color: colors.primary),
      title: Text(title),
      subtitle: Text(value),
      tileColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 15),
      leading: Icon(icon, color: colors.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      tileColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
