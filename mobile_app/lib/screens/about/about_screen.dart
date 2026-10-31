import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/brand_mark.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  void _showFeatures(BuildContext context) {
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
                  'ScamShield Features',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                _FeatureItem(
                  icon: Icons.search_rounded,
                  title: 'Multichannel Content Analysis',
                  description:
                      'Analyze suspicious SMS messages, emails, UPI requests, URLs, and image screenshots with multi-model AI reasoning.',
                ),
                const SizedBox(height: 12),
                _FeatureItem(
                  icon: Icons.shield_rounded,
                  title: 'Sentinel Live Call Guardian',
                  description:
                      'Background call-state detection, real-time on-device audio transcription, and immediate in-call scam indicator alerts.',
                ),
                const SizedBox(height: 12),
                _FeatureItem(
                  icon: Icons.translate_rounded,
                  title: 'Multilingual Safety Recommendations',
                  description:
                      'Instant protective guidance localized in English, Hindi, and Telugu to protect users across regions.',
                ),
                const SizedBox(height: 12),
                _FeatureItem(
                  icon: Icons.group_outlined,
                  title: 'Community Scam Reporting',
                  description:
                      'Report fraud patterns to help protect other users and stay informed on trending imposter threats.',
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTechnology(BuildContext context) {
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
          initialChildSize: 0.55,
          maxChildSize: 0.8,
          minChildSize: 0.35,
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
                  'Technology & Architecture',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                _FeatureItem(
                  icon: Icons.psychology_outlined,
                  title: 'AI & Machine Learning',
                  description:
                      'Sentence Transformers embeddings, RAG pattern matching, and Gemini LLM reasoning pipeline.',
                ),
                const SizedBox(height: 12),
                _FeatureItem(
                  icon: Icons.mic_rounded,
                  title: 'Audio & Speech Recognition',
                  description:
                      'Whisper speech-to-text models processing ephemeral audio chunks during active calls without permanent recording.',
                ),
                const SizedBox(height: 12),
                _FeatureItem(
                  icon: Icons.cloud_outlined,
                  title: 'FastAPI Backend',
                  description:
                      'High-performance asynchronous Python backend with SQLAlchemy ORM and Alembic schema migrations.',
                ),
                const SizedBox(height: 12),
                _FeatureItem(
                  icon: Icons.smartphone_rounded,
                  title: 'Flutter Mobile App',
                  description:
                      'Cross-platform Flutter framework with native Kotlin foreground services and platform channels on Android.',
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAcknowledgements(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'ScamShield',
      applicationVersion: '$appVersion (Build $buildNumber)',
      applicationLegalese: '© 2026 ScamShield. All rights reserved.',
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
        title: const Text('About'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardElevated
                      : colors.primaryContainer.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const ScamShieldBrandMark(size: 68),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'ScamShield',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Detect • Analyze • Protect',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Version $appVersion (Build $buildNumber)',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),

            // 1. Mission Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: isDark ? 0.2 : 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.shield_outlined, color: colors.primary, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Our Mission',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'To make digital and communication spaces safer by using AI to detect and prevent scams across calls, messages, links and more.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // 2. Features Card
            _NavigationCard(
              icon: Icons.auto_awesome_rounded,
              title: 'Features',
              subtitle: 'What ScamShield can do',
              isDark: isDark,
              onTap: () => _showFeatures(context),
            ),
            const SizedBox(height: 12),

            // 3. Technology Card
            _NavigationCard(
              icon: Icons.memory_rounded,
              title: 'Technology',
              subtitle: 'AI, ML, RAG and more',
              isDark: isDark,
              onTap: () => _showTechnology(context),
            ),
            const SizedBox(height: 12),

            // 4. Acknowledgements Card
            _NavigationCard(
              icon: Icons.favorite_border_rounded,
              title: 'Acknowledgements',
              subtitle: 'Open source libraries and credits',
              isDark: isDark,
              onTap: () => _showAcknowledgements(context),
            ),

            const SizedBox(height: 36),
            Text(
              '© 2026 ScamShield. All rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
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

class _FeatureItem extends StatelessWidget {
  const _FeatureItem({
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
              const SizedBox(height: 4),
              Text(
                description,
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
    );
  }
}
