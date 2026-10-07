import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;

import '../native/call_bridge.dart';
import 'api_service.dart';

class TranscriptSegment {
  const TranscriptSegment({
    required this.sessionId,
    required this.segmentId,
    required this.sequence,
    required this.startTime,
    required this.endTime,
    required this.text,
    required this.isFinal,
    required this.language,
    required this.createdAt,
  });

  final String sessionId;
  final String segmentId;
  final int sequence;
  final double startTime;
  final double endTime;
  final String text;
  final bool isFinal;
  final String language;
  final DateTime createdAt;

  factory TranscriptSegment.fromJson(Map<String, dynamic> json) {
    final sessionId = json['session_id'];
    final segmentId = json['segment_id'];
    final sequence = json['sequence'];
    final startTime = json['start_time'];
    final endTime = json['end_time'];
    final text = json['text'];
    final isFinal = json['is_final'];
    final language = json['language'];
    final createdAt = json['created_at'];
    if (sessionId is! String ||
        segmentId is! String ||
        sequence is! int ||
        startTime is! num ||
        endTime is! num ||
        text is! String ||
        isFinal is! bool ||
        language is! String ||
        createdAt is! String) {
      throw const FormatException('Transcription response was malformed.');
    }
    final parsedCreatedAt = DateTime.tryParse(createdAt);
    if (parsedCreatedAt == null) {
      throw const FormatException(
        'Transcription response had an invalid date.',
      );
    }
    return TranscriptSegment(
      sessionId: sessionId,
      segmentId: segmentId,
      sequence: sequence,
      startTime: startTime.toDouble(),
      endTime: endTime.toDouble(),
      text: text,
      isFinal: isFinal,
      language: language,
      createdAt: parsedCreatedAt,
    );
  }
}

class GuardianTranscriptionSnapshot {
  const GuardianTranscriptionSnapshot({
    required this.state,
    required this.message,
    required this.segments,
    required this.droppedChunks,
    required this.language,
  });

  final String state;
  final String message;
  final List<TranscriptSegment> segments;
  final int droppedChunks;
  final String? language;
}

class GuardianTranscriptionService {
  GuardianTranscriptionService({
    required Stream<GuardianAudioChunk> audioChunks,
    required this.api,
    required this.tokenProvider,
  }) {
    _chunkSubscription = audioChunks.listen(
      _acceptChunk,
      onError: (Object error, StackTrace stackTrace) {
        _setState(
          'TRANSCRIPTION_ERROR',
          'Transcription is temporarily unavailable.',
        );
      },
    );
  }

  static const _maxQueuedChunks = 2;
  static const _maxRecentChunkIds = 256;
  static const _maxTranscriptSegments = 60;

  final ApiService api;
  final Future<String?> Function() tokenProvider;
  final Queue<GuardianAudioChunk> _queue = Queue<GuardianAudioChunk>();
  final Queue<TranscriptSegment> _segments = Queue<TranscriptSegment>();
  final Queue<String> _recentChunkIds = Queue<String>();
  final Queue<String> _recentSegmentIds = Queue<String>();
  final StreamController<GuardianTranscriptionSnapshot> _changes =
      StreamController<GuardianTranscriptionSnapshot>.broadcast();
  late final StreamSubscription<GuardianAudioChunk> _chunkSubscription;

  String _state = 'TRANSCRIPTION_UNAVAILABLE';
  String _message =
      "Live transcription isn't available for this call on this device.";
  String? _sessionId;
  String? _language;
  int? _callStartedAtMs;
  int _droppedChunks = 0;
  int _lastSequence = 0;
  bool _enabled = false;
  bool _callActive = false;
  bool _processing = false;
  bool _hasRemoteChunks = false;
  bool _disposed = false;

  GuardianTranscriptionSnapshot get snapshot => GuardianTranscriptionSnapshot(
    state: _state,
    message: _message,
    segments: List.unmodifiable(_segments),
    droppedChunks: _droppedChunks,
    language: _language,
  );

  Stream<GuardianTranscriptionSnapshot> get changes => _changes.stream;

