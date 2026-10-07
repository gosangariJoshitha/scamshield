import 'dart:async';

import '../models/guardian_protection_models.dart';
import '../native/call_bridge.dart';
import 'api_service.dart';

class GuardianProtectionService {
  GuardianProtectionService({
    required this.callBridge,
    required this.api,
    required this.tokenProvider,
  });

  final CallBridge callBridge;
  final ApiService api;
  final Future<String?> Function() tokenProvider;

  final StreamController<ProtectionActionResult> _actionResults =
      StreamController<ProtectionActionResult>.broadcast();

  GuardianProtectionCapabilities _capabilities =
      GuardianProtectionCapabilities.fallback();
  GuardianProtectionSettings _settings = const GuardianProtectionSettings();

  String? _activeSessionId;
  bool _isCallActive = false;
  final List<ProtectionActionResult> _sessionActionHistory = [];
  final List<ProtectionActionResult> _lastSessionActions = [];
  final Map<ProtectionActionType, ProtectionActionStatus> _actionStatuses = {
    ProtectionActionType.endCall: ProtectionActionStatus.idle,
    ProtectionActionType.blockCaller: ProtectionActionStatus.idle,
    ProtectionActionType.verifySafely: ProtectionActionStatus.idle,
    ProtectionActionType.reportCall: ProtectionActionStatus.idle,
  };

  GuardianProtectionCapabilities get capabilities => _capabilities;
  GuardianProtectionSettings get settings => _settings;
  Stream<ProtectionActionResult> get actionResults => _actionResults.stream;
  List<ProtectionActionResult> get sessionActionHistory =>
      List.unmodifiable(_sessionActionHistory.isNotEmpty ? _sessionActionHistory : _lastSessionActions);

  ProtectionActionStatus statusFor(ProtectionActionType action) =>
      _actionStatuses[action] ?? ProtectionActionStatus.idle;

  bool isActionInProgress(ProtectionActionType action) =>
      _actionStatuses[action] == ProtectionActionStatus.inProgress ||
      _actionStatuses[action] == ProtectionActionStatus.confirming;

  Future<void> initialize() async {
    try {
      _capabilities = await callBridge.getProtectionCapabilities();
    } on Exception {
      _capabilities = GuardianProtectionCapabilities.fallback();
    }
  }

  void updateSettings(GuardianProtectionSettings newSettings) {
    _settings = newSettings;
  }

  void startSession(String sessionId) {
    _activeSessionId = sessionId;
    _isCallActive = true;
    _sessionActionHistory.clear();
    _resetActionStatuses();
  }

  void endSession(String sessionId) {
    if (_activeSessionId == sessionId) {
      _isCallActive = false;
      _lastSessionActions.clear();
      _lastSessionActions.addAll(_sessionActionHistory);
      _activeSessionId = null;
      _resetActionStatuses();
    }
  }

  void recordAction(ProtectionActionResult action) {
    _sessionActionHistory.add(action);
    _actionResults.add(action);
  }

  List<Map<String, dynamic>> exportSessionActions() {
    final list = _sessionActionHistory.isNotEmpty ? _sessionActionHistory : _lastSessionActions;
    return list.map((res) {
      final actionStr = switch (res.action) {
        ProtectionActionType.endCall => 'END_CALL',
        ProtectionActionType.blockCaller => 'BLOCK_CALLER',
        ProtectionActionType.verifySafely => 'VERIFY_BEFORE_SHARING',
        ProtectionActionType.reportCall => 'REPORT_CALL',
      };
      final resultStr = switch (res.status) {
        ProtectionActionStatus.success => 'SUCCESS',
        ProtectionActionStatus.unavailable => 'UNSUPPORTED',
        ProtectionActionStatus.failed => 'FAILED',
        _ => 'EXECUTED',
      };
      return {
        'action': actionStr,
        'timestamp': res.timestamp.toUtc().toIso8601String(),
        'result': resultStr,
      };
    }).toList();
  }

  void _resetActionStatuses() {
    for (final action in ProtectionActionType.values) {
      _actionStatuses[action] = ProtectionActionStatus.idle;
    }
  }

  Future<ProtectionActionResult> executeEndCall({
    required String sessionId,
  }) async {
    if (isActionInProgress(ProtectionActionType.endCall)) {
      return ProtectionActionResult(
        action: ProtectionActionType.endCall,
        status: ProtectionActionStatus.inProgress,
        message: 'End call request already in progress.',
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );
    }

    if (!_isCallActive || _activeSessionId != sessionId) {
      final result = ProtectionActionResult(
        action: ProtectionActionType.endCall,
        status: ProtectionActionStatus.failed,
        message: 'Call is no longer active.',
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );
      _publishActionResult(result);
      return result;
    }

    _actionStatuses[ProtectionActionType.endCall] = ProtectionActionStatus.inProgress;

    try {
      final nativeResponse = await callBridge.requestEndCall(sessionId: sessionId);
      final success = nativeResponse['success'] as bool? ?? false;
      final supported = nativeResponse['supported'] as bool? ?? false;
      final reason = nativeResponse['reason'] as String? ??
          (success ? 'Call ended.' : 'Your device does not allow ScamShield to end this call automatically.');

      final result = ProtectionActionResult(
        action: ProtectionActionType.endCall,
        status: success
            ? ProtectionActionStatus.success
            : (supported ? ProtectionActionStatus.failed : ProtectionActionStatus.unavailable),
        message: reason,
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );

      _actionStatuses[ProtectionActionType.endCall] = result.status;
      _publishActionResult(result);
      return result;
    } on Exception catch (e) {
      final result = ProtectionActionResult(
        action: ProtectionActionType.endCall,
        status: ProtectionActionStatus.failed,
        message: 'Could not end call: ${e.toString()}',
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );
      _actionStatuses[ProtectionActionType.endCall] = ProtectionActionStatus.failed;
      _publishActionResult(result);
      return result;
    } finally {
      if (_actionStatuses[ProtectionActionType.endCall] == ProtectionActionStatus.inProgress) {
        _actionStatuses[ProtectionActionType.endCall] = ProtectionActionStatus.idle;
      }
    }
  }

