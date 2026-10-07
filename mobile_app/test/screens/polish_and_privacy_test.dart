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

    expect(find.text('Privacy & Protection'), findsOneWidget);
    expect(find.text('Your Privacy Matters'), findsOneWidget);
    expect(find.text('No Permanent Audio Recording'), findsOneWidget);
    expect(find.text('Ephemeral Call Transcripts'), findsOneWidget);
    expect(find.text('No Credential or OTP Logging'), findsOneWidget);
    expect(find.text('Explicit User Confirmation'), findsOneWidget);
    expect(find.text('Isolated & Encrypted Account Data'), findsOneWidget);
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

    expect(find.text('Was this analysis result helpful?'), findsOneWidget);
    expect(find.text('Yes, helpful'), findsOneWidget);
    expect(find.text('No, needs review'), findsOneWidget);

    await tester.tap(find.text('Yes, helpful'));
    await tester.pump();

    expect(find.text('Thank you for your feedback! It helps improve ScamShield verification accuracy.'), findsOneWidget);
  });
}
