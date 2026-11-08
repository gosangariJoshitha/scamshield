import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';

class AccountDetailsScreen extends StatefulWidget {
  const AccountDetailsScreen({
    required this.user,
    required this.isDarkMode,
    this.authService,
    required this.onUserUpdated,
    required this.onChangePassword,
    required this.onOpenPrivacySecurity,
    this.isSheet = false,
    super.key,
  });

  final User user;
  final bool isDarkMode;
  final AuthService? authService;
  final ValueChanged<User> onUserUpdated;
  final VoidCallback onChangePassword;
  final VoidCallback onOpenPrivacySecurity;
  final bool isSheet;

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> {
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

    final content = ListView(
      shrinkWrap: widget.isSheet,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        if (widget.isSheet) ...[
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
        ],
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
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: isDark ? AppColors.textMainDark : const Color(0xFF0F172A),
                          ),
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
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
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
            if (widget.isSheet) Navigator.of(context).pop();
            widget.onChangePassword();
          },
          icon: const Icon(Icons.lock_reset_rounded),
          label: const Text('Change Account Password'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 10),
        FilledButton.tonalIcon(
          onPressed: () {
            if (widget.isSheet) Navigator.of(context).pop();
            widget.onOpenPrivacySecurity();
          },
          icon: const Icon(Icons.shield_outlined),
          label: const Text('Open Privacy & Security'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );

    if (widget.isSheet) {
      return content;
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(
          'Account Details',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: isDark ? AppColors.textMainDark : const Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(child: content),
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

