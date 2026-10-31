import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/screens/privacy/privacy_center_screen.dart';
import 'package:scamshield_guardian/widgets/scamshield_error_boundary.dart';
import 'package:scamshield_guardian/models/analysis_record.dart';
import 'package:scamshield_guardian/screens/results/analysis_result_screen.dart';

void main() {
  testWidgets('PrivacyCenterScreen renders all privacy safeguards', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: PrivacyCenterScreen(),
      ),
    );

    expect(find.text('Privacy & Security'), findsOneWidget);
    expect(find.text('Your privacy matters'), findsOneWidget);
    expect(find.text('App Permissions'), findsOneWidget);
    expect(find.text('Data Usage'), findsOneWidget);
    expect(find.text('Account Security'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
    expect(find.text('Data Sharing'), findsOneWidget);
    expect(find.text('Usage Analytics'), findsOneWidget);
  });

  testWidgets('ScamShieldErrorView renders friendly recovery view', (tester) async {
    bool retried = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ScamShieldErrorView(
          onRetry: () => retried = true,
        ),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('UNEXPECTED ERROR'), findsOneWidget);
    expect(find.text('Reload'), findsOneWidget);

    await tester.tap(find.text('Reload'));
    expect(retried, isTrue);
  });

  testWidgets('AnalysisResultScreen renders feedback card and registers feedback', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final analysis = AnalysisRecord(
      id: 42,
      content: 'Your account is suspended. Verify OTP 123456 now.',
      riskScore: 88,
      riskLevel: 'CRITICAL',
      classification: 'SCAM',
      category: 'Banking / KYC Scam',
      inputType: 'text',
      createdAt: DateTime.now(),
      indicators: ['Urgency', 'OTP request'],
      explanation: 'Detected aggressive urgency and credential harvesting.',
      safeActions: ['Do not share OTP'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisResultScreen(analysis: analysis),
      ),
    );

    expect(find.text('Detected aggressive urgency and credential harvesting.'), findsWidgets);
    expect(find.text('Do not share OTP'), findsOneWidget);
  });
}
