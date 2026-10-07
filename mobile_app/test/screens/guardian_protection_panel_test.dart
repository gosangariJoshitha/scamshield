import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/guardian_analysis_models.dart';
import 'package:scamshield_guardian/models/guardian_protection_models.dart';
import 'package:scamshield_guardian/native/call_bridge.dart';
import 'package:scamshield_guardian/screens/settings/settings_screen.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/guardian_protection_service.dart';
import 'package:scamshield_guardian/widgets/guardian_live_risk_card.dart';

class MockTestCallBridge extends CallBridge {
  MockTestCallBridge({
    this.endCallSupported = true,
    this.blockCallerSupported = false,
  });

  final bool endCallSupported;
  final bool blockCallerSupported;
  bool endCallRequested = false;
  bool blockCallerRequested = false;
  bool openSettingsRequested = false;

  @override
  Future<GuardianProtectionCapabilities> getProtectionCapabilities() async {
    return GuardianProtectionCapabilities(
      canEndCall: GuardianCapabilityItem(
        supported: endCallSupported,
        reason: endCallSupported ? 'Supported' : 'Android restrictions prevent programmatic hang-up',
      ),
      canBlockCaller: GuardianCapabilityItem(
        supported: blockCallerSupported,
        reason: 'Third-party apps cannot block numbers directly',
      ),
      canReport: const GuardianCapabilityItem(supported: true, reason: 'Supported'),
      canVibrate: const GuardianCapabilityItem(supported: true, reason: 'Supported'),
      canVerifySafely: const GuardianCapabilityItem(supported: true, reason: 'Supported'),
    );
  }

  @override
  Future<Map<String, dynamic>> requestEndCall({required String sessionId}) async {
    endCallRequested = true;
    if (endCallSupported) {
      return {
        'success': true,
        'supported': true,
        'reason': 'Call ended successfully.',
      };
    } else {
      return {
        'success': false,
        'supported': false,
        'reason': 'Your device does not allow ScamShield to end calls automatically.',
      };
    }
  }

  @override
  Future<Map<String, dynamic>> requestBlockCaller({
    required String sessionId,
    String? phoneNumber,
  }) async {
    blockCallerRequested = true;
    return {
      'success': false,
      'supported': false,
      'reason': 'Third-party apps cannot block numbers directly on Android.',
      'canOpenSettings': true,
    };
  }

  @override
  Future<void> openBlockedNumbersSettings() async {
    openSettingsRequested = true;
  }

  @override
  Future<void> triggerHapticAlert(String intensity) async {}
}

GuardianLiveAnalysisResult makeRiskResult({
  required String level,
  required int score,
  List<String> indicators = const ['OTP request', 'Urgency', 'Account threat'],
  String? safeAction,
}) {
  return GuardianLiveAnalysisResult(
    riskScore: score,
    riskLevel: level,
    classification: 'SCAM',
    scamCategory: 'Bank Impersonation',
    detectedIndicators: indicators,
    reasoning: 'Caller pressured for confidential credentials.',
    supportingEvidence: [
      GuardianRetrievedEvidence(
        knowledgeId: 1,
        title: 'Bank Scam Pattern',
        category: 'vishing',
        similarityScore: 0.9,
        pattern: 'OTP theft',
        description: 'Impersonates bank agent',
        indicators: indicators,
        safeAction: safeAction ?? 'Never share one-time passwords over the phone.',
        source: 'Advisory',
        language: 'en',
      ),
    ],
    mlProbability: 0.9,
    llmConfidence: 0.88,
    safeAction: safeAction ?? 'Do not share OTPs or passwords.',
    safeActions: {
      'recommended': safeAction ?? 'Do not share OTPs or passwords.',
    },
    timestamp: DateTime.now(),
    sessionId: 'session-1',
    language: 'en',
    evidenceStatus: 'RETRIEVED',
    processingStatus: 'SUCCESS',
    modelVersion: 'v1.0',
    ragVersion: 'v1.0',
    timingsMs: const {},
  );
}

