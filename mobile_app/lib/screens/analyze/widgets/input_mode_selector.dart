import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';

/// 4-mode input tab selector matching the row in all reference screens:
/// [Text, Image, Document, Audio]
class InputModeSelector extends StatelessWidget {
  const InputModeSelector({
    required this.selectedMode,
    required this.onModeSelected,
    super.key,
  });

  final String selectedMode;
  final ValueChanged<String> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final modes = const [
      _ModeItem(id: 'text', label: 'Text', icon: Icons.chat_bubble_outline_rounded),
      _ModeItem(id: 'image', label: 'Image', icon: Icons.image_outlined),
      _ModeItem(id: 'document', label: 'Document', icon: Icons.description_outlined),
      _ModeItem(id: 'audio', label: 'Audio', icon: Icons.mic_none_rounded),
    ];

    return Row(
      children: modes.map((m) {
        final isSelected = selectedMode == m.id ||
            (selectedMode == 'pdf' && m.id == 'document');
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _ModeTabButton(
              item: m,
              isSelected: isSelected,
              isDark: isDark,
              onTap: () => onModeSelected(m.id == 'document' ? 'pdf' : m.id),
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}

class _ModeItem {
  const _ModeItem({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

class _ModeTabButton extends StatelessWidget {
  const _ModeTabButton({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final _ModeItem item;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark ? AppColors.darkPrimary : AppColors.primary;
    final activeFg = isDark ? const Color(0xFF101820) : Colors.white;

    final inactiveBg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final inactiveBorder = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final inactiveIconColor = isDark ? const Color(0xFF65D4D8) : const Color(0xFF0284C7);
    final inactiveTextColor = isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${item.label} input mode',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          splashFactory: InkRipple.splashFactory,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? activeBg : inactiveBg,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected ? activeBg : inactiveBorder,
                width: 1.2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeBg.withValues(alpha: isDark ? 0.35 : 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 22,
                  color: isSelected ? activeFg : inactiveIconColor,
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? activeFg : inactiveTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
