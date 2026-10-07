import 'dart:async';

import '../native/call_bridge.dart';

class GuardianAudioService {
  GuardianAudioService({required this._bridge}) {
    _availableSubscription = _bridge.audioChunkAvailable.listen(
      (_) => _drainChunks(),
      onError: _chunks.addError,
    );
    unawaited(_drainChunks());
  }

  final CallBridge _bridge;
  final StreamController<GuardianAudioChunk> _chunks =
      StreamController<GuardianAudioChunk>.broadcast();
  late final StreamSubscription<void> _availableSubscription;
  bool _draining = false;
  bool _drainAgain = false;
  bool _disposed = false;

  Stream<GuardianAudioChunk> get chunks => _chunks.stream;

  Future<void> _drainChunks() async {
    if (_disposed) return;
    if (_draining) {
      _drainAgain = true;
      return;
    }
    _draining = true;
    try {
      do {
        _drainAgain = false;
        GuardianAudioChunk? chunk;
        do {
          chunk = await _bridge.takeNextAudioChunk();
          if (chunk != null && !_disposed) _chunks.add(chunk);
        } while (chunk != null && !_disposed);
      } while (_drainAgain && !_disposed);
    } catch (error, stackTrace) {
      if (!_disposed) _chunks.addError(error, stackTrace);
    } finally {
      _draining = false;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _availableSubscription.cancel();
    await _chunks.close();
  }
}
