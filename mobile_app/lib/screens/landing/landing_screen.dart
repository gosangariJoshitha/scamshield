import 'package:flutter/material.dart';

import '../../models/user.dart';
import '../../services/auth_service.dart';
import '../auth/authentication_screen.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/theme_mode_toggle.dart';

class LandingScreen extends StatelessWidget {
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

  void _openAuthentication(
    BuildContext context, {
    String initialMode = 'login',
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AuthenticationScreen(
          authService: authService,
          initialMode: initialMode,
          initialMessage: initialMessage,
          onThemeChanged: onThemeChanged,
          onAuthenticated: (user) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            onAuthenticated(user);
          },
          onAdminAuthenticated: (user) {
            Navigator.of(context).popUntil((route) => route.isFirst);
            onAdminAuthenticated(user);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dark
                ? const [Color(0xFF07111F), Color(0xFF0B1929)]
                : const [Color(0xFFF2FBFD), Color(0xFFF8FBFE)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 740),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const ScamShieldBrandMark(size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'SCAMSHIELD',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: colors.onSurface,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'AI-POWERED SCAM PROTECTION',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.15,
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
                    ),
                    const SizedBox(height: 28),
                    _HeroCard(
                      dark: dark,
                      onGetStarted: () =>
                          _openAuthentication(context, initialMode: 'signup'),
                      onLogin: () => _openAuthentication(context),
                    ),
                    const SizedBox(height: 30),
                    const _CapabilityStrip(),
                    const SizedBox(height: 30),
                    Text(
                      'BUILT TO HELP YOU THINK CLEARLY',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 44,
                      height: 3,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Powerful Protection, Made Simple',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.45,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use AI to analyze, understand and stay safe across multiple channels.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth < 300
                            ? 1
                            : constraints.maxWidth >= 630
                            ? 3
                            : 2;
                        return GridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: switch (columns) {
                            1 => 1.35,
                            2 => constraints.maxWidth < 380 ? 0.9 : 1.15,
                            _ => 1.2,
                          },
                          children: const [
                            _LandingFeatureCard(
                              icon: Icons.chat_bubble_rounded,
                              color: Color(0xFF12A77A),
                              title: 'Text Analysis',
                              description: 'Check messages, links and text for scam indicators.',
                            ),
                            _LandingFeatureCard(
                              icon: Icons.image_rounded,
                              color: Color(0xFF2585E8),
                              title: 'Image & Screenshot',
                              description: 'Spot fraud, fake notices and malicious content.',
                            ),
                            _LandingFeatureCard(
                              icon: Icons.description_rounded,
                              color: Color(0xFF8846D8),
                              title: 'PDF & Document',
                              description: 'Analyze documents and notices for hidden risks.',
                            ),
                            _LandingFeatureCard(
                              icon: Icons.graphic_eq_rounded,
                              color: Color(0xFFE55F61),
                              title: 'Audio Analysis',
                              description: 'Check voice messages and audio files for suspicious content.',
                            ),
                            _LandingFeatureCard(
                              icon: Icons.phone_in_talk_rounded,
                              color: Color(0xFF12A77A),
                              title: 'Live Call Guardian',
                              description: 'Planned call protection to help identify suspicious calls.',
                            ),
                            _LandingFeatureCard(
                              icon: Icons.groups_rounded,
                              color: Color(0xFF9449D7),
                              title: 'Community Insights',
                              description: 'Learn from reports and stay updated with scam trends.',
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    _LandingCallToAction(
                      dark: dark,
                      onGetStarted: () =>
                          _openAuthentication(context, initialMode: 'signup'),
                    ),
                    const SizedBox(height: 16),
                    const _TrustValueStrip(),
                    const SizedBox(height: 20),
                    Text(
                      'Understand suspicious content and choose a safer next step.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.dark,
    required this.onGetStarted,
    required this.onLogin,
  });

  final bool dark;
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final border = dark ? const Color(0xFF21435A) : const Color(0xFFB8E8EF);
    final heroStart = dark ? const Color(0xFF0C2037) : const Color(0xFFE6F8FB);
    final heroEnd = dark ? const Color(0xFF102F45) : const Color(0xFFD9F2F6);
    final headlineColor = dark
        ? const Color(0xFFF4FAFF)
        : const Color(0xFF0B1B36);
    final bodyColor = dark ? const Color(0xFFC4D4E3) : const Color(0xFF40536B);

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 460;
        final intro = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: dark ? 0.17 : 0.12),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                child: Text(
                  'STAY AHEAD OF SCAMS',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: dark
                        ? const Color(0xFF73E2EF)
                        : const Color(0xFF087E8B),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Don’t Just Detect Scams.\nUnderstand Them.',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: headlineColor,
                fontWeight: FontWeight.w900,
                height: 1.12,
                letterSpacing: -0.75,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Analyze suspicious content and understand what makes it risky, '
              'so you can choose a safer next step.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: bodyColor,
                height: 1.5,
              ),
            ),
          ],
        );

        return Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [heroStart, heroEnd],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: dark ? 0.12 : 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (horizontal)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: intro),
                    const SizedBox(width: 8),
                    const _ProtectionIllustration(size: 142),
                  ],
                )
              else ...[
                intro,
                const SizedBox(height: 4),
                const Align(
                  alignment: Alignment.centerRight,
                  child: _ProtectionIllustration(size: 126),
                ),
              ],
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onGetStarted,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  backgroundColor: dark
                      ? const Color(0xFF32D3E2)
                      : const Color(0xFF087E8B),
                  foregroundColor: dark
                      ? const Color(0xFF062034)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('GET STARTED'),
                    SizedBox(width: 12),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onLogin,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  foregroundColor: headlineColor,
                  side: BorderSide(
                    color: dark
                        ? const Color(0xFF4C718A)
                        : const Color(0xFF60758B),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text('LOGIN'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CapabilityStrip extends StatelessWidget {
  const _CapabilityStrip();

  static const _capabilities = [
    (Icons.shield_outlined, 'Multi-channel\nProtection'),
    (Icons.groups_rounded, 'AI-Powered\nAnalysis'),
    (Icons.bolt_rounded, 'Explainable\nRisk Insights'),
    (Icons.language_rounded, 'Indian\nLanguages'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          for (final capability in _capabilities)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  children: [
                    Icon(capability.$1, color: colors.primary, size: 27),
                    const SizedBox(height: 6),
                    Text(
                      capability.$2,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onSurface,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProtectionIllustration extends StatelessWidget {
  const _ProtectionIllustration({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = dark ? const Color(0xFF39D9EB) : const Color(0xFF087E8B);
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.88,
            height: size * 0.88,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.11),
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: size * 0.52,
            height: size * 0.83,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  dark ? const Color(0xFF164765) : const Color(0xFF156D87),
                  dark ? const Color(0xFF071A30) : const Color(0xFF0B2D49),
                ],
              ),
              borderRadius: BorderRadius.circular(size * 0.14),
              border: Border.all(
                color: accent.withValues(alpha: 0.8),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 18,
                ),
              ],
            ),
            child: Icon(
              Icons.shield_rounded,
              color: const Color(0xFF55E3F1),
              size: size * 0.36,
            ),
          ),
          Positioned(
            left: 0,
            top: size * 0.19,
            child: _FloatingSignal(
              icon: Icons.sms_rounded,
              color: const Color(0xFF36A5ED),
              surface: colors.surface,
            ),
          ),
          Positioned(
            right: 0,
            bottom: size * 0.18,
            child: _FloatingSignal(
              icon: Icons.verified_user_rounded,
              color: const Color(0xFF10B981),
              surface: colors.surface,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingSignal extends StatelessWidget {
  const _FloatingSignal({
    required this.icon,
    required this.color,
    required this.surface,
  });

  final IconData icon;
  final Color color;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 34,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(11),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 9,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: color, size: 23),
    );
  }
}

class _LandingFeatureCard extends StatefulWidget {
  const _LandingFeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  State<_LandingFeatureCard> createState() => _LandingFeatureCardState();
}

class _LandingFeatureCardState extends State<_LandingFeatureCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: _hovered ? colors.surfaceContainerHighest : colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? widget.color.withValues(alpha: 0.5)
                : colors.outlineVariant,
          ),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: widget.color.withValues(alpha: dark ? 0.14 : 0.1),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: dark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(widget.icon, color: widget.color, size: 22),
            ),
            const SizedBox(height: 9),
            Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                widget.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: colors.onSurfaceVariant, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingCallToAction extends StatelessWidget {
  const _LandingCallToAction({required this.dark, required this.onGetStarted});

  final bool dark;
  final VoidCallback onGetStarted;

  ButtonStyle _buttonStyle() => FilledButton.styleFrom(
    minimumSize: const Size(142, 48),
    backgroundColor: Colors.white,
    foregroundColor: const Color(0xFF08213B),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    textStyle: const TextStyle(fontWeight: FontWeight.w800),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? const [Color(0xFF0B3348), Color(0xFF0D1D30)]
              : const [Color(0xFF07516B), Color(0xFF06344E)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF20C7D9).withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: dark ? 0.16 : 0.12),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 380;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A SAFER DIGITAL WORLD',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF69E4F0),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Stay informed. Stay protected.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'ScamShield helps you identify risks, understand threats '
                'and make safer decisions with AI.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: const Color(0xFFD0E4EF), height: 1.4),
              ),
            ],
          );
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                copy,
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: onGetStarted,
                  style: _buttonStyle(),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('GET STARTED'),
                      SizedBox(width: 10),
                      Icon(Icons.arrow_forward_rounded),
                    ],
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              const ScamShieldBrandMark(size: 58),
              const SizedBox(width: 12),
              Expanded(child: copy),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: onGetStarted,
                style: _buttonStyle(),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('GET STARTED'),
                    SizedBox(width: 10),
                    Icon(Icons.arrow_forward_rounded),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TrustValueStrip extends StatelessWidget {
  const _TrustValueStrip();

  static const _items = [
    (
      Icons.lock_outline_rounded,
      'Your Privacy Matters',
      'Secure account access',
    ),
    (Icons.psychology_alt_rounded, 'AI-Powered Analysis', 'Scam intelligence'),
    (
      Icons.health_and_safety_outlined,
      'Risk-Aware Guidance',
      'Clearer decisions',
    ),
    (Icons.groups_rounded, 'Community Insights', 'User reports'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < 420 ? 2 : 4;
        return GridView.builder(
          itemCount: _items.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            mainAxisExtent: 66,
          ),
          itemBuilder: (context, index) {
            final item = _items[index];
            return _TrustValueCard(
              icon: item.$1,
              title: item.$2,
              description: item.$3,
            );
          },
        );
      },
    );
  }
}

class _TrustValueCard extends StatefulWidget {
  const _TrustValueCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  State<_TrustValueCard> createState() => _TrustValueCardState();
}

class _TrustValueCardState extends State<_TrustValueCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -2 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered
              ? colors.surfaceContainerHighest
              : colors.surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _hovered
                ? colors.primary.withValues(alpha: 0.45)
                : colors.outlineVariant,
          ),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: colors.primary.withValues(alpha: dark ? 0.13 : 0.09),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Row(
          children: [
            AnimatedScale(
              scale: _hovered ? 1.08 : 1,
              duration: const Duration(milliseconds: 180),
              child: Icon(widget.icon, color: colors.primary, size: 20),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall
                        ?.copyWith(color: colors.onSurfaceVariant),
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
