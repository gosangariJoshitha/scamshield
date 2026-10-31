import 'dart:async';

import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../widgets/common/primary_button.dart';
import '../../../widgets/common/secondary_button.dart';

/// "Built for a Safer Digital You" trust and closing actions section matching
/// Section F and G of the approved blueprint (1000261210.png).
///
/// Features an interactive, colorful carousel slideshow for
/// "Powered by Advanced AI and Real-World Intelligence" with animated indicators.
class BuiltForSaferDigitalYouSection extends StatelessWidget {
  const BuiltForSaferDigitalYouSection({
    required this.onGetStarted,
    required this.onLogin,
    this.isNavigating = false,
    this.navigatingMode,
    super.key,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onLogin;
  final bool isNavigating;
  final String? navigatingMode;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryAccent =
        isDark ? AppColors.darkPrimary : AppColors.primary;
    final headlineColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Headline with highlighted "Digital You"
        Text(
          'Built for a Safer',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: -0.4,
            color: headlineColor,
          ),
        ),
        Text(
          'Digital You',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 26,
            fontWeight: FontWeight.w700,
            height: 1.25,
            letterSpacing: -0.4,
            color: primaryAccent,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'ScamShield helps individuals and communities stay informed, alert and protected against evolving scam tactics.',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: subtitleColor,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 18),

        // 3 Colorful Capability Pills (Matching 1000261210.png)
        const Row(
          children: [
            Expanded(
              child: _CapabilityPill(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Messages',
                subtitle: 'AI Analysis',
                accentColor: Color(0xFF0891B2), // Cyan
                bgTint: Color(0xFFECFEFF),
                darkBgTint: Color(0xFF083344),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _CapabilityPill(
                icon: Icons.phone_outlined,
                title: 'Calls',
                subtitle: 'AI Analysis',
                accentColor: Color(0xFF2563EB), // Vibrant Blue
                bgTint: Color(0xFFEFF6FF),
                darkBgTint: Color(0xFF1E293B),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: _CapabilityPill(
                icon: Icons.description_outlined,
                title: 'Documents',
                subtitle: 'AI Analysis',
                accentColor: Color(0xFF086B73), // Deep Teal
                bgTint: Color(0xFFE6F7F8),
                darkBgTint: Color(0xFF132B2F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Colorful Interactive Intelligence Carousel Slideshow
        const _IntelligenceCarousel(),
        const SizedBox(height: 26),

        // Closing Actions
        Builder(
          builder: (context) {
            final isSigningUp = navigatingMode == 'signup' || (isNavigating && navigatingMode == null);
            final isLoggingIn = navigatingMode == 'login';
            return Column(
              children: [
                PrimaryButton(
                  label: isSigningUp ? 'Opening Sign Up...' : 'Get Started →',
                  onPressed: isNavigating ? null : onGetStarted,
                  loading: isSigningUp,
                ),
                const SizedBox(height: 12),
                SecondaryButton(
                  label: isLoggingIn ? 'Opening Login...' : 'Login',
                  onPressed: isNavigating ? null : onLogin,
                  loading: isLoggingIn,
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

/// A slide data model for the AI intelligence carousel.
class _CarouselSlide {
  const _CarouselSlide({
    required this.title,
    required this.description,
    required this.accentColor,
    required this.gradientColors,
    required this.isBrandLauncher,
    this.icon,
  });

  final String title;
  final String description;
  final Color accentColor;
  final List<Color> gradientColors;
  final bool isBrandLauncher;
  final IconData? icon;
}

/// Colorful, interactive PageView slideshow with animated pagination dots.
class _IntelligenceCarousel extends StatefulWidget {
  const _IntelligenceCarousel();

  @override
  State<_IntelligenceCarousel> createState() => _IntelligenceCarouselState();
}

class _IntelligenceCarouselState extends State<_IntelligenceCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoSlideTimer;

  static const List<_CarouselSlide> _slides = [
    _CarouselSlide(
      title: 'Powered by Advanced AI and Real-World Intelligence',
      description:
          'We combine AI analysis with verified scam patterns to give you clear, reliable insights.',
      accentColor: Color(0xFF06B6D4), // Cyan
      gradientColors: [Color(0xFF06B6D4), Color(0xFF086B73)],
      isBrandLauncher: true,
    ),
    _CarouselSlide(
      title: 'Multi-Modal Deep Scam Inspection',
      description:
          'Analyze SMS, WhatsApp, audio calls, screenshots, and PDFs seamlessly in one unified engine.',
      accentColor: Color(0xFF3B82F6), // Vibrant Blue
      gradientColors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      isBrandLauncher: false,
      icon: Icons.security_update_good_rounded,
    ),
    _CarouselSlide(
      title: 'Zero-Knowledge Privacy Architecture',
      description:
          'Your analyzed texts and documents stay confidential. No sensitive records are ever sold or shared.',
      accentColor: Color(0xFF10B981), // Emerald
      gradientColors: [Color(0xFF10B981), Color(0xFF047857)],
      isBrandLauncher: false,
      icon: Icons.shield_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _slides.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _goToPage(int index) {
    _startAutoSlide();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Swipeable PageView
        SizedBox(
          height: 122,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              final slide = _slides[index];
              return _CarouselSlideCard(
                slide: slide,
                isDark: isDark,
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Interactive Animated Dots (Tap to jump)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (index) {
            final isActive = index == _currentPage;
            final dotColor = isActive
                ? _slides[index].accentColor
                : (isDark
                    ? const Color(0xFF2C3E50)
                    : const Color(0xFFCBD5E1));

            return GestureDetector(
              onTap: () => _goToPage(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: _slides[index]
                                .accentColor
                                .withValues(alpha: 0.45),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

/// Rich, colorful card representing a single slide in the carousel.
class _CarouselSlideCard extends StatelessWidget {
  const _CarouselSlideCard({
    required this.slide,
    required this.isDark,
  });

  final _CarouselSlide slide;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final headlineColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF192630) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: slide.accentColor.withValues(alpha: isDark ? 0.40 : 0.28),
          width: 1.2,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF192630),
                  slide.accentColor.withValues(alpha: 0.08),
                ]
              : [
                  Colors.white,
                  slide.accentColor.withValues(alpha: 0.06),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: slide.accentColor.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Glowing Colorful Badge (Matching the phone launcher mark in 1000261210.png)
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2038),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: slide.accentColor.withValues(alpha: 0.55),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: slide.accentColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: slide.isBrandLauncher
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/scamshield_launcher.png',
                        width: 26,
                        height: 26,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.shield_rounded,
                          size: 22,
                          color: slide.accentColor,
                        ),
                      ),
                    )
                  : Icon(
                      slide.icon,
                      size: 22,
                      color: slide.accentColor,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Slide Title and Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  slide.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: headlineColor,
                    height: 1.22,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  slide.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: subtitleColor,
                    height: 1.28,
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

class _CapabilityPill extends StatelessWidget {
  const _CapabilityPill({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.bgTint,
    required this.darkBgTint,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Color bgTint;
  final Color darkBgTint;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? darkBgTint : bgTint;
    final titleColor =
        isDark ? AppColors.textMainDark : AppColors.textMainLight;
    final subtitleColor =
        isDark ? AppColors.textMutedDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: isDark ? 0.22 : 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
        ],
      ),
    );
  }
}
