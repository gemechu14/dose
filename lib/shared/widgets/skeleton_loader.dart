import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';

// ─── Base shimmer wrapper ──────────────────────────────────────────────────

class SkeletonBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final highlight =
        isDark ? AppColors.darkSurface : Colors.white;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ─── Generic card skeleton (still used elsewhere) ─────────────────────────

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        isDark ? AppColors.darkSurfaceVariant : AppColors.surfaceVariant;
    final highlight =
        isDark ? AppColors.darkSurface : Colors.white;
    final surface =
        isDark ? AppColors.darkSurface : AppColors.surface;
    final border =
        isDark ? AppColors.darkBorder : AppColors.border;

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: base,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(width: 140, height: 14, color: base),
                    const SizedBox(height: 6),
                    Container(width: 90, height: 12, color: base),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 12, color: base),
            const SizedBox(height: 6),
            Container(width: 200, height: 12, color: base),
          ],
        ),
      ),
    );
  }
}

// ─── Customer list-tile skeleton (matches CustomerListTile exactly) ────────

class CustomerSkeletonTile extends StatelessWidget {
  const CustomerSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base =
        isDark ? AppColors.darkSurfaceVariant : const Color(0xFFEEF2F7);
    final highlight =
        isDark ? AppColors.darkSurface : Colors.white;
    final surface =
        isDark ? AppColors.darkSurface : Colors.white;
    final border =
        isDark ? AppColors.darkBorder : const Color(0xFFE8EEF5);

    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: base,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 160,
                    height: 14,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 11,
                    decoration: BoxDecoration(
                      color: base,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 14,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Generic list skeleton ─────────────────────────────────────────────────

class SkeletonList extends StatelessWidget {
  final int count;
  final bool useCustomerTile;

  const SkeletonList(
      {super.key, this.count = 8, this.useCustomerTile = false});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => useCustomerTile
          ? const CustomerSkeletonTile()
          : const SkeletonCard(),
    );
  }
}
