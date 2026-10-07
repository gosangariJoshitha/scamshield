import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/guardian_protection_models.dart';
import 'package:scamshield_guardian/native/call_bridge.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/guardian_protection_service.dart';

class FakeCallBridge extends CallBridge {
  FakeCallBridge({
    this.capabilitiesToReturn,
    this.endCallResponseToReturn,
    this.blockCallerResponseToReturn,
  });

  GuardianProtectionCapabilities? capabilitiesToReturn;
  Map<String, dynamic>? endCallResponseToReturn;
  Map<String, dynamic>? blockCallerResponseToReturn;

  final List<String> hapticInvocations = [];
  final List<String> endCallInvocations = [];
  final List<String> blockCallerInvocations = [];
  bool openBlockedSettingsCalled = false;

  @override
  Future<GuardianProtectionCapabilities> getProtectionCapabilities() async {
    return capabilitiesToReturn ??
        const GuardianProtectionCapabilities(
          canEndCall: GuardianCapabilityItem(supported: true, reason: 'Supported'),
          canBlockCaller: GuardianCapabilityItem(
            supported: false,
            reason: 'Third-party apps cannot block numbers directly',
            requiresPermission: true,
          ),
          canReport: GuardianCapabilityItem(supported: true, reason: 'Supported via backend'),
          canVibrate: GuardianCapabilityItem(supported: true, reason: 'Supported'),
          canVerifySafely: GuardianCapabilityItem(supported: true, reason: 'Supported'),
        );
  }

  @override
  Future<Map<String, dynamic>> requestEndCall({
    required String sessionId,
  }) async {
    endCallInvocations.add(sessionId);
    return endCallResponseToReturn ??
        {
          'success': true,
          'supported': true,
          'reason': 'Call ended successfully.',
        };
  }

  @override
  Future<Map<String, dynamic>> requestBlockCaller({
    required String sessionId,
    String? phoneNumber,
  }) async {
    blockCallerInvocations.add(sessionId);
    return blockCallerResponseToReturn ??
        {
          'success': false,
          'supported': false,
          'reason': 'Third-party apps cannot block numbers directly on Android.',
          'canOpenSettings': true,
        };
  }

  @override
  Future<void> openBlockedNumbersSettings() async {
    openBlockedSettingsCalled = true;
  }

  @override
  Future<void> triggerHapticAlert(String intensity) async {
    hapticInvocations.add(intensity);
  }
}

