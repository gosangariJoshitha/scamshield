import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

class CategoryPillsRow extends StatelessWidget {
  const CategoryPillsRow({
    required this.selectedCategory,
    required this.onSelectCategory,
    super.key,
  });

  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;

  static const List<(String id, String label)> _categories = [
    ('call', 'Call Guardian'),
    ('message', 'Message Protection'),
    ('link', 'Link Protection'),
    ('web', 'Web Protection'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = cat.$1 == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelectCategory(cat.$1),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.darkPrimary : const Color(0xFF0284C7))
                      : (isDark ? const Color(0xFF192630) : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : (isDark ? const Color(0xFF243447) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Text(
                  cat.$2,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
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
