import 'package:flutter/material.dart';

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
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: colors.outlineVariant),
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
    final colors = Theme.of(context).colorScheme;
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
              color: selected ? colors.primaryContainer : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
