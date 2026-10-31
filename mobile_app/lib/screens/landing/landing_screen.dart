import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/common/secondary_button.dart';
import '../../widgets/theme_mode_toggle.dart';
import '../auth/authentication_screen.dart';
import 'widgets/built_for_safer_digital_you.dart';
import 'widgets/capability_shortcuts.dart';
import 'widgets/hero_security_illustration.dart';
import 'widgets/landing_footer.dart';
import 'widgets/trusted_protection_strip.dart';
import 'widgets/why_choose_scamshield.dart';

/// ScamShield 2.0 Landing Screen
///
/// Designed in strict accordance with the approved master blueprint and
/// reference flow (1000261210.png).
///
/// Sections:
/// A. Brand Header (App icon, wordmark, subtitle, theme toggle)
/// B. Hero Area (Hero security illustration, bold headline, supporting copy)
/// C. Primary Actions (Get Started ->, Login)
/// D. Quick Capability Shortcuts (Messages, Calls, Images, PDF & Docs)
/// E. Trusted Protection Strip (3 trust pillars)
/// F. Feature Overview ("Why Choose ScamShield?" + "Your Privacy Comes First")
/// G. Trust & Closing Section ("Built for a Safer Digital You" + Closing CTAs)
/// H. Minimal Footer (Legal links, copyright, direct Admin Sign-in)
class LandingScreen extends StatefulWidget {
  const LandingScreen({
    required this.authService,
    required this.onAuthenticated,
    required this.onAdminAuthenticated,
    required this.onThemeChanged,
    this.initialMessage,
    super.key,
  });

  final AuthService authService;
  final ValueChanged<User> onAuthenticated;
  final ValueChanged<User> onAdminAuthenticated;
  final ValueChanged<bool> onThemeChanged;
  final String? initialMessage;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  String? _navigatingMode;
  bool get _isNavigating => _navigatingMode != null;

