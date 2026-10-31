import 'package:flutter/material.dart';
import '../../../services/guardian_transcription_service.dart';

class LiveTranscriptionView extends StatelessWidget {
  const LiveTranscriptionView({
    this.userText,
    this.callerText,
    this.segments = const [],
    this.isScamAlert = true,
    super.key,
  });

  final String? userText;
  final String? callerText;
  final List<TranscriptSegment> segments;
  final bool isScamAlert;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Derive transcripts if provided, or parse from segments
    final displayUserText = userText ?? _findUserTranscript(segments);
    final displayCallerText = callerText ?? _findCallerTranscript(segments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Live Transcription (You)
        if (displayUserText != null && displayUserText.isNotEmpty) ...[
          Row(
            children: const [
              Icon(Icons.mic_none_rounded, size: 16, color: Color(0xFF0284C7)),
              SizedBox(width: 6),
              Text(
                'Live Transcription (You)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0284C7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF192630) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              displayUserText,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 2. Live Transcription (Caller)
        Row(
          children: [
            Icon(
              Icons.phone_in_talk_rounded,
              size: 16,
              color: isScamAlert ? const Color(0xFFEF4444) : const Color(0xFF10B981),
            ),
            const SizedBox(width: 6),
            Text(
              'Live Transcription (Caller)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isScamAlert ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isScamAlert
                ? (isDark ? const Color(0xFF2A1216) : const Color(0xFFFEF2F2))
                : (isDark ? const Color(0xFF0B241B) : const Color(0xFFF0FDF4)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isScamAlert
                  ? (isDark ? const Color(0xFFEF4444).withValues(alpha: 0.35) : const Color(0xFFFECACA))
                  : (isDark ? const Color(0xFF10B981).withValues(alpha: 0.35) : const Color(0xFF86EFAC)),
            ),
          ),
          child: Text(
            displayCallerText?.isNotEmpty == true
                ? displayCallerText!
                : 'Listening for caller speech on speakerphone…',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isScamAlert
                  ? (isDark ? const Color(0xFFFCA5A5) : const Color(0xFFDC2626))
                  : (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669)),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  static String? _findUserTranscript(List<TranscriptSegment> segments) {
    if (segments.isEmpty) return null;
    return segments.first.text;
  }

  static String? _findCallerTranscript(List<TranscriptSegment> segments) {
    if (segments.isEmpty) return null;
    if (segments.length == 1) return segments.first.text;
    return segments.sublist(1).map((s) => s.text).join(' ');
  }
}
