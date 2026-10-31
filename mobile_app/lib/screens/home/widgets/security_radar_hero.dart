import 'package:flutter/material.dart';

import '../../../native/call_bridge.dart';

/// Colorful, deeply informative Security Radar & AI Defense Hero Card
/// specifying ScamShield 2.0 active security posture at a glance.
class SecurityRadarHeroCard extends StatelessWidget {
  const SecurityRadarHeroCard({
    required this.guardianStatus,
    this.totalScans = 0,
    this.scamsDetected = 0,
    this.onOpenSentinel,
    super.key,
  });

  final CallGuardianStatus? guardianStatus;
  final int totalScans;
  final int scamsDetected;
  final VoidCallback? onOpenSentinel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isProtected =
        guardianStatus?.enabled == true && guardianStatus?.serviceRunning == true;

    final statusColor = isProtected
        ? const Color(0xFF10B981) // Emerald Green
        : const Color(0xFFF59E0B); // Amber
    final statusText = isProtected ? 'SHIELD ACTIVE' : 'SHIELD PAUSED';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF132F3D),
                  Color(0xFF101F2B),
                  Color(0xFF0F172A),
                ]
              : const [
                  Color(0xFF086B73),
                  Color(0xFF0D5A68),
                  Color(0xFF102A43),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : const Color(0xFF086B73))
                .withValues(alpha: isDark ? 0.35 : 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: (isDark ? const Color(0xFF65D4D8) : const Color(0xFFA8EDF3))
              .withValues(alpha: isDark ? 0.3 : 0.35),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Status Header Row
            Row(
              children: [
                // Glowing Shield Badge
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isProtected ? Icons.security_rounded : Icons.shield_outlined,
                      color: isProtected ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: statusColor.withValues(alpha: 0.8),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              statusText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'AI Threat Defense Engine',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onOpenSentinel != null)
                  IconButton(
                    onPressed: onOpenSentinel,
                    icon: const Icon(
                      Icons.tune_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                    tooltip: 'Sentinel Settings',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Clear Reassurance Specification
            Text(
              'Continuous multi-modal AI screening for fraudulent calls, phishing links, and deceptive media.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // 3 Colorful Capability Chips Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _DefenseChip(
                  icon: Icons.phone_in_talk_rounded,
                  label: isProtected ? 'Sentinel Active' : 'Sentinel Ready',
                  accentColor: const Color(0xFF34D399), // Emerald
                ),
                const _DefenseChip(
                  icon: Icons.document_scanner_rounded,
                  label: 'Multi-Modal AI',
                  accentColor: Color(0xFF38BDF8), // Light Blue
                ),
                const _DefenseChip(
                  icon: Icons.lock_outline_rounded,
                  label: '100% Private',
                  accentColor: Color(0xFFA78BFA), // Violet
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DefenseChip extends StatelessWidget {
  const _DefenseChip({
    required this.icon,
    required this.label,
    required this.accentColor,
  });

  final IconData icon;
  final String label;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: accentColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
