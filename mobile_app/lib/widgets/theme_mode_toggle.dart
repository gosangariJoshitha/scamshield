import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Accessible theme mode toggle switch supporting Light and Dark modes.
class ThemeModeToggle extends StatelessWidget {
  const ThemeModeToggle({
    required this.isDarkMode,
    required this.onChanged,
    super.key,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ThemeOption(
            icon: Icons.light_mode_rounded,
            label: 'Switch to light theme',
            selected: !isDarkMode,
            onTap: () => onChanged(false),
          ),
          _ThemeOption(
            icon: Icons.dark_mode_rounded,
            label: 'Switch to dark theme',
            selected: isDarkMode,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final containerColor = isDark
        ? AppColors.darkPrimary.withValues(alpha: 0.22)
        : AppColors.aqua.withValues(alpha: 0.45);

    return Semantics(
      button: true,
      label: label,
      selected: selected,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selected ? containerColor : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: selected
                  ? primaryColor
                  : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
            ),
          ),
        ),
      ),
    );
  }
}
