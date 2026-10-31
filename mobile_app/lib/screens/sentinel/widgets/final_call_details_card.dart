import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class FinalCallDetailsCard extends StatelessWidget {
  const FinalCallDetailsCard({
    required this.phoneNumber,
    required this.callerType,
    required this.dateTimeText,
    required this.durationText,
    super.key,
  });

  final String phoneNumber;
  final String callerType;
  final String dateTimeText;
  final String durationText;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final borderColor = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);
    final labelColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final valueColor = isDark ? Colors.white : AppColors.navy;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Call Details',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.navy,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 14),

          // Row 1: Phone Number
          _DetailRow(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            value: phoneNumber,
            labelColor: labelColor,
            valueColor: valueColor,
          ),
          Divider(color: isDark ? const Color(0xFF243447) : const Color(0xFFF1F5F9), height: 16),

          // Row 2: Caller Type
          _DetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Caller Type',
            value: callerType,
            labelColor: labelColor,
            valueColor: valueColor,
          ),
          Divider(color: isDark ? const Color(0xFF243447) : const Color(0xFFF1F5F9), height: 16),

          // Row 3: Date & Time
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date & Time',
            value: dateTimeText,
            labelColor: labelColor,
            valueColor: valueColor,
          ),
          Divider(color: isDark ? const Color(0xFF243447) : const Color(0xFFF1F5F9), height: 16),

          // Row 4: Call Duration
          _DetailRow(
            icon: Icons.access_time_rounded,
            label: 'Call Duration',
            value: durationText,
            labelColor: labelColor,
            valueColor: valueColor,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.labelColor,
    required this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: labelColor),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: labelColor,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
