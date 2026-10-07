import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/user.dart';
import 'package:scamshield_guardian/screens/home/home_screen.dart';
import 'package:scamshield_guardian/screens/profile/profile_screen.dart';
import 'package:scamshield_guardian/services/analysis_service.dart';
import 'package:scamshield_guardian/services/api_service.dart';

const _user = User(
  id: 1,
  fullName: 'Sam User',
  email: 'sam@example.com',
  role: 'user',
  isActive: true,
  emailVerified: true,
  twoFactorEnabled: false,
);

AnalysisService _analysisService({bool includeHistory = true}) {
  return AnalysisService(
    api: ApiService(
      client: MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer test-token');
        if (request.url.path.endsWith('/analysis/dashboard')) {
          return http.Response(
            jsonEncode({
              'total_analyses': includeHistory ? 1 : 0,
              'scams_detected': includeHistory ? 1 : 0,
              'safe_messages': 0,
              'high_risk': includeHistory ? 1 : 0,
            }),
            200,
          );
        }
        if (request.url.path.contains('/calls/history')) {
          return http.Response(
            jsonEncode({
              'items': [],
              'total': 0,
              'page': 1,
              'limit': 20,
              'has_next': false,
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode(
            includeHistory
                ? [
                    {
                      'id': 17,
                      'content': 'Unusual payment request',
                      'risk_score': 90,
                      'risk_level': 'HIGH',
                      'classification': 'SCAM',
                      'category': 'PHISHING',
                      'input_type': 'text',
                      'created_at': '2026-10-06T10:00:00Z',
                      'explanation': 'Urgent payment language.',
                      'recommended_action': 'Verify independently.',
                    },
                  ]
                : [],
          ),
          200,
        );
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    ),
    tokenProvider: () async => 'test-token',
  );
}

Widget _home({bool includeHistory = true, bool isDarkMode = false}) {
  return MaterialApp(
    home: HomeScreen(
      user: _user,
      analysisService: _analysisService(includeHistory: includeHistory),
      onLogout: () async {},
      onSessionExpired: () async {},
      isDarkMode: isDarkMode,
      onToggleTheme: () {},
    ),
  );
}

void main() {
  testWidgets('dashboard shows user identity and real backend summary data', (
    tester,
  ) async {
    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();

    expect(find.text('Hello, Sam 👋'), findsOneWidget);
    expect(find.text('Your Activity Overview'), findsOneWidget);
    expect(find.text('Total Analyses'), findsOneWidget);
    expect(find.text('Scams detected'), findsOneWidget);
    expect(find.text('High Risk'), findsOneWidget);
    expect(find.text('1'), findsNWidgets(3));
    expect(find.text('Phishing detected'), findsOneWidget);
    expect(find.text('HIGH'), findsOneWidget);
  });

  testWidgets('quick actions open the selected backend analysis workflow', (
    tester,
  ) async {
    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Image'));
    await tester.pumpAndSettle();

    expect(find.text('Analyze an image'), findsOneWidget);
    expect(find.text('Choose file'), findsOneWidget);
    expect(find.text('ANALYZE'), findsOneWidget);
  });

  testWidgets('history tab reads data and Guardian reports native readiness', (
    tester,
  ) async {
    const channel = MethodChannel('com.scamshield/native');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getCallGuardianStatus') {
            return {
              'available': true,
              'supported': true,
              'phoneStatePermissionGranted': false,
              'notificationsPermissionGranted': false,
              'enabled': false,
              'serviceRunning': false,
              'callState': 'IDLE',
              'serviceError': '',
              'callScreeningAvailable': true,
              'callScreeningEnabled': false,
              'incomingCallDetection': false,
              'outgoingCallDetection': false,
              'activeCallStateDetection': false,
              'audioCaptureAvailable': false,
              'audioPermissionGranted': false,
              'audioProtectionEnabled': false,
              'audioState': 'IDLE',
              'audioSource': '',
              'audioRoute': 'UNKNOWN',
              'audioReason': '',
              'audioChunksCreated': 0,
              'audioChunksDropped': 0,
            };
          }
          if (call.method == 'isNativeLayerAvailable') return true;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('Analysis History'), findsOneWidget);
    expect(find.text('Phishing detected'), findsOneWidget);
    await tester.tap(find.text('Calls'));
    await tester.pumpAndSettle();
    expect(find.text('No protected calls yet'), findsOneWidget);
    expect(
      find.textContaining('ScamShield Guardian call summaries will appear here'),
      findsOneWidget,
    );
    await tester.tap(find.text('Analysis'));
    await tester.pumpAndSettle();
    expect(find.text('Phishing detected'), findsOneWidget);

    await tester.tap(find.text('Guardian'));
    await tester.pumpAndSettle();
    expect(find.text('Live Call Guardian'), findsNWidgets(2));
    expect(find.textContaining('call detection'), findsOneWidget);
    expect(
      find.text('Guardian is off. Call activity is not monitored.'),
      findsOneWidget,
    );
    expect(find.textContaining('not granted'), findsNothing);
  });

  testWidgets('Guardian displays native call session events without analysis', (
    tester,
  ) async {
    const channel = MethodChannel('com.scamshield/native');
    final status = {
      'available': true,
      'supported': true,
      'phoneStatePermissionGranted': true,
      'notificationsPermissionGranted': true,
      'enabled': true,
      'serviceRunning': true,
      'callState': 'IN_CALL',
      'serviceError': '',
      'callScreeningAvailable': true,
      'callScreeningEnabled': true,
      'incomingCallDetection': true,
      'outgoingCallDetection': true,
      'activeCallStateDetection': true,
      'audioCaptureAvailable': false,
      'audioPermissionGranted': false,
      'audioProtectionEnabled': false,
      'audioState': 'IDLE',
      'audioSource': '',
      'audioRoute': 'UNKNOWN',
      'audioReason': '',
      'audioChunksCreated': 0,
      'audioChunksDropped': 0,
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getCallGuardianStatus') return status;
          if (call.method == 'getLatestCallEvent') {
            return {
              'event': 'CALL_ACTIVE',
              'sessionId': 'c02d61e7-bd84-4bb3-a4fb-0495bc60f28f',
              'direction': 'INCOMING',
              'state': 'ACTIVE',
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'source': 'TELEPHONY_STATE',
            };
          }
          if (call.method == 'isNativeLayerAvailable') return true;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardian'));
    await tester.pumpAndSettle();

    expect(find.text('Call Active'), findsOneWidget);
    expect(find.textContaining('Call duration'), findsOneWidget);
    expect(
      find.textContaining('Microphone capture is optional'),
      findsOneWidget,
    );
    expect(find.text('Threat Detected'), findsNothing);
  });

  testWidgets(
    'audio opt-in asks microphone permission after consent and handles denial',
    (tester) async {
      const channel = MethodChannel('com.scamshield/native');
      var permissionRequests = 0;
      var audioEnableRequests = 0;
      final status = {
        'available': true,
        'supported': true,
        'phoneStatePermissionGranted': true,
        'notificationsPermissionGranted': true,
        'enabled': true,
        'serviceRunning': true,
        'callState': 'IDLE',
        'serviceError': '',
        'callScreeningAvailable': false,
        'callScreeningEnabled': false,
        'incomingCallDetection': false,
        'outgoingCallDetection': false,
        'activeCallStateDetection': true,
        'audioCaptureAvailable': false,
        'audioPermissionGranted': false,
        'audioProtectionEnabled': false,
        'audioState': 'IDLE',
        'audioSource': '',
        'audioRoute': 'UNKNOWN',
        'audioReason': '',
        'audioChunksCreated': 0,
        'audioChunksDropped': 0,
      };
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            if (call.method == 'getCallGuardianStatus') return status;
            if (call.method == 'getAudioCapability') {
              return {
                'supported': true,
                'source': 'DEVICE_MICROPHONE',
                'permissionStatus': 'DENIED',
                'reason': 'Device microphone only.',
                'sampleRateHz': 16000,
                'channels': 1,
                'encoding': 'PCM_16BIT',
                'chunkDurationMs': 5000,
                'maxBufferedChunks': 2,
              };
            }
            if (call.method == 'requestAudioPermission') {
              permissionRequests++;
              return {'permissionGranted': false, 'permissionStatus': 'DENIED'};
            }
            if (call.method == 'setAudioPipelineEnabled') {
              audioEnableRequests++;
              return status;
            }
            if (call.method == 'isNativeLayerAvailable') return true;
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      await tester.pumpWidget(_home());
      await tester.pumpAndSettle();
      await tester.tap(find.text('Guardian'));
      await tester.pumpAndSettle();
      final audioProtectionSwitch = find.descendant(
        of: find.widgetWithText(SwitchListTile, 'Microphone audio protection'),
        matching: find.byType(Switch),
      );
      await tester.ensureVisible(audioProtectionSwitch);
      await tester.tap(audioProtectionSwitch);
      await tester.pumpAndSettle();

      expect(find.text('Enable microphone audio protection?'), findsOneWidget);
      expect(permissionRequests, 0);
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();

      expect(permissionRequests, 1);
      expect(audioEnableRequests, 0);
      expect(
        find.text('Microphone permission is required for audio protection.'),
        findsOneWidget,
      );
      expect(find.text('Uses device microphone only'), findsNothing);
    },
  );

  testWidgets('Guardian capabilities fit a narrow phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const channel = MethodChannel('com.scamshield/native');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getCallGuardianStatus') {
            return {
              'available': true,
              'supported': true,
              'phoneStatePermissionGranted': true,
              'notificationsPermissionGranted': true,
              'enabled': false,
              'serviceRunning': false,
              'callState': 'IDLE',
              'serviceError': '',
              'callScreeningAvailable': true,
              'callScreeningEnabled': false,
              'incomingCallDetection': false,
              'outgoingCallDetection': false,
              'activeCallStateDetection': true,
              'audioCaptureAvailable': false,
              'audioPermissionGranted': false,
              'audioProtectionEnabled': false,
              'audioState': 'IDLE',
              'audioSource': '',
              'audioRoute': 'UNKNOWN',
              'audioReason': '',
              'audioChunksCreated': 0,
              'audioChunksDropped': 0,
            };
          }
          if (call.method == 'isNativeLayerAvailable') return true;
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardian'));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).last, const Offset(0, -850));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Device capabilities'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Device capabilities'));
    await tester.pumpAndSettle();

    expect(find.text('Outgoing calls'), findsOneWidget);
    expect(find.text('Active call state'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('enabling Guardian discloses scope and requests permissions', (
    tester,
  ) async {
    const channel = MethodChannel('com.scamshield/native');
    var permissionsGranted = false;
    var guardianEnabled = false;
    var permissionRequests = 0;
    var startRequests = 0;
    Map<String, Object> status() => {
      'available': true,
      'supported': true,
      'phoneStatePermissionGranted': permissionsGranted,
      'notificationsPermissionGranted': permissionsGranted,
      'enabled': guardianEnabled,
      'serviceRunning': guardianEnabled,
      'callState': 'IDLE',
      'serviceError': '',
      'callScreeningAvailable': true,
      'callScreeningEnabled': false,
      'incomingCallDetection': false,
      'outgoingCallDetection': false,
      'activeCallStateDetection': true,
      'audioCaptureAvailable': false,
      'audioPermissionGranted': false,
      'audioProtectionEnabled': false,
      'audioState': 'IDLE',
      'audioSource': '',
      'audioRoute': 'UNKNOWN',
      'audioReason': '',
      'audioChunksCreated': 0,
      'audioChunksDropped': 0,
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getCallGuardianStatus') return status();
          if (call.method == 'requestGuardianPermissions') {
            permissionRequests++;
            permissionsGranted = true;
            return status();
          }
          if (call.method == 'setGuardianEnabled') {
            startRequests++;
            guardianEnabled = call.arguments['enabled'] as bool;
            return status();
          }
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardian'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch).first);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(find.text('Enable Guardian?'), findsOneWidget);
    expect(
      find.textContaining(
        'Android shows a notification while Guardian is enabled.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(permissionRequests, 1);
    expect(startRequests, 1);
    expect(guardianEnabled, isTrue);
    expect(find.text('Guardian is on · Ready'), findsOneWidget);

    await tester.ensureVisible(find.byType(Switch).first);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    if (find.text('DISABLE').evaluate().isNotEmpty) {
      await tester.tap(find.text('DISABLE'));
      await tester.pumpAndSettle();
    }
    expect(startRequests, 2);
    expect(guardianEnabled, isFalse);
    expect(
      find.text('Guardian is off. Call activity is not monitored.'),
      findsOneWidget,
    );
  });

  testWidgets('Guardian stays off when Android permissions are denied', (
    tester,
  ) async {
    const channel = MethodChannel('com.scamshield/native');
    var startRequests = 0;
    final status = {
      'available': true,
      'supported': true,
      'phoneStatePermissionGranted': false,
      'notificationsPermissionGranted': false,
      'enabled': false,
      'serviceRunning': false,
      'callState': 'IDLE',
      'serviceError': '',
      'callScreeningAvailable': false,
      'callScreeningEnabled': false,
      'incomingCallDetection': false,
      'outgoingCallDetection': false,
      'activeCallStateDetection': false,
      'audioCaptureAvailable': false,
      'audioPermissionGranted': false,
      'audioProtectionEnabled': false,
      'audioState': 'IDLE',
      'audioSource': '',
      'audioRoute': 'UNKNOWN',
      'audioReason': '',
      'audioChunksCreated': 0,
      'audioChunksDropped': 0,
    };
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getCallGuardianStatus' ||
              call.method == 'requestGuardianPermissions') {
            return status;
          }
          if (call.method == 'setGuardianEnabled') startRequests++;
          return status;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guardian'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byType(Switch).first);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('CONTINUE'));
    await tester.pumpAndSettle();

    expect(startRequests, 0);
    expect(
      find.text('Guardian is off. Call activity is not monitored.'),
      findsOneWidget,
    );
    expect(find.text('APP SETTINGS'), findsOneWidget);
  });

  testWidgets('empty account gets truthful zero state and actions remain', (
    tester,
  ) async {
    await tester.pumpWidget(_home(includeHistory: false));
    await tester.pumpAndSettle();

    expect(find.text('0'), findsNWidgets(4));
    expect(find.text('No analyses yet.'), findsOneWidget);
    expect(find.text('Text'), findsOneWidget);
    expect(find.text('Image'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('Audio'), findsOneWidget);
  });

  testWidgets('top theme and profile menu actions work', (tester) async {
    var toggleCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          user: _user,
          analysisService: _analysisService(),
          onLogout: () async {},
          onSessionExpired: () async {},
          isDarkMode: false,
          onToggleTheme: () => toggleCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Switch to dark theme'));
    expect(toggleCount, 1);

    await tester.tap(find.byTooltip('Profile and settings'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('sam@example.com'), findsOneWidget);
  });

  testWidgets('call-protection settings opens the real Guardian controls', (
    tester,
  ) async {
    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Profile and settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Live Call Guardian').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open Guardian'));
    await tester.pumpAndSettle();

    expect(find.text('Enable Guardian'), findsOneWidget);
    expect(find.textContaining('M9.'), findsNothing);
    expect(find.textContaining('future floating'), findsNothing);
  });

  testWidgets('dashboard remains scrollable at a narrow screen width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_home());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Analyze Something'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Recent Analyses'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Recent Analyses'), findsOneWidget);
  });

  testWidgets('dashboard adapts to a large screen and larger text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: _home(isDarkMode: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Hello, Sam 👋'), findsOneWidget);
    expect(find.text('Recent Analyses'), findsOneWidget);
  });
}
