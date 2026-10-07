import 'dart:async';
import 'dart:developer' as developer;

import '../models/guardian_analysis_models.dart';
import 'api_service.dart';
import 'guardian_transcription_service.dart';

class GuardianLiveAnalysisService {
  GuardianLiveAnalysisService({
    required Stream<GuardianTranscriptionSnapshot> transcriptionChanges,
    required this.api,
    required this.tokenProvider,
  }) {
    _subscription = transcriptionChanges.listen(
      _handleTranscriptionSnapshot,
      onError: (Object error, StackTrace stackTrace) {
        _setState(
          'AI_ERROR',
          'Live AI analysis is temporarily unavailable.',
        );
      },
    );
  }

  final ApiService api;
  final Future<String?> Function() tokenProvider;
  final StreamController<GuardianLiveAnalysisSnapshot> _changes =
      StreamController<GuardianLiveAnalysisSnapshot>.broadcast();
  late final StreamSubscription<GuardianTranscriptionSnapshot> _subscription;

  String _state = 'AI_IDLE';
  String _message = 'Live AI analysis is off.';
  GuardianLiveAnalysisResult? _result;
  String? _sessionId;
  int _lastAnalyzedSequence = 0;
  bool _enabled = false;
  bool _callActive = false;
  bool _isAnalyzing = false;
  bool _hasRemoteAnalysis = false;
  bool _disposed = false;
  bool _isCallEnded = false;
  DateTime? _lastAnalysisTime;
  TranscriptSegment? _pendingSegment;

  GuardianLiveAnalysisSnapshot get snapshot => GuardianLiveAnalysisSnapshot(
        state: _state,
        message: _message,
        result: _result,
        lastAnalyzedSequence: _lastAnalyzedSequence,
        isAnalyzing: _isAnalyzing,
        activeSessionId: _sessionId,
        isCallEnded: _isCallEnded,
        lastAnalysisTime: _lastAnalysisTime,
      );

  Stream<GuardianLiveAnalysisSnapshot> get changes => _changes.stream;

  void startSession(String sessionId, DateTime startedAt) {
    if (_disposed) return;
    _isCallEnded = false;
    if (_sessionId != sessionId) {
      _clearSessionData();
      _sessionId = sessionId;
    }
    _callActive = true;
    if (_enabled) {
      _setState(
        'AI_WAITING_FOR_TRANSCRIPT',
        'Listening for conversation to analyze for suspicious patterns…',
      );
    }
  }

