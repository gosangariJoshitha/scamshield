import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Reusable rectangular skeleton placeholder for loading states.
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
            ? colors.surfaceContainerHighest.withValues(alpha: 0.35)
            : colors.outlineVariant.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Generic card skeleton placeholder conforming to card dimensions.
class ScamShieldCardSkeleton extends StatelessWidget {
  const ScamShieldCardSkeleton({
    this.height = 110,
    super.key,
  });

  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      height: height,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppSpacing.roundedCard,
        border: Border.all(
          color: colors.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              SkeletonBox(
                width: 38,
                height: 38,
                borderRadius: 10,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(width: 140, height: 16, borderRadius: 4),
                    SizedBox(height: 6),
                    SkeletonBox(width: 80, height: 12, borderRadius: 4),
                  ],
                ),
              ),
              const SkeletonBox(width: 60, height: 24, borderRadius: 12),
            ],
          ),
          if (height > 90) ...[
            const SizedBox(height: 12),
            SkeletonBox(
              width: double.infinity,
              height: 14,
              borderRadius: 4,
            ),
          ],
        ],
      ),
    );
  }
}

/// Dashboard loading state skeleton.
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
        const ScamShieldCardSkeleton(),
        const SizedBox(height: 12),
        const ScamShieldCardSkeleton(),
      ],
    );
  }
}

/// History list loading state skeleton.
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
          child: ScamShieldCardSkeleton(),
        ),
      ),
    );
  }
}

/// Convenient alias for general skeleton loading views.
typedef SkeletonLoader = ScamShieldCardSkeleton;
