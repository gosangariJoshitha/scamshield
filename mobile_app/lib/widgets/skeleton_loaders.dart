import 'package:flutter/material.dart';

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.height,
    this.borderRadius = 12,
    super.key,
  });

  final double? width;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? colors.surfaceContainerHighest.withValues(alpha: 0.3)
            : colors.outlineVariant.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Row(
          children: [
            Expanded(child: SkeletonBox(height: 84, borderRadius: 16)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 84, borderRadius: 16)),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 84, borderRadius: 16)),
          ],
        ),
        const SizedBox(height: 20),
        const SkeletonBox(height: 18, width: 140, borderRadius: 6),
        const SizedBox(height: 12),
        const SkeletonBox(height: 110, borderRadius: 18),
        const SizedBox(height: 12),
        const SkeletonBox(height: 110, borderRadius: 18),
      ],
    );
  }
}

class HistoryListSkeleton extends StatelessWidget {
  const HistoryListSkeleton({
    this.count = 4,
    super.key,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: SkeletonBox(height: 100, borderRadius: 18),
        ),
      ),
    );
  }
}