void main() {
  group('GuardianProtectionService', () {
    late FakeCallBridge fakeBridge;
    late ApiService fakeApi;
    late List<http.Request> httpRequests;
    late GuardianProtectionService service;

    setUp(() {
      fakeBridge = FakeCallBridge();
      httpRequests = [];
      fakeApi = ApiService(
        client: MockClient((request) async {
          httpRequests.add(request);
          if (request.url.path.contains('/community/reports')) {
            return http.Response(
              jsonEncode({
                'id': 101,
                'content': 'Suspicious scam call',
                'category': 'Vishing / Call Scam',
                'created_at': DateTime.now().toIso8601String(),
              }),
              201,
              headers: {'content-type': 'application/json'},
            );
          }
          return http.Response('{}', 200);
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      );
      service = GuardianProtectionService(
        callBridge: fakeBridge,
        api: fakeApi,
        tokenProvider: () async => 'test-jwt-token',
      );
    });

    tearDown(() {
      service.dispose();
    });

    test('initializes capabilities from native bridge', () async {
      await service.initialize();
      expect(service.capabilities.canEndCall.supported, isTrue);
      expect(service.capabilities.canBlockCaller.supported, isFalse);
      expect(service.capabilities.canBlockCaller.reason, contains('cannot block'));
      expect(service.capabilities.canVibrate.supported, isTrue);
    });

    test('refuses endCall if call is not active', () async {
      await service.initialize();
      final result = await service.executeEndCall(sessionId: 'session-123');
      expect(result.status, ProtectionActionStatus.failed);
      expect(result.message, contains('Call is no longer active'));
      expect(fakeBridge.endCallInvocations, isEmpty);
    });

    test('refuses endCall if session ID does not match active session', () async {
      await service.initialize();
      service.startSession('session-active');

      final result = await service.executeEndCall(sessionId: 'session-stale');
      expect(result.status, ProtectionActionStatus.failed);
      expect(result.message, contains('Call is no longer active'));
      expect(fakeBridge.endCallInvocations, isEmpty);
    });

    test('executes endCall when call and session are active and supported', () async {
      await service.initialize();
      service.startSession('session-active');

      final result = await service.executeEndCall(sessionId: 'session-active');
      expect(result.status, ProtectionActionStatus.success);
      expect(result.message, contains('Call ended'));
      expect(fakeBridge.endCallInvocations, contains('session-active'));
    });

    test('handles endCall failure honestly from native bridge', () async {
      fakeBridge.endCallResponseToReturn = {
        'success': false,
        'supported': true,
        'reason': 'Device requires default dialer role to terminate calls.',
      };
      await service.initialize();
      service.startSession('session-active');

      final result = await service.executeEndCall(sessionId: 'session-active');
      expect(result.status, ProtectionActionStatus.failed);
      expect(result.message, contains('default dialer'));
    });

    test('duplicate endCall request is rejected while already in progress', () async {
      await service.initialize();
      service.startSession('session-active');

      final firstFuture = service.executeEndCall(sessionId: 'session-active');
      final secondResult = await service.executeEndCall(sessionId: 'session-active');

      expect(secondResult.status, ProtectionActionStatus.inProgress);
      expect(secondResult.message, contains('already in progress'));

      await firstFuture;
    });

    test('executes blockCaller and reports honest native limitation', () async {
      await service.initialize();
      service.startSession('session-active');

      final result = await service.executeBlockCaller(
        sessionId: 'session-active',
        phoneNumber: '+1234567890',
      );
      expect(result.status, ProtectionActionStatus.unavailable);
      expect(result.message, contains('cannot block numbers directly'));
      expect(fakeBridge.blockCallerInvocations, contains('session-active'));
    });

    test('submits report to backend community reports API with auth token', () async {
      await service.initialize();
      service.startSession('session-active');

      final result = await service.submitReport(
        sessionId: 'session-active',
        category: 'Vishing / Call Scam',
        description: 'Caller claimed to be bank officer requesting OTP.',
      );

      expect(result.status, ProtectionActionStatus.success);
      expect(result.message, contains('Report submitted'));
      expect(httpRequests, hasLength(1));
      expect(httpRequests.first.url.path, '/api/community/reports');
      expect(httpRequests.first.headers['authorization'], 'Bearer test-jwt-token');

      final body = jsonDecode(httpRequests.first.body) as Map<String, dynamic>;
      expect(body['category'], 'Vishing / Call Scam');
      expect(body['description'], contains('Caller claimed to be bank'));
    });

    test('handles backend report failure gracefully', () async {
      fakeApi = ApiService(
        client: MockClient((request) async {
          return http.Response('{"detail": "Server error"}', 500);
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      );
      service = GuardianProtectionService(
        callBridge: fakeBridge,
        api: fakeApi,
        tokenProvider: () async => 'test-jwt-token',
      );

      await service.initialize();
      service.startSession('session-active');

      final result = await service.submitReport(
        sessionId: 'session-active',
        category: 'Vishing',
        description: 'Suspicious call',
      );

      expect(result.status, ProtectionActionStatus.failed);
      expect(result.message, contains('Report submission failed'));
    });

    test('triggers haptic alert on HIGH and CRITICAL risk escalation according to preferences', () async {
      await service.initialize();

      // LOW risk -> no haptic
      await service.onRiskEscalated('LOW');
      expect(fakeBridge.hapticInvocations, isEmpty);

      // MEDIUM risk -> no haptic
      await service.onRiskEscalated('MEDIUM');
      expect(fakeBridge.hapticInvocations, isEmpty);

      // HIGH risk -> short pulse
      await service.onRiskEscalated('HIGH');
      expect(fakeBridge.hapticInvocations, contains('HIGH'));

      // CRITICAL risk -> strong pulse
      await service.onRiskEscalated('CRITICAL');
      expect(fakeBridge.hapticInvocations, contains('CRITICAL'));
    });

    test('respects user preference disabling vibration', () async {
      await service.initialize();
      service.updateSettings(
        const GuardianProtectionSettings(
          highRiskVibrationEnabled: false,
          criticalRiskAlertsEnabled: false,
        ),
      );

      await service.onRiskEscalated('HIGH');
      await service.onRiskEscalated('CRITICAL');
      expect(fakeBridge.hapticInvocations, isEmpty);
    });

    test('invalidates actions when session ends', () async {
      await service.initialize();
      service.startSession('session-1');
      service.endSession('session-1');

      final result = await service.executeEndCall(sessionId: 'session-1');
      expect(result.status, ProtectionActionStatus.failed);
      expect(result.message, contains('Call is no longer active'));
    });
  });
}
