import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/guardian_protection_models.dart';

class CallGuardianStatus {
  const CallGuardianStatus({
    required this.available,
    required this.supported,
    required this.phoneStatePermissionGranted,
    required this.notificationsPermissionGranted,
    required this.enabled,
    required this.serviceRunning,
    required this.callState,
    required this.serviceError,
    required this.callScreeningAvailable,
    required this.callScreeningEnabled,
    required this.incomingCallDetection,
    required this.outgoingCallDetection,
    required this.activeCallStateDetection,
    required this.audioCaptureAvailable,
    required this.audioPermissionGranted,
    required this.audioProtectionEnabled,
    required this.audioState,
    required this.audioSource,
    required this.audioRoute,
    required this.audioReason,
    required this.audioChunksCreated,
    required this.audioChunksDropped,
  });

  final bool available;
  final bool supported;
  final bool phoneStatePermissionGranted;
  final bool notificationsPermissionGranted;
  final bool enabled;
  final bool serviceRunning;
  final String callState;
  final String? serviceError;
  final bool callScreeningAvailable;
  final bool callScreeningEnabled;
  final bool incomingCallDetection;
  final bool outgoingCallDetection;
  final bool activeCallStateDetection;
  final bool audioCaptureAvailable;
  final bool audioPermissionGranted;
  final bool audioProtectionEnabled;
  final String audioState;
  final String audioSource;
  final String audioRoute;
  final String audioReason;
  final int audioChunksCreated;
  final int audioChunksDropped;

  /// Authoritative single source of truth: live protection is active ONLY when
  /// the feature is enabled, the background service is running, and phone state
  /// permission is granted by the user.
  bool get isProtected =>
      enabled && serviceRunning && phoneStatePermissionGranted;

  factory CallGuardianStatus.fromMap(Map<Object?, Object?> values) {
    bool readBool(String key) {
      final value = values[key];
      if (value is! bool) {
        throw PlatformException(
          code: 'INVALID_RESPONSE',
          message: 'Native Guardian status did not include a valid "$key".',
        );
      }
      return value;
    }

    String readString(String key) {
      final value = values[key];
      if (value is! String) {
        throw PlatformException(
          code: 'INVALID_RESPONSE',
          message: 'Native Guardian status did not include a valid "$key".',
        );
      }
      return value;
    }

    String? readOptionalString(String key) {
      final value = values[key];
      if (value is! String) {
        throw PlatformException(
          code: 'INVALID_RESPONSE',
          message: 'Native Guardian status did not include a valid "$key".',
        );
      }
      return value.isEmpty ? null : value;
    }

    return CallGuardianStatus(
      available: readBool('available'),
      supported: readBool('supported'),
      phoneStatePermissionGranted: readBool('phoneStatePermissionGranted'),
      notificationsPermissionGranted: readBool(
        'notificationsPermissionGranted',
      ),
      enabled: readBool('enabled'),
      serviceRunning: readBool('serviceRunning'),
      callState: readString('callState'),
      serviceError: readOptionalString('serviceError'),
      callScreeningAvailable: readBool('callScreeningAvailable'),
      callScreeningEnabled: readBool('callScreeningEnabled'),
      incomingCallDetection: readBool('incomingCallDetection'),
      outgoingCallDetection: readBool('outgoingCallDetection'),
      activeCallStateDetection: readBool('activeCallStateDetection'),
      audioCaptureAvailable: readBool('audioCaptureAvailable'),
      audioPermissionGranted: readBool('audioPermissionGranted'),
      audioProtectionEnabled: readBool('audioProtectionEnabled'),
      audioState: readString('audioState'),
      audioSource: readString('audioSource'),
      audioRoute: readString('audioRoute'),
      audioReason: readString('audioReason'),
      audioChunksCreated: readInt(values, 'audioChunksCreated'),
      audioChunksDropped: readInt(values, 'audioChunksDropped'),
    );
  }

  static int readInt(Map<Object?, Object?> values, String key) {
    final value = values[key];
    if (value is! num) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message: 'Native Guardian status did not include a valid "$key".',
      );
    }
    return value.toInt();
  }
}

