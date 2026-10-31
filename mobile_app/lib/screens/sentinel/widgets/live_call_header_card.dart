import 'package:flutter/material.dart';
import '../../../native/call_bridge.dart';

class LiveCallHeaderCard extends StatelessWidget {
  const LiveCallHeaderCard({
    required this.callEvent,
    this.callerNumber,
    this.riskLevel = 'HIGH',
    this.warningLabel = 'Potential Scam',
    this.onAnswer,
    this.onDecline,
    this.onEndCall,
    super.key,
  });

  final GuardianCallEvent? callEvent;
  final String? callerNumber;
  final String riskLevel;
  final String warningLabel;
  final VoidCallback? onAnswer;
  final VoidCallback? onDecline;
  final VoidCallback? onEndCall;

  @override
  Widget build(BuildContext context) {
    final isRinging = callEvent?.event == 'CALL_RINGING';
    final isScam = riskLevel.toUpperCase() == 'HIGH' || riskLevel.toUpperCase() == 'CRITICAL';
    final phoneNumber = (callerNumber != null && callerNumber!.trim().isNotEmpty)
        ? callerNumber!
        : 'Unknown Number';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Dark navy slate surface matching design
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            isRinging ? 'Incoming Call Detected' : 'Active Call Protected',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),

          // Avatar circle
          Container(
            width: 68,
            height: 68,
            decoration: const BoxDecoration(
              color: Color(0xFF334155),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Phone Number
          Text(
            phoneNumber,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),

          // Caller Type
          const Text(
            'Unknown Number',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),

          // Warning badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isScam
                  ? const Color(0xFFEF4444).withValues(alpha: 0.18)
                  : const Color(0xFF10B981).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isScam
                    ? const Color(0xFFEF4444).withValues(alpha: 0.6)
                    : const Color(0xFF10B981).withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isScam ? Icons.warning_rounded : Icons.shield_rounded,
                  size: 15,
                  color: isScam ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                Text(
                  warningLabel,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isScam ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Action Buttons: Decline / Answer
          if (isRinging)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDecline,
                    icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 18),
                    label: const Text('Decline'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onAnswer,
                    icon: const Icon(Icons.call_rounded, color: Colors.white, size: 18),
                    label: const Text('Answer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onEndCall,
                icon: const Icon(Icons.call_end_rounded, color: Colors.white, size: 18),
                label: const Text('End Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
