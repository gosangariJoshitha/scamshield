import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/theme/app_colors.dart';
import 'package:scamshield_guardian/theme/app_spacing.dart';
import 'package:scamshield_guardian/theme/app_theme.dart';
import 'package:scamshield_guardian/theme/app_typography.dart';
import 'package:scamshield_guardian/widgets/common/cyber_card.dart';
import 'package:scamshield_guardian/widgets/common/primary_button.dart';
import 'package:scamshield_guardian/widgets/common/risk_badge.dart';
import 'package:scamshield_guardian/widgets/common/secondary_button.dart';
import 'package:scamshield_guardian/widgets/skeleton_loaders.dart';
import 'package:scamshield_guardian/widgets/theme_mode_toggle.dart';

void main() {
  group('AppColors & Semantic Mapping (Phase 01 Tokens)', () {
    test('core ScamShield 2.0 palette matches approved design system', () {
      expect(AppColors.primary, const Color(0xFF086B73));
      expect(AppColors.navy, const Color(0xFF102A43));
      expect(AppColors.aqua, const Color(0xFFA8EDF3));
      expect(AppColors.darkPrimary, const Color(0xFF65D4D8));
      expect(AppColors.darkBackground, const Color(0xFF101820));
      expect(AppColors.darkCard, const Color(0xFF192630));
      expect(AppColors.darkCardElevated, const Color(0xFF22343F));
      expect(AppColors.lightBackground, const Color(0xFFF4F7FA));
      expect(AppColors.lightCard, const Color(0xFFFFFFFF));
      expect(AppColors.lightCardElevated, const Color(0xFFF8FAFC));
    });

    test('semantic risk mapping returns authoritative severity colors', () {
      // Critical (Very high risk)
      expect(
        AppColors.riskColor('CRITICAL', isDark: false),
        AppColors.riskCriticalLight,
      );
      expect(
        AppColors.riskColor('CRITICAL', isDark: true),
        AppColors.riskCriticalDark,
      );
      expect(AppColors.riskCriticalLight, const Color(0xFFB42332));
      expect(AppColors.riskCriticalDark, const Color(0xFFE53E3E));

      // High (Elevated risk)
      expect(
        AppColors.riskColor('HIGH', isDark: false),
        AppColors.riskHighLight,
      );
      expect(
        AppColors.riskColor('HIGH', isDark: true),
        AppColors.riskHighDark,
      );
      expect(AppColors.riskHighLight, const Color(0xFFD65A31));
      expect(AppColors.riskHighDark, const Color(0xFFF07844));

      // Medium / Suspicious (Caution advised)
      expect(
        AppColors.riskColor('MEDIUM', isDark: false),
        AppColors.riskMediumLight,
      );
      expect(
        AppColors.riskColor('SUSPICIOUS', isDark: true),
        AppColors.riskMediumDark,
      );
      expect(AppColors.riskMediumLight, const Color(0xFFB7791F));
      expect(AppColors.riskMediumDark, const Color(0xFFECC94B));

      // Low / Safe / Genuine (Lower observed risk)
      expect(
        AppColors.riskColor('LOW', isDark: false),
        AppColors.riskLowLight,
      );
      expect(
        AppColors.riskColor('SAFE', isDark: true),
        AppColors.riskLowDark,
      );
      expect(
        AppColors.riskColor('GENUINE', isDark: false),
        AppColors.riskLowLight,
      );
      expect(AppColors.riskLowLight, const Color(0xFF21845A));
      expect(AppColors.riskLowDark, const Color(0xFF38A169));

      // Background tints
      expect(
        AppColors.riskBackground('CRITICAL', isDark: false),
        AppColors.riskCriticalBgLight,
      );
      expect(
        AppColors.riskBackground('CRITICAL', isDark: true),
        AppColors.riskCriticalBgDark,
      );
      expect(
        AppColors.riskBackground('SAFE', isDark: false),
        AppColors.riskSafeBgLight,
      );
      expect(
        AppColors.riskBackground('SAFE', isDark: true),
        AppColors.riskSafeBgDark,
      );
    });
  });

  group('AppTheme & Material 3 Building', () {
    test('lightTheme and darkTheme construct valid ThemeData', () {
      final light = AppTheme.lightTheme;
      final dark = AppTheme.darkTheme;

      expect(light.useMaterial3, isTrue);
      expect(dark.useMaterial3, isTrue);
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);

      expect(light.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);

      expect(light.colorScheme.primary, AppColors.primary);
      expect(dark.colorScheme.primary, AppColors.darkPrimary);
    });

    test('AppTypography scales text properly using Inter tokens', () {
      final lightText = AppTypography.textTheme(isDark: false);
      final darkText = AppTypography.textTheme(isDark: true);

      expect(lightText.displayLarge?.fontSize, 34);
      expect(lightText.displayLarge?.color, AppColors.textMainLight);
      expect(darkText.displayLarge?.color, AppColors.textMainDark);

      expect(lightText.headlineLarge?.fontSize, 26);
      expect(lightText.headlineMedium?.fontSize, 21);
      expect(lightText.headlineSmall?.fontSize, 18);
      expect(lightText.titleLarge?.fontSize, 17);
      expect(lightText.bodyLarge?.fontSize, 15);
      expect(lightText.labelLarge?.fontSize, 15);
    });

    test('AppSpacing provides standard spacing constants (4px grid)', () {
      expect(AppSpacing.xxs, 4.0);
      expect(AppSpacing.xs, 8.0);
      expect(AppSpacing.sm, 12.0);
      expect(AppSpacing.md, 16.0);
      expect(AppSpacing.lg, 20.0);
      expect(AppSpacing.xl, 24.0);
      expect(AppSpacing.radiusCard, 18.0);
      expect(AppSpacing.buttonHeight, 52.0);
      expect(AppSpacing.minTouchTarget, 48.0);
      expect(AppSpacing.maxContentWidth, 720.0);
    });
  });

  group('Shared Reusable Components', () {
    testWidgets('RiskBadge displays text and semantic risk colors', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RiskBadge(label: 'High Risk', riskLevel: 'HIGH'),
          ),
        ),
      );

      expect(find.text('HIGH RISK'), findsOneWidget);
      expect(find.byIcon(Icons.warning_rounded), findsOneWidget);
    });

    testWidgets('ScamShieldCard renders child and responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ScamShieldCard(
              onTap: () => tapped = true,
              child: const Text('ScamShield Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('ScamShield Card Content'), findsOneWidget);
      await tester.tap(find.text('ScamShield Card Content'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('CyberCard is fully compatible with ScamShieldCard', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CyberCard(
              onTap: () => tapped = true,
              child: const Text('Cyber Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Cyber Card Content'), findsOneWidget);
      await tester.tap(find.text('Cyber Card Content'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('PrimaryButton renders label, handles taps and loading state', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Analyze Now',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Analyze Now'), findsOneWidget);
      await tester.tap(find.text('Analyze Now'));
      await tester.pump();
      expect(tapped, isTrue);

      // Loading state hides label and displays progress indicator
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrimaryButton(
              label: 'Analyze Now',
              loading: true,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Analyze Now'), findsOneWidget);
    });

    testWidgets('SecondaryButton renders outline style and handles taps', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecondaryButton(
              label: 'Cancel',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('SkeletonLoader renders without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(),
          ),
        ),
      );

      expect(find.byType(ScamShieldCardSkeleton), findsOneWidget);
    });

    testWidgets('ThemeModeToggle switches between light and dark options', (tester) async {
      bool? modeChangedTo;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemeModeToggle(
              isDarkMode: false,
              onChanged: (val) => modeChangedTo = val,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
      expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.dark_mode_rounded));
      await tester.pump();
      expect(modeChangedTo, isTrue);
    });
  });
}