class AudioCapability {
  const AudioCapability({
    required this.supported,
    required this.source,
    required this.permissionStatus,
    required this.reason,
    required this.sampleRateHz,
    required this.channels,
    required this.encoding,
    required this.chunkDurationMs,
    required this.maxBufferedChunks,
  });

  final bool supported;
  final String? source;
  final String permissionStatus;
  final String reason;
  final int sampleRateHz;
  final int channels;
  final String encoding;
  final int chunkDurationMs;
  final int maxBufferedChunks;

  factory AudioCapability.fromMap(Map<Object?, Object?> values) {
    String stringValue(String key) {
      final value = values[key];
      if (value is! String) {
        throw PlatformException(
          code: 'INVALID_RESPONSE',
          message: 'Native audio capability did not include a valid "$key".',
        );
      }
      return value;
    }

    final supported = values['supported'];
    final source = values['source'];
    if (supported is! bool || (source != null && source is! String)) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message: 'Native audio capability was malformed.',
      );
    }
    return AudioCapability(
      supported: supported,
      source: source as String?,
      permissionStatus: stringValue('permissionStatus'),
      reason: stringValue('reason'),
      sampleRateHz: CallGuardianStatus.readInt(values, 'sampleRateHz'),
      channels: CallGuardianStatus.readInt(values, 'channels'),
      encoding: stringValue('encoding'),
      chunkDurationMs: CallGuardianStatus.readInt(values, 'chunkDurationMs'),
      maxBufferedChunks: CallGuardianStatus.readInt(
        values,
        'maxBufferedChunks',
      ),
    );
  }
}

class GuardianAudioChunk {
  const GuardianAudioChunk({
    required this.chunkId,
    required this.sessionId,
    required this.sequenceNumber,
    required this.timestamp,
    required this.durationMs,
    required this.sampleRateHz,
    required this.channels,
    required this.encoding,
    required this.source,
    required this.audioData,
    this.rms = 0.0,
    this.isSilent = false,
  });

  final String chunkId;
  final String sessionId;
  final int sequenceNumber;
  final DateTime timestamp;
  final int durationMs;
  final int sampleRateHz;
  final int channels;
  final String encoding;
  final String source;
  final Uint8List audioData;
  final double rms;
  final bool isSilent;

  factory GuardianAudioChunk.fromMap(Map<Object?, Object?> values) {
    String readString(String key) {
      final value = values[key];
      if (value is! String || value.isEmpty) {
        throw PlatformException(
          code: 'INVALID_RESPONSE',
          message: 'Native audio chunk did not include a valid "$key".',
        );
      }
      return value;
    }

    final timestamp = values['timestamp'];
    final audioData = values['audioData'];
    if (timestamp is! num || audioData is! Uint8List) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message: 'Native audio chunk metadata or audio data was malformed.',
      );
    }
    final rmsVal = values['rms'];
    final isSilentVal = values['isSilent'];
    return GuardianAudioChunk(
      chunkId: readString('chunkId'),
      sessionId: readString('sessionId'),
      sequenceNumber: CallGuardianStatus.readInt(values, 'sequenceNumber'),
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()),
      durationMs: CallGuardianStatus.readInt(values, 'durationMs'),
      sampleRateHz: CallGuardianStatus.readInt(values, 'sampleRateHz'),
      channels: CallGuardianStatus.readInt(values, 'channels'),
      encoding: readString('encoding'),
      source: readString('source'),
      audioData: audioData,
      rms: rmsVal is num ? rmsVal.toDouble() : 0.0,
      isSilent: isSilentVal is bool ? isSilentVal : false,
    );
  }
}

class GuardianCallEvent {
  const GuardianCallEvent({
    required this.event,
    required this.sessionId,
    required this.direction,
    required this.state,
    required this.timestamp,
    required this.source,
  });

  final String event;
  final String sessionId;
  final String direction;
  final String state;
  final DateTime timestamp;
  final String source;

