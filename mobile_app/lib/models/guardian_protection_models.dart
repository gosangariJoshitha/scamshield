import 'package:flutter/foundation.dart';

enum ProtectionActionType {
  endCall,
  blockCaller,
  verifySafely,
  reportCall,
}

enum ProtectionActionStatus {
  idle,
  confirming,
  inProgress,
  success,
  failed,
  unavailable,
}

@immutable
class GuardianCapabilityItem {
  const GuardianCapabilityItem({
    required this.supported,
    required this.reason,
    this.requiresPermission = false,
    this.requiresUserConfirmation = true,
    this.canOpenSettings = false,
  });

  final bool supported;
  final String reason;
  final bool requiresPermission;
  final bool requiresUserConfirmation;
  final bool canOpenSettings;

  factory GuardianCapabilityItem.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const GuardianCapabilityItem(
        supported: false,
        reason: 'Capability information unavailable.',
      );
    }
    return GuardianCapabilityItem(
      supported: map['supported'] as bool? ?? false,
      reason: map['reason'] as String? ?? '',
      requiresPermission: map['requiresPermission'] as bool? ?? false,
      requiresUserConfirmation: map['requiresUserConfirmation'] as bool? ?? true,
      canOpenSettings: map['canOpenSettings'] as bool? ?? false,
    );
  }
}

@immutable
class GuardianProtectionCapabilities {
  const GuardianProtectionCapabilities({
    required this.canEndCall,
    required this.canBlockCaller,
    required this.canVibrate,
    required this.canVerifySafely,
    required this.canReport,
  });

  final GuardianCapabilityItem canEndCall;
  final GuardianCapabilityItem canBlockCaller;
  final GuardianCapabilityItem canVibrate;
  final GuardianCapabilityItem canVerifySafely;
  final GuardianCapabilityItem canReport;

  factory GuardianProtectionCapabilities.fromMap(Map<String, dynamic> map) {
    return GuardianProtectionCapabilities(
      canEndCall: GuardianCapabilityItem.fromMap(map['canEndCall'] as Map?),
      canBlockCaller: GuardianCapabilityItem.fromMap(map['canBlockCaller'] as Map?),
      canVibrate: GuardianCapabilityItem.fromMap(map['canVibrate'] as Map?),
      canVerifySafely: GuardianCapabilityItem.fromMap(map['canVerifySafely'] as Map?),
      canReport: GuardianCapabilityItem.fromMap(map['canReport'] as Map?),
    );
  }

  factory GuardianProtectionCapabilities.fallback() {
    return const GuardianProtectionCapabilities(
      canEndCall: GuardianCapabilityItem(
        supported: false,
        reason: 'Call termination not available automatically. You can end the call using your phone controls.',
      ),
      canBlockCaller: GuardianCapabilityItem(
        supported: false,
        reason: 'Direct caller blocking requires system phone app role. You can block this number from your phone\'s call settings.',
        canOpenSettings: true,
      ),
      canVibrate: GuardianCapabilityItem(
        supported: true,
        reason: 'Haptic alert supported.',
      ),
      canVerifySafely: GuardianCapabilityItem(
        supported: true,
        reason: 'Independent verification guidance available.',
      ),
      canReport: GuardianCapabilityItem(
        supported: true,
        reason: 'Community scam reporting available.',
      ),
    );
  }
}

@immutable
class ProtectionActionResult {
  const ProtectionActionResult({
    required this.action,
    required this.status,
    required this.message,
    required this.timestamp,
    required this.sessionId,
    this.canOpenSettings = false,
  });

  final ProtectionActionType action;
  final ProtectionActionStatus status;
  final String message;
  final DateTime timestamp;
  final String sessionId;
  final bool canOpenSettings;
}

@immutable
class GuardianProtectionSettings {
  const GuardianProtectionSettings({
    this.riskAlertsEnabled = true,
    this.highRiskVibrationEnabled = true,
    this.criticalRiskAlertsEnabled = true,
    this.showProtectionActions = true,
    this.askBeforeProtectiveActions = true,
  });

  final bool riskAlertsEnabled;
  final bool highRiskVibrationEnabled;
  final bool criticalRiskAlertsEnabled;
  final bool showProtectionActions;
  final bool askBeforeProtectiveActions;

  GuardianProtectionSettings copyWith({
    bool? riskAlertsEnabled,
    bool? highRiskVibrationEnabled,
    bool? criticalRiskAlertsEnabled,
    bool? showProtectionActions,
  }) {
    return GuardianProtectionSettings(
      riskAlertsEnabled: riskAlertsEnabled ?? this.riskAlertsEnabled,
      highRiskVibrationEnabled:
          highRiskVibrationEnabled ?? this.highRiskVibrationEnabled,
      criticalRiskAlertsEnabled:
          criticalRiskAlertsEnabled ?? this.criticalRiskAlertsEnabled,
      showProtectionActions:
          showProtectionActions ?? this.showProtectionActions,
      askBeforeProtectiveActions: true,
    );
  }
}
