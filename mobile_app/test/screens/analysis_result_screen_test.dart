import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/models/analysis_record.dart';
import 'package:scamshield_guardian/screens/results/analysis_result_screen.dart';

final _analysis = AnalysisRecord(
  id: 1,
  content: 'Your account will be closed unless you pay now.',
  riskScore: 86,
  riskLevel: 'HIGH',
  classification: 'SCAM',
  category: 'bank_kyc',
  inputType: 'text',
  createdAt: DateTime.utc(2026, 10, 7, 4, 30),
  explanation: 'The message uses urgency and requests an immediate payment.',
  recommendedAction: 'Contact the organization using its official website.',
  mlProbability: 0.94,
  llmConfidence: 0.91,
  indicators: ['OTP request detected', 'Urgency or Account threat'],
  retrievedEvidence: [
    AnalysisEvidence(
      title: 'Bank KYC scam pattern',
      category: 'Banking/KYC',
      pattern: 'Scammers request OTPs to complete fake KYC.',
      source: 'ScamShield knowledge base',
      similarityScore: 0.88,
    ),
  ],
  safeActions: [
    'Contact the organization using its official website.',
    'Do not share your OTP.',
  ],
);

void main() {
  testWidgets('shows an enriched analysis result using the supplied findings', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: AnalysisResultScreen(analysis: _analysis)),
    );

    expect(find.text('ANALYSIS COMPLETE'), findsOneWidget);
    expect(find.text('SCAM'), findsOneWidget);
    expect(find.text('RISK SCORE'), findsOneWidget);
    expect(find.text('86'), findsOneWidget);
    expect(find.text('Bank KYC'), findsOneWidget);
    expect(find.text('Text'), findsOneWidget);
    expect(find.text('Detected indicators'), findsOneWidget);
    expect(find.text('OTP request detected'), findsOneWidget);
    expect(find.text('Supporting evidence'), findsOneWidget);
    expect(find.text('Why this result?'), findsOneWidget);
    expect(find.text('What you should do now'), findsOneWidget);
    expect(find.text('Strong'), findsOneWidget);
    expect(find.text('94%'), findsNothing);
    await tester.ensureVisible(find.text('Technical details'));
    await tester.tap(find.text('Technical details'));
    await tester.pumpAndSettle();
    expect(find.text('94%'), findsOneWidget);
    expect(find.text('91%'), findsOneWidget);
    expect(
      find.text(
        'Contact the organization using its official website.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('hides optional indicator, evidence and confidence sections', (
    tester,
  ) async {
    final plainAnalysis = AnalysisRecord(
      id: 2,
      content: 'Meeting at ten.',
      riskScore: 8,
      riskLevel: 'LOW',
      classification: 'GENUINE',
      category: 'general_informational',
      inputType: 'text',
      createdAt: DateTime.utc(2026, 10, 7),
      explanation: 'This message contains no suspicious request.',
      recommendedAction: 'Continue to verify unexpected links.',
      processingStatus: 'COMPLETED_WITH_LIMITATIONS',
    );

    await tester.pumpWidget(
      MaterialApp(home: AnalysisResultScreen(analysis: plainAnalysis)),
    );

    expect(find.text('Bank KYC'), findsNothing);
    expect(find.text('Detected indicators'), findsNothing);
    expect(find.text('Supporting evidence'), findsNothing);
    expect(find.text('ML confidence'), findsNothing);
    expect(find.text('AI confidence'), findsNothing);
    expect(find.text('Why this is safe'), findsOneWidget);
    expect(find.text('General Informational'), findsOneWidget);
    expect(
      find.textContaining('Some analysis services were unavailable'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('result content remains scrollable on a narrow dark screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF087E8B),
            brightness: Brightness.dark,
          ),
        ),
        home: AnalysisResultScreen(analysis: _analysis),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('ANALYSIS COMPLETE'), findsOneWidget);
    await tester.ensureVisible(
      find.textContaining('ScamShield analysis is guidance'),
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('ScamShield analysis is guidance'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('analysis actions invoke their provided navigation callbacks', (
    tester,
  ) async {
    var returnedToDashboard = false;
    var requestedAnotherAnalysis = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AnalysisResultScreen(
          analysis: _analysis,
          onBackToDashboard: () => returnedToDashboard = true,
          onAnalyzeAnother: () => requestedAnotherAnalysis = true,
        ),
      ),
    );

    final backButton = find.text('Back to Dashboard');
    await tester.ensureVisible(backButton);
    await tester.tap(backButton);
    final analyzeButton = find.text('Analyze Another');
    await tester.ensureVisible(analyzeButton);
    await tester.tap(analyzeButton);
    expect(returnedToDashboard, isTrue);
    expect(requestedAnotherAnalysis, isTrue);
    expect(tester.takeException(), isNull);
  });
}
