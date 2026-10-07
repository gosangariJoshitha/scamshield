import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/native/call_bridge.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/guardian_transcription_service.dart';

void main() {
  test(
    'does not upload device microphone chunks as caller transcription',
    () async {
      final requests = <http.Request>[];
      final api = ApiService(
        client: MockClient((request) async {
          requests.add(request);
          return http.Response('{}', 200);
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      );
      final chunks = StreamController<GuardianAudioChunk>();
      final service = GuardianTranscriptionService(
        audioChunks: chunks.stream,
        api: api,
        tokenProvider: () async => 'session-token',
      );
      final callStartedAt = DateTime.utc(2026, 10, 7);
      service.startSession('session-1', callStartedAt);
      await service.setEnabled(true);

      chunks.add(
        GuardianAudioChunk(
          chunkId: 'chunk-1',
          sessionId: 'session-1',
          sequenceNumber: 1,
          timestamp: callStartedAt.add(const Duration(seconds: 5)),
          durationMs: 5000,
          sampleRateHz: 16000,
          channels: 1,
          encoding: 'PCM_16BIT',
          source: 'DEVICE_MICROPHONE',
          audioData: Uint8List(160000),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(requests, isEmpty);
      expect(service.snapshot.state, 'TRANSCRIPTION_UNAVAILABLE');
      expect(service.snapshot.segments, isEmpty);

      await service.dispose();
      await chunks.close();
    },
  );

  test(
    'sends supported call audio and displays returned final segments',
    () async {
      final sessionId = '00000000-0000-4000-8000-000000000001';
      final chunkId = '00000000-0000-4000-8000-000000000002';
      final requestedPaths = <String>[];
      final api = ApiService(
        client: MockClient((request) async {
          requestedPaths.add(request.url.path);
          expect(request.headers['authorization'], startsWith('Bearer '));
          return http.Response('''
          {
            "language": "en",
            "segments": [
              {
                "session_id": "$sessionId",
                "segment_id": "$chunkId:0",
                "sequence": 1,
                "start_time": 0.4,
                "end_time": 1.8,
                "text": "Verified call transcript.",
                "is_final": true,
                "language": "en",
                "created_at": "2026-10-07T00:00:00Z"
              }
            ]
          }
          ''', 200);
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      );
      final chunks = StreamController<GuardianAudioChunk>();
      final service = GuardianTranscriptionService(
        audioChunks: chunks.stream,
        api: api,
        tokenProvider: () async => 'session-token',
      );
      final callStartedAt = DateTime.utc(2026, 10, 7);
      service.startSession(sessionId, callStartedAt);
      await service.setEnabled(true);
      chunks.add(
        GuardianAudioChunk(
          chunkId: chunkId,
          sessionId: sessionId,
          sequenceNumber: 1,
          timestamp: callStartedAt.add(const Duration(seconds: 5)),
          durationMs: 5000,
          sampleRateHz: 16000,
          channels: 1,
          encoding: 'PCM_16BIT',
          source: 'CALL_AUDIO',
          audioData: Uint8List(160000),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(requestedPaths, ['/api/guardian/transcription/chunk']);
      expect(service.snapshot.state, 'TRANSCRIPTION_READY');
      expect(service.snapshot.language, 'en');
      expect(service.snapshot.segments, hasLength(1));
      expect(
        service.snapshot.segments.single.text,
        'Verified call transcript.',
      );
      expect(service.snapshot.segments.single.isFinal, isTrue);

      await service.dispose();
      await chunks.close();
    },
  );

  test(
    'finalizes only after an in-flight chunk completes when disabled',
    () async {
      final sessionId = '00000000-0000-4000-8000-000000000011';
      final chunkId = '00000000-0000-4000-8000-000000000012';
      final chunkResponse = Completer<http.Response>();
      final chunkRequestStarted = Completer<void>();
      final requestedPaths = <String>[];
      final api = ApiService(
        client: MockClient((request) async {
          requestedPaths.add(request.url.path);
          if (request.url.path.endsWith('/chunk')) {
            chunkRequestStarted.complete();
            return chunkResponse.future;
          }
          return http.Response('{"status":"FINALIZED"}', 200);
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      );
      final chunks = StreamController<GuardianAudioChunk>();
      final service = GuardianTranscriptionService(
        audioChunks: chunks.stream,
        api: api,
        tokenProvider: () async => 'session-token',
      );
      final callStartedAt = DateTime.utc(2026, 10, 7);
      service.startSession(sessionId, callStartedAt);
      await service.setEnabled(true);
      chunks.add(
        GuardianAudioChunk(
          chunkId: chunkId,
          sessionId: sessionId,
          sequenceNumber: 1,
          timestamp: callStartedAt.add(const Duration(seconds: 5)),
          durationMs: 5000,
          sampleRateHz: 16000,
          channels: 1,
          encoding: 'PCM_16BIT',
          source: 'CALL_AUDIO',
          audioData: Uint8List(160000),
        ),
      );
      await chunkRequestStarted.future;
      final disabling = service.setEnabled(false);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(requestedPaths, ['/api/guardian/transcription/chunk']);
      chunkResponse.complete(
        http.Response('{"language":"en","segments":[]}', 200),
      );
      await disabling;

      expect(requestedPaths, [
        '/api/guardian/transcription/chunk',
        '/api/guardian/transcription/session/$sessionId/finalize',
      ]);
      expect(service.snapshot.state, 'AI_IDLE');
      expect(service.snapshot.segments, isEmpty);

      await service.dispose();
      await chunks.close();
    },
  );
}
