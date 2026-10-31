import 'package:flutter/material.dart';
import '../../models/guardian_analysis_models.dart';
import '../../native/call_bridge.dart';
import '../../services/guardian_protection_service.dart';
import '../../services/guardian_transcription_service.dart';
import '../../theme/app_colors.dart';
import 'widgets/category_pills_row.dart';
import 'widgets/guardian_radar_hero.dart';
import 'widgets/permissions_access_card.dart';

class GuardianDetailsScreen extends StatefulWidget {
  const GuardianDetailsScreen({
    required this.status,
    required this.audioCapability,
    required this.transcriptionEnabled,
    required this.transcriptionSnapshot,
    required this.analysisSnapshot,
    required this.onToggleGuardian,
    required this.onToggleAudioProtection,
    required this.onToggleTranscription,
    required this.onRequestCallScreeningRole,
    this.audioCapabilityError,
    this.protectionService,
    this.onRetryAudioProtection,
    this.onOpenSettings,
    this.onBack,
    super.key,
  });

  final CallGuardianStatus? status;
  final AudioCapability? audioCapability;
  final String? audioCapabilityError;
  final bool transcriptionEnabled;
  final GuardianTranscriptionSnapshot? transcriptionSnapshot;
  final GuardianLiveAnalysisSnapshot? analysisSnapshot;
  final ValueChanged<bool> onToggleGuardian;
  final ValueChanged<bool> onToggleAudioProtection;
  final ValueChanged<bool> onToggleTranscription;
  final VoidCallback onRequestCallScreeningRole;
  final VoidCallback? onRetryAudioProtection;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onBack;
  final GuardianProtectionService? protectionService;

  @override
  State<GuardianDetailsScreen> createState() => _GuardianDetailsScreenState();
}

class _GuardianDetailsScreenState extends State<GuardianDetailsScreen> {
  String _selectedCategory = 'call';
  bool _showCapabilities = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor = isDark ? Colors.white : AppColors.navy;
    final currentStatus = widget.status;
    final capability = widget.audioCapability;

    final canEnable = currentStatus?.available == true && currentStatus?.supported == true;
    final running = currentStatus?.enabled == true && currentStatus?.serviceRunning == true;
    final audioProtectionEnabled = currentStatus?.audioProtectionEnabled == true;
    final audioCanChange = running || audioProtectionEnabled;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: headlineColor),
          onPressed: widget.onBack ?? () => Navigator.of(context).maybePop(),
          tooltip: 'Back',
        ),
        title: Text(
          'Sentinel',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18.5,
            fontWeight: FontWeight.w700,
            color: headlineColor,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Category selector pills
                  CategoryPillsRow(
                    selectedCategory: _selectedCategory,
                    onSelectCategory: (cat) => setState(() => _selectedCategory = cat),
                  ),
                  const SizedBox(height: 20),

                  // 2. Central Radar Hero with Phone Icon & Soundwaves
                  GuardianRadarHero(
                    status: currentStatus,
                    onTapInfo: () => _showGuardianInfoDialog(context),
                  ),
                  const SizedBox(height: 20),

                  // 3. Permissions & Access Card
                  PermissionsAccessCard(
                    status: currentStatus,
                    audioCapability: capability,
                    onRequestMicrophone: () => widget.onToggleAudioProtection(!audioProtectionEnabled),
                    onRequestPhone: () => widget.onToggleGuardian(!(currentStatus?.enabled ?? false)),
                    onRequestOverlay: widget.onRequestCallScreeningRole,
                    onRequestAccessibility: widget.onRequestCallScreeningRole,
                  ),
                  const SizedBox(height: 16),

                  // 4. Interactive Call Guardian Settings Card
                  Container(
                    width: double.infinity,
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
                        padding: const EdgeInsets.all(16),
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Protection Controls',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 12),

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
                        const Divider(height: 16),

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
                                ? widget.transcriptionSnapshot?.message ?? 'Transcribes nearby speakerphone speech using Whisper.'
                                : 'Enable microphone audio protection first.',
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

                        // Device Capabilities Expandable
                        const SizedBox(height: 10),
                        InkWell(
                          onTap: () => setState(() => _showCapabilities = !_showCapabilities),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Device capabilities',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                                Icon(
                                  _showCapabilities ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                  size: 20,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_showCapabilities) ...[
                          const SizedBox(height: 8),
                          _CapabilityRow(
                            label: 'Outgoing calls',
                            value: currentStatus?.outgoingCallDetection == true ? 'Supported' : 'Not supported',
                          ),
                          const SizedBox(height: 6),
                          _CapabilityRow(
                            label: 'Active call state',
                            value: currentStatus?.activeCallStateDetection == true ? 'Supported' : 'Not supported',
                          ),
                          const SizedBox(height: 6),
                          _CapabilityRow(
                            label: 'Speakerphone capture',
                            value: capability?.supported == true ? 'Supported (Mic only)' : 'Unavailable',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

                  if (widget.onOpenSettings != null) ...[
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGuardianInfoDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('About Live Call Guardian'),
        content: const Text(
          'Live Call Guardian monitors telephony state events in the background under supported Android conditions. '
          'Audio capture is strictly optional, requires explicit user consent, and captures microphone audio only while on speakerphone. '
          'No audio is permanently stored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  const _CapabilityRow({required this.label, required this.value});

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
