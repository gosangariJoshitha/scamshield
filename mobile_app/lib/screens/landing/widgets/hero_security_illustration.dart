import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Custom clipper that draws a security shield with rounded apex and curved base.
class ShieldClipper extends CustomClipper<Path> {
  const ShieldClipper();

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final cornerRadius = w * 0.12;

    path.moveTo(cornerRadius, 0);
    path.lineTo(w - cornerRadius, 0);
    path.quadraticBezierTo(w, 0, w, cornerRadius);
    path.lineTo(w, h * 0.58);
    path.cubicTo(w, h * 0.82, w * 0.55, h * 0.96, w * 0.5, h);
    path.cubicTo(w * 0.45, h * 0.96, 0, h * 0.82, 0, h * 0.58);
    path.lineTo(0, cornerRadius);
    path.quadraticBezierTo(0, 0, cornerRadius, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

/// Custom painter that draws the glowing border for the security shield.
class ShieldBorderPainter extends CustomPainter {
  const ShieldBorderPainter({
    required this.strokeColor,
    required this.strokeWidth,
  });

  final Color strokeColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = const ShieldClipper().getClip(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ShieldBorderPainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

/// A security hero illustration directly matching the approved
/// ScamShield 2.0 design reference (1000261210.png).
///
/// Features a central glowing cyan/teal shield with a white checkmark,
/// surrounded by four floating capability badges (Messages, Calls, Images, PDF & Docs)
/// and ambient luminous particles.
class HeroSecurityIllustration extends StatelessWidget {
  const HeroSecurityIllustration({this.size = 230, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryAccent =
        isDark ? AppColors.darkPrimary : const Color(0xFF06B6D4);
    final glowColor = primaryAccent.withValues(alpha: isDark ? 0.35 : 0.22);

    final shieldWidth = size * 0.52;
    final shieldHeight = size * 0.62;

    return Semantics(
      label: 'Security Shield Illustration with AI protection capabilities',
      image: true,
      child: Center(
        child: SizedBox(
          width: size * 1.35,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // 1. Ambient Glow Halo Behind Shield
              Container(
                width: shieldWidth * 1.5,
                height: shieldHeight * 1.3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor,
                      blurRadius: 45,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),

              // 2. Central Glowing Shield
              SizedBox(
                width: shieldWidth,
                height: shieldHeight,
                child: Stack(
                  children: [
                    ClipPath(
                      clipper: const ShieldClipper(),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? const [
                                    Color(0xFF65D4D8),
                                    Color(0xFF0E7490),
                                    Color(0xFF083344),
                                  ]
                                : const [
                                    Color(0xFFA8EDF3),
                                    Color(0xFF0891B2),
                                    Color(0xFF086B73),
                                  ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: shieldWidth * 0.52,
                            color: Colors.white,
                            shadows: const [
                              Shadow(
                                color: Color(0x66000000),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    CustomPaint(
                      size: Size(shieldWidth, shieldHeight),
                      painter: ShieldBorderPainter(
                        strokeColor: Colors.white.withValues(alpha: 0.85),
                        strokeWidth: 2.2,
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Floating Particle Sparkles
              Positioned(
                top: size * 0.12,
                left: size * 0.28,
                child: _ParticleDot(color: primaryAccent, size: 5),
              ),
              Positioned(
                top: size * 0.18,
                right: size * 0.26,
                child: _ParticleDot(color: primaryAccent, size: 4),
              ),
              Positioned(
                bottom: size * 0.15,
                left: size * 0.24,
                child: _ParticleDot(color: primaryAccent, size: 6),
              ),
              Positioned(
                bottom: size * 0.18,
                right: size * 0.22,
                child: _ParticleDot(color: primaryAccent, size: 5),
              ),

              // 4. Four Floating Capability Badges (Matching 1000261210.png)
              // Top-Left: Messages (Cyan)
              Positioned(
                top: size * 0.08,
                left: size * 0.06,
                child: _FloatingCapabilityBadge(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: const Color(0xFF0284C7),
                  backgroundColor: isDark ? const Color(0xFF0C2438) : const Color(0xFFF0F9FF),
                  borderColor: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.6 : 0.4),
                  glowColor: const Color(0xFF06B6D4),
                ),
              ),

              // Top-Right: Calls (Vibrant Blue)
              Positioned(
                top: size * 0.08,
                right: size * 0.06,
                child: _FloatingCapabilityBadge(
                  icon: Icons.phone_outlined,
                  iconColor: const Color(0xFF2563EB),
                  backgroundColor: isDark ? const Color(0xFF132247) : const Color(0xFFEFF6FF),
                  borderColor: const Color(0xFF2563EB).withValues(alpha: isDark ? 0.6 : 0.4),
                  glowColor: const Color(0xFF3B82F6),
                ),
              ),

              // Bottom-Left: Images (Emerald Teal)
              Positioned(
                bottom: size * 0.16,
                left: size * 0.03,
                child: _FloatingCapabilityBadge(
                  icon: Icons.image_outlined,
                  iconColor: const Color(0xFF0D9488),
                  backgroundColor: isDark ? const Color(0xFF0D2E2B) : const Color(0xFFF0FDF4),
                  borderColor: const Color(0xFF0D9488).withValues(alpha: isDark ? 0.6 : 0.4),
                  glowColor: const Color(0xFF10B981),
                ),
              ),

              // Bottom-Right: PDF & Documents (Indigo/Violet)
              Positioned(
                bottom: size * 0.16,
                right: size * 0.03,
                child: _FloatingCapabilityBadge(
                  icon: Icons.description_outlined,
                  iconColor: const Color(0xFF6366F1),
                  backgroundColor: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                  borderColor: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.6 : 0.4),
                  glowColor: const Color(0xFF818CF8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingCapabilityBadge extends StatelessWidget {
  const _FloatingCapabilityBadge({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.borderColor,
    required this.glowColor,
  });

  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          icon,
          size: 22,
          color: iconColor,
        ),
      ),
    );
  }
}

class _ParticleDot extends StatelessWidget {
  const _ParticleDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.8),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.6),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
