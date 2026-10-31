import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/user.dart';
import '../../native/call_bridge.dart';
import '../../services/analysis_service.dart';
import '../../services/api_service.dart';
import '../../services/guardian_audio_service.dart';
import '../../services/guardian_transcription_service.dart';
import '../../models/guardian_analysis_models.dart';
import '../../services/guardian_live_analysis_service.dart';
import '../../services/guardian_protection_service.dart';
import '../../widgets/brand_mark.dart';
import '../analyze/analyze_screen.dart';
import '../history/history_screen.dart';
import '../history/call_summary_screen.dart';
import '../profile/profile_screen.dart';
import '../results/analysis_result_screen.dart';
import '../settings/settings_screen.dart';
import '../../models/call_history_models.dart';
import '../../services/call_history_service.dart';
import '../../services/auth_service.dart';
import '../../services/notification_service.dart';
import '../../services/community_service.dart';
import '../community/community_screen.dart';
import '../help/help_support_screen.dart';
import '../sentinel/sentinel_screen.dart';
import 'dashboard_view.dart';

enum _ProfileAction { profile, settings, community, help, logout }

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    required this.user,
    required this.analysisService,
    required this.onLogout,
    required this.onSessionExpired,
    required this.isDarkMode,
    required this.onToggleTheme,
    this.callHistoryService,
    this.authService,
    this.notificationService,
    this.communityService,
    super.key,
  });

  final User user;
  final AnalysisService analysisService;
  final CallHistoryService? callHistoryService;
  final AuthService? authService;
  final NotificationService? notificationService;
  final CommunityService? communityService;
  final Future<void> Function() onLogout;
  final Future<void> Function() onSessionExpired;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class ScamShieldNotification {
  const ScamShieldNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.icon,
    required this.color,
    this.isRead = false,
  });

  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final IconData icon;
  final Color color;
  final bool isRead;

  ScamShieldNotification copyWith({bool? isRead}) {
    return ScamShieldNotification(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      icon: icon,
      color: color,
      isRead: isRead ?? this.isRead,
    );
  }
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final _callBridge = CallBridge();
  late final GuardianAudioService _guardianAudioService;
  late final GuardianTranscriptionService _guardianTranscriptionService;
  late final StreamSubscription<CallGuardianStatus> _guardianSubscription;
  late final StreamSubscription<GuardianCallEvent> _callEventSubscription;
  late final StreamSubscription<GuardianTranscriptionSnapshot>
  _transcriptionSubscription;
  Timer? _callTimer;
  DashboardData? _dashboard;
  CallGuardianStatus? _guardianStatus;
  AudioCapability? _audioCapability;
  String? _audioCapabilityError;
  GuardianTranscriptionSnapshot? _transcriptionSnapshot;
  GuardianCallEvent? _callEvent;
  late final GuardianLiveAnalysisService _guardianLiveAnalysisService;
  late final GuardianProtectionService _guardianProtectionService;
  late final StreamSubscription<GuardianLiveAnalysisSnapshot>
  _analysisSubscription;
  GuardianLiveAnalysisSnapshot? _analysisSnapshot;
  int _activeCallSeconds = 0;
  String? _dashboardError;
  String? _bridgeError;
  late final CallHistoryService _callHistoryService;
  late final AuthService _authService;
  late final NotificationService _notificationService;
  late final CommunityService _communityService;
  DateTime? _sessionStartedAt;
  CallHistoryDetail? _lastFinalizedSummary;
  int _selectedIndex = 0;
  int _historyRevision = 0;
  String _selectedAnalysisType = 'text';
  bool _loadingDashboard = true;
  bool _handlingExpiredSession = false;
  bool _transcriptionEnabled = false;
  int _totalCallsAnalyzed = 0;
  List<ScamShieldNotification> _notifications = [];
  final Set<String> _readNotificationIds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _callHistoryService = widget.callHistoryService ??
        CallHistoryService(
          api: widget.analysisService.api,
          tokenProvider: widget.analysisService.tokenProvider,
        );
    _authService = widget.authService ?? AuthService(api: widget.analysisService.api);
    _notificationService = widget.notificationService ??
        NotificationService(
          api: widget.analysisService.api,
          authService: _authService,
        );
    _communityService = widget.communityService ??
        CommunityService(
          api: widget.analysisService.api,
          authService: _authService,
        );
    _guardianAudioService = GuardianAudioService(bridge: _callBridge);
    _guardianTranscriptionService = GuardianTranscriptionService(
      audioChunks: _guardianAudioService.chunks,
      api: widget.analysisService.api,
      tokenProvider: widget.analysisService.tokenProvider,
    );
    _transcriptionSnapshot = _guardianTranscriptionService.snapshot;
    _transcriptionSubscription = _guardianTranscriptionService.changes.listen((
      snapshot,
    ) {
      if (mounted) setState(() => _transcriptionSnapshot = snapshot);
    });
    _guardianLiveAnalysisService = GuardianLiveAnalysisService(
      transcriptionChanges: _guardianTranscriptionService.changes,
      api: widget.analysisService.api,
      tokenProvider: widget.analysisService.tokenProvider,
    );
    _guardianProtectionService = GuardianProtectionService(
      callBridge: _callBridge,
      api: widget.analysisService.api,
      tokenProvider: widget.analysisService.tokenProvider,
    );
    unawaited(_guardianProtectionService.initialize());
    _analysisSnapshot = _guardianLiveAnalysisService.snapshot;
    _analysisSubscription = _guardianLiveAnalysisService.changes.listen((
      snapshot,
    ) {
      if (mounted) {
        setState(() => _analysisSnapshot = snapshot);
        final result = snapshot.result;
        if (result != null) {
          unawaited(
            _guardianProtectionService.onRiskEscalated(result.riskLevel),
          );
        }
      }
    });
    _guardianSubscription = _callBridge.guardianStatusChanges.listen(
      (status) {
        if (mounted) {
          _guardianTranscriptionService.setAudioSource(status.audioSource);
          setState(() {
            _guardianStatus = status;
            _bridgeError = null;
          });
        }
      },
      onError: (Object error) {
        if (mounted && _guardianStatus == null) {
          setState(() => _bridgeError = 'Native bridge unavailable.');
        }
      },
    );
    _callEventSubscription = _callBridge.callEvents.listen(
      _handleCallEvent,
      onError: (Object error) {
        if (mounted && _guardianStatus == null) {
          setState(
            () => _bridgeError = 'Native call-event stream unavailable.',
          );
        }
      },
    );
    _loadDashboard();
    _loadGuardianStatus();
    _loadAudioCapability();
    _loadLatestCallEvent();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _loadGuardianStatus();
    if (state == AppLifecycleState.resumed) _loadAudioCapability();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_guardianSubscription.cancel());
    unawaited(_callEventSubscription.cancel());
    unawaited(_transcriptionSubscription.cancel());
    unawaited(_analysisSubscription.cancel());
    _guardianProtectionService.dispose();
    unawaited(_guardianLiveAnalysisService.dispose());
    unawaited(_guardianTranscriptionService.dispose());
    unawaited(_guardianAudioService.dispose());
    _callTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loadingDashboard = true;
      _dashboardError = null;
    });
    try {
      final data = await widget.analysisService.loadDashboard();
      if (mounted) setState(() => _dashboard = data);
    } on ApiException catch (error) {
      if (error.statusCode == 401 || error.statusCode == 403) {
        await _expireSession();
        return;
      }
      if (mounted) {
        setState(() => _dashboardError = 'Unable to load your dashboard.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _dashboardError = 'Unable to load your dashboard.');
      }
    } finally {
      if (mounted) setState(() => _loadingDashboard = false);
    }

    try {
      final calls = await _callHistoryService.loadCallHistory(page: 1, limit: 1);
      if (mounted) setState(() => _totalCallsAnalyzed = calls.total);
    } catch (_) {}

    _refreshNotifications();
  }

  void _refreshNotifications() {
    final list = <ScamShieldNotification>[];
    final recent = _dashboard?.recentAnalyses ?? [];

    for (final r in recent) {
      final isHigh = r.riskLevel.toUpperCase() == 'HIGH' ||
          r.classification.toUpperCase() == 'SCAM' ||
          r.riskScore >= 70;
      if (isHigh) {
        final snippet = r.content.replaceAll('\n', ' ').trim();
        final displaySnippet = snippet.length > 36 ? '${snippet.substring(0, 36)}...' : snippet;
        list.add(
          ScamShieldNotification(
            id: 'analysis-${r.id}',
            title: '⚠️ High Risk Threat Detected',
            message: 'A ${r.inputType.toUpperCase()} analysis was flagged as ${r.category.isNotEmpty ? r.category : "High Risk"}: "$displaySnippet".',
            timestamp: r.createdAt,
            icon: Icons.warning_amber_rounded,
            color: const Color(0xFFEF4444),
            isRead: _readNotificationIds.contains('analysis-${r.id}'),
          ),
        );
      } else if (r.riskLevel.toUpperCase() == 'LOW' || r.classification.toUpperCase() == 'SAFE') {
        list.add(
          ScamShieldNotification(
            id: 'analysis-${r.id}',
            title: '✓ Analysis Verified Genuine',
            message: 'Your ${r.inputType} submission was analyzed and verified safe.',
            timestamp: r.createdAt,
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF10B981),
            isRead: _readNotificationIds.contains('analysis-${r.id}'),
          ),
        );
      }
    }

    if (_guardianStatus?.enabled == true && _guardianStatus?.serviceRunning == true) {
      list.add(
        ScamShieldNotification(
          id: 'guardian-active',
          title: '🛡️ Live Call Guardian Active',
          message: 'Incoming and active call detection is running on your device.',
          timestamp: DateTime.now(),
          icon: Icons.phone_in_talk_rounded,
          color: const Color(0xFF10B981),
          isRead: _readNotificationIds.contains('guardian-active'),
        ),
      );
    }

    list.add(
      ScamShieldNotification(
        id: 'system-intel-update',
        title: '🔒 Scam Intelligence Updated',
        message: 'Security definitions for UPI, KYC, and imposter scams have been refreshed.',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        icon: Icons.shield_rounded,
        color: const Color(0xFF06B6D4),
        isRead: _readNotificationIds.contains('system-intel-update'),
      ),
    );

    if (mounted) {
      setState(() {
        _notifications = list;
      });
    }
  }

  Future<void> _loadGuardianStatus() async {
    try {
      final status = await _callBridge.getCallGuardianStatus();
      if (!mounted) return;
      setState(() {
        _guardianStatus = status;
        _bridgeError = null;
      });
    } on PlatformException {
      if (mounted) setState(() => _bridgeError = 'Native bridge unavailable.');
    } on MissingPluginException {
      if (mounted) setState(() => _bridgeError = 'Native bridge unavailable.');
    }
  }

  Future<void> _loadAudioCapability() async {
    try {
      final capability = await _callBridge.getAudioCapability();
      if (mounted) {
        setState(() {
          _audioCapability = capability;
          _audioCapabilityError = null;
        });
      }
    } on PlatformException {
      if (mounted) {
        setState(() {
          _audioCapability = null;
          _audioCapabilityError =
              'Android could not report microphone capability.';
        });
      }
    } on MissingPluginException {
      if (mounted) {
        setState(() {
          _audioCapability = null;
          _audioCapabilityError =
              'Audio protection is available only in the Android app.';
        });
      }
    }
  }

  Future<void> _loadLatestCallEvent() async {
    try {
      final event = await _callBridge.getLatestCallEvent();
      if (event != null && mounted) _handleCallEvent(event);
    } on PlatformException {
      if (mounted && _guardianStatus == null) {
        setState(() => _bridgeError = 'Native call-event status unavailable.');
      }
    } on MissingPluginException {
      if (mounted && _guardianStatus == null) {
        setState(() => _bridgeError = 'Native call-event status unavailable.');
      }
    }
  }

  void _handleCallEvent(GuardianCallEvent event) {
    if (!mounted ||
        !const {
          'CALL_RINGING',
          'CALL_ACTIVE',
          'CALL_ENDED',
        }.contains(event.event)) {
      return;
    }
    final previous = _callEvent;
    if (previous != null && previous.sessionId == event.sessionId) {
      if (previous.event == 'CALL_ENDED' ||
          !event.timestamp.isAfter(previous.timestamp) ||
          (previous.event == 'CALL_ACTIVE' && event.event == 'CALL_RINGING')) {
        return;
      }
      if (previous.event == event.event) return;
    }
    setState(() {
      _callEvent = event;
      _activeCallSeconds = event.event == 'CALL_ACTIVE'
          ? DateTime.now()
                .difference(event.timestamp)
                .inSeconds
                .clamp(0, 1 << 30)
                .toInt()
          : 0;
    });
    if (event.event == 'CALL_ACTIVE') {
      _sessionStartedAt = event.timestamp;
      _lastFinalizedSummary = null;
      _guardianTranscriptionService.startSession(
        event.sessionId,
        event.timestamp,
      );
      _guardianLiveAnalysisService.startSession(
        event.sessionId,
        event.timestamp,
      );
      _guardianProtectionService.startSession(event.sessionId);
    } else if (event.event == 'CALL_ENDED') {
      unawaited(_guardianTranscriptionService.endSession(event.sessionId));
      unawaited(_guardianLiveAnalysisService.endSession(event.sessionId));
      _guardianProtectionService.endSession(event.sessionId);

      final sessionStartedAt = _sessionStartedAt;
      final sessionDuration = sessionStartedAt != null
          ? event.timestamp
              .difference(sessionStartedAt)
              .inSeconds
              .clamp(0, 1 << 30)
              .toInt()
          : _activeCallSeconds;
      final finalResult = _analysisSnapshot?.result;
      final localHeuristic = _analysisSnapshot?.localHeuristicResult;
      final hasLocalWarning = localHeuristic != null && localHeuristic.hasMatches;
      final protectionActions =
          _guardianProtectionService.exportSessionActions();

      String analysisStatus = 'COMPLETED';
      String transcriptionStatus = 'COMPLETED';
      String audioStatus = 'AVAILABLE';

      if (_guardianStatus?.audioState == 'AUDIO_UNAVAILABLE' ||
          _guardianStatus?.audioCaptureAvailable != true) {
        audioStatus = 'AUDIO_UNAVAILABLE';
      }
      if (!_transcriptionEnabled ||
          _transcriptionSnapshot?.state == 'TRANSCRIPTION_UNAVAILABLE' ||
          _transcriptionSnapshot?.state == 'TRANSCRIPTION_ERROR') {
        transcriptionStatus = 'TRANSCRIPTION_UNAVAILABLE';
      }
      if (finalResult == null) {
        if (hasLocalWarning) {
          analysisStatus = 'OFFLINE_HEURISTIC';
        } else if (audioStatus == 'AUDIO_UNAVAILABLE') {
          analysisStatus = 'AUDIO_UNAVAILABLE';
        } else if (transcriptionStatus == 'TRANSCRIPTION_UNAVAILABLE') {
          analysisStatus = 'TRANSCRIPTION_UNAVAILABLE';
        } else if (sessionDuration < 5) {
          analysisStatus = 'INCOMPLETE';
        } else {
          analysisStatus = 'ANALYSIS_UNAVAILABLE';
        }
      }

      final payload = CallFinalizePayload(
        sessionId: event.sessionId,
        startedAt: sessionStartedAt,
        endedAt: event.timestamp,
        durationSeconds: sessionDuration,
        guardianEnabled: _guardianStatus?.enabled ?? true,
        guardianStatus: _guardianStatus?.serviceRunning == true
            ? 'RUNNING'
            : (_guardianStatus?.enabled == true ? 'ENABLED' : 'DISABLED'),
        finalRiskScore: finalResult?.riskScore ?? 0,
        finalRiskLevel: finalResult != null
            ? finalResult.riskLevel
            : (hasLocalWarning ? 'HIGH' : 'LOW'),
        classification: finalResult != null
            ? finalResult.classification
            : (hasLocalWarning ? 'SUSPICIOUS' : 'GENUINE'),
        scamCategory: finalResult != null
            ? finalResult.scamCategory
            : (hasLocalWarning && localHeuristic.matchedRules.isNotEmpty
                ? localHeuristic.matchedRules.first
                : 'General'),
        riskReasoning: finalResult?.reasoning ??
            (hasLocalWarning
                ? '[Offline Heuristic Rule] ${localHeuristic.warningHeadline}'
                : (analysisStatus == 'INCOMPLETE'
                    ? 'Call ended before conversation analysis was completed.'
                    : null)),
        safeAction: finalResult?.safeAction ?? (hasLocalWarning ? localHeuristic.safeAction : null),
        detectedIndicators: finalResult?.detectedIndicators ??
            (hasLocalWarning ? localHeuristic.matchedRules : null),
        supportingEvidence: finalResult != null &&
                finalResult.supportingEvidence.isNotEmpty
            ? finalResult.supportingEvidence
                .map((e) => {
                      'knowledge_id': e.knowledgeId,
                      'title': e.title,
                      'category': e.category,
                      'similarity': e.similarityScore,
                      'description': e.description,
                    })
                .toList()
            : null,
        protectionActions:
            protectionActions.isNotEmpty ? protectionActions : null,
        analysisStatus: analysisStatus,
        transcriptionStatus: transcriptionStatus,
        audioStatus: audioStatus,
      );
      unawaited(_finalizeCallSession(payload));
    }
    _callTimer?.cancel();
    if (event.event == 'CALL_ACTIVE') {
      _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted || _callEvent?.sessionId != event.sessionId) return;
        setState(() {
          _activeCallSeconds = DateTime.now()
              .difference(event.timestamp)
              .inSeconds
              .clamp(0, 1 << 30)
              .toInt();
        });
      });
    }
  }

  Future<void> _finalizeCallSession(CallFinalizePayload payload) async {
    if (_callHistoryService.isSessionFinalized(payload.sessionId)) return;
    try {
      final detail = await _callHistoryService.finalizeCallSession(payload);
      if (mounted) {
        setState(() {
          _lastFinalizedSummary = detail;
          _historyRevision++;
        });
      }
    } catch (_) {
      // Offline / network failure: retain local summary from payload so user still has summary
      if (mounted) {
        setState(() {
          _lastFinalizedSummary = CallHistoryDetail(
            id: 0,
            sessionId: payload.sessionId,
            startedAt: payload.startedAt,
            endedAt: payload.endedAt ?? DateTime.now(),
            durationSeconds: payload.durationSeconds,
            guardianEnabled: payload.guardianEnabled,
            guardianStatus: payload.guardianStatus,
            finalRiskScore: payload.finalRiskScore,
            finalRiskLevel: payload.finalRiskLevel,
            classification: payload.classification,
            scamCategory: payload.scamCategory,
            riskReasoning: payload.riskReasoning,
            safeAction: payload.safeAction,
            detectedIndicators: payload.detectedIndicators ?? const [],
            supportingEvidence: payload.supportingEvidence ?? const [],
            protectionActions: payload.protectionActions ?? const [],
            analysisStatus: payload.analysisStatus,
            transcriptionStatus: payload.transcriptionStatus,
            audioStatus: payload.audioStatus,
          );
          _historyRevision++;
        });
      }
    }
  }

  void _openCallDetail(CallHistoryDetail detail) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CallSummaryScreen(
          call: detail,
          callHistoryService: _callHistoryService,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _requestCallScreeningRole() async {
    try {
      final status = await _callBridge.requestCallScreeningRole();
      if (mounted) setState(() => _guardianStatus = status);
    } on PlatformException {
      _showGuardianError('Could not open call-screening setup. Please retry.');
      await _loadGuardianStatus();
    } on MissingPluginException {
      _showGuardianError(
        'Call screening is available only in the Android app.',
      );
    }
  }

  Future<void> _toggleGuardian(bool enabled) async {
    if (!enabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable Call Guardian?'),
          content: const Text(
            'Live call monitoring and real-time scam warnings will be stopped. You can re-enable Guardian anytime.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('KEEP ON'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('DISABLE'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    if (!enabled && _transcriptionEnabled) {
      await _guardianTranscriptionService.setEnabled(false);
      await _guardianLiveAnalysisService.setEnabled(false);
      if (!mounted) return;
      setState(() => _transcriptionEnabled = false);
    }
    if (enabled) {
      final consented = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable Guardian?'),
          content: const Text(
            'Guardian uses the required Android permissions to detect supported call activity. This call-state monitor does not access call audio; optional device-microphone capture is a separate setting with its own permission and consent. Guardian does not read conversations or block or end calls. Android shows a notification while Guardian is enabled.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('NOT NOW'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('CONTINUE'),
            ),
          ],
        ),
      );
      if (consented != true || !mounted) return;

      try {
        final permissions = await _callBridge.requestGuardianPermissions();
        if (!permissions.phoneStatePermissionGranted ||
            !permissions.notificationsPermissionGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Phone-state and notification permissions are required to enable Guardian.',
                ),
                action: SnackBarAction(
                  label: 'APP SETTINGS',
                  onPressed: () => unawaited(_openGuardianAppSettings()),
                ),
              ),
            );
            setState(() => _guardianStatus = permissions);
          }
          return;
        }
      } on PlatformException {
        _showGuardianError(
          'Could not request Guardian permissions. Please retry.',
        );
        return;
      } on MissingPluginException {
        _showGuardianError('Guardian is available only in the Android app.');
        return;
      }
    }

    try {
      final status = await _callBridge.setGuardianEnabled(enabled);
      if (mounted) setState(() => _guardianStatus = status);
    } on PlatformException catch (error) {
      if (error.code == 'UNSUPPORTED_DEVICE') {
        _showGuardianError(
          'This device does not support phone call-state monitoring.',
        );
      } else if (error.code == 'PERMISSION_REQUIRED') {
        _showGuardianError(
          'Grant the required Android permissions to continue.',
        );
      } else {
        _showGuardianError('Could not update Guardian. Please retry.');
      }
      await _loadGuardianStatus();
    } on MissingPluginException {
      _showGuardianError('Guardian is available only in the Android app.');
    }
  }

  Future<void> _toggleAudioProtection(bool enabled) async {
    if (enabled) {
      final capability = _audioCapability;
      if (capability == null || !capability.supported) {
        _showGuardianError('Audio protection unavailable on this device.');
        return;
      }
      final consented = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Enable microphone audio protection?'),
          content: const Text(
            'With your permission, ScamShield will capture device microphone input only while Guardian detects an active call. This is not direct access to cellular call audio. If you want nearby call audio picked up, you must turn on speakerphone yourself; Android or the device may still limit what the microphone receives. Audio is held in a small, bounded in-memory buffer and is not uploaded or saved as a recording in this milestone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('CONTINUE'),
            ),
          ],
        ),
      );
      if (consented != true || !mounted) return;
      if (_guardianStatus?.audioPermissionGranted != true) {
        try {
          final permission = await _callBridge.requestAudioPermission();
          if (permission['permissionGranted'] != true) {
            final permanentlyDenied =
                permission['permissionStatus'] == 'DENIED_PERMANENTLY';
            _showGuardianError(
              permanentlyDenied
                  ? 'Microphone permission is blocked. Open app settings to allow it.'
                  : 'Microphone permission is required for audio protection.',
            );
            if (permanentlyDenied) {
              await _openGuardianAppSettings();
            }
            await _loadGuardianStatus();
            return;
          }
        } on PlatformException {
          _showGuardianError('Could not request microphone permission.');
          return;
        } on MissingPluginException {
          _showGuardianError(
            'Audio protection is available only in the Android app.',
          );
          return;
        }
      }
    }
    if (!enabled && _transcriptionEnabled) {
      await _guardianTranscriptionService.setEnabled(false);
      await _guardianLiveAnalysisService.setEnabled(false);
      if (mounted) setState(() => _transcriptionEnabled = false);
    }

    try {
      final status = await _callBridge.setAudioPipelineEnabled(enabled);
      if (mounted) setState(() => _guardianStatus = status);
    } on PlatformException catch (error) {
      _showGuardianError(
        error.code == 'AUDIO_SERVICE_UNAVAILABLE'
            ? 'Android could not start audio protection. Guardian call detection remains available.'
            : 'Could not update audio protection. Please try again.',
      );
      await _loadGuardianStatus();
    } on MissingPluginException {
      _showGuardianError(
        'Audio protection is available only in the Android app.',
      );
    }
  }

  Future<void> _toggleTranscription(bool enabled) async {
    if (!enabled) {
      await _guardianTranscriptionService.setEnabled(false);
      await _guardianLiveAnalysisService.setEnabled(false);
      if (mounted) setState(() => _transcriptionEnabled = false);
      return;
    }
    if (_guardianStatus?.audioProtectionEnabled != true) {
      _showGuardianError(
        'Enable microphone audio protection before live transcription.',
      );
      return;
    }
    final consented = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enable live transcription?'),
        content: const Text(
          'With your consent, ScamShield captures speakerphone audio during active calls and sends temporary 5-second PCM chunks to your configured ScamShield server for Whisper transcription and real-time scam analysis. Transcripts are held in ephemeral memory for the duration of the call and never saved to your account. For best results, place your phone on speakerphone so incoming speech can be analyzed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('CONTINUE'),
          ),
        ],
      ),
    );
    if (consented != true || !mounted) return;
    await _guardianTranscriptionService.setEnabled(true);
    await _guardianLiveAnalysisService.setEnabled(true);
    if (mounted) setState(() => _transcriptionEnabled = true);
  }

  Future<void> _retryAudioProtection() async {
    try {
      await _callBridge.setAudioPipelineEnabled(false);
      final status = await _callBridge.setAudioPipelineEnabled(true);
      if (mounted) setState(() => _guardianStatus = status);
    } on PlatformException catch (error) {
      if (error.code == 'PERMISSION_REQUIRED') {
        _showGuardianError(
          'Microphone permission is required. Allow it in app settings, then retry.',
        );
        await _openGuardianAppSettings();
        return;
      }
      _showGuardianError(
        error.code == 'AUDIO_SERVICE_UNAVAILABLE'
            ? 'Android could not restart microphone capture.'
            : 'Could not restart microphone capture. Please try again.',
      );
      await _loadGuardianStatus();
    } on MissingPluginException {
      _showGuardianError(
        'Audio protection is available only in the Android app.',
      );
    }
  }

  void _showGuardianError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openGuardianAppSettings() async {
    try {
      await _callBridge.openAppSettings();
    } on PlatformException {
      _showGuardianError('Could not open app settings. Please retry.');
    } on MissingPluginException {
      _showGuardianError(
        'Android app settings are unavailable on this platform.',
      );
    }
  }

  Future<void> _expireSession() async {
    if (_handlingExpiredSession) return;
    _handlingExpiredSession = true;
    await widget.onSessionExpired();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 18,
        title: const _BrandTitle(),
        actions: [
          IconButton(
            tooltip: widget.isDarkMode
                ? 'Switch to light theme'
                : 'Switch to dark theme',
            onPressed: widget.onToggleTheme,
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: _showNotificationCenter,
            icon: _notifications.where((n) => !n.isRead).isNotEmpty
                ? Badge(
                    label: Text(
                      '${_notifications.where((n) => !n.isRead).length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    backgroundColor: Theme.of(context).colorScheme.error,
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_none_rounded),
          ),
          PopupMenuButton<_ProfileAction>(
            tooltip: 'Profile and settings',
            onSelected: _handleProfileAction,
            itemBuilder: (context) => [
              PopupMenuItem(
                enabled: false,
                child: SizedBox(
                  width: 210,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        widget.user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _ProfileAction.profile,
                child: ListTile(
                  leading: Icon(Icons.person_outline_rounded),
                  title: Text('Profile'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: _ProfileAction.settings,
                child: ListTile(
                  leading: Icon(Icons.settings_outlined),
                  title: Text('Settings'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: _ProfileAction.community,
                child: ListTile(
                  leading: Icon(Icons.people_outline_rounded),
                  title: Text('Community'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: _ProfileAction.help,
                child: ListTile(
                  leading: Icon(Icons.help_outline_rounded),
                  title: Text('Help & Support'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _ProfileAction.logout,
                child: ListTile(
                  leading: Icon(Icons.logout_rounded),
                  title: Text('Logout'),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: CircleAvatar(
                radius: 17,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  widget.user.fullName.trim().isEmpty
                      ? '?'
                      : widget.user.fullName.trim()[0].toUpperCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboard(context),
          AnalyzeScreen(
            key: ValueKey('analyze-$_selectedAnalysisType'),
            analysisService: widget.analysisService,
            initialType: _selectedAnalysisType,
            onSessionExpired: _expireSession,
            onAnalysisCompleted: _loadDashboard,
            onBackToDashboard: () => _returnToTab(0),
          ),
          HistoryScreen(
            key: ValueKey('history-$_historyRevision'),
            analysisService: widget.analysisService,
            callHistoryService: _callHistoryService,
            onSessionExpired: _expireSession,
            onBackToDashboard: () => _returnToTab(0),
            onAnalyzeAnother: () => _returnToTab(1),
            onOpenGuardian: () => _returnToTab(3),
          ),
          SentinelScreen(
            status: _guardianStatus,
            audioCapability: _audioCapability,
            audioCapabilityError: _audioCapabilityError,
            error: _bridgeError,
            callEvent: _callEvent,
            activeCallSeconds: _activeCallSeconds,
            onRetry: _loadGuardianStatus,
            onToggleGuardian: _toggleGuardian,
            onToggleAudioProtection: _toggleAudioProtection,
            onRetryAudioProtection: _retryAudioProtection,
            transcriptionEnabled: _transcriptionEnabled,
            transcriptionSnapshot: _transcriptionSnapshot,
            analysisSnapshot: _analysisSnapshot,
            protectionService: _guardianProtectionService,
            onToggleTranscription: _toggleTranscription,
            onOpenSettings: () => _openSettings(),
            onRequestCallScreeningRole: _requestCallScreeningRole,
            onDismissCallEnded: () =>
                _guardianLiveAnalysisService.dismissCallEndedResult(),
            onRetryAnalysis: () => _guardianLiveAnalysisService.retry(
              segment: _transcriptionSnapshot?.segments.lastOrNull,
            ),
            lastFinalizedSummary: _lastFinalizedSummary,
            onViewCallSummary: _lastFinalizedSummary != null
                ? () => _openCallDetail(_lastFinalizedSummary!)
                : null,
          ),
          ProfileScreen(
            key: const ValueKey('profile-tab'),
            user: widget.user,
            isDarkMode: widget.isDarkMode,
            onToggleTheme: widget.onToggleTheme,
            onLogout: widget.onLogout,
            protectionService: _guardianProtectionService,
            notificationService: _notificationService,
            communityService: _communityService,
            callBridge: _callBridge,
            authService: _authService,
            onOpenGuardian: () => _returnToTab(3),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() {
          _selectedIndex = index;
          if (index == 2) _historyRevision++;
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.manage_search_rounded),
            label: 'Analyze',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Guardian',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }

  Future<void> _handleProfileAction(_ProfileAction action) async {
    switch (action) {
      case _ProfileAction.profile:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ProfileScreen(
              user: widget.user,
              isDarkMode: widget.isDarkMode,
              onToggleTheme: widget.onToggleTheme,
              onLogout: widget.onLogout,
              protectionService: _guardianProtectionService,
              notificationService: _notificationService,
              communityService: _communityService,
              callBridge: _callBridge,
              authService: _authService,
              onOpenGuardian: () => _returnToTab(3),
            ),
          ),
        );
      case _ProfileAction.settings:
        await _openSettings();
      case _ProfileAction.community:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => CommunityScreen(
              communityService: _communityService,
            ),
          ),
        );
      case _ProfileAction.help:
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => const HelpSupportScreen(),
          ),
        );
      case _ProfileAction.logout:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Log out of ScamShield?'),
            content: const Text(
              'You will need to sign in again to access your analysis and call protection history.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('CANCEL'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('LOG OUT'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) return;
        try {
          await widget.onLogout();
        } catch (_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not sign out. Please try again.'),
              ),
            );
          }
        }
    }
  }

  Future<void> _openSettings() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => SettingsScreen(
        protectionService: _guardianProtectionService,
        notificationService: _notificationService,
        isDarkMode: widget.isDarkMode,
        onToggleTheme: widget.onToggleTheme,
        callBridge: _callBridge,
        onOpenGuardian: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          if (mounted) setState(() => _selectedIndex = 3);
        },
      ),
    ),
  );

  void _showNotificationCenter() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final bg = isDark ? const Color(0xFF111827) : Colors.white;
            final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
            final unread = _notifications.where((n) => !n.isRead).length;

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 6, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.notifications_active_outlined,
                              color: Color(0xFF06B6D4),
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_notifications.isNotEmpty && unread > 0) ...[
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    for (final n in _notifications) {
                                      _readNotificationIds.add(n.id);
                                    }
                                    _notifications = _notifications
                                        .map((n) => n.copyWith(isRead: true))
                                        .toList();
                                  });
                                  setSheetState(() {});
                                },
                                icon: const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF06B6D4)),
                                label: const Text(
                                  'Clear All',
                                  style: TextStyle(
                                    color: Color(0xFF06B6D4),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              tooltip: 'Close',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: _notifications.isEmpty || unread == 0
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.done_all_rounded,
                                    color: Color(0xFF06B6D4),
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'All caught up!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No unread security alerts at this time.\nStay alert and informed.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shrinkWrap: true,
                            itemCount: _notifications.length,
                            separatorBuilder: (_, _) => Divider(
                              height: 1,
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            ),
                            itemBuilder: (context, index) {
                              final item = _notifications[index];
                              return Material(
                                color: Colors.transparent,
                                child: ListTile(
                                  leading: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: item.color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(item.icon, color: item.color, size: 20),
                                  ),
                                  title: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  subtitle: Text(
                                    item.message,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  trailing: item.isRead
                                      ? null
                                      : Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF06B6D4),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                  onTap: () {
                                    setState(() {
                                      _readNotificationIds.add(item.id);
                                      _notifications[index] = item.copyWith(isRead: true);
                                    });
                                    setSheetState(() {});
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDashboard(BuildContext context) {
    return HomeDashboardView(
      user: widget.user,
      dashboard: _dashboard,
      loadingDashboard: _loadingDashboard,
      dashboardError: _dashboardError,
      guardianStatus: _guardianStatus,
      totalCallsAnalyzed: _totalCallsAnalyzed,
      onRefresh: _loadDashboard,
      onOpenAnalyze: _openAnalyze,
      onOpenGuardian: () => _returnToTab(3),
      onOpenHistory: () => _returnToTab(2),
      onOpenAnalysisResult: (record) => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AnalysisResultScreen(
            analysis: record,
            onBackToDashboard: () => _returnToTab(0),
            onAnalyzeAnother: () => _returnToTab(1),
          ),
        ),
      ),
      isDarkMode: widget.isDarkMode,
      onToggleTheme: widget.onToggleTheme,
      onOpenProfile: () => _returnToTab(4),
      onOpenSettings: _openSettings,
      onLogout: widget.onLogout,
    );
  }

  void _returnToTab(int index) {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    if (mounted) {
      setState(() {
        _selectedIndex = index;
        if (index == 2) _historyRevision++;
      });
    }
  }

  void _openAnalyze(String type) {
    setState(() {
      _selectedAnalysisType = type;
      _selectedIndex = 1;
    });
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ScamShieldBrandMark(size: 26),
        const SizedBox(width: 8),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'SCAMSHIELD',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  'AI-POWERED SCAM PROTECTION',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