  void startSession(String sessionId, DateTime startedAt) {
    if (_disposed) return;
    if (_sessionId != sessionId) {
      _clearSessionData();
      _sessionId = sessionId;
      _callStartedAtMs = startedAt.millisecondsSinceEpoch;
    }
    _callActive = true;
    if (_enabled) {
      _setState(
        'TRANSCRIPTION_UNAVAILABLE',
        "Live transcription isn't available for this call on this device.",
      );
    }
  }

  void setAudioSource(String source) {
    if (!_enabled || !_callActive) return;
    if (source != 'CALL_AUDIO') {
      _queue.clear();
      _setState(
        'TRANSCRIPTION_UNAVAILABLE',
        "Live transcription isn't available for this call on this device.",
      );
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (_disposed || _enabled == enabled) return;
    _enabled = enabled;
    if (!enabled) {
      _queue.clear();
      while (_processing) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      _segments.clear();
      _recentChunkIds.clear();
      _recentSegmentIds.clear();
      _language = null;
      var cleanupFailed = false;
      if (_hasRemoteChunks && _sessionId != null) {
        try {
          await _finalizeRemoteSession(_sessionId!);
        } on ApiException {
          cleanupFailed = true;
          _setCleanupError();
        } on Exception {
          cleanupFailed = true;
          _setCleanupError();
        }
      }
      _hasRemoteChunks = false;
      if (!cleanupFailed) _setState('AI_IDLE', 'Live transcription is off.');
      return;
    }
    if (!_callActive) {
      _setState(
        'TRANSCRIPTION_INITIALIZING',
        'Preparing live transcription for the next supported call.',
      );
      return;
    }
    _setState(
      'TRANSCRIPTION_UNAVAILABLE',
      "Live transcription isn't available for this call on this device.",
    );
  }

  Future<void> endSession(String sessionId) async {
    if (_sessionId != sessionId) return;
    _callActive = false;
    _queue.clear();
    while (_processing) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    var cleanupFailed = false;
    if (_enabled) {
      try {
        if (_hasRemoteChunks) await _finalizeRemoteSession(sessionId);
      } on ApiException {
        cleanupFailed = true;
        _setCleanupError();
      } on Exception {
        cleanupFailed = true;
        _setCleanupError();
      }
    }
    _clearSessionData();
    _hasRemoteChunks = false;
    if (!cleanupFailed) _setState('CALL_ENDED', 'Call ended.');
  }

  Future<void> _finalizeRemoteSession(String sessionId) async {
    final token = await tokenProvider();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Your session has expired. Please sign in again.',
        statusCode: 401,
      );
    }
    await api.postJson(
      '/guardian/transcription/session/${Uri.encodeComponent(sessionId)}/finalize',
      const {},
      token: token,
    );
  }

  void _acceptChunk(GuardianAudioChunk chunk) {
    if (_disposed || !_enabled || !_callActive) return;
    if (_sessionId != chunk.sessionId) return;
    if (chunk.source != 'CALL_AUDIO') {
      setAudioSource(chunk.source);
      return;
    }
    if (chunk.sampleRateHz != 16000 ||
        chunk.channels != 1 ||
        chunk.encoding != 'PCM_16BIT' ||
        chunk.durationMs != 5000) {
      _setState(
        'TRANSCRIPTION_UNAVAILABLE',
        'This audio format is not supported for live transcription.',
      );
      return;
    }
    if (_recentChunkIds.contains(chunk.chunkId) ||
        chunk.sequenceNumber <= _lastSequence ||
        _queue.any((queued) => queued.chunkId == chunk.chunkId)) {
      return;
    }
    if (_queue.length >= _maxQueuedChunks) {
      _droppedChunks++;
      _publish();
      return;
    }
    _recentChunkIds.addLast(chunk.chunkId);
    while (_recentChunkIds.length > _maxRecentChunkIds) {
      _recentChunkIds.removeFirst();
    }
    _queue.addLast(chunk);
    unawaited(_processQueue());
  }

  Future<void> _processQueue() async {
    if (_processing || _disposed) return;
    _processing = true;
    try {
      while (_queue.isNotEmpty && _enabled && _callActive && !_disposed) {
        final chunk = _queue.removeFirst();
        if (_sessionId != chunk.sessionId) continue;
        _setState('TRANSCRIBING', 'Transcribing supported call audio…');
        try {
          final token = await tokenProvider();
          if (token == null || token.isEmpty) {
            throw const ApiException(
              'Your session has expired. Please sign in again.',
              statusCode: 401,
            );
          }
          _hasRemoteChunks = true;
          final response = await api.postMultipart(
            path: '/guardian/transcription/chunk',
            fieldName: 'file',
            bytes: chunk.audioData,
            filename: '${chunk.chunkId}.pcm',
            token: token,
            fields: {
              'session_id': chunk.sessionId,
              'chunk_id': chunk.chunkId,
              'sequence': '${chunk.sequenceNumber}',
              'timestamp_ms': '${chunk.timestamp.millisecondsSinceEpoch}',
              'call_started_at_ms':
                  '${_callStartedAtMs ?? chunk.timestamp.millisecondsSinceEpoch}',
              'duration_ms': '${chunk.durationMs}',
              'sample_rate_hz': '${chunk.sampleRateHz}',
              'channels': '${chunk.channels}',
              'encoding': chunk.encoding,
              'source': chunk.source,
            },
          );
          if (!_enabled || !_callActive || _sessionId != chunk.sessionId) {
            continue;
          }
          if (response is! Map<String, dynamic> ||
              response['segments'] is! List) {
            throw const ApiException('Transcription response was malformed.');
          }
          final responseLanguage = response['language'];
          if (responseLanguage is! String || responseLanguage.isEmpty) {
            throw const ApiException('Transcription response was malformed.');
          }
          _language = responseLanguage;
          final parsedSegments =
              (response['segments'] as List)
                  .whereType<Map<String, dynamic>>()
                  .map(TranscriptSegment.fromJson)
                  .toList(growable: false)
                ..sort((a, b) {
                  final sequenceOrder = a.sequence.compareTo(b.sequence);
                  return sequenceOrder != 0
                      ? sequenceOrder
                      : a.startTime.compareTo(b.startTime);
                });
          for (final segment in parsedSegments) {
            if (_recentSegmentIds.contains(segment.segmentId)) continue;
            _recentSegmentIds.addLast(segment.segmentId);
            while (_recentSegmentIds.length > _maxTranscriptSegments * 2) {
              _recentSegmentIds.removeFirst();
            }
            _segments.addLast(segment);
            while (_segments.length > _maxTranscriptSegments) {
              _segments.removeFirst();
            }
            _language = segment.language;
          }
          _lastSequence = chunk.sequenceNumber;
          _setState(
            'TRANSCRIPTION_READY',
            _segments.isEmpty
                ? 'No speech detected yet.'
                : 'Live transcription active.',
          );
        } on ApiException catch (error) {
          if (error.statusCode == 401) {
            _setState(
              'TRANSCRIPTION_ERROR',
              'Your session has expired. Sign in again to continue.',
            );
          } else {
            _setState(
              'TRANSCRIPTION_ERROR',
              'Transcription is temporarily unavailable.',
            );
          }
        } on FormatException {
          _setState(
            'TRANSCRIPTION_ERROR',
            'Transcription is temporarily unavailable.',
          );
        } on Exception {
          _setState(
            'TRANSCRIPTION_ERROR',
            'Transcription is temporarily unavailable.',
          );
        }
      }
    } finally {
      _processing = false;
    }
  }

  void _clearSessionData() {
    _queue.clear();
    _segments.clear();
    _recentChunkIds.clear();
    _recentSegmentIds.clear();
    _lastSequence = 0;
    _callStartedAtMs = null;
    _language = null;
    _droppedChunks = 0;
    _hasRemoteChunks = false;
  }

  void _setState(String state, String message) {
    _state = state;
    _message = message;
    _publish();
  }

  void _publish() {
    if (!_disposed) _changes.add(snapshot);
  }

  void _setCleanupError() {
    _setState(
      'TRANSCRIPTION_ERROR',
      'Temporary transcript cleanup could not be confirmed.',
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _queue.clear();
    await _chunkSubscription.cancel();
    while (_processing) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    if (_hasRemoteChunks && _sessionId != null) {
      try {
        await _finalizeRemoteSession(_sessionId!);
      } on Exception catch (error, stackTrace) {
        developer.log(
          'Temporary transcription cleanup failed during disposal.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    _clearSessionData();
    await _changes.close();
  }
}
