import 'package:flutter/material.dart';

class HistoryFilterPills extends StatelessWidget {
  const HistoryFilterPills({
    required this.options,
    required this.selectedOption,
    required this.onSelected,
    super.key,
  });

  final List<String> options;
  final String selectedOption;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = const Color(0xFF0284C7);
    final inactiveBg = isDark ? const Color(0xFF131F2A) : const Color(0xFFF1F5F9);
    final inactiveBorder = isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0);
    final activeTextColor = Colors.white;
    final inactiveTextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: options.map((option) {
          final isSelected = selectedOption.toUpperCase() == option.toUpperCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => onSelected(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? activeBg : inactiveBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? activeBg : inactiveBorder,
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: activeBg.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? activeTextColor : inactiveTextColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
