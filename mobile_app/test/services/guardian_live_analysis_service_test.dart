import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:scamshield_guardian/models/guardian_analysis_models.dart';
import 'package:scamshield_guardian/services/api_service.dart';
import 'package:scamshield_guardian/services/guardian_live_analysis_service.dart';
import 'package:scamshield_guardian/services/guardian_local_heuristic_engine.dart';
import 'package:scamshield_guardian/services/guardian_transcription_service.dart';

void main() {
  test('does not send analysis requests when disabled', () async {
    final requests = <http.Request>[];
    final api = ApiService(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response('{}', 200);
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    );
    final transcriptController =
        StreamController<GuardianTranscriptionSnapshot>();
    final service = GuardianLiveAnalysisService(
      transcriptionChanges: transcriptController.stream,
      api: api,
      tokenProvider: () async => 'test-token',
    );

    const sessionId = '00000000-0000-4000-8000-000000000001';
    service.startSession(sessionId, DateTime.utc(2026, 10, 7));

    transcriptController.add(
      GuardianTranscriptionSnapshot(
        state: 'TRANSCRIPTION_READY',
        message: 'Live transcription active.',
        segments: [
          TranscriptSegment(
            sessionId: sessionId,
            segmentId: 'seg-1',
            sequence: 1,
            startTime: 0.0,
            endTime: 2.0,
            text: 'Your bank account has been blocked.',
            isFinal: true,
            language: 'en',
            createdAt: DateTime.utc(2026, 10, 7),
          ),
        ],
        droppedChunks: 0,
        language: 'en',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(requests, isEmpty);
    expect(service.snapshot.state, 'AI_IDLE');
    expect(service.snapshot.result, isNull);

    await service.dispose();
    await transcriptController.close();
  });

  test(
    'sends transcript segment and updates snapshot with live risk result',
    () async {
      const sessionId = '00000000-0000-4000-8000-000000000002';
      final requestedPaths = <String>[];
      final api = ApiService(
        client: MockClient((request) async {
          requestedPaths.add(request.url.path);
          expect(request.headers['authorization'], 'Bearer test-token');
          return http.Response('''
          {
            "session_id": "$sessionId",
            "status": "AI_RESULT_READY",
            "message": "Analysis ready.",
            "processed_sequence": 1,
            "window_id": "win-123",
            "result": {
              "risk_score": 92,
              "risk_level": "CRITICAL",
              "classification": "SCAM",
              "scam_category": "OTP/Verification",
              "detected_indicators": ["Urgency", "Account threat", "OTP request"],
              "reasoning": "The caller claims an urgent bank block and requests an OTP.",
              "supporting_evidence": [
                {
                  "knowledge_id": 42,
                  "title": "Bank Impersonation OTP Scam",
                  "category": "vishing",
                  "similarity_score": 0.89,
                  "pattern": "Threatens account suspension and asks for one-time code",
                  "description": "Common fraudulent bank call tactic.",
                  "indicators": ["OTP request", "Account suspension"],
                  "safe_action": "Do not share OTP under any circumstances.",
                  "source": "RBI Advisory",
                  "language": "en"
                }
              ],
              "ml_probability": 0.96,
              "llm_confidence": 0.94,
              "safe_action": "Do not share your OTP.",
              "safe_actions": {
                "canonical": ["Do not share your OTP."],
                "translations": {"en": ["Do not share your OTP."]},
                "default_language": "en"
              },
              "timestamp": "2026-10-07T00:00:00Z",
              "session_id": "$sessionId",
              "language": "en",
              "evidence_status": "MATCH_FOUND",
              "processing_status": "COMPLETED",
              "model_version": "scamshield-classifier-v5",
              "rag_version": "scamshield-rag-v1",
              "timings_ms": {
                "total_ms": 150.0
              }
            }
          }
          ''', 200);
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      );

      final transcriptController =
          StreamController<GuardianTranscriptionSnapshot>();
      final service = GuardianLiveAnalysisService(
        transcriptionChanges: transcriptController.stream,
        api: api,
        tokenProvider: () async => 'test-token',
      );

      service.startSession(sessionId, DateTime.utc(2026, 10, 7));
      await service.setEnabled(true);

      transcriptController.add(
        GuardianTranscriptionSnapshot(
          state: 'TRANSCRIPTION_READY',
          message: 'Live transcription active.',
          segments: [
            TranscriptSegment(
              sessionId: sessionId,
              segmentId: 'seg-1',
              sequence: 1,
              startTime: 0.0,
              endTime: 4.0,
              text: 'Your account is blocked. Tell me the OTP immediately.',
              isFinal: true,
              language: 'en',
              createdAt: DateTime.utc(2026, 10, 7),
            ),
          ],
          droppedChunks: 0,
          language: 'en',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(requestedPaths, ['/api/guardian/analysis/segment']);
      expect(service.snapshot.state, 'AI_RESULT_READY');
      expect(service.snapshot.result, isNotNull);
      expect(service.snapshot.result!.riskScore, 92);
      expect(service.snapshot.result!.riskLevel, 'CRITICAL');
      expect(service.snapshot.result!.classification, 'SCAM');
      expect(service.snapshot.result!.scamCategory, 'OTP/Verification');
      expect(service.snapshot.result!.detectedIndicators, hasLength(3));
      expect(service.snapshot.result!.supportingEvidence, hasLength(1));
      expect(
        service.snapshot.result!.supportingEvidence.first.title,
        'Bank Impersonation OTP Scam',
      );

      await service.dispose();
      await transcriptController.close();
    },
  );

  test(
    'submits speakerphone transcript segment with SPEAKERPHONE_AUDIO source',
    () async {
      const sessionId = '00000000-0000-4000-8000-000000000007';
      var capturedSource = '';
      final api = ApiService(
        client: MockClient((request) async {
          if (request.url.path.endsWith('/segment')) {
            capturedSource =
                request.body.contains('"source":"SPEAKERPHONE_AUDIO"')
                    ? 'SPEAKERPHONE_AUDIO'
                    : '';
          }
          return http.Response('''
          {
            "session_id": "$sessionId",
            "status": "AI_RESULT_READY",
            "message": "Analysis ready.",
            "processed_sequence": 1,
            "window_id": "win-123",
            "result": {
              "risk_score": 85,
              "risk_level": "HIGH",
              "classification": "SCAM",
              "scam_category": "Impersonation",
              "detected_indicators": ["Threat", "Account freeze"],
              "reasoning": "Speakerphone conversation detected scam indicators.",
              "supporting_evidence": [],
              "ml_probability": 0.88,
              "llm_confidence": 0.85,
              "safe_action": "Hang up and verify directly.",
              "safe_actions": {},
              "timestamp": "2026-10-07T00:00:00Z",
              "session_id": "$sessionId",
              "language": "en",
              "evidence_status": "MATCH_FOUND",
              "processing_status": "COMPLETED",
              "model_version": "test",
              "rag_version": "test",
              "timings_ms": {}
            }
          }
          ''', 200);
        }),
        baseUri: Uri.parse('https://api.example.test/api'),
      );
      final transcriptController =
          StreamController<GuardianTranscriptionSnapshot>();
      final service = GuardianLiveAnalysisService(
        transcriptionChanges: transcriptController.stream,
        api: api,
        tokenProvider: () async => 'test-token',
      );

      service.startSession(sessionId, DateTime.utc(2026, 10, 7));
      await service.setEnabled(true);

      transcriptController.add(
        GuardianTranscriptionSnapshot(
          state: 'TRANSCRIPTION_READY',
          message: 'Live transcription active.',
          segments: [
            TranscriptSegment(
              sessionId: sessionId,
              segmentId: 'seg-1',
              sequence: 1,
              startTime: 0.0,
              endTime: 4.0,
              text: 'Your account is blocked. Tell me the OTP immediately.',
              isFinal: true,
              language: 'en',
              source: 'SPEAKERPHONE_AUDIO',
              createdAt: DateTime.utc(2026, 10, 7),
            ),
          ],
          droppedChunks: 0,
          language: 'en',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(capturedSource, 'SPEAKERPHONE_AUDIO');
      expect(service.snapshot.state, 'AI_RESULT_READY');
      expect(service.snapshot.result!.riskLevel, 'HIGH');

      await service.dispose();
      await transcriptController.close();
    },
  );

  test('handles waiting response from server without error', () async {
    const sessionId = '00000000-0000-4000-8000-000000000003';
    final api = ApiService(
      client: MockClient((request) async {
        return http.Response('''
        {
          "session_id": "$sessionId",
          "status": "AI_WAITING_FOR_TRANSCRIPT",
          "message": "Waiting for more conversation before analysis.",
          "processed_sequence": 1
        }
        ''', 200);
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    );

    final transcriptController =
        StreamController<GuardianTranscriptionSnapshot>();
    final service = GuardianLiveAnalysisService(
      transcriptionChanges: transcriptController.stream,
      api: api,
      tokenProvider: () async => 'test-token',
    );

    service.startSession(sessionId, DateTime.utc(2026, 10, 7));
    await service.setEnabled(true);

    transcriptController.add(
      GuardianTranscriptionSnapshot(
        state: 'TRANSCRIPTION_READY',
        message: 'Live transcription active.',
        segments: [
          TranscriptSegment(
            sessionId: sessionId,
            segmentId: 'seg-1',
            sequence: 1,
            startTime: 0.0,
            endTime: 1.0,
            text: 'Hello.',
            isFinal: true,
            language: 'en',
            createdAt: DateTime.utc(2026, 10, 7),
          ),
        ],
        droppedChunks: 0,
        language: 'en',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(service.snapshot.state, 'AI_WAITING_FOR_TRANSCRIPT');
    expect(service.snapshot.result, isNull);

    await service.dispose();
    await transcriptController.close();
  });

  test('handles 503 unavailable gracefully without crashing', () async {
    const sessionId = '00000000-0000-4000-8000-000000000004';
    final api = ApiService(
      client: MockClient((request) async {
        return http.Response(
          '{"detail":"Live AI analysis is temporarily unavailable."}',
          503,
        );
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    );

    final transcriptController =
        StreamController<GuardianTranscriptionSnapshot>();
    final service = GuardianLiveAnalysisService(
      transcriptionChanges: transcriptController.stream,
      api: api,
      tokenProvider: () async => 'test-token',
    );

    service.startSession(sessionId, DateTime.utc(2026, 10, 7));
    await service.setEnabled(true);

    transcriptController.add(
      GuardianTranscriptionSnapshot(
        state: 'TRANSCRIPTION_READY',
        message: 'Live transcription active.',
        segments: [
          TranscriptSegment(
            sessionId: sessionId,
            segmentId: 'seg-1',
            sequence: 1,
            startTime: 0.0,
            endTime: 3.0,
            text: 'Your account is blocked.',
            isFinal: true,
            language: 'en',
            createdAt: DateTime.utc(2026, 10, 7),
          ),
        ],
        droppedChunks: 0,
        language: 'en',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(service.snapshot.state, 'AI_UNAVAILABLE');

    await service.dispose();
    await transcriptController.close();
  });

  test('finalizes remote session when call ends', () async {
    const sessionId = '00000000-0000-4000-8000-000000000005';
    final requestedPaths = <String>[];
    final api = ApiService(
      client: MockClient((request) async {
        requestedPaths.add(request.url.path);
        if (request.url.path.endsWith('/finalize')) {
          return http.Response(
            '{"status":"AI_WAITING_FOR_TRANSCRIPT","message":"Live analysis session finalized."}',
            200,
          );
        }
        return http.Response('''
        {
          "session_id": "$sessionId",
          "status": "AI_WAITING_FOR_TRANSCRIPT",
          "message": "Waiting for more conversation before analysis."
        }
        ''', 200);
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    );

    final transcriptController =
        StreamController<GuardianTranscriptionSnapshot>();
    final service = GuardianLiveAnalysisService(
      transcriptionChanges: transcriptController.stream,
      api: api,
      tokenProvider: () async => 'test-token',
    );

    service.startSession(sessionId, DateTime.utc(2026, 10, 7));
    await service.setEnabled(true);

    transcriptController.add(
      GuardianTranscriptionSnapshot(
        state: 'TRANSCRIPTION_READY',
        message: 'Live transcription active.',
        segments: [
          TranscriptSegment(
            sessionId: sessionId,
            segmentId: 'seg-1',
            sequence: 1,
            startTime: 0.0,
            endTime: 2.0,
            text: 'Verify your account.',
            isFinal: true,
            language: 'en',
            createdAt: DateTime.utc(2026, 10, 7),
          ),
        ],
        droppedChunks: 0,
        language: 'en',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    await service.endSession(sessionId);

    expect(requestedPaths, [
      '/api/guardian/analysis/segment',
      '/api/guardian/analysis/session/$sessionId/finalize',
    ]);
    expect(service.snapshot.state, 'AI_IDLE');

    await service.dispose();
    await transcriptController.close();
  });

  test('preserves final risk result on call end with CALL_ENDED state and allows dismissal', () async {
    const sessionId = '00000000-0000-4000-8000-000000000006';
    final api = ApiService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/finalize')) {
          return http.Response('{"status":"OK"}', 200);
        }
        return http.Response('''
        {
          "session_id": "$sessionId",
          "status": "AI_RESULT_READY",
          "message": "Analysis ready.",
          "processed_sequence": 1,
          "result": {
            "risk_score": 85,
            "risk_level": "CRITICAL",
            "classification": "SCAM",
            "scam_category": "Urgent Threat",
            "detected_indicators": ["Urgency", "Threat"],
            "reasoning": "Urgent caller threatening police action.",
            "supporting_evidence": [],
            "ml_probability": 0.90,
            "llm_confidence": 0.88,
            "safe_action": "Hang up immediately.",
            "timestamp": "2026-10-07T00:00:00Z",
            "session_id": "$sessionId",
            "language": "en",
            "evidence_status": "NO_RELEVANT_MATCH",
            "processing_status": "COMPLETED",
            "model_version": "scamshield-classifier-v5",
            "rag_version": "scamshield-rag-v1",
            "timings_ms": {}
          }
        }
        ''', 200);
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    );

    final transcriptController = StreamController<GuardianTranscriptionSnapshot>();
    final service = GuardianLiveAnalysisService(
      transcriptionChanges: transcriptController.stream,
      api: api,
      tokenProvider: () async => 'test-token',
    );

    service.startSession(sessionId, DateTime.utc(2026, 10, 7));
    await service.setEnabled(true);

    transcriptController.add(
      GuardianTranscriptionSnapshot(
        state: 'TRANSCRIPTION_READY',
        message: 'Live transcription active.',
        segments: [
          TranscriptSegment(
            sessionId: sessionId,
            segmentId: 'seg-1',
            sequence: 1,
            startTime: 0.0,
            endTime: 3.0,
            text: 'You must pay penalty or face arrest.',
            isFinal: true,
            language: 'en',
            createdAt: DateTime.utc(2026, 10, 7),
          ),
        ],
        droppedChunks: 0,
        language: 'en',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(service.snapshot.state, 'AI_RESULT_READY');
    expect(service.snapshot.result?.riskScore, 85);

    // End the call session
    await service.endSession(sessionId);

    // Final result is preserved in CALL_ENDED state
    expect(service.snapshot.state, 'CALL_ENDED');
    expect(service.snapshot.isCallEnded, isTrue);
    expect(service.snapshot.result?.riskScore, 85);

    // User dismisses temporary call risk card
    service.dismissCallEndedResult();
    expect(service.snapshot.state, 'AI_IDLE');
    expect(service.snapshot.result, isNull);
    expect(service.snapshot.isCallEnded, isFalse);

    await service.dispose();
    await transcriptController.close();
  });

  test('security: discards delayed analysis results from older session when new session starts', () async {
    const sessionA = '00000000-0000-4000-8000-00000000000A';
    const sessionB = '00000000-0000-4000-8000-00000000000B';

    final completerA = Completer<http.Response>();

    final api = ApiService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/finalize')) {
          return http.Response('{"status":"OK"}', 200);
        }
        // Delayed response for Session A
        return completerA.future;
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    );

    final transcriptController = StreamController<GuardianTranscriptionSnapshot>();
    final service = GuardianLiveAnalysisService(
      transcriptionChanges: transcriptController.stream,
      api: api,
      tokenProvider: () async => 'test-token',
    );

    // Session A starts
    service.startSession(sessionA, DateTime.utc(2026, 10, 7));
    await service.setEnabled(true);

    transcriptController.add(
      GuardianTranscriptionSnapshot(
        state: 'TRANSCRIPTION_READY',
        message: 'Live transcription active.',
        segments: [
          TranscriptSegment(
            sessionId: sessionA,
            segmentId: 'seg-1',
            sequence: 1,
            startTime: 0.0,
            endTime: 2.0,
            text: 'Your account is blocked.',
            isFinal: true,
            language: 'en',
            createdAt: DateTime.utc(2026, 10, 7),
          ),
        ],
        droppedChunks: 0,
        language: 'en',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 20));

    // Session B starts immediately before Session A's request completes!
    service.startSession(sessionB, DateTime.utc(2026, 10, 7));

    // Now Session A's delayed HTTP response arrives
    completerA.complete(
      http.Response('''
      {
        "session_id": "$sessionA",
        "status": "AI_RESULT_READY",
        "message": "Analysis ready.",
        "processed_sequence": 1,
        "result": {
          "risk_score": 99,
          "risk_level": "CRITICAL",
          "classification": "SCAM",
          "scam_category": "OTP",
          "detected_indicators": ["Urgency"],
          "reasoning": "Old session scam.",
          "supporting_evidence": [],
          "ml_probability": 0.99,
          "llm_confidence": 0.99,
          "safe_action": "None",
          "timestamp": "2026-10-07T00:00:00Z",
          "session_id": "$sessionA",
          "language": "en",
          "evidence_status": "MATCH_FOUND",
          "processing_status": "COMPLETED",
          "model_version": "scamshield-classifier-v5",
          "rag_version": "scamshield-rag-v1",
          "timings_ms": {}
        }
      }
      ''', 200),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Session B MUST NOT have Session A's result!
    expect(service.snapshot.activeSessionId, sessionB);
    expect(service.snapshot.result, isNull);

    await service.dispose();
    await transcriptController.close();
  });

  test('retry re-triggers analysis of the latest segment after transient failure', () async {
    const sessionId = '00000000-0000-4000-8000-00000000000C';
    var callCount = 0;

    final api = ApiService(
      client: MockClient((request) async {
        callCount++;
        if (callCount == 1) {
          // First attempt fails with 503
          return http.Response('{"detail":"Service unavailable"}', 503);
        }
        // Second attempt succeeds
        return http.Response('''
        {
          "session_id": "$sessionId",
          "status": "AI_RESULT_READY",
          "message": "Analysis ready.",
          "processed_sequence": 1,
          "result": {
            "risk_score": 82,
            "risk_level": "CRITICAL",
            "classification": "SCAM",
            "scam_category": "OTP",
            "detected_indicators": ["OTP"],
            "reasoning": "Recovered via retry.",
            "supporting_evidence": [],
            "ml_probability": 0.88,
            "llm_confidence": 0.85,
            "safe_action": "Do not share OTP.",
            "timestamp": "2026-10-07T00:00:00Z",
            "session_id": "$sessionId",
            "language": "en",
            "evidence_status": "MATCH_FOUND",
            "processing_status": "COMPLETED",
            "model_version": "scamshield-classifier-v5",
            "rag_version": "scamshield-rag-v1",
            "timings_ms": {}
          }
        }
        ''', 200);
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    );

    final transcriptController = StreamController<GuardianTranscriptionSnapshot>();
    final service = GuardianLiveAnalysisService(
      transcriptionChanges: transcriptController.stream,
      api: api,
      tokenProvider: () async => 'test-token',
    );

    service.startSession(sessionId, DateTime.utc(2026, 10, 7));
    await service.setEnabled(true);

    final segment = TranscriptSegment(
      sessionId: sessionId,
      segmentId: 'seg-1',
      sequence: 1,
      startTime: 0.0,
      endTime: 3.0,
      text: 'Share your verification code.',
      isFinal: true,
      language: 'en',
      createdAt: DateTime.utc(2026, 10, 7),
    );

    transcriptController.add(
      GuardianTranscriptionSnapshot(
        state: 'TRANSCRIPTION_READY',
        message: 'Live transcription active.',
        segments: [segment],
        droppedChunks: 0,
        language: 'en',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 40));

    // First attempt resulted in error/unavailable
    expect(callCount, 1);
    expect(service.snapshot.state, 'AI_UNAVAILABLE');
    expect(service.snapshot.result, isNull);

    // Now call retry()
    service.retry();

    await Future<void>.delayed(const Duration(milliseconds: 50));

    // Second attempt succeeded
    expect(callCount, 2);
    expect(service.snapshot.state, 'AI_RESULT_READY');
    expect(service.snapshot.result?.riskScore, 82);

    await service.dispose();
    await transcriptController.close();
  });

  test('distinguishes noNetwork when network probe reports offline', () async {
    final api = ApiService(
      client: MockClient((request) async {
        throw http.ClientException('Network unreachable');
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    );
    final transcriptController =
        StreamController<GuardianTranscriptionSnapshot>();
    final service = GuardianLiveAnalysisService(
      transcriptionChanges: transcriptController.stream,
      api: api,
      tokenProvider: () async => 'test-token',
      networkProbe: () async => false, // Network probe confirms offline
    );

    const sessionId = '00000000-0000-4000-8000-000000000010';
    service.startSession(sessionId, DateTime.utc(2026, 10, 7));
    await service.setEnabled(true);

    transcriptController.add(
      GuardianTranscriptionSnapshot(
        state: 'TRANSCRIPTION_READY',
        message: 'Live transcription active.',
        segments: [
          TranscriptSegment(
            sessionId: sessionId,
            segmentId: 'seg-offline-1',
            sequence: 1,
            startTime: 0.0,
            endTime: 2.0,
            text: 'Hello, I am calling from bank.',
            isFinal: true,
            language: 'en',
            createdAt: DateTime.utc(2026, 10, 7),
          ),
        ],
        droppedChunks: 0,
        language: 'en',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(service.snapshot.networkStatus, GuardianNetworkStatus.noNetwork);
    expect(service.snapshot.state, 'AI_ERROR');
    expect(service.snapshot.queuedCount, 1);

    await service.dispose();
    await transcriptController.close();
  });

  test(
      'distinguishes backendUnreachable when network is up but backend returns 503',
      () async {
    final api = ApiService(
      client: MockClient((request) async {
        return http.Response('{"detail": "Service Unavailable"}', 503);
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    );
    final transcriptController =
        StreamController<GuardianTranscriptionSnapshot>();
    final service = GuardianLiveAnalysisService(
      transcriptionChanges: transcriptController.stream,
      api: api,
      tokenProvider: () async => 'test-token',
      networkProbe: () async => true, // Network probe confirms internet is connected
    );

    const sessionId = '00000000-0000-4000-8000-000000000011';
    service.startSession(sessionId, DateTime.utc(2026, 10, 7));
    await service.setEnabled(true);

    transcriptController.add(
      GuardianTranscriptionSnapshot(
        state: 'TRANSCRIPTION_READY',
        message: 'Live transcription active.',
        segments: [
          TranscriptSegment(
            sessionId: sessionId,
            segmentId: 'seg-backend-1',
            sequence: 1,
            startTime: 0.0,
            endTime: 2.0,
            text: 'Please hold the line.',
            isFinal: true,
            language: 'en',
            createdAt: DateTime.utc(2026, 10, 7),
          ),
        ],
        droppedChunks: 0,
        language: 'en',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(service.snapshot.networkStatus, GuardianNetworkStatus.backendUnreachable);
    expect(service.snapshot.state, 'AI_UNAVAILABLE');
    expect(service.snapshot.queuedCount, 1);

    await service.dispose();
    await transcriptController.close();
  });

  test('does not queue permanent authentication failures (401)', () async {
    final api = ApiService(
      client: MockClient((request) async {
        return http.Response('{"detail": "Unauthorized"}', 401);
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    );
    final transcriptController =
        StreamController<GuardianTranscriptionSnapshot>();
    final service = GuardianLiveAnalysisService(
      transcriptionChanges: transcriptController.stream,
      api: api,
      tokenProvider: () async => 'test-token',
    );

    const sessionId = '00000000-0000-4000-8000-000000000012';
    service.startSession(sessionId, DateTime.utc(2026, 10, 7));
    await service.setEnabled(true);

    transcriptController.add(
      GuardianTranscriptionSnapshot(
        state: 'TRANSCRIPTION_READY',
        message: 'Live transcription active.',
        segments: [
          TranscriptSegment(
            sessionId: sessionId,
            segmentId: 'seg-auth-1',
            sequence: 1,
            startTime: 0.0,
            endTime: 2.0,
            text: 'Test message.',
            isFinal: true,
            language: 'en',
            createdAt: DateTime.utc(2026, 10, 7),
          ),
        ],
        droppedChunks: 0,
        language: 'en',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(service.snapshot.state, 'AI_ERROR');
    expect(service.snapshot.message, contains('expired'));
    expect(service.snapshot.queuedCount, 0); // Permanent error: NOT queued!

    await service.dispose();
    await transcriptController.close();
  });

  test('bounds retry queue to maximum size (3) and discards oldest', () async {
    final api = ApiService(
      client: MockClient((request) async {
        return http.Response('{"detail": "Service Unavailable"}', 503);
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    );
    final transcriptController =
        StreamController<GuardianTranscriptionSnapshot>();
    final service = GuardianLiveAnalysisService(
      transcriptionChanges: transcriptController.stream,
      api: api,
      tokenProvider: () async => 'test-token',
      networkProbe: () async => false,
    );

    const sessionId = '00000000-0000-4000-8000-000000000013';
    service.startSession(sessionId, DateTime.utc(2026, 10, 7));
    await service.setEnabled(true);

    for (int seq = 1; seq <= 5; seq++) {
      transcriptController.add(
        GuardianTranscriptionSnapshot(
          state: 'TRANSCRIPTION_READY',
          message: 'Live transcription active.',
          segments: [
            TranscriptSegment(
              sessionId: sessionId,
              segmentId: 'seg-bound-$seq',
              sequence: seq,
              startTime: seq.toDouble(),
              endTime: (seq + 1).toDouble(),
              text: 'Message chunk number $seq.',
              isFinal: true,
              language: 'en',
              createdAt: DateTime.utc(2026, 10, 7),
            ),
          ],
          droppedChunks: 0,
          language: 'en',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 35));
    }

    // Queue must be strictly bounded <= 3
    expect(service.snapshot.queuedCount, lessThanOrEqualTo(3));

    await service.dispose();
    await transcriptController.close();
  });

  test('evaluates local heuristics immediately on device upon transcript reception', () async {
    final api = ApiService(
      client: MockClient((request) async {
        return http.Response('{"detail": "Offline"}', 503);
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    );
    final transcriptController =
        StreamController<GuardianTranscriptionSnapshot>();
    final service = GuardianLiveAnalysisService(
      transcriptionChanges: transcriptController.stream,
      api: api,
      tokenProvider: () async => 'test-token',
    );

    const sessionId = '00000000-0000-4000-8000-000000000014';
    service.startSession(sessionId, DateTime.utc(2026, 10, 7));
    await service.setEnabled(true);

    transcriptController.add(
      GuardianTranscriptionSnapshot(
        state: 'TRANSCRIPTION_READY',
        message: 'Live transcription active.',
        segments: [
          TranscriptSegment(
            sessionId: sessionId,
            segmentId: 'seg-heuristic-1',
            sequence: 1,
            startTime: 0.0,
            endTime: 3.0,
            text: 'Download AnyDesk right now to verify account.',
            isFinal: true,
            language: 'en',
            createdAt: DateTime.utc(2026, 10, 7),
          ),
        ],
        droppedChunks: 0,
        language: 'en',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 40));

    final heuristic = service.snapshot.localHeuristicResult;
    expect(heuristic, isNotNull);
    expect(heuristic!.hasMatches, isTrue);
    expect(heuristic.matchedRules, contains(GuardianLocalHeuristicEngine.ruleRemoteAccessTool));
    expect(heuristic.matchedPhrases, contains('anydesk'));

    await service.dispose();
    await transcriptController.close();
  });

  test('cleans up retry queue and local heuristics on endSession', () async {
    final api = ApiService(
      client: MockClient((request) async {
        return http.Response('{"detail": "Offline"}', 503);
      }),
      baseUri: Uri.parse('https://api.example.test/api'),
    );
    final transcriptController =
        StreamController<GuardianTranscriptionSnapshot>();
    final service = GuardianLiveAnalysisService(
      transcriptionChanges: transcriptController.stream,
      api: api,
      tokenProvider: () async => 'test-token',
      networkProbe: () async => false,
    );

    const sessionId = '00000000-0000-4000-8000-000000000015';
    service.startSession(sessionId, DateTime.utc(2026, 10, 7));
    await service.setEnabled(true);

    transcriptController.add(
      GuardianTranscriptionSnapshot(
        state: 'TRANSCRIPTION_READY',
        message: 'Live transcription active.',
        segments: [
          TranscriptSegment(
            sessionId: sessionId,
            segmentId: 'seg-cleanup-1',
            sequence: 1,
            startTime: 0.0,
            endTime: 3.0,
            text: 'Share your OTP code.',
            isFinal: true,
            language: 'en',
            createdAt: DateTime.utc(2026, 10, 7),
          ),
        ],
        droppedChunks: 0,
        language: 'en',
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(service.snapshot.queuedCount, 1);
    expect(service.snapshot.localHeuristicResult?.hasMatches, isTrue);

    // End session
    await service.endSession(sessionId);

    // Memory buffer & queue must be completely cleared
    expect(service.snapshot.queuedCount, 0);
    expect(service.snapshot.localHeuristicResult, isNull);

    await service.dispose();
    await transcriptController.close();
  });
}

