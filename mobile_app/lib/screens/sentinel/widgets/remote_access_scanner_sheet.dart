import 'package:flutter/material.dart';
import '../../../native/call_bridge.dart';
import '../../../theme/app_colors.dart';

class RemoteAccessScannerSheet extends StatefulWidget {
  const RemoteAccessScannerSheet({
    required this.callBridge,
    super.key,
  });

  final CallBridge callBridge;

  @override
  State<RemoteAccessScannerSheet> createState() => _RemoteAccessScannerSheetState();
}

class _RemoteAccessScannerSheetState extends State<RemoteAccessScannerSheet> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _detectedApps = const [];

  @override
  void initState() {
    super.initState();
    _scanForRemoteApps();
  }

  Future<void> _scanForRemoteApps() async {
    setState(() => _isLoading = true);
    try {
      final results = await widget.callBridge.detectActiveRemoteAccessApps();
      if (mounted) {
        setState(() {
          _detectedApps = results;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _uninstallApp(String packageName) async {
    await widget.callBridge.openAppUninstallSettings(packageName);
    // Re-scan when returning
    Future<void>.delayed(const Duration(seconds: 1), _scanForRemoteApps);
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
                      color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.22 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.screen_share_rounded,
                      color: Color(0xFFDC2626),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remote Access App Shield',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'AnyDesk, TeamViewer & screen-sharing detector',
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
                    tooltip: 'Rescan',
                    onPressed: _isLoading ? null : _scanForRemoteApps,
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
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Scanning installed apps for remote access tools...'),
                          ],
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        if (_detectedApps.isNotEmpty) ...[
                          // Critical alert banner
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withValues(alpha: isDark ? 0.2 : 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.warning_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'High-Risk App(s) Installed!',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: Color(0xFFDC2626),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Scammers impersonating bank officials, electricity boards, or customer care frequently ask victims to install these screen-sharing tools to steal UPI PINs, banking passwords, and OTPs. Uninstall immediately if you did not intentionally install them.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'DETECTED SCREEN-SHARING APPS (${_detectedApps.length})',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ..._detectedApps.map((app) {
                            final name = app['appName'] as String? ?? 'Remote Access Tool';
                            final pkg = app['packageName'] as String? ?? '';
                            final desc = app['description'] as String? ?? '';
                            final version = app['versionName'] as String? ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.darkCard : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.phonelink_erase_rounded,
                                          color: Color(0xFFDC2626),
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 15,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                            ),
                                            Text(
                                              '$pkg • v$version',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    desc,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: () => _uninstallApp(pkg),
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                      label: Text('Uninstall $name'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFDC2626),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ] else ...[
                          // Clean / Safe State
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified_user_rounded,
                                    color: Color(0xFF10B981),
                                    size: 36,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'Device Clean & Safe',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No known remote access software (AnyDesk, TeamViewer, RustDesk, AirDroid, HopToDesk) detected on this device. Callers cannot mirror or take over your screen.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        // Information note
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 18,
                                color: colors.onSurfaceVariant,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'In-call protection automatically checks for remote access tools during ongoing phone calls and alerts you if screen sharing is active.',
                                  style: TextStyle(
                                    fontSize: 11.5,
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