  factory GuardianCallEvent.fromMap(Map<Object?, Object?> values) {
    String readString(String key) {
      final value = values[key];
      if (value is! String || value.isEmpty) {
        throw PlatformException(
          code: 'INVALID_RESPONSE',
          message: 'Native call event did not include a valid "$key".',
        );
      }
      return value;
    }

    final timestamp = values['timestamp'];
    if (timestamp is! num) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message: 'Native call event did not include a valid "timestamp".',
      );
    }

    return GuardianCallEvent(
      event: readString('event'),
      sessionId: readString('sessionId'),
      direction: readString('direction'),
      state: readString('state'),
      timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp.toInt()),
      source: readString('source'),
    );
  }
}

class CallBridge {
  static const _channel = MethodChannel('com.scamshield/native');
  static const _guardianEvents = EventChannel(
    'com.scamshield/native/guardianEvents',
  );
  static const _callEvents = EventChannel('com.scamshield/native/callEvents');
  static const _audioEvents = EventChannel('com.scamshield/native/audioEvents');

  Future<Map<String, String>> getPlatformInfo() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getPlatformInfo',
    );
    if (result == null) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message: 'Native platform information was unavailable.',
      );
    }
    return result.map((key, value) => MapEntry(key, value.toString()));
  }

  Future<bool> isNativeLayerAvailable() async {
    return await _channel.invokeMethod<bool>('isNativeLayerAvailable') ?? false;
  }

  Future<CallGuardianStatus> getCallGuardianStatus() async {
    final status = await _channel.invokeMapMethod<String, dynamic>(
      'getCallGuardianStatus',
    );
    if (status == null) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message: 'Native Guardian status was unavailable.',
      );
    }
    return CallGuardianStatus.fromMap(status);
  }

  Future<AudioCapability> getAudioCapability() async {
    final capability = await _channel.invokeMapMethod<String, dynamic>(
      'getAudioCapability',
    );
    if (capability == null) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message: 'Android did not return audio capability information.',
      );
    }
    return AudioCapability.fromMap(capability);
  }

  Future<Map<String, dynamic>> requestAudioPermission() async {
    final permission = await _channel.invokeMapMethod<String, dynamic>(
      'requestAudioPermission',
    );
    if (permission == null) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message: 'Android did not return microphone permission status.',
      );
    }
    return permission;
  }

  Future<CallGuardianStatus> setAudioPipelineEnabled(bool enabled) async {
    final status = await _channel.invokeMapMethod<String, dynamic>(
      'setAudioPipelineEnabled',
      {'enabled': enabled},
    );
    if (status == null) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message: 'Android did not return audio protection status.',
      );
    }
    return CallGuardianStatus.fromMap(status);
  }

  Stream<void> get audioChunkAvailable =>
      _audioEvents.receiveBroadcastStream().map((event) {
        if (event is! Map<Object?, Object?> ||
            event['event'] != 'audioChunkAvailable') {
          throw PlatformException(
            code: 'INVALID_RESPONSE',
            message: 'Native audio event was malformed.',
          );
        }
      });

  Future<GuardianAudioChunk?> takeNextAudioChunk() async {
    final chunk = await _channel.invokeMapMethod<String, dynamic>(
      'takeNextAudioChunk',
    );
    return chunk == null ? null : GuardianAudioChunk.fromMap(chunk);
  }

  Stream<CallGuardianStatus> get guardianStatusChanges =>
      _guardianEvents.receiveBroadcastStream().map((event) {
        if (event is! Map<Object?, Object?>) {
          throw PlatformException(
            code: 'INVALID_RESPONSE',
            message: 'Native Guardian event was not a status map.',
          );
        }
        return CallGuardianStatus.fromMap(event);
      });

  Stream<GuardianCallEvent> get callEvents =>
      _callEvents.receiveBroadcastStream().map((event) {
        if (event is! Map<Object?, Object?>) {
          throw PlatformException(
            code: 'INVALID_RESPONSE',
            message: 'Native call event was not a map.',
          );
        }
        return GuardianCallEvent.fromMap(event);
      });

  Future<CallGuardianStatus> requestCallScreeningRole() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'requestCallScreeningRole',
    );
    if (result == null) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message: 'Android did not return call-screening role status.',
      );
    }
    return CallGuardianStatus.fromMap(result);
  }

  Future<GuardianCallEvent?> getLatestCallEvent() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'getLatestCallEvent',
    );
    return result == null ? null : GuardianCallEvent.fromMap(result);
  }

  Future<CallGuardianStatus> requestGuardianPermissions() async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'requestGuardianPermissions',
    );
    if (result == null) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message: 'Android did not return Guardian permission status.',
      );
    }
    return CallGuardianStatus.fromMap(result);
  }

  Future<CallGuardianStatus> setGuardianEnabled(bool enabled) async {
    final result = await _channel.invokeMapMethod<String, dynamic>(
      'setGuardianEnabled',
      {'enabled': enabled},
    );
    if (result == null) {
      throw PlatformException(
        code: 'INVALID_RESPONSE',
        message: 'Android did not return Guardian status after the update.',
      );
    }
    return CallGuardianStatus.fromMap(result);
  }

  Future<void> openAppSettings() =>
      _channel.invokeMethod<void>('openAppSettings');

  Future<GuardianProtectionCapabilities> getProtectionCapabilities() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'getProtectionCapabilities',
      );
      if (result == null) return GuardianProtectionCapabilities.fallback();
      return GuardianProtectionCapabilities.fromMap(result);
    } on PlatformException {
      return GuardianProtectionCapabilities.fallback();
    } on MissingPluginException {
      return GuardianProtectionCapabilities.fallback();
    }
  }

  Future<Map<String, dynamic>> requestEndCall({required String sessionId}) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'requestEndCall',
        {'sessionId': sessionId},
      );
      return result ?? {
        'success': false,
        'supported': false,
        'reason': 'Your device does not allow ScamShield to end this call automatically. You can end the call using your phone controls.',
      };
    } on PlatformException catch (e) {
      return {
        'success': false,
        'supported': false,
        'reason': e.message ?? 'Call termination unavailable on this device.',
      };
    } on MissingPluginException {
      return {
        'success': false,
        'supported': false,
        'reason': 'Call control is available only in the Android app.',
      };
    }
  }

  Future<Map<String, dynamic>> requestBlockCaller({
    required String sessionId,
    String? phoneNumber,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
        'requestBlockCaller',
        {
          'sessionId': sessionId,
          'phoneNumber': phoneNumber,
        },
      );
      return result ?? {
        'success': false,
        'supported': false,
        'reason': 'Caller blocking is unavailable on this device.',
        'canOpenSettings': true,
      };
    } on PlatformException catch (e) {
      return {
        'success': false,
        'supported': false,
        'reason': e.message ?? 'Caller blocking unavailable.',
        'canOpenSettings': true,
      };
    } on MissingPluginException {
      return {
        'success': false,
        'supported': false,
        'reason': 'Caller blocking is available only in the Android app.',
        'canOpenSettings': false,
      };
    }
  }

  Future<void> openBlockedNumbersSettings() async {
    try {
      await _channel.invokeMethod<void>('openBlockedNumbersSettings');
    } on Exception {
      await openAppSettings();
    }
  }

  Future<bool> launchDialer(String phoneNumber) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'launchDialer',
        {'phoneNumber': phoneNumber},
      );
      return result ?? false;
    } on Exception {
      return false;
    }
  }

  Future<void> triggerHapticAlert(String intensity) async {
    try {
      await _channel.invokeMethod<void>(
        'triggerHapticAlert',
        {'intensity': intensity},
      );
    } catch (_) {
      // Haptics fail silently without disturbing UI
    }
  }

  Future<bool> canDrawOverlays() async {
    try {
      final result = await _channel.invokeMethod<bool>('canDrawOverlays');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<void> requestOverlayPermission() async {
    try {
      await _channel.invokeMethod<void>('requestOverlayPermission');
    } catch (_) {
      // Ignored
    }
  }

  Future<bool> speakVoiceAlert(String message) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'speakVoiceAlert',
        {'message': message},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> showFloatingGuardian({
    required String state,
    String? title,
    int? riskScore,
    String? category,
    String? snippet,
  }) async {
    try {
      final args = <String, dynamic>{'state': state};
      if (title != null) args['title'] = title;
      if (riskScore != null) args['riskScore'] = riskScore;
      if (category != null) args['category'] = category;
      if (snippet != null) args['snippet'] = snippet;
      final result = await _channel.invokeMethod<bool>(
        'showFloatingGuardian',
        args,
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateFloatingGuardian({
    required String state,
    String? title,
    int? riskScore,
    String? category,
    String? snippet,
  }) async {
    try {
      final args = <String, dynamic>{'state': state};
      if (title != null) args['title'] = title;
      if (riskScore != null) args['riskScore'] = riskScore;
      if (category != null) args['category'] = category;
      if (snippet != null) args['snippet'] = snippet;
      final result = await _channel.invokeMethod<bool>(
        'updateFloatingGuardian',
        args,
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addNumberToBlacklist(String phoneNumber, {String? reason}) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'addNumberToBlacklist',
        {
          'phoneNumber': phoneNumber,
          // ignore: use_null_aware_elements
          if (reason != null) 'reason': reason,
        },
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> removeNumberFromBlacklist(String phoneNumber) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'removeNumberFromBlacklist',
        {'phoneNumber': phoneNumber},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isNumberBlacklisted(String phoneNumber) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'isNumberBlacklisted',
        {'phoneNumber': phoneNumber},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<String>> getBlacklistedNumbers() async {
    try {
      final result = await _channel.invokeListMethod<String>('getBlacklistedNumbers');
      return result ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<bool> showAutoDisconnectNotification({
    required String phoneNumber,
    required String reason,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'showAutoDisconnectNotification',
        {
          'phoneNumber': phoneNumber,
          'reason': reason,
        },
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hideFloatingGuardian() async {
    try {
      final result = await _channel.invokeMethod<bool>('hideFloatingGuardian');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setFloatingGuardianEnabled(bool enabled) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setFloatingGuardianEnabled',
        {'enabled': enabled},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> showCallSummaryNotification({
    required String sessionId,
    required String phoneNumber,
    required String riskLevel,
    required int riskScore,
    required String category,
    String? reasoning,
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'showCallSummaryNotification',
        {
          'sessionId': sessionId,
          'phoneNumber': phoneNumber,
          'riskLevel': riskLevel,
          'riskScore': riskScore,
          'category': category,
          'reasoning': ?reasoning,
        },
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> dismissFloatingGuardian() => hideFloatingGuardian();

  Future<bool> setAutoSpeakerphoneEnabled(bool enabled) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setAutoSpeakerphoneEnabled',
        {'enabled': enabled},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isAutoSpeakerphoneEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAutoSpeakerphoneEnabled');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isSpeakerphoneActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isSpeakerphoneActive');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<String> getCurrentAudioRoute() async {
    try {
      final result = await _channel.invokeMethod<String>('getCurrentAudioRoute');
      return result ?? 'UNKNOWN';
    } catch (_) {
      return 'UNKNOWN';
    }
  }

  Future<bool> isAutoSpeakerphoneSupported() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAutoSpeakerphoneSupported');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isFloatingGuardianShowing() async {
    try {
      final result = await _channel.invokeMethod<bool>('isFloatingGuardianShowing');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getInitialAction() async {
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>('getInitialAction');
      return result;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setSpeakerphoneEnabled(bool enabled) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setSpeakerphoneEnabled',
        {'enabled': enabled},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isNotificationListenerPermissionGranted() async {
    try {
      final result = await _channel.invokeMethod<bool>('isNotificationListenerPermissionGranted');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> openNotificationListenerSettings() async {
    try {
      final result = await _channel.invokeMethod<bool>('openNotificationListenerSettings');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isNotificationShieldEnabled() async {
    try {
      final result = await _channel.invokeMethod<bool>('isNotificationShieldEnabled');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  Future<bool> setNotificationShieldEnabled(bool enabled) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'setNotificationShieldEnabled',
        {'enabled': enabled},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getDetectedSmsThreats() async {
    try {
      final raw = await _channel.invokeMethod<String>('getDetectedSmsThreats');
      if (raw == null || raw.isEmpty) return const [];
      final parsed = jsonDecode(raw);
      if (parsed is List) {
        return parsed
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> detectActiveRemoteAccessApps() async {
    try {
      final result = await _channel.invokeListMethod<dynamic>('detectActiveRemoteAccessApps');
      if (result == null) return const [];
      return result
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> openAppUninstallSettings(String packageName) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'openAppUninstallSettings',
        {'packageName': packageName},
      );
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
