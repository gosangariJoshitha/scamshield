import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/analysis_record.dart';
import '../../models/user.dart';
import '../../native/call_bridge.dart';
import '../../services/analysis_service.dart';
import '../../services/api_service.dart';
import '../../services/guardian_audio_service.dart';
import '../../services/guardian_transcription_service.dart';
import '../../models/guardian_analysis_models.dart';
import '../../services/guardian_live_analysis_service.dart';
import '../../services/guardian_protection_service.dart';
import '../../widgets/guardian_live_risk_card.dart';
import '../../widgets/brand_mark.dart';
import '../analyze/analyze_screen.dart';
import '../history/history_screen.dart';
import '../history/call_summary_screen.dart';
import '../profile/profile_screen.dart';
import '../results/analysis_result_screen.dart';
import '../settings/settings_screen.dart';
import '../../models/call_history_models.dart';
import '../../services/call_history_service.dart';
import '../../widgets/skeleton_loaders.dart';

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
    super.key,
  });

  final User user;
  final AnalysisService analysisService;
  final CallHistoryService? callHistoryService;
  final Future<void> Function() onLogout;
  final Future<void> Function() onSessionExpired;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
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
  DateTime? _sessionStartedAt;
  CallHistoryDetail? _lastFinalizedSummary;
  int _selectedIndex = 0;
  int _historyRevision = 0;
  String _selectedAnalysisType = 'text';
  bool _loadingDashboard = true;
  bool _handlingExpiredSession = false;
  bool _transcriptionEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _callHistoryService = widget.callHistoryService ??
        CallHistoryService(
          api: widget.analysisService.api,
          tokenProvider: widget.analysisService.tokenProvider,
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
        if (audioStatus == 'AUDIO_UNAVAILABLE') {
          analysisStatus = 'AUDIO_UNAVAILABLE';
        } else if (transcriptionStatus == 'TRANSCRIPTION_UNAVAILABLE') {
          analysisStatus = 'TRANSCRIPTION_UNAVAILABLE';
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
        finalRiskLevel: finalResult?.riskLevel ?? 'LOW',
        classification: finalResult?.classification ?? 'GENUINE',
        scamCategory: finalResult?.scamCategory ?? 'General',
        riskReasoning: finalResult?.reasoning,
        safeAction: finalResult?.safeAction,
        detectedIndicators: finalResult?.detectedIndicators,
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
      // Offline / network failure handled gracefully
    }
  }

  void _openCallDetail(CallHistoryDetail detail) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CallSummaryScreen(
          call: detail,
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
          'Supported call audio will be sent to your configured ScamShield server for temporary transcription. The server uses its configured Faster-Whisper model, keeps retry data in memory for up to 10 minutes, and does not save transcripts to your account. The current Android pipeline provides device-microphone audio only, not cellular-call audio, so transcription will remain unavailable for this call and microphone audio will not be uploaded.',
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
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
            key: const ValueKey('analyze'),
            analysisService: widget.analysisService,
            initialType: _selectedAnalysisType,
            onSessionExpired: _expireSession,
            onAnalysisCompleted: _loadDashboard,
            onBackToDashboard: () => _returnToTab(0),
          ),
          _GuardianSection(
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
            onDismissCallEnded: () => _guardianLiveAnalysisService.dismissCallEndedResult(),
            lastFinalizedSummary: _lastFinalizedSummary,
            onViewCallSummary: _lastFinalizedSummary != null
                ? () => _openCallDetail(_lastFinalizedSummary!)
                : null,
          ),
          HistoryScreen(
            key: ValueKey('history-$_historyRevision'),
            analysisService: widget.analysisService,
            callHistoryService: _callHistoryService,
            onSessionExpired: _expireSession,
            onBackToDashboard: () => _returnToTab(0),
            onAnalyzeAnother: () => _returnToTab(1),
            onOpenGuardian: () => _returnToTab(2),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() {
          _selectedIndex = index;
          if (index == 3) _historyRevision++;
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
            icon: Icon(Icons.shield_outlined),
            selectedIcon: Icon(Icons.shield_rounded),
            label: 'Guardian',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
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
            ),
          ),
        );
      case _ProfileAction.settings:
        await _openSettings();
      case _ProfileAction.community:
        _showNotice(
          'Community',
          'Community features are coming soon. Community activity is not shown in the mobile app yet.',
        );
      case _ProfileAction.help:
        _showHelpSupport();
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
        onOpenGuardian: () {
          Navigator.of(context).popUntil((route) => route.isFirst);
          if (mounted) setState(() => _selectedIndex = 2);
        },
      ),
    ),
  );

  void _showHelpSupport() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _HelpTopic(
                title: 'How ScamShield works',
                description: 'Submit a suspicious message or file to receive a risk assessment and safety guidance.',
              ),
              _HelpTopic(
                title: 'Analysis help',
                description: 'Results are guidance, not a guarantee. Verify urgent requests through an independent trusted channel.',
              ),
              _HelpTopic(
                title: 'Guardian help',
                description: 'When enabled, Guardian monitors supported call states. It does not access call audio or control calls.',
              ),
              _HelpTopic(
                title: 'Privacy & security',
                description: 'Do not submit passwords, one-time codes, or payment card details for analysis.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  void _showNotice(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: RefreshIndicator(
        onRefresh: _loadDashboard,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_dashboardError != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: colors.errorContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.wifi_off_rounded, size: 18, color: colors.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Offline mode — Some live data may be temporarily unavailable.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: colors.onSurface,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadDashboard,
                              child: const Text('Retry', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    _WelcomeCard(
                      name: _firstName(widget.user.fullName),
                      guardianStatus: _guardianStatus,
                      onOpenGuardian: () => setState(() => _selectedIndex = 2),
                    ),
                    const SizedBox(height: 16),
                    _AnalyzeCta(onTap: () => _openAnalyze('text')),
                    const SizedBox(height: 22),
                    Text(
                      'Quick Actions',
                      style: Theme.of(context).textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 11),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 680 ? 4 : 2;
                        final actions = [
                          _QuickAction(
                            title: 'Text',
                            subtitle: 'Analyze messages and links',
                            icon: Icons.chat_bubble_outline_rounded,
                            color: const Color(0xFF1AA77A),
                            onTap: () => _openAnalyze('text'),
                          ),
                          _QuickAction(
                            title: 'Image',
                            subtitle: 'Upload images or screenshots',
                            icon: Icons.image_outlined,
                            color: const Color(0xFF168ED0),
                            onTap: () => _openAnalyze('image'),
                          ),
                          _QuickAction(
                            title: 'PDF',
                            subtitle: 'Analyze documents and files',
                            icon: Icons.picture_as_pdf_outlined,
                            color: const Color(0xFF8151D9),
                            onTap: () => _openAnalyze('pdf'),
                          ),
                          _QuickAction(
                            title: 'Audio',
                            subtitle: 'Check voice messages',
                            icon: Icons.graphic_eq_rounded,
                            color: const Color(0xFFE35C66),
                            onTap: () => _openAnalyze('audio'),
                          ),
                        ];
                        return GridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: columns == 2 ? 1.05 : 1.3,
                          children: actions,
                        );
                      },
                    ),
                    if (_dashboardError != null && _dashboard != null) ...[
                      const SizedBox(height: 10),
                      _DashboardFailure(
                        message: 'Unable to load your dashboard.',
                        onRetry: _loadDashboard,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Your Activity Overview',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loadingDashboard && _dashboard == null)
                      const _DashboardLoading()
                    else if (_dashboardError != null && _dashboard == null)
                      _DashboardFailure(
                        message: 'Unable to load your dashboard.',
                        onRetry: _loadDashboard,
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final stats = _dashboard?.stats;
                          return GridView.count(
                            crossAxisCount: constraints.maxWidth >= 680 ? 4 : 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.05,
                            children: [
                              _StatCard(
                                title: 'Total Analyses',
                                value: stats?.totalAnalyses,
                                icon: Icons.description_outlined,
                                color: colors.primary,
                                loading: _loadingDashboard && stats == null,
                              ),
                              _StatCard(
                                title: 'Genuine',
                                value: stats?.safeMessages,
                                icon: Icons.verified_user_outlined,
                                color: const Color(0xFF14804A),
                                loading: _loadingDashboard && stats == null,
                              ),
                              _StatCard(
                                title: 'Scams detected',
                                value: stats?.scamsDetected,
                                icon: Icons.warning_amber_rounded,
                                color: const Color(0xFFC27500),
                                loading: _loadingDashboard && stats == null,
                              ),
                              _StatCard(
                                title: 'High Risk',
                                value: stats?.highRisk,
                                icon: Icons.gpp_bad_outlined,
                                color: colors.error,
                                loading: _loadingDashboard && stats == null,
                              ),
                            ],
                          );
                        },
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Recent Analyses',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _selectedIndex = 3),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_loadingDashboard && _dashboard == null)
                      const _DashboardLoading(compact: true)
                    else if (_dashboardError != null && _dashboard == null)
                      const SizedBox.shrink()
                    else if (_dashboard?.recentAnalyses.isEmpty ?? true)
                      _EmptyAnalyses(onAnalyze: () => _openAnalyze('text'))
                    else
                      ..._dashboard!.recentAnalyses.map(
                        (analysis) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _RecentAnalysisTile(
                            analysis: analysis,
                            onTap: () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => AnalysisResultScreen(
                                  analysis: analysis,
                                  onBackToDashboard: () => _returnToTab(0),
                                  onAnalyzeAnother: () => _returnToTab(1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _firstName(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'there' : parts.first;
  }

  void _returnToTab(int index) {
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
    if (mounted) setState(() => _selectedIndex = index);
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
      children: [
        const ScamShieldBrandMark(size: 28),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            'SCAMSHIELD',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 0.15),
          ),
        ),
      ],
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.name,
    required this.guardianStatus,
    required this.onOpenGuardian,
  });

  final String name;
  final CallGuardianStatus? guardianStatus;
  final VoidCallback onOpenGuardian;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isRunning =
        guardianStatus?.enabled == true &&
        guardianStatus?.serviceRunning == true;
    final statusText = guardianStatus == null
        ? 'Checking call protection'
        : !guardianStatus!.supported
        ? 'Guardian unavailable on this device'
        : isRunning
        ? 'Guardian is on'
        : 'Guardian is off';
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 19, 16, 17),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primaryContainer.withValues(alpha: 0.92),
            colors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, $name 👋',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                Text(
                  'Stay aware. Stay protected.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 13),
                InkWell(
                  onTap: onOpenGuardian,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isRunning
                              ? Icons.check_circle_rounded
                              : guardianStatus == null
                              ? Icons.more_horiz_rounded
                              : Icons.shield_outlined,
                          size: 16,
                          color: isRunning
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            statusText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: colors.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.surface.withValues(alpha: 0.75),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Icon(
              Icons.shield_rounded,
              size: 32,
              color: colors.primary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyzeCta extends StatelessWidget {
  const _AnalyzeCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.search_rounded, color: colors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analyze Something',
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Check messages, images, documents, audio and more for scams.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: colors.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatefulWidget {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: widget.color.withValues(alpha: dark ? 0.16 : 0.1),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Material(
          color: _hovered ? colors.surfaceContainerHighest : colors.surface,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _hovered = true),
            onTapCancel: () => setState(() => _hovered = false),
            onTapUp: (_) => setState(() => _hovered = false),
            onHover: (hovering) => setState(() => _hovered = hovering),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _hovered
                      ? widget.color.withValues(alpha: 0.48)
                      : colors.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 39,
                    height: 39,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon, color: widget.color),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.loading,
  });

  final String title;
  final int? value;
  final IconData icon;
  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color),
          Text(
            loading ? '—' : '${value ?? 0}',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardLoading extends StatelessWidget {
  const _DashboardLoading({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return const Column(
        children: [
          SkeletonBox(height: 72, borderRadius: 16),
          SizedBox(height: 8),
          SkeletonBox(height: 72, borderRadius: 16),
        ],
      );
    }
    return const DashboardSkeleton();
  }
}

class _DashboardFailure extends StatelessWidget {
  const _DashboardFailure({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 9),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _HelpTopic extends StatelessWidget {
  const _HelpTopic({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(
            description,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: colors.onSurfaceVariant, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _EmptyAnalyses extends StatelessWidget {
  const _EmptyAnalyses({required this.onAnalyze});

  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: colors.primary, size: 30),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No analyses yet.'),
                Text('Your analysis history will appear here.'),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(onPressed: onAnalyze, child: const Text('Analyze')),
        ],
      ),
    );
  }
}

class _RecentAnalysisTile extends StatelessWidget {
  const _RecentAnalysisTile({required this.analysis, required this.onTap});

  final AnalysisRecord analysis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final riskColor = switch (analysis.riskLevel.toUpperCase()) {
      'HIGH' || 'CRITICAL' => colors.error,
      'MEDIUM' => const Color(0xFFC27500),
      _ => const Color(0xFF14804A),
    };
    final label = _analysisTitle(analysis);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              Icon(Icons.shield_outlined, color: riskColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.isEmpty ? 'Analysis ${analysis.id}' : label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${analysis.inputType.toUpperCase()} · ${_shortDate(analysis.createdAt)}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  analysis.riskLevel,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: riskColor, fontWeight: FontWeight.w800),
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

String _analysisTitle(AnalysisRecord analysis) {
  final filename = analysis.originalFilename?.trim();
  if (filename != null && filename.isNotEmpty) return filename;
  final category = analysis.category.trim();
  if (category.isNotEmpty && category.toLowerCase() != 'unknown') {
    return '${_formatAnalysisCategory(category)} detected';
  }
  return '${analysis.inputType.toUpperCase()} analysis';
}

String _formatAnalysisCategory(String category) => category
    .replaceAll(RegExp(r'[_-]+'), ' ')
    .split(RegExp(r'\s+'))
    .where((word) => word.isNotEmpty)
    .map((word) {
      final normalized = word.toLowerCase();
      if (const {'ai', 'kyc', 'otp', 'upi', 'sms'}.contains(normalized)) {
        return normalized.toUpperCase();
      }
      return '${normalized[0].toUpperCase()}${normalized.substring(1)}';
    })
    .join(' ');

class _GuardianSection extends StatelessWidget {
  const _GuardianSection({
    required this.status,
    required this.audioCapability,
    required this.audioCapabilityError,
    required this.transcriptionEnabled,
    required this.transcriptionSnapshot,
    required this.analysisSnapshot,
    required this.error,
    required this.callEvent,
    required this.activeCallSeconds,
    required this.onRetry,
    required this.onToggleGuardian,
    required this.onToggleAudioProtection,
    required this.onRetryAudioProtection,
    required this.onToggleTranscription,
    required this.onOpenSettings,
    required this.onRequestCallScreeningRole,
    this.onDismissCallEnded,
    this.protectionService,
    this.lastFinalizedSummary,
    this.onViewCallSummary,
  });

  final CallGuardianStatus? status;
  final AudioCapability? audioCapability;
  final String? audioCapabilityError;
  final bool transcriptionEnabled;
  final GuardianTranscriptionSnapshot? transcriptionSnapshot;
  final GuardianLiveAnalysisSnapshot? analysisSnapshot;
  final String? error;
  final GuardianCallEvent? callEvent;
  final int activeCallSeconds;
  final VoidCallback onRetry;
  final ValueChanged<bool> onToggleGuardian;
  final ValueChanged<bool> onToggleAudioProtection;
  final VoidCallback onRetryAudioProtection;
  final ValueChanged<bool> onToggleTranscription;
  final VoidCallback onOpenSettings;
  final VoidCallback onRequestCallScreeningRole;
  final VoidCallback? onDismissCallEnded;
  final GuardianProtectionService? protectionService;
  final CallHistoryDetail? lastFinalizedSummary;
  final VoidCallback? onViewCallSummary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
        children: [
          Text(
            'Live Call Guardian',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 7),
          Text(
            'Enable Guardian call detection, then separately opt in to microphone audio protection.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primary.withValues(alpha: 0.95),
                  colors.primary.withValues(alpha: 0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 38,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Call Guardian',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Call detection is separate from audio protection. Microphone capture is optional, user-controlled, and only enabled during active calls.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _GuardianControlCard(
            status: status,
            audioCapability: audioCapability,
            audioCapabilityError: audioCapabilityError,
            transcriptionEnabled: transcriptionEnabled,
            transcriptionSnapshot: transcriptionSnapshot,
            analysisSnapshot: analysisSnapshot,
            error: error,
            callEvent: callEvent,
            activeCallSeconds: activeCallSeconds,
            onRetry: onRetry,
            onToggleGuardian: onToggleGuardian,
            onToggleAudioProtection: onToggleAudioProtection,
            onRetryAudioProtection: onRetryAudioProtection,
            transcriptionEnabledValue: transcriptionEnabled,
            onToggleTranscription: onToggleTranscription,
            onRequestCallScreeningRole: onRequestCallScreeningRole,
            onDismissCallEnded: onDismissCallEnded,
            protectionService: protectionService,
            lastFinalizedSummary: lastFinalizedSummary,
            onViewCallSummary: onViewCallSummary,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpenSettings,
            icon: const Icon(Icons.settings_outlined),
            label: const Text('Call Protection Settings'),
          ),
        ],
      ),
    );
  }
}

class _GuardianControlCard extends StatelessWidget {
  const _GuardianControlCard({
    required this.status,
    required this.audioCapability,
    required this.audioCapabilityError,
    required this.transcriptionEnabled,
    required this.transcriptionSnapshot,
    required this.analysisSnapshot,
    required this.error,
    required this.callEvent,
    required this.activeCallSeconds,
    required this.onRetry,
    required this.onToggleGuardian,
    required this.onToggleAudioProtection,
    required this.onRetryAudioProtection,
    required this.onToggleTranscription,
    required this.onRequestCallScreeningRole,
    this.onDismissCallEnded,
    this.protectionService,
    this.lastFinalizedSummary,
    this.onViewCallSummary,
    bool? transcriptionEnabledValue,
  });

  final CallGuardianStatus? status;
  final AudioCapability? audioCapability;
  final String? audioCapabilityError;
  final bool transcriptionEnabled;
  final GuardianTranscriptionSnapshot? transcriptionSnapshot;
  final GuardianLiveAnalysisSnapshot? analysisSnapshot;
  final String? error;
  final GuardianCallEvent? callEvent;
  final int activeCallSeconds;
  final VoidCallback onRetry;
  final ValueChanged<bool> onToggleGuardian;
  final ValueChanged<bool> onToggleAudioProtection;
  final VoidCallback onRetryAudioProtection;
  final ValueChanged<bool> onToggleTranscription;
  final VoidCallback onRequestCallScreeningRole;
  final VoidCallback? onDismissCallEnded;
  final GuardianProtectionService? protectionService;
  final CallHistoryDetail? lastFinalizedSummary;
  final VoidCallback? onViewCallSummary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currentStatus = status;
    final capability = audioCapability;
    final canEnable =
        currentStatus?.available == true && currentStatus?.supported == true;
    final running =
        currentStatus?.enabled == true && currentStatus?.serviceRunning == true;
    final audioProtectionEnabled =
        currentStatus?.audioProtectionEnabled == true;
    final audioCanChange = running || audioProtectionEnabled;
    final audioRoute = currentStatus?.audioRoute
        .replaceAll('_', ' ')
        .toLowerCase();
    final audioStateLabel = switch (currentStatus?.audioState) {
      'AUDIO_INITIALIZING' => 'Preparing microphone',
      'AUDIO_READY' => 'Microphone ready',
      'AUDIO_STREAMING' => 'Microphone input flowing',
      'AUDIO_UNAVAILABLE' => 'Microphone unavailable',
      _ => audioProtectionEnabled ? 'Waiting for an active call' : 'Off',
    };
    final audioStatusDescription = switch (currentStatus?.audioState) {
      'AUDIO_INITIALIZING' => 'Android is preparing device microphone capture.',
      'AUDIO_READY' => 'The microphone is ready. Audio chunks will be created only while capture is running.',
      'AUDIO_STREAMING' => 'Device microphone input is flowing. This does not confirm that the other caller is audible.',
      'AUDIO_UNAVAILABLE' =>
        currentStatus?.audioReason.isNotEmpty == true
            ? currentStatus!.audioReason
            : 'Android could not provide microphone input. Turn audio protection off and on to retry.',
      _ =>
        audioProtectionEnabled
            ? 'Capture starts only when Guardian detects an active call.'
            : 'Microphone capture is off.',
    };
    final stateLabel = switch (currentStatus?.callState) {
      'IDLE' => 'Ready',
      'RINGING' => 'Ringing',
      'IN_CALL' => 'In call',
      'PERMISSION_REQUIRED' => 'Permission required',
      'UNAVAILABLE' => 'Unavailable',
      _ => 'Unknown',
    };
    final String statusDescription;
    if (error != null) {
      statusDescription = 'Guardian needs attention. Try again to reconnect.';
    } else if (currentStatus == null) {
      statusDescription = 'Checking call protection availability…';
    } else if (currentStatus.serviceError != null) {
      statusDescription = 'Guardian could not start. Tap retry to try again.';
    } else if (!currentStatus.supported) {
      statusDescription = 'Call protection is unavailable on this device.';
    } else if (currentStatus.enabled && !currentStatus.serviceRunning) {
      statusDescription = 'Guardian needs attention. Tap retry to try again.';
    } else if (currentStatus.enabled) {
      statusDescription = 'Guardian is on · $stateLabel';
    } else {
      statusDescription = 'Guardian is off. Call activity is not monitored.';
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CallCapabilityRow(
            label: 'Call screening',
            value: currentStatus == null
                ? 'Checking…'
                : currentStatus.callScreeningEnabled
                ? 'Enabled'
                : currentStatus.callScreeningAvailable
                ? 'Available · not enabled'
                : 'Unavailable',
            available: currentStatus?.callScreeningAvailable == true,
            enabled: currentStatus?.callScreeningEnabled == true,
          ),
          if (currentStatus?.callScreeningAvailable == true &&
              currentStatus?.callScreeningEnabled != true) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRequestCallScreeningRole,
              icon: const Icon(Icons.phone_callback_outlined),
              label: const Text('ENABLE CALL SCREENING'),
            ),
            Text(
              'To detect supported incoming calls, choose ScamShield as your call-screening service.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
          if (callEvent != null) ...[
            const SizedBox(height: 14),
            _CallSessionCard(
              event: callEvent!,
              activeCallSeconds: activeCallSeconds,
              hasCallSummary: lastFinalizedSummary != null,
              onViewCallSummary: onViewCallSummary,
            ),
          ],
          if ((callEvent?.event == 'CALL_ACTIVE' ||
                  analysisSnapshot?.isCallEnded == true ||
                  analysisSnapshot?.result != null) &&
              !transcriptionEnabled) ...[
            const SizedBox(height: 14),
            GuardianLiveRiskCard(
              snapshot: analysisSnapshot,
              isCallActive: callEvent?.event == 'CALL_ACTIVE',
              transcriptSegments: transcriptionSnapshot?.segments,
              onDismissCallEnded: onDismissCallEnded,
              protectionService: protectionService,
            ),
          ],
          const Divider(height: 24),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: currentStatus?.enabled ?? false,
              onChanged: canEnable ? onToggleGuardian : null,
              title: const Text(
                'Enable Guardian',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                canEnable
                    ? 'Monitor supported call activity. Android shows a notification while Guardian is on.'
                    : currentStatus?.supported == true
                    ? 'Guardian is currently unavailable. Check your device permissions and try again.'
                    : 'Call protection is unavailable on this device.',
              ),
              secondary: Icon(
                running ? Icons.shield_rounded : Icons.shield_outlined,
                color: running ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(height: 16),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: audioProtectionEnabled,
              onChanged:
                  audioCanChange &&
                      (audioProtectionEnabled || capability?.supported == true)
                  ? onToggleAudioProtection
                  : null,
              title: const Text(
                'Microphone audio protection',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                capability == null
                    ? audioCapabilityError ?? 'Checking microphone capability…'
                    : !capability.supported
                    ? capability.reason
                    : audioCanChange
                    ? 'Optional device-microphone input during detected active calls only.'
                    : 'Enable Guardian first. Microphone permission is requested only after you opt in.',
              ),
              secondary: Icon(
                Icons.mic_none_rounded,
                color: audioProtectionEnabled
                    ? colors.primary
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
          if (audioProtectionEnabled) ...[
            const SizedBox(height: 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        currentStatus?.audioState == 'AUDIO_UNAVAILABLE'
                            ? Icons.mic_off_outlined
                            : Icons.mic_none_rounded,
                        size: 18,
                        color: currentStatus?.audioState == 'AUDIO_UNAVAILABLE'
                            ? colors.error
                            : colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          audioStateLabel,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (currentStatus?.audioState == 'AUDIO_UNAVAILABLE')
                        IconButton(
                          tooltip: 'Retry microphone capture',
                          onPressed: onRetryAudioProtection,
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    audioStatusDescription,
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  if (currentStatus?.audioCaptureAvailable == true) ...[
                    const SizedBox(height: 8),
                    _CallCapabilityRow(
                      label: 'Input route',
                      value: audioRoute == null || audioRoute.isEmpty
                          ? 'Unknown'
                          : audioRoute,
                      available: true,
                      enabled: true,
                    ),
                  ],
                  const SizedBox(height: 8),
                  _CallCapabilityRow(
                    label: 'Audio chunks created',
                    value: '${currentStatus?.audioChunksCreated ?? 0}',
                    available: true,
                  ),
                  const SizedBox(height: 6),
                  _CallCapabilityRow(
                    label: 'Audio chunks dropped',
                    value: '${currentStatus?.audioChunksDropped ?? 0}',
                    available: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Uses the device microphone only—not direct cellular-call audio. Turn on speakerphone manually if you want nearby call audio picked up; the other caller may still not be captured. Audio is kept in a bounded in-memory buffer, not saved as a recording or uploaded.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 16),
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: transcriptionEnabled,
              onChanged: audioProtectionEnabled ? onToggleTranscription : null,
              title: const Text(
                'Live transcription',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                audioProtectionEnabled
                    ? transcriptionSnapshot?.message ?? 'Off. Enable only if you want supported call audio transcribed.'
                    : 'Enable microphone audio protection first. Transcription is unavailable for the current microphone-only source.',
              ),
              secondary: Icon(
                transcriptionEnabled
                    ? Icons.closed_caption_rounded
                    : Icons.closed_caption_off_rounded,
                color: transcriptionEnabled
                    ? colors.primary
                    : colors.onSurfaceVariant,
              ),
            ),
          ),
          if (transcriptionEnabled) ...[
            const SizedBox(height: 2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        transcriptionSnapshot?.state == 'TRANSCRIPTION_ERROR'
                            ? Icons.error_outline
                            : Icons.info_outline,
                        size: 18,
                        color:
                            transcriptionSnapshot?.state ==
                                'TRANSCRIPTION_ERROR'
                            ? colors.error
                            : colors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transcriptionSnapshot?.state == 'TRANSCRIPTION_READY'
                              ? 'Transcript'
                              : 'Transcription status',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (transcriptionSnapshot?.language != null)
                        Text(
                          transcriptionSnapshot!.language!.toUpperCase(),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    transcriptionSnapshot?.message ?? "Live transcription isn't available for this call on this device.",
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  if ((transcriptionSnapshot?.droppedChunks ?? 0) > 0) ...[
                    const SizedBox(height: 6),
                    Text(
                      '${transcriptionSnapshot!.droppedChunks} audio chunk(s) were dropped because processing could not keep up.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.error),
                    ),
                  ],
                  if (transcriptionSnapshot?.segments.isNotEmpty == true) ...[
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    for (final segment in transcriptionSnapshot!.segments) ...[
                      const SizedBox(height: 9),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatTranscriptTime(segment.startTime),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.onSurfaceVariant),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              segment.text,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 10),
                  Text(
                    'Only verified CALL_AUDIO input can be transcribed. This device currently provides microphone input, not cellular-call audio; those microphone chunks are not uploaded. Transcript and retry data are temporary.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            GuardianLiveRiskCard(
              snapshot: analysisSnapshot,
              isCallActive: callEvent?.event == 'CALL_ACTIVE',
              transcriptSegments: transcriptionSnapshot?.segments,
              onDismissCallEnded: onDismissCallEnded,
              protectionService: protectionService,
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                running ? Icons.check_circle_outline : Icons.info_outline,
                size: 19,
                color: running ? colors.primary : colors.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  statusDescription,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
              ),
              if (error != null || (currentStatus?.enabled == true && !running))
                IconButton(
                  tooltip: error != null
                      ? 'Retry native connection'
                      : 'Retry Guardian',
                  onPressed: currentStatus?.enabled == true && !running
                      ? () => onToggleGuardian(true)
                      : onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                ),
            ],
          ),
          Material(
            color: colors.surface,
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              title: const Text('Device capabilities'),
              children: [
                _CallCapabilityRow(
                  label: 'Incoming calls',
                  value: currentStatus?.incomingCallDetection == true
                      ? 'Supported'
                      : 'Not available',
                  available: currentStatus?.incomingCallDetection == true,
                ),
                const SizedBox(height: 8),
                _CallCapabilityRow(
                  label: 'Outgoing calls',
                  value: currentStatus?.outgoingCallDetection == true
                      ? 'Supported'
                      : 'Not supported',
                  available: currentStatus?.outgoingCallDetection == true,
                ),
                const SizedBox(height: 8),
                _CallCapabilityRow(
                  label: 'Active call state',
                  value: currentStatus?.activeCallStateDetection != true
                      ? 'Unavailable'
                      : currentStatus?.enabled == true &&
                            currentStatus?.serviceRunning == true
                      ? 'Monitoring'
                      : 'Requires Guardian enabled',
                  available: currentStatus?.activeCallStateDetection == true,
                ),
                const SizedBox(height: 8),
                _CallCapabilityRow(
                  label: 'Device microphone',
                  value: capability?.supported == true
                      ? currentStatus?.audioPermissionGranted == true
                            ? 'Available · permission granted'
                            : 'Available · permission not granted'
                      : capability == null && audioCapabilityError == null
                      ? 'Checking…'
                      : 'Unavailable',
                  available: capability?.supported == true,
                  enabled: currentStatus?.audioPermissionGranted == true,
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CallCapabilityRow extends StatelessWidget {
  const _CallCapabilityRow({
    required this.label,
    required this.value,
    required this.available,
    this.enabled = false,
  });

  final String label;
  final String value;
  final bool available;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = enabled
        ? colors.primary
        : available
        ? colors.tertiary
        : colors.onSurfaceVariant;
    return Row(
      children: [
        Icon(
          enabled || available
              ? Icons.check_circle_outline
              : Icons.info_outline,
          size: 18,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _CallSessionCard extends StatelessWidget {
  const _CallSessionCard({
    required this.event,
    required this.activeCallSeconds,
    this.hasCallSummary = false,
    this.onViewCallSummary,
  });

  final GuardianCallEvent event;
  final int activeCallSeconds;
  final bool hasCallSummary;
  final VoidCallback? onViewCallSummary;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final label = switch (event.event) {
      'CALL_RINGING' =>
        event.direction == 'OUTGOING'
            ? 'Outgoing Call'
            : event.direction == 'INCOMING'
            ? 'Incoming Call Detected'
            : 'Call Detected',
      'CALL_ACTIVE' => 'Call Active',
      'CALL_ENDED' => 'Call Ended',
      _ => 'Call Status',
    };
    final duration =
        '${(activeCallSeconds ~/ 60).toString().padLeft(2, '0')}:'
        '${(activeCallSeconds % 60).toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.45),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                event.event == 'CALL_ACTIVE'
                    ? Icons.call
                    : event.event == 'CALL_ENDED'
                    ? Icons.call_end
                    : Icons.ring_volume_outlined,
                color: colors.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      event.event == 'CALL_ACTIVE'
                          ? 'Call duration · $duration'
                          : event.event == 'CALL_ENDED'
                          ? 'Call ended. Protected summary saved to Call History.'
                          : 'Guardian detected call activity.',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (event.event == 'CALL_ENDED' && hasCallSummary && onViewCallSummary != null) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onViewCallSummary,
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('View Call Summary'),
            ),
          ],
        ],
      ),
    );
  }
}

String _shortDate(DateTime date) {
  final local = date.toLocal();
  final today = DateTime.now();
  final dateLabel =
      local.year == today.year &&
          local.month == today.month &&
          local.day == today.day
      ? 'Today'
      : '${local.day} ${_monthName(local.month)}';
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '$dateLabel, $hour:$minute $suffix';
}

String _formatTranscriptTime(double seconds) {
  final wholeSeconds = seconds.floor().clamp(0, 1 << 30);
  final minutes = (wholeSeconds ~/ 60).toString().padLeft(2, '0');
  final remainder = (wholeSeconds % 60).toString().padLeft(2, '0');
  return '$minutes:$remainder';
}

String _monthName(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];
