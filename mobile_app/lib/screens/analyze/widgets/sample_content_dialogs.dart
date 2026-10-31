import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// Educational sample messages, documents, and audio transcripts for scam awareness.
abstract final class SampleScamData {
  static const List<Map<String, String>> messages = [
    {
      'title': 'Bank KYC Suspension Scam',
      'category': 'Banking Fraud',
      'content':
          'Dear Customer, your SBI bank account has been suspended due to pending KYC update. Click http://sbi-kyc-verify.xyz to update your PAN and Aadhaar immediately to avoid permanent closure.',
    },
    {
      'title': 'Lottery / Prize Claim Scam',
      'category': 'Lottery Fraud',
      'content':
          'Congratulations! You have won a cash prize of ₹50,000 in the Diwali Special Draw. Click the link below to verify your identity and claim your reward: http://bit.ly/claim-now-50k',
    },
    {
      'title': 'Work-from-Home Job Offer',
      'category': 'Employment Fraud',
      'content':
          'Part-time job opportunity! Earn ₹3,000 - ₹8,000 daily working 1-2 hours from home. Simply like YouTube videos and rate hotel reviews. WhatsApp HR on +91 98765 43210 to start today.',
    },
    {
      'title': 'Electricity Disconnection Threat',
      'category': 'Utility Bill Scam',
      'content':
          'URGENT: Your electricity power supply will be disconnected tonight at 9:30 PM because your previous month bill was not updated. Immediately contact Electricity Officer on 9876543210.',
    },
  ];

  static const List<Map<String, String>> documents = [
    {
      'title': 'Fake Job Offer Letter (PDF)',
      'category': 'Employment Fraud',
      'description':
          'Forged multinational company appointment letter requiring an upfront "refundable security deposit" of ₹9,500.',
      'sampleText':
          'Appointment Offer Letter - TechCorp Global Services. Congratulations! You are selected as Senior Executive. Note: Mandatory equipment deposit of ₹9,500 required via UPI prior to training commencement.',
    },
    {
      'title': 'Suspicious Customs Notice (PDF)',
      'category': 'Courier / Customs Scam',
      'description':
          'Counterfeit customs clearance invoice claiming illegal narcotics detected in an overseas courier parcel.',
      'sampleText':
          'Department of Customs and Border Protection. Notice of Seizure: Parcel #IN-90823 flagged for prohibited substances. Pay administrative settlement fine within 24 hours to prevent arrest warrant.',
    },
  ];

  static const List<Map<String, String>> audios = [
    {
      'title': 'Digital Arrest Cyber Crime Call',
      'category': 'Impersonation Scam',
      'description':
          'Automated IVR call from fake CBI / Cyber Crime cell claiming your Aadhaar is linked to money laundering.',
      'transcript':
          '"This is an automated priority call from the Central Cyber Crime Cell. A case has been registered against your Aadhaar card for illegal fund transfers. Press 1 to speak with the investigating officer or face immediate arrest."',
    },
    {
      'title': 'Bank Credit Card Upgrade IVR',
      'category': 'Banking Impersonation',
      'description':
          'Robocall claiming your credit card points are expiring and asking you to confirm card details and OTP.',
      'transcript':
          '"Your reward points worth ₹14,250 are expiring today on your credit card. To convert your points into cash balance in your bank account, please share the 6-digit confirmation code sent to your mobile phone."',
    },
  ];
}

/// Dialog to select an educational sample message.
class SampleMessagesDialog extends StatelessWidget {
  const SampleMessagesDialog({
    required this.onMessageSelected,
    super.key,
  });

  final ValueChanged<String> onMessageSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final primaryTeal = isDark ? AppColors.darkPrimary : AppColors.primary;

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryTeal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.forum_outlined, color: primaryTeal, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Sample Scams',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select an educational scam example to load into the text analyzer:',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: SampleScamData.messages.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final msg = SampleScamData.messages[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        onMessageSelected(msg['content']!);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    msg['title']!,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    msg['category']!,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              msg['content']!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 12,
                                color: isDark
                                    ? AppColors.textMutedDark
                                    : AppColors.textMutedLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

/// Dialog presenting educational sample documents or audio files.
class SampleInfoDialog extends StatelessWidget {
  const SampleInfoDialog({
    required this.title,
    required this.subtitle,
    required this.items,
    this.onLoadText,
    super.key,
  });

  final String title;
  final String subtitle;
  final List<Map<String, String>> items;
  final ValueChanged<String>? onLoadText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final primaryTeal = isDark ? AppColors.darkPrimary : AppColors.primary;

    return AlertDialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              final content = item['sampleText'] ?? item['transcript'] ?? '';
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['title']!,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['description']!,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    if (onLoadText != null && content.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onLoadText!(content);
                          },
                          icon: Icon(Icons.arrow_forward_rounded, size: 16, color: primaryTeal),
                          label: Text(
                            'Analyze this text',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: primaryTeal,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