  void _openAuthentication(
    BuildContext context, {
    String initialMode = 'login',
    String? message,
  }) {
    if (_isNavigating) return;
    setState(() => _navigatingMode = initialMode);

    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => AuthenticationScreen(
              authService: widget.authService,
              initialMode: initialMode,
              initialMessage: message ?? widget.initialMessage,
              onThemeChanged: widget.onThemeChanged,
              onAuthenticated: (user) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                widget.onAuthenticated(user);
              },
              onAdminAuthenticated: (user) {
                Navigator.of(context).popUntil((route) => route.isFirst);
                widget.onAdminAuthenticated(user);
              },
            ),
          ),
        )
        .then((_) {
          if (mounted) {
            setState(() => _navigatingMode = null);
          }
        });
  }

  void _showCapabilityInfo(BuildContext context, String title) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title capability available. Sign in or create an account to start analyzing.',
        ),
        action: SnackBarAction(
          label: 'Get Started',
          onPressed: () => _openAuthentication(context, initialMode: 'signup'),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;

    final primaryAccent =
        dark ? AppColors.darkPrimary : AppColors.primary;
    final headlineColor =
        dark ? AppColors.textMainDark : AppColors.textMainLight;
    final bodyColor =
        dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor:
          dark ? AppColors.darkBackground : AppColors.lightBackground,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: dark
                      ? const [
                          Color(0xFF101820),
                          Color(0xFF0D1520),
                          Color(0xFF0A1017),
                        ]
                      : const [
                          Color(0xFFE8F7F9),
                          Color(0xFFF4F7FA),
                          Color(0xFFFFFFFF),
                        ],
                ),
              ),
            ),
          ),

          // Luminous Ambient Bottom Wave (matching Screens 1 & 2 of 1000261210.png)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 220,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _AmbientBottomWavePainter(dark: dark),
              ),
            ),
          ),

          // Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 36),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSpacing.maxContentWidth,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // SECTION A: BRAND HEADER
                    _BrandHeader(
                      dark: dark,
                      onThemeChanged: widget.onThemeChanged,
                    ),
                    const SizedBox(height: 18),

                    // SECTION B: HERO AREA (Illustration, Headline, Copy)
                    const HeroSecurityIllustration(size: 210),
                    const SizedBox(height: 20),

                    // Headline: "Don't Just Detect Scams. Understand Them."
                    Text(
                      "Don't Just Detect Scams.",
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -0.7,
                        color: headlineColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Understand Them.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        height: 1.15,
                        letterSpacing: -0.7,
                        color: primaryAccent,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Supporting copy
                    Text(
                      'Analyze suspicious messages, calls, images, documents and more with AI — and stay one step ahead.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: bodyColor,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 22),

                    // SECTION C: PRIMARY ACTIONS
                    PrimaryButton(
                      label: _navigatingMode == 'signup'
                          ? 'Opening Sign Up...'
                          : 'Get Started →',
                      onPressed: _isNavigating
                          ? null
                          : () => _openAuthentication(
                                context,
                                initialMode: 'signup',
                              ),
                      loading: _navigatingMode == 'signup',
                    ),
                    const SizedBox(height: 12),
                    SecondaryButton(
                      label: _navigatingMode == 'login'
                          ? 'Opening Login...'
                          : 'Login',
                      onPressed: _isNavigating
                          ? null
                          : () => _openAuthentication(
                                context,
                                initialMode: 'login',
                              ),
                      loading: _navigatingMode == 'login',
                    ),
                    const SizedBox(height: 26),

                    // SECTION D: QUICK CAPABILITY SHORTCUTS
                    CapabilityShortcuts(
                      onCapabilitySelected: (title) =>
                          _showCapabilityInfo(context, title),
                    ),
                    const SizedBox(height: 26),

                    // SECTION E: TRUSTED PROTECTION STRIP
                    const TrustedProtectionStrip(),
                    const SizedBox(height: 36),

                    // SECTION F: FEATURE OVERVIEW ("Why Choose ScamShield?")
                    const WhyChooseScamShieldSection(),
                    const SizedBox(height: 36),

                    // SECTION G: TRUST & CLOSING ACTIONS ("Built for a Safer Digital You")
                    BuiltForSaferDigitalYouSection(
                      onGetStarted: () =>
                          _openAuthentication(context, initialMode: 'signup'),
                      onLogin: () =>
                          _openAuthentication(context, initialMode: 'login'),
                      isNavigating: _isNavigating,
                      navigatingMode: _navigatingMode,
                    ),
                    const SizedBox(height: 36),

                    // SECTION H: MINIMAL FOOTER
                    LandingFooter(
                      onAdminSignIn: () => _openAuthentication(
                        context,
                        initialMode: 'admin',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
}

/// Brand header matching Section A of 1000261210.png
class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.dark,
    required this.onThemeChanged,
  });

  final bool dark;
  final ValueChanged<bool> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ScamShieldBrandMark(size: 38),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ScamShield',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                  color: dark ? AppColors.textMainDark : AppColors.navy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'AI-POWERED SCAM PROTECTION',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: dark ? AppColors.darkPrimary : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        ThemeModeToggle(
          isDarkMode: dark,
          onChanged: onThemeChanged,
        ),
      ],
    );
  }
}

/// Luminous ambient wave painter matching the bottom curved glow
/// seen on Screens 1 and 2 in the approved blueprint (1000261210.png).
class _AmbientBottomWavePainter extends CustomPainter {
  const _AmbientBottomWavePainter({required this.dark});

  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: dark
            ? [
                const Color(0xFF086B73).withValues(alpha: 0.32),
                const Color(0xFF65DAD8).withValues(alpha: 0.18),
                const Color(0xFF102A43).withValues(alpha: 0.40),
              ]
            : [
                const Color(0xFFA8EDF3).withValues(alpha: 0.75),
                const Color(0xFF65DAD8).withValues(alpha: 0.45),
                const Color(0xFF086B73).withValues(alpha: 0.25),
              ],
      ).createShader(rect);

    final path = Path()
      ..moveTo(0, size.height * 0.50)
      ..quadraticBezierTo(
        size.width * 0.30,
        size.height * 0.15,
        size.width * 0.60,
        size.height * 0.38,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.55,
        size.width,
        size.height * 0.28,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _AmbientBottomWavePainter oldDelegate) =>
      oldDelegate.dark != dark;
}

