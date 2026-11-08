import 'package:flutter/material.dart';
import '../../../native/call_bridge.dart';
import '../../../theme/app_colors.dart';

class SmsShieldSheet extends StatefulWidget {
  const SmsShieldSheet({
    required this.callBridge,
    super.key,
  });

  final CallBridge callBridge;

  @override
  State<SmsShieldSheet> createState() => _SmsShieldSheetState();
}

class _SmsShieldSheetState extends State<SmsShieldSheet> with WidgetsBindingObserver {
  bool _isLoading = true;
  bool _isPermissionGranted = false;
  bool _isShieldEnabled = true;
  List<Map<String, dynamic>> _detectedThreats = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadState();
    }
  }

  Future<void> _loadState() async {
    setState(() => _isLoading = true);
    try {
      final perm = await widget.callBridge.isNotificationListenerPermissionGranted();
      final enabled = await widget.callBridge.isNotificationShieldEnabled();
      final threats = await widget.callBridge.getDetectedSmsThreats();
      if (mounted) {
        setState(() {
          _isPermissionGranted = perm;
          _isShieldEnabled = enabled;
          _detectedThreats = threats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleShield(bool value) async {
    if (value && !_isPermissionGranted) {
      final open = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Notification Access Required'),
          content: const Text(
            'ScamShield needs Notification Access to analyze incoming SMS & WhatsApp notifications for banking fraud, fake electricity bills, and malicious APK links.\n\nAndroid requires you to grant this access in system settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
      if (open == true) {
        await widget.callBridge.openNotificationListenerSettings();
      }
      return;
    }

    await widget.callBridge.setNotificationShieldEnabled(value);
    setState(() => _isShieldEnabled = value);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: isDark ? 0.22 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.mark_chat_unread_rounded,
                      color: Color(0xFF0284C7),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SMS & Notification Shield',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Zero-Click on-device scam message protection',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    tooltip: 'Refresh',
                    onPressed: _isLoading ? null : _loadState,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content body
            Flexible(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        // Switch & Status Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Real-time Threat Interception',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          !_isShieldEnabled
                                              ? 'Disabled — Turn on to protect against text scams'
                                              : (!_isPermissionGranted
                                                  ? 'Permission Required — Android Notification Access needed'
                                                  : 'Active — Scanning incoming SMS & WhatsApp'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: !_isShieldEnabled
                                                ? const Color(0xFF94A3B8)
                                                : (!_isPermissionGranted
                                                    ? const Color(0xFFF59E0B)
                                                    : const Color(0xFF10B981)),
                                            fontWeight: _isShieldEnabled ? FontWeight.w600 : FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: _isShieldEnabled,
                                    onChanged: _toggleShield,
                                  ),
                                ],
                              ),
                              if (!_isPermissionGranted) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.2 : 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: Color(0xFFF59E0B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Notification Access not granted. Tap below to enable in Android settings.',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: widget.callBridge.openNotificationListenerSettings,
                                        child: const Text('Enable'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Section Title: Intercepted Threats
                        Text(
                          'INTERCEPTED FRAUD ATTEMPTS (${_detectedThreats.length})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 10),

                        if (_detectedThreats.isNotEmpty) ...[
                          ..._detectedThreats.reversed.map((threat) {
                            final sender = threat['sender'] as String? ?? 'Unknown';
                            final category = threat['category'] as String? ?? 'Scam Attempt';
                            final preview = threat['preview'] as String? ?? '';
                            final timestamp = threat['timestamp'] as num? ?? 0;
                            final date = DateTime.fromMillisecondsSinceEpoch(timestamp.toInt());
                            final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          category.toUpperCase(),
                                          style: const TextStyle(
                                            color: Color(0xFFDC2626),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        timeStr,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Sender: $sender',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    preview,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                      height: 1.35,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }),
                        ] else ...[
                          // Clean threat state
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            decoration: BoxDecoration(
                              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFF10B981),
                                  size: 26,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'No Fraud Messages Detected',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'ScamShield is actively inspecting incoming messages for phishing, fake bank alerts, and dangerous APK links.',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          height: 1.3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),

                        // Privacy explanation
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 18,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Privacy Guarantee: Notification analysis runs 100% on-device using local regular expression patterns. Your personal messages and OTPs are never uploaded to any remote server.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colors.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

