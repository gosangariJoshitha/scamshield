import 'package:flutter/material.dart';

import '../models/guardian_analysis_models.dart';
import '../models/guardian_protection_models.dart';
import '../services/guardian_protection_service.dart';

class GuardianProtectionPanel extends StatefulWidget {
  const GuardianProtectionPanel({
    super.key,
    required this.result,
    required this.protectionService,
    this.isCallActive = true,
    this.callerNumber,
  });

  final GuardianLiveAnalysisResult result;
  final GuardianProtectionService protectionService;
  final bool isCallActive;
  final String? callerNumber;

  @override
  State<GuardianProtectionPanel> createState() => _GuardianProtectionPanelState();
}

class _GuardianProtectionPanelState extends State<GuardianProtectionPanel> {
  ProtectionActionResult? _lastActionResult;

  Color _riskColor(String level) {
    switch (level.toUpperCase()) {
      case 'CRITICAL':
        return const Color(0xFFD32F2F);
      case 'HIGH':
        return const Color(0xFFE65100);
      case 'MEDIUM':
        return const Color(0xFFF57C00);
      case 'LOW':
      default:
        return const Color(0xFF2E7D32);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final service = widget.protectionService;
    final capabilities = service.capabilities;
    final riskColor = _riskColor(widget.result.riskLevel);
    final isMeaningfulRisk = widget.result.riskLevel == 'MEDIUM' ||
        widget.result.riskLevel == 'HIGH' ||
        widget.result.riskLevel == 'CRITICAL';

    if (!service.settings.showProtectionActions || !isMeaningfulRisk) {
      return const SizedBox.shrink();
    }

    final isEndCallBusy = service.isActionInProgress(ProtectionActionType.endCall);
    final isBlockBusy = service.isActionInProgress(ProtectionActionType.blockCaller);
    final isReportBusy = service.isActionInProgress(ProtectionActionType.reportCall);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E222B) : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: riskColor.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            children: [
              Icon(Icons.shield_rounded, size: 20, color: riskColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Stay Protected',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${widget.result.riskLevel} RISK',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: riskColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Recommended Action Text
          if (widget.result.safeAction.isNotEmpty) ...[
            Text(
              'Recommended:',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.result.safeAction,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Last Action Status Feedback Banner
          if (_lastActionResult != null) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _lastActionResult!.status == ProtectionActionStatus.success
                    ? Colors.green.withValues(alpha: 0.12)
                    : colors.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _lastActionResult!.status == ProtectionActionStatus.success
                      ? Colors.green.withValues(alpha: 0.4)
                      : colors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _lastActionResult!.status == ProtectionActionStatus.success
                        ? Icons.check_circle_outline
                        : Icons.info_outline,
                    size: 16,
                    color: _lastActionResult!.status == ProtectionActionStatus.success
                        ? Colors.green
                        : colors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _lastActionResult!.message,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (_lastActionResult!.canOpenSettings)
                    TextButton(
                      onPressed: () => service.openBlockedNumbersSettings(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Settings'),
                    ),
                ],
              ),
            ),
          ],

          // Action Buttons Grid
          Text(
            'Protection Actions',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // 1. Verify Safely (Always Available)
              OutlinedButton.icon(
                onPressed: () => _showVerifySafelyDialog(context),
                icon: const Icon(Icons.verified_outlined, size: 16),
                label: const Text('Verify Safely'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),

              // 2. Report Call (Always Available)
              OutlinedButton.icon(
                onPressed: isReportBusy ? null : () => _confirmReportCall(context),
                icon: isReportBusy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.flag_outlined, size: 16),
                label: Text(isReportBusy ? 'Reporting…' : 'Report Call'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),

              // 3. End Call (Capability-Aware)
              FilledButton.icon(
                onPressed: (isEndCallBusy || !widget.isCallActive)
                    ? null
                    : () => _confirmEndCall(context, capabilities.canEndCall),
                icon: isEndCallBusy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.call_end_rounded, size: 16),
                label: Text(isEndCallBusy ? 'Ending…' : 'End Call'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
              ),

              // 4. Block Caller (Capability-Aware)
              OutlinedButton.icon(
                onPressed: isBlockBusy
                    ? null
                    : () => _confirmBlockCaller(context, capabilities.canBlockCaller),
                icon: isBlockBusy
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.block_rounded, size: 16),
                label: Text(isBlockBusy ? 'Blocking…' : 'Block Caller'),
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: riskColor,
                  side: BorderSide(color: riskColor.withValues(alpha: 0.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showVerifySafelyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_user_outlined, color: Colors.blue),
            SizedBox(width: 8),
            Text('Verify Safely'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Before taking action or sharing any details, verify the caller independently:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            _buildChecklistItem('1. Do not use phone numbers or links provided by the caller.'),
            _buildChecklistItem('2. Open the official bank/service app or verified website directly.'),
            _buildChecklistItem('3. Call official customer support from your bank card or official site.'),
            _buildChecklistItem('4. Never disclose OTPs, PINs, passwords, or CVV codes to anyone.'),
            const SizedBox(height: 8),
            Text(
              'ScamShield Recommendation: ${widget.result.safeAction}',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('UNDERSTOOD'),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(fontSize: 13, height: 1.3)),
    );
  }

  Future<void> _confirmEndCall(
    BuildContext context,
    GuardianCapabilityItem capability,
  ) async {
    if (!capability.supported) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('End call isn\'t supported on this device'),
          content: Text(
            capability.reason.isNotEmpty
                ? capability.reason
                : 'Your device does not allow ScamShield to end calls automatically. You can end the call using your phone controls.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('GOT IT'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this call?'),
        content: Text(
          'ScamShield detected ${widget.result.riskLevel} risk scam indicators. You can end the call to stop the conversation safely.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('END CALL'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await widget.protectionService.executeEndCall(
        sessionId: widget.result.sessionId,
      );
      if (mounted) setState(() => _lastActionResult = result);
    }
  }

  Future<void> _confirmBlockCaller(
    BuildContext context,
    GuardianCapabilityItem capability,
  ) async {
    if (!capability.supported) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Caller blocking unavailable directly'),
          content: Text(
            capability.reason.isNotEmpty
                ? capability.reason
                : 'Caller blocking isn\'t available directly from third-party apps on this device. You can block this number from your phone\'s call settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                widget.protectionService.openBlockedNumbersSettings();
              },
              child: const Text('OPEN CALL SETTINGS'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block this caller?'),
        content: const Text(
          'You will no longer receive calls from this number through supported device blocking mechanisms.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('BLOCK CALLER'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await widget.protectionService.executeBlockCaller(
        sessionId: widget.result.sessionId,
        phoneNumber: widget.callerNumber,
      );
      if (mounted) setState(() => _lastActionResult = result);
    }
  }

  Future<void> _confirmReportCall(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report this call?'),
        content: Text(
          'Submit an anonymous fraud report to ScamShield community database for pattern ${widget.result.scamCategory}. No call audio or private conversation data will be shared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('SUBMIT REPORT'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final result = await widget.protectionService.submitReport(
        sessionId: widget.result.sessionId,
        category: widget.result.scamCategory,
        description: widget.result.reasoning,
        evidence: widget.result.detectedIndicators.join(', '),
      );
      if (mounted) setState(() => _lastActionResult = result);
    }
  }
}