  Future<void> setEnabled(bool enabled) async {
    if (_disposed || _enabled == enabled) return;
    _enabled = enabled;
    if (!enabled) {
      _isCallEnded = false;
      _pendingSegment = null;
      while (_isAnalyzing) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      var cleanupFailed = false;
      if (_hasRemoteAnalysis && _sessionId != null) {
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
      _clearSessionData();
      if (!cleanupFailed) {
        _setState('AI_IDLE', 'Live AI analysis is off.');
      }
      return;
    }

    if (!_callActive) {
      _setState(
        'AI_IDLE',
        'Live AI analysis ready for the next supported call.',
      );
      return;
    }

    _setState(
      'AI_WAITING_FOR_TRANSCRIPT',
      'Listening for conversation to analyze for suspicious patterns…',
    );
  }

  Future<void> endSession(String sessionId) async {
    if (_sessionId != sessionId) return;
    _callActive = false;
    _pendingSegment = null;
    final finalResult = _result;
    while (_isAnalyzing) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    var cleanupFailed = false;
    if (_enabled && _hasRemoteAnalysis) {
      try {
        await _finalizeRemoteSession(sessionId);
      } on ApiException {
        cleanupFailed = true;
        _setCleanupError();
      } on Exception {
        cleanupFailed = true;
        _setCleanupError();
      }
    }
    _clearSessionData();
    if (!cleanupFailed) {
      if (finalResult != null) {
        _result = finalResult;
        _isCallEnded = true;
        _setState('CALL_ENDED', 'Call ended. Guardian protection stopped.');
      } else {
        _setState('AI_IDLE', 'Call ended.');
      }
    }
  }

  void dismissCallEndedResult() {
    if (_isCallEnded) {
      _clearSessionData();
      _setState('AI_IDLE', 'Guardian is ready for the next call.');
    }
  }

  void _handleTranscriptionSnapshot(GuardianTranscriptionSnapshot snapshot) {
    if (_disposed || !_enabled || !_callActive || _sessionId == null) return;
    if (snapshot.segments.isEmpty) return;

    final latest = snapshot.segments.last;
    if (latest.sessionId != _sessionId) return;
    if (latest.sequence <= _lastAnalyzedSequence) return;

    _pendingSegment = latest;
    if (!_isAnalyzing) {
      unawaited(_processPendingSegments());
    }
  }

  Future<void> _processPendingSegments() async {
    if (_isAnalyzing || _disposed) return;
    _isAnalyzing = true;
    _publish();

    try {
      while (_pendingSegment != null && _enabled && _callActive && !_disposed) {
        final segment = _pendingSegment!;
        _pendingSegment = null;

        if (segment.sessionId != _sessionId) continue;
        if (segment.sequence <= _lastAnalyzedSequence) continue;

        _setState(
          'AI_ANALYZING',
          'Analyzing conversation for suspicious patterns…',
        );

        try {
          final token = await tokenProvider();
          if (token == null || token.isEmpty) {
            throw const ApiException(
              'Your session has expired. Please sign in again.',
              statusCode: 401,
            );
          }

          _hasRemoteAnalysis = true;
          final responseData = await api.postJson(
            '/guardian/analysis/segment',
            {
              'session_id': segment.sessionId,
              'segment_id': segment.segmentId,
              'sequence': segment.sequence,
              'start_time': segment.startTime,
              'end_time': segment.endTime,
              'text': segment.text,
              'is_final': segment.isFinal,
              'language': segment.language,
              'source': 'CALL_AUDIO',
              'created_at': segment.createdAt.toIso8601String(),
            },
            token: token,
          );

          if (!_enabled || !_callActive || _sessionId != segment.sessionId) {
            continue;
          }

          if (responseData is! Map<String, dynamic>) {
            throw const ApiException('Live analysis response was malformed.');
          }

          final response = GuardianLiveAnalysisResponse.fromJson(responseData);
          _lastAnalyzedSequence = segment.sequence;

          switch (response.status) {
            case 'AI_RESULT_READY':
              if (response.result != null && response.result!.sessionId == _sessionId) {
                _result = response.result;
                _lastAnalysisTime = DateTime.now();
                _setState('AI_RESULT_READY', response.message);
              }
              break;
            case 'AI_WAITING_FOR_TRANSCRIPT':
              _setState(
                _result != null ? 'AI_RESULT_READY' : 'AI_WAITING_FOR_TRANSCRIPT',
                response.message,
              );
              break;
            case 'AI_DUPLICATE':
              // Keep existing state and result
              _setState(_state, response.message);
              break;
            case 'AI_UNAVAILABLE':
            default:
              _setState(
                'AI_UNAVAILABLE',
                response.message.isNotEmpty
                    ? response.message
                    : 'Live AI analysis is temporarily unavailable.',
              );
              break;
          }
        } on ApiException catch (error) {
          if (error.statusCode == 401) {
            _setState(
              'AI_ERROR',
              'Your session has expired. Sign in again to continue.',
            );
          } else if (error.statusCode == 503) {
            _setState(
              'AI_UNAVAILABLE',
              'Live AI analysis is temporarily unavailable.',
            );
          } else {
            _setState(
              'AI_ERROR',
              'Live AI analysis is temporarily unavailable.',
            );
          }
        } on FormatException {
          _setState(
            'AI_ERROR',
            'Live AI analysis is temporarily unavailable.',
          );
        } on Exception {
          _setState(
            'AI_ERROR',
            'Live AI analysis is temporarily unavailable.',
          );
        }
      }
    } finally {
      _isAnalyzing = false;
      _publish();
    }
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
      '/guardian/analysis/session/${Uri.encodeComponent(sessionId)}/finalize',
      const {},
      token: token,
    );
  }

  void _clearSessionData() {
    _sessionId = null;
    _lastAnalyzedSequence = 0;
    _result = null;
    _pendingSegment = null;
    _hasRemoteAnalysis = false;
    _isCallEnded = false;
    _lastAnalysisTime = null;
  }

  void _setState(String state, String message) {
    _state = state;
    _message = message;
    _publish();
  }

  void _setCleanupError() {
    _setState(
      'AI_ERROR',
      'Temporary analysis session cleanup could not be confirmed.',
    );
  }

  void _publish() {
    if (!_disposed) _changes.add(snapshot);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _pendingSegment = null;
    await _subscription.cancel();
    while (_isAnalyzing) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    if (_hasRemoteAnalysis && _sessionId != null) {
      try {
        await _finalizeRemoteSession(_sessionId!);
      } on Exception catch (error, stackTrace) {
        developer.log(
          'Temporary live analysis cleanup failed during disposal.',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }
    _clearSessionData();
    await _changes.close();
  }
}
