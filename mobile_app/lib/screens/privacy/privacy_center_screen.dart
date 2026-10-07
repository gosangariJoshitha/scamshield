import 'package:flutter/material.dart';

import '../../widgets/brand_mark.dart';

class PrivacyCenterScreen extends StatelessWidget {
  const PrivacyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy & Protection'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const ScamShieldBrandMark(size: 44),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Privacy Matters',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ScamShield is engineered with strict privacy safeguards by design.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'DATA SAFEGUARDS',
              style: theme.textTheme.labelSmall?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            _PrivacyItem(
              icon: Icons.mic_off_outlined,
              title: 'No Permanent Audio Recording',
              description:
                  'Call audio is never saved to device storage or servers. Audio chunks are analyzed in temporary memory and promptly discarded.',
            ),
            const SizedBox(height: 12),
            _PrivacyItem(
              icon: Icons.timer_outlined,
              title: 'Ephemeral Call Transcripts',
              description:
                  'Live speech-to-text transcripts are temporary and cleared from memory upon session finalization. Only high-level risk summaries and matched indicators are retained.',
            ),
            const SizedBox(height: 12),
            _PrivacyItem(
              icon: Icons.password_rounded,
              title: 'No Credential or OTP Logging',
              description:
                  'Sensitive credentials, passwords, bank account details, and one-time passcodes are strictly excluded from diagnostics, telemetry, and system logs.',
            ),
            const SizedBox(height: 12),
            _PrivacyItem(
              icon: Icons.touch_app_outlined,
              title: 'Explicit User Confirmation',
              description:
                  'All protective actions (ending calls, blocking numbers, reporting fraud) require your explicit consent. ScamShield never acts autonomously without your permission.',
            ),
            const SizedBox(height: 12),
            _PrivacyItem(
              icon: Icons.lock_outline,
              title: 'Isolated & Encrypted Account Data',
              description:
                  'Your analysis records and call summaries are strictly isolated to your verified account and authenticated using industry-standard tokens.',
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151C28) : colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Icon(Icons.shield_outlined, color: colors.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Questions or privacy concerns? Reach our trust and safety team at security@scamshield.ai.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
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

class _PrivacyItem extends StatelessWidget {
  const _PrivacyItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.4),
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
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
