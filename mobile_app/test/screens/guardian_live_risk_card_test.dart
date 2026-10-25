import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/models/guardian_analysis_models.dart';
import 'package:scamshield_guardian/services/guardian_local_heuristic_engine.dart';
import 'package:scamshield_guardian/services/guardian_transcription_service.dart';
import 'package:scamshield_guardian/widgets/guardian_live_risk_card.dart';

void main() {
  testWidgets('renders idle state gracefully', (tester) async {
    const snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_IDLE',
      message: 'Live AI analysis is off.',
      result: null,
      lastAnalyzedSequence: 0,
      isAnalyzing: false,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(snapshot: snapshot),
        ),
      ),
    );

    expect(find.textContaining('Live AI analysis ready'), findsOneWidget);
  });

  testWidgets('renders waiting state when speech is being monitored', (
    tester,
  ) async {
    const snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_WAITING_FOR_TRANSCRIPT',
      message: 'Listening for conversation to analyze for suspicious patterns…',
      result: null,
      lastAnalyzedSequence: 0,
      isAnalyzing: false,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(snapshot: snapshot),
        ),
      ),
    );

    expect(find.text('Listening for conversation'), findsOneWidget);
    expect(find.text('MONITORING'), findsOneWidget);
    expect(
      find.textContaining('Listening for conversation to analyze'),
      findsOneWidget,
    );
  });

  testWidgets('renders active analyzing state', (tester) async {
    const snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_ANALYZING',
      message: 'Analyzing conversation for suspicious patterns…',
      result: null,
      lastAnalyzedSequence: 0,
      isAnalyzing: true,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(snapshot: snapshot),
        ),
      ),
    );

    expect(find.text('Analyzing conversation…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders full live risk result card', (tester) async {
    final result = GuardianLiveAnalysisResult(
      riskScore: 88,
      riskLevel: 'CRITICAL',
      classification: 'SCAM',
      scamCategory: 'OTP/Verification',
      detectedIndicators: ['Urgency', 'Account threat', 'OTP request'],
      reasoning:
          'The caller is requesting sensitive information under urgent account-verification pressure.',
      supportingEvidence: [
        GuardianRetrievedEvidence(
          knowledgeId: 10,
          title: 'Bank Verification Scam',
          category: 'vishing',
          similarityScore: 0.91,
          pattern: 'Threatens blockage and asks for OTP',
          description: 'Common fraud tactic',
          indicators: ['OTP', 'Block threat'],
          safeAction: 'Never disclose verification codes.',
          source: 'Cyber Police Advisory',
          language: 'en',
        ),
      ],
      mlProbability: 0.95,
      llmConfidence: 0.92,
      safeAction: 'Do not share your OTP or banking details with the caller.',
      safeActions: null,
      timestamp: DateTime.utc(2026, 10, 7),
      sessionId: '00000000-0000-4000-8000-000000000010',
      language: 'en',
      evidenceStatus: 'MATCH_FOUND',
      processingStatus: 'COMPLETED',
      modelVersion: 'scamshield-classifier-v5',
      ragVersion: 'scamshield-rag-v1',
      timingsMs: const {},
    );

    final snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_RESULT_READY',
      message: 'Analysis ready.',
      result: result,
      lastAnalyzedSequence: 1,
      isAnalyzing: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(snapshot: snapshot),
        ),
      ),
    );

    expect(find.text('Risk Assessment'), findsOneWidget);
    expect(find.text('CRITICAL RISK'), findsOneWidget);
    expect(find.text('88'), findsOneWidget);
    expect(find.text(' / 100'), findsOneWidget);
    expect(find.text('Suspicious activity detected'), findsOneWidget);
    expect(find.text('OTP/Verification'), findsOneWidget);
    expect(find.text('Detected indicators'), findsOneWidget);
    expect(find.text('Urgency'), findsOneWidget);
    expect(find.text('Account threat'), findsOneWidget);
    expect(find.text('OTP request'), findsOneWidget);
    expect(find.text('Why?'), findsOneWidget);
    expect(
      find.textContaining('The caller is requesting sensitive information'),
      findsOneWidget,
    );
    expect(find.text('Supporting evidence'), findsOneWidget);
    expect(
      find.textContaining('1 relevant scam pattern(s) identified'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Do not share your OTP or banking details'),
      findsOneWidget,
    );
    // Warning banner and meter validation
    expect(find.text('High-risk scam indicators detected.'), findsOneWidget);
    expect(find.byType(GuardianRiskMeter), findsOneWidget);
  });

  testWidgets('renders unavailable state when AI is degraded with retry option', (tester) async {
    var retried = false;
    const snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_UNAVAILABLE',
      message: 'Live AI analysis is temporarily unavailable.',
      result: null,
      lastAnalyzedSequence: 0,
      isAnalyzing: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(
            snapshot: snapshot,
            onRetryAnalysis: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('Live AI Analysis Unavailable'), findsOneWidget);
    expect(
      find.text('Live AI analysis is temporarily unavailable.'),
      findsOneWidget,
    );
    expect(find.text('Retry analysis'), findsOneWidget);

    await tester.tap(find.text('Retry analysis'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('GuardianRiskMeter renders all 4 tiers with semantic accessibility label', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GuardianRiskMeter(score: 72, level: 'HIGH'),
        ),
      ),
    );

    expect(find.text('LOW'), findsOneWidget);
    expect(find.text('MEDIUM'), findsOneWidget);
    expect(find.text('HIGH'), findsOneWidget);
    expect(find.text('CRITICAL'), findsOneWidget);
    expect(find.text('0–29'), findsOneWidget);
    expect(find.text('30–59'), findsOneWidget);
    expect(find.text('60–79'), findsOneWidget);
    expect(find.text('80–100'), findsOneWidget);

    final semantics = tester.getSemantics(find.byType(GuardianRiskMeter));
    expect(semantics.label, contains('Risk meter showing 72 out of 100, HIGH risk tier'));
  });

  testWidgets('expands and collapses indicators when more than 3 exist', (
    tester,
  ) async {
    final result = GuardianLiveAnalysisResult(
      riskScore: 75,
      riskLevel: 'HIGH',
      classification: 'SCAM',
      scamCategory: 'Impersonation',
      detectedIndicators: ['Urgency', 'Threat', 'OTP', 'Fake Authority', 'Financial penalty'],
      reasoning: 'Urgent caller claims to be from tax department.',
      supportingEvidence: const [],
      mlProbability: 0.88,
      llmConfidence: 0.85,
      safeAction: 'Hang up and contact official department directly.',
      safeActions: null,
      timestamp: DateTime.utc(2026, 10, 7),
      sessionId: '00000000-0000-4000-8000-000000000011',
      language: 'en',
      evidenceStatus: 'NO_RELEVANT_MATCH',
      processingStatus: 'COMPLETED',
      modelVersion: 'scamshield-classifier-v5',
      ragVersion: 'scamshield-rag-v1',
      timingsMs: const {},
    );

    final snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_RESULT_READY',
      message: 'Analysis ready.',
      result: result,
      lastAnalyzedSequence: 1,
      isAnalyzing: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(snapshot: snapshot),
        ),
      ),
    );

    // Initial state: first 3 indicators visible, +2 more chip visible
    expect(find.text('Urgency'), findsOneWidget);
    expect(find.text('Threat'), findsOneWidget);
    expect(find.text('OTP'), findsOneWidget);
    expect(find.text('+2 more'), findsOneWidget);
    expect(find.text('Fake Authority'), findsNothing);

    // Tap +2 more to expand
    await tester.tap(find.text('+2 more'));
    await tester.pumpAndSettle();

    expect(find.text('Fake Authority'), findsOneWidget);
    expect(find.text('Financial penalty'), findsOneWidget);
    expect(find.text('Show less'), findsOneWidget);

    // Tap Show less to collapse
    await tester.tap(find.text('Show less'));
    await tester.pumpAndSettle();

    expect(find.text('+2 more'), findsOneWidget);
    expect(find.text('Fake Authority'), findsNothing);
  });

  testWidgets('renders live transcript preview when transcript segments are provided', (
    tester,
  ) async {
    final result = GuardianLiveAnalysisResult(
      riskScore: 50,
      riskLevel: 'MEDIUM',
      classification: 'SUSPICIOUS',
      scamCategory: 'General',
      detectedIndicators: ['Suspicious phrasing'],
      reasoning: 'Conversation includes unverified claims.',
      supportingEvidence: const [],
      mlProbability: 0.55,
      llmConfidence: 0.60,
      safeAction: 'Ask caller for official verification.',
      safeActions: null,
      timestamp: DateTime.utc(2026, 10, 7),
      sessionId: '00000000-0000-4000-8000-000000000012',
      language: 'en',
      evidenceStatus: 'NO_RELEVANT_MATCH',
      processingStatus: 'COMPLETED',
      modelVersion: 'scamshield-classifier-v5',
      ragVersion: 'scamshield-rag-v1',
      timingsMs: const {},
    );

    final snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_RESULT_READY',
      message: 'Analysis ready.',
      result: result,
      lastAnalyzedSequence: 2,
      isAnalyzing: false,
    );

    final segments = [
      TranscriptSegment(
        sessionId: '00000000-0000-4000-8000-000000000012',
        segmentId: 'seg-1',
        sequence: 1,
        startTime: 0.0,
        endTime: 2.0,
        text: 'Your account is under review.',
        isFinal: true,
        language: 'en',
        createdAt: DateTime.utc(2026, 10, 7),
      ),
      TranscriptSegment(
        sessionId: '00000000-0000-4000-8000-000000000012',
        segmentId: 'seg-2',
        sequence: 2,
        startTime: 2.5,
        endTime: 4.5,
        text: 'Please confirm your identification number.',
        isFinal: true,
        language: 'en',
        createdAt: DateTime.utc(2026, 10, 7),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(
            snapshot: snapshot,
            transcriptSegments: segments,
          ),
        ),
      ),
    );

    expect(find.text('Live transcript preview'), findsOneWidget);
    expect(find.text('"Your account is under review."'), findsOneWidget);
    expect(find.text('"Please confirm your identification number."'), findsOneWidget);
  });

  testWidgets('renders call ended state with final assessment and dismiss action', (
    tester,
  ) async {
    var dismissed = false;
    final result = GuardianLiveAnalysisResult(
      riskScore: 78,
      riskLevel: 'HIGH',
      classification: 'SCAM',
      scamCategory: 'Bank Impersonation',
      detectedIndicators: ['Account threat'],
      reasoning: 'Final analysis confirmed high scam indicators.',
      supportingEvidence: const [],
      mlProbability: 0.85,
      llmConfidence: 0.82,
      safeAction: 'Do not follow caller instructions.',
      safeActions: null,
      timestamp: DateTime.utc(2026, 10, 7),
      sessionId: '00000000-0000-4000-8000-000000000013',
      language: 'en',
      evidenceStatus: 'NO_RELEVANT_MATCH',
      processingStatus: 'COMPLETED',
      modelVersion: 'scamshield-classifier-v5',
      ragVersion: 'scamshield-rag-v1',
      timingsMs: const {},
    );

    final snapshot = GuardianLiveAnalysisSnapshot(
      state: 'CALL_ENDED',
      message: 'Call ended. Guardian protection stopped.',
      result: result,
      lastAnalyzedSequence: 3,
      isAnalyzing: false,
      isCallEnded: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(
            snapshot: snapshot,
            onDismissCallEnded: () => dismissed = true,
          ),
        ),
      ),
    );

    expect(find.text('Final Risk Assessment'), findsOneWidget);
    expect(find.text('Dismiss call risk'), findsOneWidget);

    await tester.tap(find.text('Dismiss call risk'));
    await tester.pump();
    expect(dismissed, isTrue);
  });

  testWidgets('renders updates paused badge with retry option when previous result exists but updates fail', (
    tester,
  ) async {
    var retried = false;
    final result = GuardianLiveAnalysisResult(
      riskScore: 65,
      riskLevel: 'HIGH',
      classification: 'SUSPICIOUS',
      scamCategory: 'KYC Update',
      detectedIndicators: ['Urgency'],
      reasoning: 'Caller asks to update KYC immediately.',
      supportingEvidence: const [],
      mlProbability: 0.70,
      llmConfidence: 0.75,
      safeAction: 'Do not click unknown links.',
      safeActions: null,
      timestamp: DateTime.utc(2026, 10, 7, 14, 30),
      sessionId: '00000000-0000-4000-8000-000000000014',
      language: 'en',
      evidenceStatus: 'NO_RELEVANT_MATCH',
      processingStatus: 'COMPLETED',
      modelVersion: 'scamshield-classifier-v5',
      ragVersion: 'scamshield-rag-v1',
      timingsMs: const {},
    );

    final snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_UNAVAILABLE',
      message: 'Live AI analysis is temporarily unavailable.',
      result: result,
      lastAnalyzedSequence: 2,
      isAnalyzing: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(
            snapshot: snapshot,
            onRetryAnalysis: () => retried = true,
          ),
        ),
      ),
    );

    expect(find.text('65'), findsOneWidget);
    expect(find.text('Updates paused'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(
      find.text('Live updates temporarily paused. Showing last confirmed assessment.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retried, isTrue);
  });

  testWidgets('renders expanded supporting evidence description and source', (
    tester,
  ) async {
    final result = GuardianLiveAnalysisResult(
      riskScore: 90,
      riskLevel: 'CRITICAL',
      classification: 'SCAM',
      scamCategory: 'Police Impersonation',
      detectedIndicators: ['Arrest threat'],
      reasoning: 'Impersonating police and threatening digital arrest.',
      supportingEvidence: [
        GuardianRetrievedEvidence(
          knowledgeId: 101,
          title: 'Digital Arrest Scam Advisory',
          category: 'impersonation',
          similarityScore: 0.94,
          pattern: 'Threatens digital arrest via video call',
          description: 'Cyber criminals impersonate law enforcement and demand immediate money transfer.',
          indicators: ['Arrest threat', 'Money transfer'],
          safeAction: 'Law enforcement never conducts digital arrests via phone.',
          source: 'Indian Cyber Crime Coordination Centre (I4C)',
          language: 'en',
        ),
      ],
      mlProbability: 0.98,
      llmConfidence: 0.95,
      safeAction: 'Disconnect call immediately.',
      safeActions: null,
      timestamp: DateTime.utc(2026, 10, 7),
      sessionId: '00000000-0000-4000-8000-000000000015',
      language: 'en',
      evidenceStatus: 'MATCH_FOUND',
      processingStatus: 'COMPLETED',
      modelVersion: 'scamshield-classifier-v5',
      ragVersion: 'scamshield-rag-v1',
      timingsMs: const {},
    );

    final snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_RESULT_READY',
      message: 'Analysis ready.',
      result: result,
      lastAnalyzedSequence: 1,
      isAnalyzing: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(snapshot: snapshot),
        ),
      ),
    );

    // Initial collapsed state
    expect(find.text('Digital Arrest Scam Advisory'), findsOneWidget);
    expect(find.text('Details >'), findsOneWidget);
    expect(find.textContaining('Cyber criminals impersonate law enforcement'), findsNothing);

    // Tap Details > to expand
    await tester.tap(find.text('Details >'));
    await tester.pumpAndSettle();

    expect(find.text('Collapse'), findsOneWidget);
    expect(find.textContaining('Cyber criminals impersonate law enforcement'), findsOneWidget);
    expect(find.textContaining('Source: Indian Cyber Crime Coordination Centre (I4C)'), findsOneWidget);
  });

  testWidgets('renders honest explanation when evidence retrieval is unavailable', (
    tester,
  ) async {
    final result = GuardianLiveAnalysisResult(
      riskScore: 70,
      riskLevel: 'HIGH',
      classification: 'SUSPICIOUS',
      scamCategory: 'Prize Lottery',
      detectedIndicators: ['Urgency'],
      reasoning: 'Lottery win claims.',
      supportingEvidence: const [],
      mlProbability: 0.75,
      llmConfidence: null,
      safeAction: 'Do not pay fees to claim prizes.',
      safeActions: null,
      timestamp: DateTime.utc(2026, 10, 7),
      sessionId: '00000000-0000-4000-8000-000000000016',
      language: 'en',
      evidenceStatus: 'RETRIEVAL_UNAVAILABLE',
      processingStatus: 'COMPLETED_WITH_LIMITATIONS',
      modelVersion: 'scamshield-classifier-v5',
      ragVersion: 'scamshield-rag-v1',
      timingsMs: const {},
    );

    final snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_RESULT_READY',
      message: 'Analysis ready.',
      result: result,
      lastAnalyzedSequence: 1,
      isAnalyzing: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(snapshot: snapshot),
        ),
      ),
    );

    expect(
      find.text('Advisory evidence retrieval is temporarily unavailable.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Basic analysis (AI reasoning limited)'),
      findsOneWidget,
    );
  });

  testWidgets('resolves multilingual safe action when translations match detected language', (
    tester,
  ) async {
    final result = GuardianLiveAnalysisResult(
      riskScore: 85,
      riskLevel: 'CRITICAL',
      classification: 'SCAM',
      scamCategory: 'OTP/Verification',
      detectedIndicators: ['OTP'],
      reasoning: 'Caller asks for OTP.',
      supportingEvidence: const [],
      mlProbability: 0.90,
      llmConfidence: 0.90,
      safeAction: 'Do not share your OTP with anyone.',
      safeActions: const {
        'canonical': ['Do not share your OTP with anyone.'],
        'translations': {
          'hi': ['किसी के साथ अपना ओटीपी साझा न करें।'],
          'te': ['ఎవరితోనూ మీ ఓటీపీని పంచుకోవద్దు.'],
        },
      },
      timestamp: DateTime.utc(2026, 10, 7),
      sessionId: '00000000-0000-4000-8000-000000000017',
      language: 'te',
      evidenceStatus: 'NO_RELEVANT_MATCH',
      processingStatus: 'COMPLETED',
      modelVersion: 'scamshield-classifier-v5',
      ragVersion: 'scamshield-rag-v1',
      timingsMs: const {},
    );

    final snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_RESULT_READY',
      message: 'Analysis ready.',
      result: result,
      lastAnalyzedSequence: 1,
      isAnalyzing: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(snapshot: snapshot),
        ),
      ),
    );

    // Should display Telugu translation
    expect(find.text('ఎవరితోనూ మీ ఓటీపీని పంచుకోవద్దు.'), findsOneWidget);
  });

  testWidgets(
      'renders offline no-network state with network status badge and queued count',
      (tester) async {
    const snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_ERROR',
      message: 'Network connection failed.',
      result: null,
      lastAnalyzedSequence: 0,
      isAnalyzing: false,
      networkStatus: GuardianNetworkStatus.noNetwork,
      queuedCount: 2,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(snapshot: snapshot),
        ),
      ),
    );

    expect(find.text('Offline — No Internet Connection'), findsOneWidget);
    expect(find.text('No Internet'), findsOneWidget);
    expect(
      find.text('2 analysis request(s) queued for reconnection.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'renders local heuristic warning when rule matched during offline state',
      (tester) async {
    final heuristic = GuardianLocalHeuristicResult(
      matchedRules: const [GuardianLocalHeuristicEngine.ruleRemoteAccessTool],
      matchedPhrases: const ['anydesk'],
      warningHeadline: 'Urgent: Screen-sharing application installation requested',
      safeAction:
          'Never install AnyDesk, TeamViewer, or remote access apps on instructions from unknown callers.',
      evaluatedAt: DateTime.utc(2026, 10, 7),
      engineVersion: '1.0.0',
      hasMatches: true,
    );

    final snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_UNAVAILABLE',
      message: 'Backend unreachable.',
      result: null,
      lastAnalyzedSequence: 0,
      isAnalyzing: false,
      networkStatus: GuardianNetworkStatus.backendUnreachable,
      localHeuristicResult: heuristic,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(snapshot: snapshot),
        ),
      ),
    );

    expect(find.text('LOCAL HEURISTIC — OFFLINE'), findsOneWidget);
    expect(find.text('"anydesk"'), findsOneWidget);
    expect(
      find.textContaining('Never install AnyDesk'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Does not include AI reasoning'),
      findsOneWidget,
    );
  });

  testWidgets(
      'renders honest no-match notice when offline and no local rule matches',
      (tester) async {
    final heuristic = GuardianLocalHeuristicResult(
      matchedRules: const [],
      matchedPhrases: const [],
      warningHeadline: 'No local rule matched.',
      safeAction: GuardianLocalHeuristicResult.noMatchNotice,
      evaluatedAt: DateTime.utc(2026, 10, 7),
      engineVersion: '1.0.0',
      hasMatches: false,
    );

    final snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_UNAVAILABLE',
      message: 'Backend unreachable.',
      result: null,
      lastAnalyzedSequence: 0,
      isAnalyzing: false,
      networkStatus: GuardianNetworkStatus.backendUnreachable,
      localHeuristicResult: heuristic,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(snapshot: snapshot),
        ),
      ),
    );

    expect(find.text('LOCAL HEURISTIC — OFFLINE'), findsOneWidget);
    expect(
      find.text('No local rule matched. This does not establish that the conversation is safe.'),
      findsOneWidget,
    );
    expect(
      find.text('Full AI analysis requires backend connectivity.'),
      findsOneWidget,
    );
  });

  testWidgets(
      'preserves previous online result with stale warning and local heuristic alert',
      (tester) async {
    final result = GuardianLiveAnalysisResult(
      riskScore: 78,
      riskLevel: 'HIGH',
      classification: 'SCAM',
      scamCategory: 'Govt Impersonation',
      detectedIndicators: ['Intimidation'],
      reasoning: 'Impersonates customs authority.',
      supportingEvidence: const [],
      mlProbability: 0.88,
      llmConfidence: 0.85,
      safeAction: 'Do not transfer funds.',
      safeActions: null,
      timestamp: DateTime.utc(2026, 10, 7),
      sessionId: '00000000-0000-4000-8000-000000000018',
      language: 'en',
      evidenceStatus: 'NO_RELEVANT_MATCH',
      processingStatus: 'COMPLETED',
      modelVersion: 'scamshield-classifier-v5',
      ragVersion: 'scamshield-rag-v1',
      timingsMs: const {},
    );

    final snapshot = GuardianLiveAnalysisSnapshot(
      state: 'AI_UNAVAILABLE',
      message: 'Network offline.',
      result: result,
      lastAnalyzedSequence: 2,
      isAnalyzing: false,
      networkStatus: GuardianNetworkStatus.backendUnreachable,
      queuedCount: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GuardianLiveRiskCard(snapshot: snapshot),
        ),
      ),
    );

    // Risk score 78 preserved
    expect(find.text('78'), findsOneWidget);
    expect(find.text('HIGH RISK'), findsOneWidget);

    // Stale & updates paused indicators rendered
    expect(find.text('Updates paused'), findsOneWidget);
    expect(find.text('(1 queued)'), findsOneWidget);
    expect(
      find.textContaining('Backend unreachable. Showing last confirmed assessment (potentially stale).'),
      findsOneWidget,
    );
  });
}