void main() {
  group('GuardianProtectionPanel Widget Tests', () {
    late MockTestCallBridge bridge;
    late ApiService api;
    late GuardianProtectionService protectionService;

    setUp(() {
      bridge = MockTestCallBridge(endCallSupported: true);
      api = ApiService(
        client: MockClient((request) async => http.Response('{}', 200)),
        baseUri: Uri.parse('https://api.example.test/api'),
      );
      protectionService = GuardianProtectionService(
        callBridge: bridge,
        api: api,
        tokenProvider: () async => 'token',
      );
    });

    tearDown(() {
      protectionService.dispose();
    });

    void setLargeSurface(WidgetTester tester) {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('does not show protective actions for LOW risk result', (tester) async {
      setLargeSurface(tester);
      await protectionService.initialize();
      protectionService.startSession('session-1');

      final result = makeRiskResult(level: 'LOW', score: 15);
      final snapshot = GuardianLiveAnalysisSnapshot(
        state: 'AI_ANALYSIS_AVAILABLE',
        message: 'Call monitored.',
        result: result,
        lastAnalyzedSequence: 1,
        isAnalyzing: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuardianLiveRiskCard(
                snapshot: snapshot,
                isCallActive: true,
                protectionService: protectionService,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Protection Actions'), findsNothing);
      expect(find.text('End Call'), findsNothing);
      expect(find.text('Verify Safely'), findsNothing);
    });

    testWidgets('shows protection actions panel for HIGH risk result', (tester) async {
      setLargeSurface(tester);
      await protectionService.initialize();
      protectionService.startSession('session-1');

      final result = makeRiskResult(level: 'HIGH', score: 75);
      final snapshot = GuardianLiveAnalysisSnapshot(
        state: 'AI_ANALYSIS_AVAILABLE',
        message: 'High risk detected.',
        result: result,
        lastAnalyzedSequence: 1,
        isAnalyzing: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuardianLiveRiskCard(
                snapshot: snapshot,
                isCallActive: true,
                protectionService: protectionService,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Stay Protected'), findsOneWidget);
      expect(find.text('HIGH RISK'), findsAtLeastNWidgets(1));
      expect(find.text('End Call'), findsOneWidget);
      expect(find.text('Block Caller'), findsOneWidget);
      expect(find.text('Verify Safely'), findsOneWidget);
    });

    testWidgets('shows critical protection banner for CRITICAL risk result', (tester) async {
      setLargeSurface(tester);
      await protectionService.initialize();
      protectionService.startSession('session-1');

      final result = makeRiskResult(level: 'CRITICAL', score: 92);
      final snapshot = GuardianLiveAnalysisSnapshot(
        state: 'AI_ANALYSIS_AVAILABLE',
        message: 'Critical scam indicators detected.',
        result: result,
        lastAnalyzedSequence: 1,
        isAnalyzing: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuardianLiveRiskCard(
                snapshot: snapshot,
                isCallActive: true,
                protectionService: protectionService,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Stay Protected'), findsOneWidget);
      expect(find.text('CRITICAL RISK'), findsAtLeastNWidgets(1));
      expect(find.text('End Call'), findsOneWidget);
    });

    testWidgets('tapping Verify Safely displays step-by-step guidance dialog', (tester) async {
      setLargeSurface(tester);
      await protectionService.initialize();
      protectionService.startSession('session-1');

      final result = makeRiskResult(
        level: 'HIGH',
        score: 78,
        safeAction: 'Open the verified banking app directly to check alerts.',
      );
      final snapshot = GuardianLiveAnalysisSnapshot(
        state: 'AI_ANALYSIS_AVAILABLE',
        message: 'High risk detected.',
        result: result,
        lastAnalyzedSequence: 1,
        isAnalyzing: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuardianLiveRiskCard(
                snapshot: snapshot,
                isCallActive: true,
                protectionService: protectionService,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Verify Safely'));
      await tester.pumpAndSettle();

      expect(find.text('Verify Safely'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Before taking action or sharing any details'), findsOneWidget);
      expect(find.textContaining('Never disclose OTPs, PINs, passwords'), findsOneWidget);

      await tester.tap(find.text('UNDERSTOOD'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Before taking action or sharing any details'), findsNothing);
    });

    testWidgets('End Call prompts confirmation dialog and respects Cancel', (tester) async {
      setLargeSurface(tester);
      await protectionService.initialize();
      protectionService.startSession('session-1');

      final result = makeRiskResult(level: 'HIGH', score: 75);
      final snapshot = GuardianLiveAnalysisSnapshot(
        state: 'AI_ANALYSIS_AVAILABLE',
        message: 'High risk detected.',
        result: result,
        lastAnalyzedSequence: 1,
        isAnalyzing: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuardianLiveRiskCard(
                snapshot: snapshot,
                isCallActive: true,
                protectionService: protectionService,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('End Call'));
      await tester.pumpAndSettle();

      expect(find.text('End this call?'), findsOneWidget);
      expect(find.textContaining('ScamShield detected HIGH risk scam indicators'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);

      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();

      expect(bridge.endCallRequested, isFalse);
      expect(find.text('End this call?'), findsNothing);
    });

    testWidgets('End Call confirmed executes native termination when supported', (tester) async {
      setLargeSurface(tester);
      await protectionService.initialize();
      protectionService.startSession('session-1');

      final result = makeRiskResult(level: 'HIGH', score: 75);
      final snapshot = GuardianLiveAnalysisSnapshot(
        state: 'AI_ANALYSIS_AVAILABLE',
        message: 'High risk detected.',
        result: result,
        lastAnalyzedSequence: 1,
        isAnalyzing: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuardianLiveRiskCard(
                snapshot: snapshot,
                isCallActive: true,
                protectionService: protectionService,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('End Call'));
      await tester.pumpAndSettle();

      expect(find.text('END CALL'), findsOneWidget);
      await tester.tap(find.text('END CALL'));
      await tester.pumpAndSettle();

      expect(bridge.endCallRequested, isTrue);
    });

    testWidgets('End Call honestly reports limitation when device does not support it', (tester) async {
      setLargeSurface(tester);
      final unsupportedBridge = MockTestCallBridge(endCallSupported: false);
      final localService = GuardianProtectionService(
        callBridge: unsupportedBridge,
        api: api,
        tokenProvider: () async => 'token',
      );
      await localService.initialize();
      localService.startSession('session-1');

      final result = makeRiskResult(level: 'HIGH', score: 75);
      final snapshot = GuardianLiveAnalysisSnapshot(
        state: 'AI_ANALYSIS_AVAILABLE',
        message: 'High risk detected.',
        result: result,
        lastAnalyzedSequence: 1,
        isAnalyzing: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuardianLiveRiskCard(
                snapshot: snapshot,
                isCallActive: true,
                protectionService: localService,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('End Call'));
      await tester.pumpAndSettle();

      expect(find.text('End call isn\'t supported on this device'), findsOneWidget);
      expect(
        find.textContaining('Android restrictions prevent programmatic hang-up'),
        findsOneWidget,
      );

      await tester.tap(find.text('GOT IT'));
      await tester.pumpAndSettle();
      expect(find.text('End call isn\'t supported on this device'), findsNothing);

      localService.dispose();
    });

    testWidgets('Block Caller displays honest third-party guidance and system settings intent', (tester) async {
      setLargeSurface(tester);
      await protectionService.initialize();
      protectionService.startSession('session-1');

      final result = makeRiskResult(level: 'HIGH', score: 75);
      final snapshot = GuardianLiveAnalysisSnapshot(
        state: 'AI_ANALYSIS_AVAILABLE',
        message: 'High risk detected.',
        result: result,
        lastAnalyzedSequence: 1,
        isAnalyzing: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GuardianLiveRiskCard(
                snapshot: snapshot,
                isCallActive: true,
                protectionService: protectionService,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Block Caller'));
      await tester.pumpAndSettle();

      expect(find.text('Caller blocking unavailable directly'), findsOneWidget);
      expect(
        find.textContaining('Third-party apps cannot block numbers directly'),
        findsOneWidget,
      );
      expect(find.text('OPEN CALL SETTINGS'), findsOneWidget);

      await tester.tap(find.text('OPEN CALL SETTINGS'));
      await tester.pumpAndSettle();

      expect(bridge.openSettingsRequested, isTrue);
    });

    testWidgets('CallProtectionSettingsScreen renders protection preference switches with safety constraints', (tester) async {
      setLargeSurface(tester);
      await protectionService.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: CallProtectionSettingsScreen(
            onOpenGuardian: () {},
            protectionService: protectionService,
          ),
        ),
      );

      expect(find.text('GUARDIAN PROTECTION'), findsOneWidget);
      expect(find.text('Risk alerts'), findsOneWidget);
      expect(find.text('High-risk vibration'), findsOneWidget);
      expect(find.text('Critical-risk alerts'), findsOneWidget);
      expect(find.text('Show protection actions'), findsOneWidget);
      expect(find.text('Ask before protective actions'), findsOneWidget);

      await tester.tap(find.widgetWithText(SwitchListTile, 'High-risk vibration'));
      await tester.pumpAndSettle();

      expect(protectionService.settings.highRiskVibrationEnabled, isFalse);
    });
  });
}
