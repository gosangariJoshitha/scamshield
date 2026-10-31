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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentStatus = widget.status;
    final capability = widget.audioCapability;
    final callEvent = widget.callEvent;

    final canEnable = currentStatus?.available == true && currentStatus?.supported == true;
    final running = currentStatus?.enabled == true && currentStatus?.serviceRunning == true;
    final audioProtectionEnabled = currentStatus?.audioProtectionEnabled == true;
    final audioCanChange = running || audioProtectionEnabled;



    final hasActiveCall = callEvent?.event == 'CALL_ACTIVE' || callEvent?.event == 'CALL_RINGING';

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
            children: [
              // 1. Sentinel Overview Header
              const SentinelOverviewHeader(),
              const SizedBox(height: 10),

              // 2. Active Call Banner (if call is ringing or active)
              if (hasActiveCall) ...[
                _ActiveCallAlertBanner(
                  callEvent: callEvent!,
                  activeCallSeconds: widget.activeCallSeconds,
                  onTapMonitor: () => _openLiveMonitoring(context),
                ),
                const SizedBox(height: 10),
              ],

              // 3. Live Call Guardian Hero Card (Panel 1 of sentinel page.jpeg)
              SentinelHeroCard(
                status: currentStatus,
                onToggle: widget.onToggleGuardian,
                onTapDetails: () => _openDetails(context),
              ),
              const SizedBox(height: 10),

              // 4. Comprehensive Guardian Controls Card (maintains 100% test compatibility)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0),
                    width: 1.1,
                  ),
                ),
                child: Material(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Row(
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          size: 18,
                          color: isDark ? AppColors.darkPrimary : const Color(0xFF0284C7),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Live Call Guardian',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.navy,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Supported call detection is separate from audio protection. Microphone capture is optional, user-controlled, and only enabled during active calls.',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const Divider(height: 10),

                    // Switch 1: Enable Guardian
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: currentStatus?.enabled ?? false,
                      onChanged: canEnable ? widget.onToggleGuardian : null,
                      title: const Text(
                        'Enable Guardian',
                        style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                      ),
                      subtitle: Text(
                        canEnable
                            ? 'Monitor supported call activity. Android shows a notification while Guardian is on.'
                            : 'Call protection is unavailable on this device.',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                      ),
                      secondary: Icon(
                        running ? Icons.shield_rounded : Icons.shield_outlined,
                        color: running ? (isDark ? AppColors.darkPrimary : AppColors.primary) : const Color(0xFF94A3B8),
                      ),
                    ),
                    const Divider(height: 10),

                    // Switch 2: Microphone audio protection
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: audioProtectionEnabled,
                      onChanged: audioCanChange && (audioProtectionEnabled || capability?.supported == true)
                          ? widget.onToggleAudioProtection
                          : null,
                      title: const Text(
                        'Microphone audio protection',
                        style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                      ),
                      subtitle: Text(
                        capability == null
                            ? widget.audioCapabilityError ?? 'Checking microphone capability…'
                            : !capability.supported
                                ? capability.reason
                                : 'Optional device-microphone input during detected active calls only.',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                      ),
                      secondary: Icon(
                        Icons.mic_none_rounded,
                        color: audioProtectionEnabled
                            ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                    const Divider(height: 16),

                    // Switch 3: Live transcription
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: widget.transcriptionEnabled,
                      onChanged: audioProtectionEnabled ? widget.onToggleTranscription : null,
                      title: const Text(
                        'Live transcription',
                        style: TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Inter'),
                      ),
                      subtitle: Text(
                        audioProtectionEnabled
                            ? widget.transcriptionSnapshot?.message ?? 'Off. Enable only if you want supported call audio transcribed.'
                            : 'Enable microphone audio protection first. Transcription is unavailable for the current microphone-only source.',
                        style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                      ),
                      secondary: Icon(
                        widget.transcriptionEnabled
                            ? Icons.closed_caption_rounded
                            : Icons.closed_caption_off_rounded,
                        color: widget.transcriptionEnabled
                            ? (isDark ? AppColors.darkPrimary : AppColors.primary)
                            : const Color(0xFF94A3B8),
                      ),
                    ),

                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: widget.onOpenSettings,
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text('Call Protection Settings'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                    // Device Capabilities Expandable
                    const Divider(height: 20),
                    ExpansionTile(
                      key: const Key('guardian_device_capabilities_tile'),
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
                          value: currentStatus?.incomingCallDetection == true ? 'Supported' : 'Not available',
                        ),
                        const SizedBox(height: 6),
                        _DeviceCapabilityRow(
                          label: 'Outgoing calls',
                          value: currentStatus?.outgoingCallDetection == true ? 'Supported' : 'Not supported',
                        ),
                        const SizedBox(height: 6),
                        _DeviceCapabilityRow(
                          label: 'Active call state',
                          value: currentStatus?.activeCallStateDetection == true ? 'Supported' : 'Not supported',
                        ),
                        const SizedBox(height: 6),
                        _DeviceCapabilityRow(
                          label: 'Device microphone',
                          value: capability?.supported == true ? 'Available · permission granted' : 'Unavailable',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

              // 5. 2x2 Protection Grid (Call, Message, Link, Web Protection)
              ProtectionGrid2x2(
                onTapCallProtection: () => _openDetails(context),
                onTapMessageProtection: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Message Protection is active.')),
                  );
                },
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

              // 6. Sentinel Feature Navigation List
              SentinelFeatureList(
                onTapRealTimeAlerts: () => _openDetails(context),
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
                const SizedBox(height: 14),
                _RecentCallSummaryCard(
                  summary: widget.lastFinalizedSummary!,
                  onTap: () => _openFinalReport(context, widget.lastFinalizedSummary!),
                ),
              ],

              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: widget.onOpenSettings,
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Call Protection Settings'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveCallAlertBanner extends StatelessWidget {
  const _ActiveCallAlertBanner({
    required this.callEvent,
    required this.activeCallSeconds,
    required this.onTapMonitor,
  });

  final GuardianCallEvent callEvent;
  final int activeCallSeconds;
  final VoidCallback onTapMonitor;

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFEF4444),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  callEvent.event == 'CALL_ACTIVE'
                      ? 'Call duration · $minutes:$seconds'
                      : callEvent.event == 'CALL_ENDED'
                      ? 'Call ended. Protected summary saved to Call History.'
                      : 'Guardian detected call activity.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Monitor', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
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
