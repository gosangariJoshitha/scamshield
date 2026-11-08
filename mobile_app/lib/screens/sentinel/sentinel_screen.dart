import 'package:flutter/material.dart';
import '../../models/call_history_models.dart';
import '../../models/guardian_analysis_models.dart';
import '../../native/call_bridge.dart';
import '../../services/guardian_protection_service.dart';
import '../../services/guardian_transcription_service.dart';
import '../../theme/app_colors.dart';
import 'call_report_screen.dart';
import 'guardian_details_screen.dart';
import 'live_call_monitoring_screen.dart';
import 'widgets/protection_grid_2x2.dart';
import 'widgets/sentinel_feature_list.dart';
import 'widgets/sentinel_hero_card.dart';
import 'widgets/sentinel_overview_header.dart';
import 'widgets/remote_access_scanner_sheet.dart';
import 'widgets/sms_shield_sheet.dart';

class SentinelScreen extends StatefulWidget {
  const SentinelScreen({
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
    this.onRetryAnalysis,
    this.protectionService,
    this.lastFinalizedSummary,
    this.onViewCallSummary,
    super.key,
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
  final VoidCallback? onRetryAnalysis;
  final GuardianProtectionService? protectionService;
  final CallHistoryDetail? lastFinalizedSummary;
  final VoidCallback? onViewCallSummary;

  @override
  State<SentinelScreen> createState() => _SentinelScreenState();
}

class _SentinelScreenState extends State<SentinelScreen> {
  void _openDetails(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GuardianDetailsScreen(
          status: widget.status,
          audioCapability: widget.audioCapability,
          audioCapabilityError: widget.audioCapabilityError,
          transcriptionEnabled: widget.transcriptionEnabled,
          transcriptionSnapshot: widget.transcriptionSnapshot,
          analysisSnapshot: widget.analysisSnapshot,
          onToggleGuardian: widget.onToggleGuardian,
          onToggleAudioProtection: widget.onToggleAudioProtection,
          onToggleTranscription: widget.onToggleTranscription,
          onRequestCallScreeningRole: widget.onRequestCallScreeningRole,
          onRetryAudioProtection: widget.onRetryAudioProtection,
          onOpenSettings: widget.onOpenSettings,
          protectionService: widget.protectionService,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openLiveMonitoring(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveCallMonitoringScreen(
          callEvent: widget.callEvent,
          activeCallSeconds: widget.activeCallSeconds,
          analysisSnapshot: widget.analysisSnapshot,
          segments: widget.transcriptionSnapshot?.segments ?? const [],
          protectionService: widget.protectionService,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Future<void> _confirmAndOpenLiveMonitoring(BuildContext context) async {
    final audioAlreadyEnabled = widget.status?.audioProtectionEnabled == true;
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
      if (confirmed != true) return;
      widget.onToggleAudioProtection(true);
    }
    if (context.mounted) {
      _openLiveMonitoring(context);
    }
  }

  void _openFinalReport(BuildContext context, CallHistoryDetail detail) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CallReportScreen(
          call: detail,
          protectionService: widget.protectionService,
          onViewHistory: widget.onViewCallSummary,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _openSmsShield(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SmsShieldSheet(callBridge: CallBridge()),
    );
  }

  void _openRemoteAccessShield(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => RemoteAccessScannerSheet(callBridge: CallBridge()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStatus = widget.status;
    final capability = widget.audioCapability;
    final callEvent = widget.callEvent;

    final audioProtectionEnabled = currentStatus?.audioProtectionEnabled == true;

    final hasActiveCall = callEvent?.event == 'CALL_ACTIVE' || callEvent?.event == 'CALL_RINGING';

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            children: [
              // 1. Section A: Sentinel Overview Header
              const SentinelOverviewHeader(),
              const SizedBox(height: 10),

              // 2. Active Call Banner (if call is ringing or active)
              if (hasActiveCall) ...[
                _ActiveCallAlertBanner(
                  callEvent: callEvent!,
                  activeCallSeconds: widget.activeCallSeconds,
                  status: currentStatus,
                  analysisSnapshot: widget.analysisSnapshot,
                  latestSnippet: widget.transcriptionSnapshot?.segments.isNotEmpty == true
                      ? widget.transcriptionSnapshot!.segments.last.text
                      : null,
                  onTapMonitor: () => _confirmAndOpenLiveMonitoring(context),
                ),
                const SizedBox(height: 10),
              ],

              // 3. Section B: Primary Protection Card (Live Call Sentinel + authoritative switch)
              SentinelHeroCard(
                status: currentStatus,
                onToggle: widget.onToggleGuardian,
                onTapDetails: () => _openDetails(context),
              ),
              const SizedBox(height: 10),

              // Call detection advisory note
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Supported call detection is separate from audio protection. Microphone capture is optional, user-controlled, and only enabled during active calls.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 4. Section D: Microphone Audio Protection (Single switch + speakerphone advisory)
              _MicrophoneAudioProtectionCard(
                enabled: audioProtectionEnabled,
                capability: capability,
                capabilityError: widget.audioCapabilityError,
                onToggle: widget.onToggleAudioProtection,
                transcriptionEnabled: widget.transcriptionEnabled,
                onToggleTranscription: widget.onToggleTranscription,
                transcriptionSnapshot: widget.transcriptionSnapshot,
              ),
              const SizedBox(height: 12),

              // 5. Section C: Required Permissions (Compact 3-row status)
              _RequiredPermissionsSection(
                phoneGranted: currentStatus?.phoneStatePermissionGranted ?? false,
                micGranted: currentStatus?.audioPermissionGranted ?? false,
                notifGranted: currentStatus?.notificationsPermissionGranted ?? false,
                onOpenSettings: widget.onOpenSettings,
                onRequestMic: widget.onRetryAudioProtection,
              ),
              const SizedBox(height: 14),

              // Expandable Device Capabilities section
              _DeviceCapabilitiesCard(
                status: currentStatus,
                capability: capability,
              ),
              const SizedBox(height: 16),

              // 6. Section E: Protection Capabilities Grid (Call, Message, Link, Web Protection)
              ProtectionGrid2x2(
                onTapCallProtection: () => _openDetails(context),
                onTapMessageProtection: () => _openSmsShield(context),
                onTapLinkProtection: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Link Protection is active.')),
                  );
                },
                onTapWebProtection: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Web Protection is active.')),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Sentinel Feature Navigation List (Real-time Alerts, App Shield, Database, Community)
              SentinelFeatureList(
                onTapRealTimeAlerts: () => _openDetails(context),
                onTapAppShield: () => _openRemoteAccessShield(context),
                onTapDatabase: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Scam Database is up to date.')),
                  );
                },
                onTapCommunity: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Community Protection is active.')),
                  );
                },
              ),
              const SizedBox(height: 16),

              // 7. Last finalized call summary card (if available)
              if (widget.lastFinalizedSummary != null) ...[
                _RecentCallSummaryCard(
                  summary: widget.lastFinalizedSummary!,
                  onTap: () => _openFinalReport(context, widget.lastFinalizedSummary!),
                ),
                const SizedBox(height: 14),
              ],

              // 8. Section F: Settings (Single authoritative action card)
              _ProtectionSettingsActionCard(
                onOpenSettings: widget.onOpenSettings,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RequiredPermissionsSection extends StatelessWidget {
  const _RequiredPermissionsSection({
    required this.phoneGranted,
    required this.micGranted,
    required this.notifGranted,
    required this.onOpenSettings,
    required this.onRequestMic,
  });

  final bool phoneGranted;
  final bool micGranted;
  final bool notifGranted;
  final VoidCallback onOpenSettings;
  final VoidCallback onRequestMic;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  size: 16,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Required Permissions',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _PermissionListRow(
              icon: Icons.phone_android_rounded,
              title: 'Phone State',
              status: phoneGranted ? 'Granted' : 'Required',
              isGranted: phoneGranted,
              onAction: onOpenSettings,
            ),
            Divider(
              height: 14,
              color: isDark ? const Color(0xFF243447) : const Color(0xFFF1F5F9),
            ),
            _PermissionListRow(
              icon: Icons.mic_none_rounded,
              title: 'Microphone',
              status: micGranted ? 'Granted' : 'Optional',
              isGranted: micGranted,
              onAction: onRequestMic,
            ),
            Divider(
              height: 14,
              color: isDark ? const Color(0xFF243447) : const Color(0xFFF1F5F9),
            ),
            _PermissionListRow(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              status: notifGranted ? 'Granted' : 'Required',
              isGranted: notifGranted,
              onAction: onOpenSettings,
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionListRow extends StatelessWidget {
  const _PermissionListRow({
    required this.icon,
    required this.title,
    required this.status,
    required this.isGranted,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String status;
  final bool isGranted;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badgeColor = isGranted
        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF10B981))
        : (status == 'Optional'
            ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))
            : (isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444)));

    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.navy,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
          ),
          child: Text(
            status,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ),
        if (!isGranted) ...[
          const SizedBox(width: 6),
          InkWell(
            onTap: onAction,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                'Grant',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.darkPrimary : AppColors.primary,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MicrophoneAudioProtectionCard extends StatelessWidget {
  const _MicrophoneAudioProtectionCard({
    required this.enabled,
    required this.capability,
    required this.capabilityError,
    required this.onToggle,
    required this.transcriptionEnabled,
    required this.onToggleTranscription,
    this.transcriptionSnapshot,
  });

  final bool enabled;
  final AudioCapability? capability;
  final String? capabilityError;
  final ValueChanged<bool> onToggle;
  final bool transcriptionEnabled;
  final ValueChanged<bool> onToggleTranscription;
  final GuardianTranscriptionSnapshot? transcriptionSnapshot;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              onChanged: onToggle,
              title: const Text(
                'Microphone audio protection',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                capability == null
                    ? capabilityError ?? 'Checking microphone capability…'
                    : !capability!.supported
                        ? capability!.reason
                        : 'Optional live audio analysis during detected phone calls.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              secondary: Icon(
                Icons.mic_none_rounded,
                color: enabled
                    ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                    : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.volume_up_rounded,
                    size: 16,
                    color: isDark ? AppColors.darkPrimary : AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Device microphone capture is optional and only active during phone calls. For best scam detection accuracy, use speakerphone during calls.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              height: 18,
              color: isDark ? const Color(0xFF243447) : const Color(0xFFF1F5F9),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: transcriptionEnabled,
              onChanged: enabled ? onToggleTranscription : null,
              title: const Text(
                'Live transcription',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                enabled
                    ? transcriptionSnapshot?.message ?? 'Live transcription analyzes spoken sentences.'
                    : 'Enable microphone audio protection first.',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              secondary: Icon(
                transcriptionEnabled
                    ? Icons.closed_caption_rounded
                    : Icons.closed_caption_off_rounded,
                color: transcriptionEnabled
                    ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                    : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCapabilitiesCard extends StatelessWidget {
  const _DeviceCapabilitiesCard({
    required this.status,
    required this.capability,
  });

  final CallGuardianStatus? status;
  final AudioCapability? capability;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.1),
        ),
        child: ExpansionTile(
          key: const Key('guardian_device_capabilities_tile'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Text(
            'Device capabilities',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          children: [
            _DeviceCapabilityRow(
              label: 'Incoming calls',
              value: status?.incomingCallDetection == true ? 'Supported' : 'Not available',
            ),
            const SizedBox(height: 6),
            _DeviceCapabilityRow(
              label: 'Outgoing calls',
              value: status?.outgoingCallDetection == true ? 'Supported' : 'Not supported',
            ),
            const SizedBox(height: 6),
            _DeviceCapabilityRow(
              label: 'Active call state',
              value: status?.activeCallStateDetection == true ? 'Supported' : 'Not supported',
            ),
            const SizedBox(height: 6),
            _DeviceCapabilityRow(
              label: 'Device microphone',
              value: capability?.supported == true ? 'Available · permission granted' : 'Unavailable',
            ),
          ],
        ),
      ),
    );
  }
}

class _DeviceCapabilityRow extends StatelessWidget {
  const _DeviceCapabilityRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProtectionSettingsActionCard extends StatelessWidget {
  const _ProtectionSettingsActionCard({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return OutlinedButton.icon(
      onPressed: onOpenSettings,
      icon: const Icon(Icons.settings_outlined, size: 18),
      label: const Text('Call Protection Settings'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(
          color: isDark ? const Color(0xFF243447) : const Color(0xFFCBD5E1),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ActiveCallAlertBanner extends StatelessWidget {
  const _ActiveCallAlertBanner({
    required this.callEvent,
    required this.activeCallSeconds,
    required this.onTapMonitor,
    this.status,
    this.analysisSnapshot,
    this.latestSnippet,
  });

  final GuardianCallEvent callEvent;
  final int activeCallSeconds;
  final VoidCallback onTapMonitor;
  final CallGuardianStatus? status;
  final GuardianLiveAnalysisSnapshot? analysisSnapshot;
  final String? latestSnippet;

  @override
  Widget build(BuildContext context) {
    final minutes = (activeCallSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (activeCallSeconds % 60).toString().padLeft(2, '0');

    final label = switch (callEvent.event) {
      'CALL_RINGING' =>
        callEvent.direction == 'OUTGOING'
            ? 'Outgoing Call'
            : callEvent.direction == 'INCOMING'
            ? 'Incoming Call Detected'
            : 'Call Detected',
      'CALL_ACTIVE' => 'Call Active',
      'CALL_ENDED' => 'Call Ended',
      _ => 'Call Status',
    };

    final isSpeaker = status?.audioRoute == 'SPEAKER';
    final result = analysisSnapshot?.result;
    final localHeuristic = analysisSnapshot?.localHeuristicResult;
    final riskLevel = result?.riskLevel ?? (localHeuristic?.riskLevel ?? 'ANALYZING');
    final isScam = riskLevel == 'HIGH' || riskLevel == 'CRITICAL';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isScam ? const Color(0xFFEF4444) : const Color(0xFF0284C7).withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: (isScam ? const Color(0xFFEF4444) : const Color(0xFF0284C7)).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isScam ? const Color(0xFFEF4444) : const Color(0xFF0284C7),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      callEvent.event == 'CALL_ACTIVE'
                          ? (isSpeaker
                              ? 'Call duration · $minutes:$seconds • 🔊 Speaker'
                              : 'Call duration · $minutes:$seconds')
                          : callEvent.event == 'CALL_ENDED'
                          ? 'Call ended. Protected summary saved to Call History.'
                          : 'Sentinel detected call activity.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onTapMonitor,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0284C7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Monitor', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
          if (latestSnippet != null || result != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isScam ? const Color(0xFF450A0A) : const Color(0xFF0B192C),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isScam ? const Color(0xFFEF4444).withValues(alpha: 0.5) : const Color(0xFF1E3A8A),
                ),
              ),
              child: Text(
                latestSnippet != null
                    ? 'Live: "$latestSnippet"'
                    : (result?.reasoning ?? (localHeuristic?.warningHeadline ?? 'Listening to call for scam indicators...')),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: isScam ? const Color(0xFFFECACA) : const Color(0xFF93C5FD),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentCallSummaryCard extends StatelessWidget {
  const _RecentCallSummaryCard({required this.summary, required this.onTap});

  final CallHistoryDetail summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isScam = summary.finalRiskLevel.toUpperCase() == 'HIGH' ||
        summary.finalRiskLevel.toUpperCase() == 'CRITICAL';
    final riskColor = isScam ? const Color(0xFFEF4444) : const Color(0xFF10B981);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isScam ? Icons.warning_rounded : Icons.shield_rounded,
                color: riskColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latest Call Report',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.navy,
                    ),
                  ),
                  Text(
                    '${summary.classification}  •  ${summary.finalRiskLevel} Risk',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: riskColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}