  Future<ProtectionActionResult> executeBlockCaller({
    required String sessionId,
    String? phoneNumber,
  }) async {
    if (isActionInProgress(ProtectionActionType.blockCaller)) {
      return ProtectionActionResult(
        action: ProtectionActionType.blockCaller,
        status: ProtectionActionStatus.inProgress,
        message: 'Block caller request already in progress.',
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );
    }

    _actionStatuses[ProtectionActionType.blockCaller] = ProtectionActionStatus.inProgress;

    try {
      final nativeResponse = await callBridge.requestBlockCaller(
        sessionId: sessionId,
        phoneNumber: phoneNumber,
      );
      final success = nativeResponse['success'] as bool? ?? false;
      final canOpenSettings = nativeResponse['canOpenSettings'] as bool? ?? false;
      final reason = nativeResponse['reason'] as String? ??
          'Caller blocking is unavailable on this device. You can block this number from your phone\'s call settings.';

      final result = ProtectionActionResult(
        action: ProtectionActionType.blockCaller,
        status: success ? ProtectionActionStatus.success : ProtectionActionStatus.unavailable,
        message: reason,
        timestamp: DateTime.now(),
        sessionId: sessionId,
        canOpenSettings: canOpenSettings,
      );

      _actionStatuses[ProtectionActionType.blockCaller] = result.status;
      _publishActionResult(result);
      return result;
    } on Exception catch (e) {
      final result = ProtectionActionResult(
        action: ProtectionActionType.blockCaller,
        status: ProtectionActionStatus.failed,
        message: 'Could not block caller: ${e.toString()}',
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );
      _actionStatuses[ProtectionActionType.blockCaller] = ProtectionActionStatus.failed;
      _publishActionResult(result);
      return result;
    } finally {
      if (_actionStatuses[ProtectionActionType.blockCaller] == ProtectionActionStatus.inProgress) {
        _actionStatuses[ProtectionActionType.blockCaller] = ProtectionActionStatus.idle;
      }
    }
  }

  Future<ProtectionActionResult> submitReport({
    required String sessionId,
    required String category,
    required String description,
    String? evidence,
  }) async {
    if (isActionInProgress(ProtectionActionType.reportCall)) {
      return ProtectionActionResult(
        action: ProtectionActionType.reportCall,
        status: ProtectionActionStatus.inProgress,
        message: 'Report submission already in progress.',
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );
    }

    _actionStatuses[ProtectionActionType.reportCall] = ProtectionActionStatus.inProgress;

    try {
      final token = await tokenProvider();
      if (token == null || token.isEmpty) {
        throw const ApiException(
          'Sign in to submit a scam report.',
          statusCode: 401,
        );
      }

      await api.postJson(
        '/community/reports',
        {
          'content': 'Scam call report from Guardian session $sessionId',
          'category': category.isNotEmpty ? category : 'vishing',
          'description': description.isNotEmpty ? description : 'Suspicious call reported by user',
          'evidence': evidence ?? 'Reported via Guardian Live Protection Panel',
        },
        token: token,
      );

      final result = ProtectionActionResult(
        action: ProtectionActionType.reportCall,
        status: ProtectionActionStatus.success,
        message: 'Report submitted to ScamShield community database.',
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );

      _actionStatuses[ProtectionActionType.reportCall] = ProtectionActionStatus.success;
      _publishActionResult(result);
      return result;
    } on ApiException catch (e) {
      final result = ProtectionActionResult(
        action: ProtectionActionType.reportCall,
        status: ProtectionActionStatus.failed,
        message: 'Report submission failed: ${e.message}',
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );
      _actionStatuses[ProtectionActionType.reportCall] = ProtectionActionStatus.failed;
      _publishActionResult(result);
      return result;
    } on Exception catch (_) {
      final result = ProtectionActionResult(
        action: ProtectionActionType.reportCall,
        status: ProtectionActionStatus.failed,
        message: 'Report could not be submitted right now.',
        timestamp: DateTime.now(),
        sessionId: sessionId,
      );
      _actionStatuses[ProtectionActionType.reportCall] = ProtectionActionStatus.failed;
      _publishActionResult(result);
      return result;
    } finally {
      if (_actionStatuses[ProtectionActionType.reportCall] == ProtectionActionStatus.inProgress) {
        _actionStatuses[ProtectionActionType.reportCall] = ProtectionActionStatus.idle;
      }
    }
  }

  void _publishActionResult(ProtectionActionResult result) {
    _sessionActionHistory.add(result);
    _actionResults.add(result);
  }

  Future<void> onRiskEscalated(String riskLevel) async {
    if (!_settings.riskAlertsEnabled) return;

    if (riskLevel.toUpperCase() == 'CRITICAL' && _settings.criticalRiskAlertsEnabled) {
      if (_settings.highRiskVibrationEnabled) {
        await callBridge.triggerHapticAlert('CRITICAL');
      }
    } else if (riskLevel.toUpperCase() == 'HIGH') {
      if (_settings.highRiskVibrationEnabled) {
        await callBridge.triggerHapticAlert('HIGH');
      }
    }
  }

  void openBlockedNumbersSettings() {
    callBridge.openBlockedNumbersSettings();
  }

  void dispose() {
    _actionResults.close();
  }
}
