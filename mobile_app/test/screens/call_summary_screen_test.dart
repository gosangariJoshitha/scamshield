import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/models/call_history_models.dart';
import 'package:scamshield_guardian/screens/history/call_summary_screen.dart';

CallHistoryDetail _testDetail({
  String riskLevel = 'HIGH',
  int riskScore = 78,
  String analysisStatus = 'COMPLETED',
  String transcriptionStatus = 'COMPLETED',
  String audioStatus = 'AVAILABLE',
}) {
  return CallHistoryDetail(
    id: 1,
    sessionId: 'session-summary-test',
    startedAt: DateTime.utc(2026, 10, 7, 11, 37),
    endedAt: DateTime.utc(2026, 10, 7, 11, 42),
    durationSeconds: 277,
    guardianEnabled: true,
    guardianStatus: 'ENABLED',
    finalRiskScore: riskScore,
    finalRiskLevel: riskLevel,
    classification: 'SCAM',
    scamCategory: 'OTP Verification Scam',
    riskReasoning: 'The caller requested an OTP and created urgency around account verification.',
    safeAction: 'Do not share OTPs or banking credentials.',
    detectedIndicators: ['OTP request', 'Urgency', 'Account verification request'],
    supportingEvidence: [
      {'title': 'OTP Verification Scam', 'similarity': 'Strong match'}
    ],
    protectionActions: [
      {'action': 'WARNING_SHOWN', 'result': 'SUCCESS'},
      {'action': 'VERIFY_BEFORE_SHARING', 'result': 'SUCCESS'},
      {'action': 'END_CALL', 'result': 'SUCCESS'},
      {'action': 'BLOCK_CALLER', 'result': 'UNSUPPORTED'},
    ],
    analysisStatus: analysisStatus,
    transcriptionStatus: transcriptionStatus,
    audioStatus: audioStatus,
  );
}

void main() {
  testWidgets('CallSummaryScreen renders full call summary with indicators, evidence, and actions', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final detail = _testDetail();

    await tester.pumpWidget(
      MaterialApp(
        home: CallSummaryScreen(call: detail),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Risk Header
    expect(find.text('HIGH RISK'), findsWidgets);
    expect(find.text('78 / 100'), findsOneWidget);
    expect(find.text('OTP Verification Scam'), findsWidgets);

    // Verify Why this result
    expect(find.text('Why this result?'), findsOneWidget);
    expect(find.textContaining('The caller requested an OTP and created urgency'), findsOneWidget);

    // Verify Detected Indicators
    expect(find.text('Detected indicators'), findsOneWidget);
    expect(find.text('OTP request'), findsOneWidget);
    expect(find.text('Urgency'), findsOneWidget);
    expect(find.text('Account verification request'), findsOneWidget);

    // Verify Supporting Evidence
    expect(find.text('Supporting evidence'), findsOneWidget);
    expect(find.text('Strong match'), findsOneWidget);

    // Verify Protection Actions
    expect(find.text('Protection actions'), findsOneWidget);
    expect(find.text('Warning displayed to user'), findsOneWidget);
    expect(find.text('Verify before sharing guidance shown'), findsOneWidget);
    expect(find.text('Call ended by user'), findsOneWidget);
    expect(find.text('Caller blocking was unavailable'), findsOneWidget);

    // Verify Safer Next Step
    expect(find.text('Safer Next Step'), findsOneWidget);
    expect(find.text('Do not share OTPs or banking credentials.'), findsOneWidget);

    // Verify Call Details
    expect(find.text('Call details'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('04:37'), findsWidgets);
  });

  testWidgets('CallSummaryScreen displays audio unavailable notice when audio status is unavailable', (tester) async {
    final detail = _testDetail(
      analysisStatus: 'AUDIO_UNAVAILABLE',
      audioStatus: 'AUDIO_UNAVAILABLE',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CallSummaryScreen(call: detail),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Audio analysis unavailable'), findsOneWidget);
    expect(find.textContaining('supported call audio was unavailable'), findsOneWidget);
  });

  testWidgets('CallSummaryScreen displays transcription unavailable notice', (tester) async {
    final detail = _testDetail(
      transcriptionStatus: 'TRANSCRIPTION_UNAVAILABLE',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CallSummaryScreen(call: detail),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transcription unavailable'), findsOneWidget);
    expect(find.textContaining('speech-to-text could not be completed'), findsOneWidget);
  });
}
