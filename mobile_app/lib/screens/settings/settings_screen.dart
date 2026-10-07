import 'package:flutter/material.dart';

import '../../models/guardian_protection_models.dart';
import '../../services/guardian_protection_service.dart';

import '../privacy/privacy_center_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    required this.onOpenGuardian,
    this.protectionService,
    super.key,
  });

  final VoidCallback onOpenGuardian;
  final GuardianProtectionService? protectionService;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
          children: [
            Text(
              'PROTECTION',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 9),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                minVerticalPadding: 14,
                leading: Icon(Icons.shield_outlined, color: colors.primary),
                title: const Text(
                  'Live Call Guardian',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'Manage call monitoring and device support',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => CallProtectionSettingsScreen(
                      onOpenGuardian: onOpenGuardian,
                      protectionService: protectionService,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'PRIVACY',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 9),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                minVerticalPadding: 14,
                leading: Icon(Icons.privacy_tip_outlined, color: colors.primary),
                title: const Text(
                  'Privacy Center',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: const Text(
                  'How your audio, transcripts, and account data are protected',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (_) => const PrivacyCenterScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Theme preferences are available from the profile menu.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
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
