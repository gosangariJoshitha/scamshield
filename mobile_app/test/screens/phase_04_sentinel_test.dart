import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/models/call_history_models.dart';
import 'package:scamshield_guardian/native/call_bridge.dart';
import 'package:scamshield_guardian/screens/home/widgets/security_radar_hero.dart';
import 'package:scamshield_guardian/screens/sentinel/call_report_screen.dart';
import 'package:scamshield_guardian/screens/sentinel/guardian_details_screen.dart';
import 'package:scamshield_guardian/screens/sentinel/live_call_monitoring_screen.dart';
import 'package:scamshield_guardian/screens/sentinel/sentinel_screen.dart';
import 'package:scamshield_guardian/services/guardian_transcription_service.dart';

void main() {
  const activeStatus = CallGuardianStatus(
    available: true,
    supported: true,
    phoneStatePermissionGranted: true,
    notificationsPermissionGranted: true,
    enabled: true,
    serviceRunning: true,
    callState: 'IDLE',
    serviceError: null,
    callScreeningAvailable: true,
    callScreeningEnabled: true,
    incomingCallDetection: true,
    outgoingCallDetection: true,
    activeCallStateDetection: true,
    audioCaptureAvailable: true,
    audioPermissionGranted: true,
    audioProtectionEnabled: true,
    audioState: 'IDLE',
    audioSource: 'MIC',
    audioRoute: 'SPEAKERPHONE',
    audioReason: '',
    audioChunksCreated: 10,
    audioChunksDropped: 0,
  );

  const serviceStoppedStatus = CallGuardianStatus(
    available: true,
    supported: true,
    phoneStatePermissionGranted: true,
    notificationsPermissionGranted: true,
    enabled: true,
    serviceRunning: false, // Service stopped by OS
    callState: 'IDLE',
    serviceError: null,
    callScreeningAvailable: true,
    callScreeningEnabled: true,
    incomingCallDetection: true,
    outgoingCallDetection: true,
    activeCallStateDetection: true,
    audioCaptureAvailable: false,
    audioPermissionGranted: true,
    audioProtectionEnabled: false,
    audioState: 'UNAVAILABLE',
    audioSource: '',
    audioRoute: 'UNKNOWN',
    audioReason: '',
    audioChunksCreated: 0,
    audioChunksDropped: 0,
  );

  const permissionRevokedStatus = CallGuardianStatus(
    available: true,
    supported: true,
    phoneStatePermissionGranted: false, // Revoked by user
    notificationsPermissionGranted: true,
    enabled: true,
    serviceRunning: false,
    callState: 'IDLE',
    serviceError: null,
    callScreeningAvailable: true,
    callScreeningEnabled: false,
    incomingCallDetection: false,
    outgoingCallDetection: false,
    activeCallStateDetection: false,
    audioCaptureAvailable: false,
    audioPermissionGranted: false,
    audioProtectionEnabled: false,
    audioState: 'UNAVAILABLE',
    audioSource: '',
    audioRoute: 'UNKNOWN',
    audioReason: '',
    audioChunksCreated: 0,
    audioChunksDropped: 0,
  );

  const disabledStatus = CallGuardianStatus(
    available: true,
    supported: true,
    phoneStatePermissionGranted: false,
    notificationsPermissionGranted: false,
    enabled: false,
    serviceRunning: false,
    callState: 'IDLE',
    serviceError: null,
    callScreeningAvailable: false,
    callScreeningEnabled: false,
    incomingCallDetection: false,
    outgoingCallDetection: false,
    activeCallStateDetection: false,
    audioCaptureAvailable: false,
    audioPermissionGranted: false,
    audioProtectionEnabled: false,
    audioState: 'IDLE',
    audioSource: '',
    audioRoute: 'UNKNOWN',
    audioReason: '',
    audioChunksCreated: 0,
    audioChunksDropped: 0,
  );

  const micCapability = AudioCapability(
    supported: true,
    source: 'MIC',
    permissionStatus: 'GRANTED',
    sampleRateHz: 16000,
    channels: 1,
    encoding: 'pcm_s16le',
    chunkDurationMs: 5000,
    maxBufferedChunks: 2,
    reason: 'Supported microphone source',
  );

  group('Phase 04 — Sentinel Protection State Synchronization', () {
    test('Authoritative isProtected getter strictly requires all 3 conditions', () {
      expect(activeStatus.isProtected, isTrue);
      expect(serviceStoppedStatus.isProtected, isFalse);
      expect(permissionRevokedStatus.isProtected, isFalse);
      expect(disabledStatus.isProtected, isFalse);
    });

    testWidgets('SecurityRadarHeroCard displays SENTINEL ACTIVE when fully protected', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecurityRadarHeroCard(
              guardianStatus: activeStatus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SENTINEL ACTIVE'), findsOneWidget);
      expect(find.text('AI Threat Defence'), findsOneWidget);
      expect(find.text('Sentinel Active'), findsOneWidget);
    });

    testWidgets('SecurityRadarHeroCard displays SERVICE STOPPED when OS killed background service', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecurityRadarHeroCard(
              guardianStatus: serviceStoppedStatus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SERVICE STOPPED'), findsOneWidget);
      expect(find.textContaining('Background call service was stopped'), findsOneWidget);
      expect(find.text('Sentinel Ready'), findsOneWidget);
    });

    testWidgets('SecurityRadarHeroCard displays SETUP REQUIRED when permissions are revoked', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecurityRadarHeroCard(
              guardianStatus: permissionRevokedStatus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SETUP REQUIRED'), findsOneWidget);
      expect(find.textContaining('Phone permissions required'), findsOneWidget);
    });

    testWidgets('SecurityRadarHeroCard displays SENTINEL INACTIVE when turned off', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SecurityRadarHeroCard(
              guardianStatus: disabledStatus,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SENTINEL INACTIVE'), findsOneWidget);
      expect(find.text('Sentinel Ready'), findsOneWidget);
    });

    testWidgets('SecurityRadarHeroCard navigates to Sentinel on card tap', (tester) async {
      var openedSentinel = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SecurityRadarHeroCard(
              guardianStatus: activeStatus,
              onOpenSentinel: () => openedSentinel = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('AI Threat Defence'));
      await tester.pumpAndSettle();

      expect(openedSentinel, isTrue);
    });
  });

  group('Phase 04 — Sentinel User-Facing Labeling and Verification', () {
    testWidgets('SentinelScreen displays Live Call Sentinel headers and switches', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentinelScreen(
              status: activeStatus,
              audioCapability: micCapability,
              audioCapabilityError: null,
              error: null,
              callEvent: null,
              activeCallSeconds: 0,
              onRetry: () {},
              onToggleGuardian: (_) {},
              onToggleAudioProtection: (_) {},
              onRetryAudioProtection: () {},
              transcriptionEnabled: true,
              transcriptionSnapshot: null,
              analysisSnapshot: null,
              onToggleTranscription: (_) {},
              onOpenSettings: () {},
              onRequestCallScreeningRole: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sentinel'), findsOneWidget);
      expect(find.text('Live Call Sentinel'), findsAtLeastNWidgets(1));
      expect(find.text('Sentinel is on · Ready'), findsOneWidget);
      expect(find.text('Enable Sentinel'), findsOneWidget);
    });

    testWidgets('GuardianDetailsScreen displays About Live Call Sentinel dialog and Sentinel controls', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: GuardianDetailsScreen(
            status: activeStatus,
            audioCapability: micCapability,
            audioCapabilityError: null,
            transcriptionEnabled: true,
            transcriptionSnapshot: null,
            analysisSnapshot: null,
            onToggleGuardian: (_) {},
            onToggleAudioProtection: (_) {},
            onToggleTranscription: (_) {},
            onRequestCallScreeningRole: () {},
            onOpenSettings: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Call Sentinel'), findsOneWidget);
      expect(find.text('Sentinel Service'), findsOneWidget);
      expect(find.text('Enable Sentinel'), findsOneWidget);

      // Tap Info icon to verify dialog title
      await tester.tap(find.byIcon(Icons.info_outline_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('About Live Call Sentinel'), findsOneWidget);
    });
  });

  group('Phase 04 — Speakerphone Guidance and Live Call Lifecycle', () {
    testWidgets('LiveCallMonitoringScreen renders prominent Speakerphone Required banner', (tester) async {
      final callEvent = GuardianCallEvent(
        event: 'CALL_ACTIVE',
        sessionId: 'session-404-e2e',
        direction: 'INCOMING',
        state: 'ACTIVE',
        timestamp: DateTime.now(),
        source: 'TELEPHONY_CALLBACK',
      );

      final segments = [
        TranscriptSegment(
          sessionId: 'session-404-e2e',
          segmentId: 'seg_1',
          sequence: 1,
          startTime: 0.0,
          endTime: 4.0,
          text: 'Hello, this is State Bank security team.',
          isFinal: true,
          language: 'en',
          createdAt: DateTime.now(),
          source: 'DEVICE_MICROPHONE',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: LiveCallMonitoringScreen(
            callEvent: callEvent,
            activeCallSeconds: 15,
            segments: segments,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Speakerphone Required'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.text('Live Call Monitoring'), findsOneWidget);
      expect(find.text('Sentinel live call shield is active.'), findsNothing); // SnackBar initially hidden
    });

    testWidgets('CallReportScreen renders multilingual recommendations and final actions', (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final callReport = CallHistoryDetail(
        id: 999,
        sessionId: 'session-404-finalize',
        startedAt: DateTime.now().subtract(const Duration(seconds: 90)),
        endedAt: DateTime.now(),
        durationSeconds: 90,
        finalRiskScore: 95,
        finalRiskLevel: 'CRITICAL',
        classification: 'SCAM',
        scamCategory: 'BANK_IMPERSONATION',
        analysisStatus: 'COMPLETED',
        transcriptionStatus: 'COMPLETED',
        audioStatus: 'SPEAKERPHONE_CAPTURED',
        guardianEnabled: true,
        guardianStatus: 'RUNNING',
        riskReasoning: 'Caller impersonated a bank representative demanding immediate OTP verification.',
        detectedIndicators: const ['Urgent Action', 'OTP Request', 'Bank Impersonation'],
        protectionActions: const [
          {'action': 'Never share OTP or banking credentials.'},
          {'action': 'Hang up immediately and contact your branch.'},
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CallReportScreen(
            call: callReport,
            onViewHistory: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Scam Call Detected'), findsOneWidget);
      expect(find.text('Critical Risk'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.text('తెలుగు'), findsOneWidget);

      // Verify Hindi translation
      await tester.ensureVisible(find.text('हिंदी'));
      await tester.tap(find.text('हिंदी'));
      await tester.pumpAndSettle();
      expect(find.textContaining('व्यक्तिगत या बैंकिंग विवरण'), findsOneWidget);

      // Verify Telugu translation
      await tester.ensureVisible(find.text('తెలుగు'));
      await tester.tap(find.text('తెలుగు'));
      await tester.pumpAndSettle();
      expect(find.textContaining('వ్యక్తిగత లేదా బ్యాంకింగ్'), findsOneWidget);
    });
  });
}
