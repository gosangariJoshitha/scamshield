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
import '../sentinel/call_report_screen.dart';
import '../sentinel/live_call_monitoring_screen.dart';
import '../sentinel/sentinel_screen.dart';
import '../../theme/app_colors.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../notifications/notification_screen.dart';
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
    this.secureStorage,
    this.callBridge,
    super.key,
  });

  final User user;
  final AnalysisService analysisService;
  final CallHistoryService? callHistoryService;
  final AuthService? authService;
  final NotificationService? notificationService;
  final CommunityService? communityService;
  final FlutterSecureStorage? secureStorage;
  final CallBridge? callBridge;
  final Future<void> Function() onLogout;
  final Future<void> Function() onSessionExpired;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late final CallBridge _callBridge;
  late final FlutterSecureStorage _secureStorage;
  bool _showCyberHelpline = true;
  int _unreadNotificationCount = 0;
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


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _callBridge = widget.callBridge ?? CallBridge();
    _secureStorage = widget.secureStorage ?? const FlutterSecureStorage();
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
          if (result.riskLevel == 'CRITICAL' || result.riskScore >= 80) {
            unawaited(_callBridge.updateFloatingGuardian(
              state: 'CRITICAL',
              title: 'CRITICAL: ${result.riskScore}',
              riskScore: result.riskScore,
            ));
          } else if (result.riskLevel == 'HIGH' || result.riskScore >= 70) {
            unawaited(_callBridge.updateFloatingGuardian(
              state: 'SUSPICIOUS',
              title: 'HIGH RISK: ${result.riskScore}',
              riskScore: result.riskScore,
            ));
          } else {
            unawaited(_callBridge.updateFloatingGuardian(
              state: 'MONITORING',
              title: 'LIVE: ${result.riskScore}',
              riskScore: result.riskScore,
            ));
          }
          final currentSessionId = _callEvent?.sessionId;
          final isCallActive = _callEvent?.event == 'CALL_ACTIVE';
          if (isCallActive &&
              currentSessionId != null &&
              _guardianProtectionService.settings.autoDisconnectHighRisk) {
            final isTrigger = result.riskLevel == 'HIGH' ||
                result.riskLevel == 'CRITICAL' ||
                result.riskScore >=
                    _guardianProtectionService.settings.autoDisconnectThreshold;
            if (isTrigger &&
                !_guardianProtectionService.isAutoDisconnected(currentSessionId)) {
              unawaited(_triggerAutoDisconnect(currentSessionId, result));
            }
          }
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
    _loadCyberHelplineState();
    _loadUnreadNotificationCount();
    _checkPendingAction();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      setState(() {
        _unreadNotificationCount = 0;
        _dashboard = null;
        _showCyberHelpline = true;
      });
      _loadUnreadNotificationCount();
      _loadDashboard();
      _loadCyberHelplineState();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadGuardianStatus();
      _loadAudioCapability();
      _checkPendingAction();
    }
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

    _loadUnreadNotificationCount();
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() => _unreadNotificationCount = count);
      }
    } catch (_) {
      // Retain existing count on network error
    }
  }

  Future<void> _loadCyberHelplineState() async {
    try {
      final dismissed = await _secureStorage.read(
        key: 'cyber_helpline_dismissed_${widget.user.id}',
      );
      if (mounted) {
        setState(() {
          _showCyberHelpline = dismissed != 'true';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _showCyberHelpline = true;
        });
      }
    }
  }

  Future<void> _handleCyberHelplineDial() async {
    final success = await _callBridge.launchDialer('1930');
    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening phone dialer for National Cyber Helpline 1930...'),
          duration: Duration(seconds: 3),
        ),
      );
      await _dismissCyberHelpline();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Could not open phone dialer. National Cyber Helpline is 1930.'),
          action: SnackBarAction(
            label: 'Copy 1930',
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: '1930'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Helpline number 1930 copied to clipboard.')),
              );
            },
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Future<void> _dismissCyberHelpline() async {
    setState(() {
      _showCyberHelpline = false;
    });
    try {
      await _secureStorage.write(
        key: 'cyber_helpline_dismissed_${widget.user.id}',
        value: 'true',
      );
    } catch (_) {}
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
      unawaited(_callBridge.updateFloatingGuardian(
        state: 'CALL_DETECTED',
        title: 'Protect Call',
      ));
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
    } else if (event.event == 'CALL_RINGING') {
      unawaited(_callBridge.updateFloatingGuardian(
        state: 'CALL_DETECTED',
        title: 'Protect Call',
      ));
    } else if (event.event == 'CALL_ENDED') {
      unawaited(_callBridge.setSpeakerphoneEnabled(false));
      unawaited(_callBridge.updateFloatingGuardian(
        state: 'NORMAL',
        title: 'ScamShield',
      ));
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

  Future<void> _triggerAutoDisconnect(
    String sessionId,
    GuardianLiveAnalysisResult result,
  ) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🚨 High Scam Risk (${result.riskScore}/100) detected! Auto-disconnecting call for your protection...',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: const Color(0xFFDC2626),
        duration: const Duration(seconds: 4),
      ),
    );
    await _guardianProtectionService.autoDisconnectIfHighRisk(
      sessionId: sessionId,
      riskLevel: result.riskLevel,
      riskScore: result.riskScore,
      reasoning: result.reasoning,
    );
  }

  void _autoOpenReportScreen(CallHistoryDetail detail) {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CallReportScreen(
          call: detail,
          protectionService: _guardianProtectionService,
          onViewHistory: () {
            Navigator.of(context).pop();
            _returnToTab(2);
          },
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _checkPendingAction() async {
    try {
      final actionData = await _callBridge.getInitialAction();
      final action = actionData?['action'];
      if (action == 'PROTECT_CALL' && mounted) {
        await _onProtectCallTapped();
      }
    } catch (_) {}
  }

  Future<void> _onProtectCallTapped() async {
    if (!mounted) return;
    setState(() => _selectedIndex = 3);

    final isCallActive = _callEvent?.event == 'CALL_ACTIVE' || _callEvent?.event == 'CALL_RINGING';
    if (isCallActive) {
      final audioAlreadyEnabled = _guardianStatus?.audioProtectionEnabled == true;
      if (!audioAlreadyEnabled) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) {
            final isDark = Theme.of(ctx).brightness == Brightness.dark;
            return AlertDialog(
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.volume_up_rounded, color: Color(0xFF0284C7), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Start Call Protection?',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              content: const Text(
                'Speaker mode will be enabled for live call protection. ScamShield will analyze incoming conversation in real-time to alert you of potential scams.',
                style: TextStyle(fontFamily: 'Inter', fontSize: 13.5, height: 1.45),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  icon: const Icon(Icons.shield_rounded, size: 18),
                  label: const Text('Start Protection'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0284C7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            );
          },
        );
        if (confirmed != true || !mounted) return;
        await _toggleAudioProtection(true);
        await _callBridge.setSpeakerphoneEnabled(true);
      }
      if (mounted) {
        _openLiveMonitoringScreen();
      }
    }
  }

  void _openLiveMonitoringScreen() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveCallMonitoringScreen(
          callEvent: _callEvent,
          activeCallSeconds: _activeCallSeconds,
          analysisSnapshot: _analysisSnapshot,
          segments: _transcriptionSnapshot?.segments ?? const [],
          protectionService: _guardianProtectionService,
          onBack: () => Navigator.of(context).pop(),
          onEndCall: () {
            final sid = _callEvent?.sessionId;
            if (sid != null) {
              _guardianProtectionService.executeEndCall(sessionId: sid);
            }
          },
        ),
      ),
    );
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
        if (detail.finalRiskLevel == 'HIGH' ||
            detail.finalRiskLevel == 'CRITICAL' ||
            detail.finalRiskScore >= 70 ||
            _guardianProtectionService.isAutoDisconnected(detail.sessionId)) {
          _autoOpenReportScreen(detail);
        }
      }
    } catch (_) {
      // Offline / network failure: retain local summary from payload so user still has summary
      if (mounted) {
        final fallbackDetail = CallHistoryDetail(
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
        setState(() {
          _lastFinalizedSummary = fallbackDetail;
          _historyRevision++;
        });
        if (fallbackDetail.finalRiskLevel == 'HIGH' ||
            fallbackDetail.finalRiskLevel == 'CRITICAL' ||
            fallbackDetail.finalRiskScore >= 70 ||
            _guardianProtectionService.isAutoDisconnected(payload.sessionId)) {
          _autoOpenReportScreen(fallbackDetail);
        }
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
          title: const Text('Disable Call Sentinel?'),
          content: const Text(
            'Live call monitoring and real-time scam warnings will be stopped. You can re-enable Sentinel anytime.',
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
          title: const Text('Enable Sentinel?'),
          content: const Text(
            'Sentinel uses the required Android permissions to detect supported call activity. This call-state monitor does not access call audio; optional device-microphone capture is a separate setting with its own permission and consent. Sentinel does not read private conversations or block calls without permission. Android shows a notification while Sentinel is enabled.',
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
                  'Phone-state and notification permissions are required to enable Sentinel.',
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
          'Could not request Sentinel permissions. Please retry.',
        );
        return;
      } on MissingPluginException {
        _showGuardianError('Sentinel is available only in the Android app.');
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
        _showGuardianError('Could not update Sentinel. Please retry.');
      }
      await _loadGuardianStatus();
    } on MissingPluginException {
      _showGuardianError('Sentinel is available only in the Android app.');
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
            'With your permission, ScamShield will capture device microphone input only while Sentinel detects an active call. This is not direct access to cellular call audio. If you want nearby call audio picked up, you must turn on speakerphone yourself; Android or the device may still limit what the microphone receives. Audio is held in a small, bounded in-memory buffer and is not uploaded or saved as a recording in this milestone.',
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
            ? 'Android could not start audio protection. Sentinel call detection remains available.'
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
            onPressed: _openNotificationScreen,
            icon: _unreadNotificationCount > 0
                ? Badge(
                    label: Text(
                      '$_unreadNotificationCount',
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
      body: Column(
        children: [
          if (_callEvent != null &&
              (_callEvent!.event == 'CALL_ACTIVE' || _callEvent!.event == 'CALL_RINGING'))
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _analysisSnapshot?.result != null &&
                          (_analysisSnapshot!.result!.riskLevel == 'CRITICAL' ||
                              _analysisSnapshot!.result!.riskLevel == 'HIGH')
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF0284C7),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _analysisSnapshot?.result != null &&
                              (_analysisSnapshot!.result!.riskLevel == 'CRITICAL' ||
                                  _analysisSnapshot!.result!.riskLevel == 'HIGH')
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF0284C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.phone_in_talk_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _callEvent!.event == 'CALL_RINGING'
                              ? 'Incoming Call Detected'
                              : 'Active Call in Progress',
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          _analysisSnapshot?.result != null
                              ? 'Risk: ${_analysisSnapshot!.result!.riskScore}/100 (${_analysisSnapshot!.result!.riskLevel})'
                              : 'Tap to activate live AI shield',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: _analysisSnapshot?.result != null &&
                                    (_analysisSnapshot!.result!.riskLevel == 'CRITICAL' ||
                                        _analysisSnapshot!.result!.riskLevel == 'HIGH')
                                ? const Color(0xFFFCA5A5)
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _onProtectCallTapped,
                    icon: const Icon(Icons.shield_rounded, size: 14),
                    label: const Text('Protect Call'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0284C7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      textStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: IndexedStack(
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
            label: 'Sentinel',
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

  Future<void> _openNotificationScreen() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => NotificationScreen(
          notificationService: _notificationService,
          onOpenAnalysis: (id) => _openAnalysisDetails(id),
          onOpenCallSummary: (sessionId) => _openCallSummary(sessionId),
        ),
      ),
    );
    if (mounted) {
      await _loadUnreadNotificationCount();
    }
  }

  Future<void> _openAnalysisDetails(int analysisId) async {
    try {
      final record = await widget.analysisService.getAnalysis(analysisId);
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => AnalysisResultScreen(
            analysis: record,
            onBackToDashboard: () => _returnToTab(0),
            onAnalyzeAnother: () => _returnToTab(1),
          ),
        ),
      );
    } catch (_) {
      if (mounted) _returnToTab(2);
    }
  }

  Future<void> _openCallSummary(String sessionId) async {
    try {
      final detail = await _callHistoryService.getCallSummary(sessionId);
      if (!mounted) return;
      _openCallDetail(detail);
    } catch (_) {
      if (mounted) _returnToTab(2);
    }
  }

  Widget _buildDashboard(BuildContext context) {
    return HomeDashboardView(
      user: widget.user,
      dashboard: _dashboard,
      loadingDashboard: _loadingDashboard,
      dashboardError: _dashboardError,
      guardianStatus: _guardianStatus,
      totalCallsAnalyzed: _totalCallsAnalyzed,
      showCyberHelpline: _showCyberHelpline,
      onDismissCyberHelpline: _dismissCyberHelpline,
      onDialCyberHelpline: _handleCyberHelplineDial,
      onToggleProtection: _toggleGuardian,
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

