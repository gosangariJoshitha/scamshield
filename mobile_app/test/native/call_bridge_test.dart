import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scamshield_guardian/native/call_bridge.dart';

void main() {
  test('Guardian status requires explicit native capability values', () {
    final status = CallGuardianStatus.fromMap({
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
    });

    expect(status.callScreeningEnabled, isTrue);
    expect(status.incomingCallDetection, isTrue);
    expect(status.outgoingCallDetection, isTrue);
    expect(status.audioCaptureAvailable, isFalse);
    expect(status.audioState, 'IDLE');
    expect(status.audioChunksCreated, 0);
    expect(status.audioChunksDropped, 0);
  });

  test(
    'audio capability reports device-microphone limits and chunk bounds',
    () {
      final capability = AudioCapability.fromMap({
        'supported': true,
        'source': 'DEVICE_MICROPHONE',
        'permissionStatus': 'DENIED',
        'reason': 'Device microphone only.',
        'sampleRateHz': 16000,
        'channels': 1,
        'encoding': 'PCM_16BIT',
        'chunkDurationMs': 5000,
        'maxBufferedChunks': 2,
      });

      expect(capability.supported, isTrue);
      expect(capability.source, 'DEVICE_MICROPHONE');
      expect(capability.permissionStatus, 'DENIED');
      expect(capability.sampleRateHz, 16000);
      expect(capability.chunkDurationMs, 5000);
      expect(capability.maxBufferedChunks, 2);
    },
  );

  test('audio chunks preserve exact capture metadata and bytes', () {
    final chunk = GuardianAudioChunk.fromMap({
      'chunkId': 'chunk-1',
      'sessionId': 'session-1',
      'sequenceNumber': 3,
      'timestamp': 1770000000000,
      'durationMs': 5000,
      'sampleRateHz': 16000,
      'channels': 1,
      'encoding': 'PCM_16BIT',
      'source': 'DEVICE_MICROPHONE',
      'audioData': Uint8List.fromList([1, 2, 3, 4]),
    });

    expect(chunk.chunkId, 'chunk-1');
    expect(chunk.sessionId, 'session-1');
    expect(chunk.sequenceNumber, 3);
    expect(chunk.sampleRateHz, 16000);
    expect(chunk.audioData, Uint8List.fromList([1, 2, 3, 4]));
  });

  test('audio chunk parser rejects malformed metadata or audio bytes', () {
    expect(
      () => GuardianAudioChunk.fromMap({
        'chunkId': 'chunk-1',
        'sessionId': 'session-1',
      }),
      throwsA(isA<PlatformException>()),
    );
  });

  group('GuardianCallEvent', () {
    test('decodes normalized events without exposing caller identifiers', () {
      final event = GuardianCallEvent.fromMap({
        'event': 'CALL_ACTIVE',
        'sessionId': 'c02d61e7-bd84-4bb3-a4fb-0495bc60f28f',
        'direction': 'INCOMING',
        'state': 'ACTIVE',
        'timestamp': 1770000000000,
        'source': 'TELEPHONY_STATE',
      });

      expect(event.event, 'CALL_ACTIVE');
      expect(event.direction, 'INCOMING');
      expect(event.state, 'ACTIVE');
      expect(event.timestamp.millisecondsSinceEpoch, 1770000000000);
      expect(event.sessionId, hasLength(36));
    });

    test('rejects malformed native events instead of fabricating defaults', () {
      expect(
        () => GuardianCallEvent.fromMap({
          'event': 'CALL_RINGING',
          'sessionId': 'session',
        }),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}
