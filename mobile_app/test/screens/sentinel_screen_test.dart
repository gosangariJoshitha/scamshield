import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/models/call_history_models.dart';
import 'package:scamshield_guardian/native/call_bridge.dart';
import 'package:scamshield_guardian/screens/sentinel/call_report_screen.dart';
import 'package:scamshield_guardian/screens/sentinel/guardian_details_screen.dart';
import 'package:scamshield_guardian/screens/sentinel/live_call_monitoring_screen.dart';
import 'package:scamshield_guardian/screens/sentinel/sentinel_screen.dart';
import 'package:scamshield_guardian/services/guardian_transcription_service.dart';

void main() {
  const idleStatus = CallGuardianStatus(
    available: true,
    supported: true,
    phoneStatePermissionGranted: true,
    notificationsPermissionGranted: true,
    enabled: true,
    serviceRunning: true,
    callState: 'IDLE',
    serviceError: null,
    callScreeningAvailable: true,
    callScreeningEnabled: false,
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
    callScreeningAvailable: true,
    callScreeningEnabled: false,
    incomingCallDetection: true,
    outgoingCallDetection: true,
    activeCallStateDetection: true,
    audioCaptureAvailable: true,
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

  group('Screen A — Sentinel Overview', () {
    testWidgets('renders Sentinel brand header, hero card, 2x2 grid, and feature list', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentinelScreen(
              status: idleStatus,
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
      expect(find.text('Live Call Guardian'), findsAtLeastNWidgets(1));
      expect(find.text('Guardian is on · Ready'), findsAtLeastNWidgets(1));
      expect(find.text('Call Protection'), findsOneWidget);
      expect(find.text('Message Protection'), findsOneWidget);
      expect(find.text('Link Protection'), findsOneWidget);
      expect(find.text('Web Protection'), findsOneWidget);
      await tester.ensureVisible(find.text('Real-time Alerts'));
      expect(find.text('Real-time Alerts'), findsOneWidget);
      expect(find.text('Updated Scam Database'), findsOneWidget);
      expect(find.text('Community Protection'), findsOneWidget);
    });

    testWidgets('shows disabled status when Guardian is off', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentinelScreen(
              status: disabledStatus,
              audioCapability: micCapability,
              audioCapabilityError: null,
              error: null,
              callEvent: null,
              activeCallSeconds: 0,
              onRetry: () {},
              onToggleGuardian: (_) {},
              onToggleAudioProtection: (_) {},
              onRetryAudioProtection: () {},
              transcriptionEnabled: false,
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

      expect(find.text('Guardian is off. Call activity is not monitored.'), findsOneWidget);
    });

    testWidgets('displays active call alert banner when a call is ongoing', (tester) async {
      final activeCallEvent = GuardianCallEvent(
        event: 'CALL_ACTIVE',
        sessionId: 'test-session-1234',
        direction: 'INCOMING',
        state: 'ACTIVE',
        timestamp: DateTime.now(),
        source: 'TELEPHONY_CALLBACK',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SentinelScreen(
              status: idleStatus,
              audioCapability: micCapability,
              audioCapabilityError: null,
              error: null,
              callEvent: activeCallEvent,
              activeCallSeconds: 45,
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

      expect(find.text('Call Active'), findsOneWidget);
      expect(find.text('Call duration · 00:45'), findsOneWidget);
      expect(find.text('Monitor'), findsOneWidget);
    });
  });

  group('Screen B — Guardian Details & Permissions', () {
    testWidgets('renders category pills, radar animation, and permission checklist', (tester) async {
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: GuardianDetailsScreen(
            status: idleStatus,
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

      expect(find.text('Sentinel'), findsOneWidget);
      expect(find.text('Call Guardian'), findsOneWidget);
      expect(find.text('Message Protection'), findsOneWidget);
      await tester.ensureVisible(find.text('Permissions & Access'));
      expect(find.text('Permissions & Access'), findsOneWidget);
      expect(find.text('Microphone'), findsOneWidget);
      expect(find.text('Phone Access'), findsOneWidget);
      expect(find.textContaining('Draw over other apps'), findsOneWidget);
      expect(find.text('Guardian Service'), findsOneWidget);
      expect(find.text('Running'), findsOneWidget);
    });
  });

  group('Screen C — Live Call Monitoring', () {
    testWidgets('renders caller metadata, 4-step timeline, and live transcripts', (tester) async {
      final ringingEvent = GuardianCallEvent(
        event: 'CALL_RINGING',
        sessionId: 'test-session-9876',
        direction: 'INCOMING',
        state: 'RINGING',
        timestamp: DateTime.now(),
        source: 'TELEPHONY_CALLBACK',
      );

      final segments = [
        TranscriptSegment(
          sessionId: 'test-session-9876',
          segmentId: 'seg_1',
          sequence: 1,
          startTime: 0.0,
          endTime: 4.5,
          text: 'Hello, who is this?',
          isFinal: true,
          language: 'en',
          createdAt: DateTime.now(),
          source: 'DEVICE_MICROPHONE',
        ),
        TranscriptSegment(
          sessionId: 'test-session-9876',
          segmentId: 'seg_2',
          sequence: 2,
          startTime: 5.0,
          endTime: 9.5,
          text: 'You have won a prize of 50,000 rupees. Please share your bank details.',
          isFinal: true,
          language: 'en',
          createdAt: DateTime.now(),
          source: 'SPEAKERPHONE_AUDIO',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: LiveCallMonitoringScreen(
            callEvent: ringingEvent,
            activeCallSeconds: 8,
            segments: segments,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sentinel'), findsOneWidget);
      expect(find.text('Live Call Monitoring'), findsOneWidget);
      expect(find.text('Potential Scam'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
      expect(find.text('Answer'), findsOneWidget);
      expect(find.textContaining('Analyzing Call in Real-Time'), findsOneWidget);
      expect(find.textContaining('Capturing'), findsOneWidget);
      expect(find.text('Live Transcription (You)'), findsOneWidget);
      expect(find.text('Live Transcription (Caller)'), findsOneWidget);
      expect(find.text('Hello, who is this?'), findsOneWidget);
      expect(find.textContaining('You have won a prize'), findsOneWidget);
      expect(find.text('Detected Indicators'), findsOneWidget);
    });
  });

  group('Screen D — Final Call Analysis Report', () {
    testWidgets('renders final report outcome, summary, indicators, and multilingual recommendations', (tester) async {
      tester.view.physicalSize = const Size(800, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final callReport = CallHistoryDetail(
        id: 101,
        sessionId: 'test-session-5555',
        startedAt: DateTime.now().subtract(const Duration(minutes: 3, seconds: 25)),
        endedAt: DateTime.now(),
        durationSeconds: 205,
        finalRiskScore: 92,
        finalRiskLevel: 'HIGH',
        classification: 'SCAM',
        scamCategory: 'LOTTERY_PRIZE_SCAM',
        analysisStatus: 'COMPLETED',
        transcriptionStatus: 'COMPLETED',
        audioStatus: 'SPEAKERPHONE_CAPTURED',
        guardianEnabled: true,
        guardianStatus: 'RUNNING',
        riskReasoning: 'The caller claimed a prize reward and asked for personal and banking details. This matches known scam patterns used to steal financial information.',
        detectedIndicators: const [
          'Prize Claim',
          'Urgent Action',
          'Bank Details',
          'Unknown Number',
          'Scam Pattern Match',
        ],
        protectionActions: const [
          {'action': 'Do not share any personal or banking details.'},
          {'action': 'Do not make any payments.'},
          {'action': 'Block and report this number.'},
          {'action': 'If you have already shared information, contact your bank immediately.'},
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

      expect(find.text('Sentinel'), findsOneWidget);
      expect(find.text('Scam Call Detected'), findsOneWidget);
      expect(find.text('High Risk'), findsOneWidget);
      expect(find.text('Call Details'), findsOneWidget);
      expect(find.text('00:03:25'), findsOneWidget);
      expect(find.text('Analysis Summary'), findsOneWidget);
      await tester.ensureVisible(find.text('Prize Claim'));
      expect(find.text('Prize Claim'), findsOneWidget);
      expect(find.text('Bank Details'), findsOneWidget);
      await tester.ensureVisible(find.text('Recommendation'));
      expect(find.text('Recommendation'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('हिंदी'), findsOneWidget);
      expect(find.text('తెలుగు'), findsOneWidget);
      await tester.ensureVisible(find.text('View in History'));
      expect(find.text('View in History'), findsOneWidget);
      expect(find.text('Block Number'), findsOneWidget);

      // Verify switching to Hindi
      await tester.ensureVisible(find.text('हिंदी'));
      await tester.tap(find.text('हिंदी'));
      await tester.pumpAndSettle();
      expect(find.textContaining('व्यक्तिगत या बैंकिंग विवरण'), findsOneWidget);

      // Verify switching to Telugu
      await tester.ensureVisible(find.text('తెలుగు'));
      await tester.tap(find.text('తెలుగు'));
      await tester.pumpAndSettle();
      expect(find.textContaining('వ్యక్తిగత లేదా బ్యాంకింగ్'), findsOneWidget);
    });
  });
}
