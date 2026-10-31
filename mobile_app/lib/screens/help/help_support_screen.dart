import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const String supportEmail = 'security@scamshield.ai';

  void _showFaqs(BuildContext context) {
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
                  'Frequently Asked Questions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 16),
                const _FaqTile(
                  question: 'Does ScamShield record my phone calls?',
                  answer:
                      'No. ScamShield never permanently stores call audio. During active calls, temporary audio chunks are transcribed in ephemeral memory and immediately discarded. Only high-level risk indicators are preserved.',
                ),
                const _FaqTile(
                  question: 'What types of content can I analyze?',
                  answer:
                      'You can analyze suspicious SMS text messages, WhatsApp or Telegram forwards, email text, UPI payment requests, shortened web URLs, and screenshots containing text.',
                ),
                const _FaqTile(
                  question: 'Can ScamShield hang up calls automatically?',
                  answer:
                      'No. ScamShield operates on explicit user consent. We provide real-time alerts and recommendations, but you retain complete control over answering, muting, or ending calls.',
                ),
                const _FaqTile(
                  question: 'How do multilingual recommendations work?',
                  answer:
                      'Safety warnings and actionable advice can be viewed in English, Hindi (हिंदी), and Telugu (తెలుగు) directly on the analysis results screen.',
                ),
                const _FaqTile(
                  question: 'Is my personal information shared with third parties?',
                  answer:
                      'No. Your submitted content and analysis history are strictly tied to your account and never sold or shared with advertisers or third-party data brokers.',
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showContactUs(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Our trust and security team is available to assist you with inquiries, false positives, or account questions.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Official Email:',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            SelectableText(
              supportEmail,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Operating Hours: Mon - Fri, 9:00 AM - 6:00 PM IST',
              style: TextStyle(fontSize: 12),
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

  void _showReportIssue(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report an Issue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe the issue, bug, or incorrect analysis result you encountered:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Enter details here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Note: Please do not include passwords or personal credit card information.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Issue report received. Our engineering team will review it.'),
                ),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showUserGuide(BuildContext context) {
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
                  'ScamShield User Guide',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                const _GuideStep(
                  step: '1',
                  title: 'Analyze Suspicious Messages & Links',
                  description:
                      'Paste text, URLs, or upload screenshots into the Analyze tab to evaluate risk scores, indicators, and recommended actions.',
                ),
                const SizedBox(height: 12),
                const _GuideStep(
                  step: '2',
                  title: 'Enable Sentinel Call Protection',
                  description:
                      'Activate Sentinel from the Guardian tab. Grant phone state and notification permissions to allow background call monitoring.',
                ),
                const SizedBox(height: 12),
                const _GuideStep(
                  step: '3',
                  title: 'Review Risk Assessment During Calls',
                  description:
                      'When Sentinel detects high-risk scam patterns such as urgent OTP requests or impersonation, haptic and visual alerts will inform you.',
                ),
                const SizedBox(height: 12),
                const _GuideStep(
                  step: '4',
                  title: 'Inspect Analysis History & Call Summaries',
                  description:
                      'Check past analyses, indicators, and call protection reports under the History tab at any time.',
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTerms(BuildContext context) {
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
                  'Terms & Conditions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                Text(
                  '1. Acceptance of Terms\nBy creating an account and using ScamShield, you agree to these Terms and Conditions. ScamShield is an AI-powered advisory tool intended to help identify potential scam indicators.\n\n'
                  '2. Advisory Purpose\nScamShield results represent statistical risk assessments and AI heuristics. While we strive for high precision, ScamShield does not guarantee 100% detection of all fraudulent communications. Users should practice prudent caution before sharing sensitive credentials or funds.\n\n'
                  '3. Account Responsibility\nYou are responsible for safeguarding your login credentials. If you suspect unauthorized access, reset your password immediately.\n\n'
                  '4. Permitted Use\nYou agree not to reverse engineer or abuse ScamShield automated APIs for unauthorized high-volume scanning or malicious purposes.\n\n'
                  '5. Limitation of Liability\nScamShield and its operators are not liable for losses resulting from user financial transactions executed independently.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
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
                  'Privacy Policy',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 14),
                Text(
                  '1. Information We Process\nWhen you submit content for analysis, we process text, links, and image content through our threat detection models. During Sentinel protection, live call audio chunks are transcribed in ephemeral memory and discarded immediately without persistent audio storage.\n\n'
                  '2. Account Data\nWe store your email address, hashed credentials, and analysis history tied to your account to provide service continuity. We never sell your personal information.\n\n'
                  '3. Ephemeral Call Protection\nSpeech-to-text transcripts generated during protected calls are ephemeral. Only high-level risk classifications, detected indicator categories, and duration summaries are saved to your account.\n\n'
                  '4. Account Deletion\nYou have the right to permanently delete your account and all associated analysis records directly from the Privacy & Security settings at any time.\n\n'
                  '5. Contact\nFor privacy inquiries, contact security@scamshield.ai.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                    height: 1.45,
                  ),
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
        title: const Text('Help & Support'),
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
                    child: Icon(Icons.headset_mic_rounded, color: colors.primary, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "We're here to help",
                          style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Find answers, get support or reach out to our team.',
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

            _HelpTile(
              icon: Icons.help_outline_rounded,
              title: 'FAQs',
              subtitle: 'Quick answers to common questions',
              isDark: isDark,
              onTap: () => _showFaqs(context),
            ),
            const SizedBox(height: 12),

            _HelpTile(
              icon: Icons.mail_outline_rounded,
              title: 'Contact Us',
              subtitle: 'Email, support form or call',
              isDark: isDark,
              onTap: () => _showContactUs(context),
            ),
            const SizedBox(height: 12),

            _HelpTile(
              icon: Icons.bug_report_outlined,
              title: 'Report an Issue',
              subtitle: 'App bugs, wrong results, etc.',
              isDark: isDark,
              onTap: () => _showReportIssue(context),
            ),
            const SizedBox(height: 12),

            _HelpTile(
              icon: Icons.menu_book_rounded,
              title: 'User Guide',
              subtitle: 'Learn how to use ScamShield',
              isDark: isDark,
              onTap: () => _showUserGuide(context),
            ),
            const SizedBox(height: 12),

            _HelpTile(
              icon: Icons.description_outlined,
              title: 'Terms & Conditions',
              subtitle: 'Read our terms and policies',
              isDark: isDark,
              onTap: () => _showTerms(context),
            ),
            const SizedBox(height: 12),

            _HelpTile(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy Policy',
              subtitle: 'How we protect your data',
              isDark: isDark,
              onTap: () => _showPrivacyPolicy(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpTile extends StatelessWidget {
  const _HelpTile({
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

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
  });

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        Text(
          answer,
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _GuideStep extends StatelessWidget {
  const _GuideStep({
    required this.step,
    required this.title,
    required this.description,
  });

  final String step;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: colors.primary,
          child: Text(
            step,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          ),
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
