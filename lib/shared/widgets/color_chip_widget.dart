import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';

/// Displays a single color shade as a chip card with name, code, and amount.
class ColorChipCard extends StatelessWidget {
  final Color color;
  final String name;
  final String? productCode;
  final double? amountGrams;
  final double? percentContribution;
  final bool showLowStockWarning;
  final bool showIncompatibleWarning;
  final VoidCallback? onRemove;
  final ValueChanged<double>? onAmountChanged;

  const ColorChipCard({
    super.key,
    required this.color,
    required this.name,
    this.productCode,
    this.amountGrams,
    this.percentContribution,
    this.showLowStockWarning = false,
    this.showIncompatibleWarning = false,
    this.onRemove,
    this.onAmountChanged,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Color swatch
          Container(
            height: 64,
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showLowStockWarning)
                  _WarningBadge(
                    icon: Icons.inventory_2_outlined,
                    label: 'Low stock',
                    color: AppColors.warning,
                  ),
                if (showIncompatibleWarning) ...[
                  const SizedBox(width: 4),
                  _WarningBadge(
                    icon: Icons.warning_amber_rounded,
                    label: 'Tone mismatch',
                    color: AppColors.destructive,
                  ),
                ],
                const Spacer(),
                if (onRemove != null)
                  GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, size: 14,
                          color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),

          // Info
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTextStyles.labelBold.copyWith(color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (productCode != null)
                  Text(productCode!,
                      style: AppTextStyles.caption
                          .copyWith(color: cs.onSurfaceVariant)),
                if (amountGrams != null || percentContribution != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (amountGrams != null)
                        _InfoPill(
                          label: '${amountGrams!.toStringAsFixed(1)}g',
                          icon: Icons.scale_outlined,
                        ),
                      if (percentContribution != null) ...[
                        const SizedBox(width: 6),
                        _InfoPill(
                          label:
                              '${percentContribution!.toStringAsFixed(1)}%',
                          icon: Icons.pie_chart_outline,
                          highlighted: true,
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _WarningBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _WarningBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool highlighted;

  const _InfoPill({
    required this.label,
    required this.icon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlighted
            ? cs.primary.withOpacity(0.1)
            : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 11,
              color: highlighted ? cs.primary : cs.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: highlighted ? cs.primary : cs.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows a blended swatch computed from a list of (color, weight) pairs.
class MixPreviewSwatch extends StatelessWidget {
  final List<({Color color, double grams})> items;
  final double size;

  const MixPreviewSwatch({
    super.key,
    required this.items,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final blended = _blendColors(items);
    if (blended == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Icon(Icons.palette_outlined,
            color: cs.onSurfaceVariant, size: 28),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: blended,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: blended.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Color? _blendColors(List<({Color color, double grams})> items) {
    if (items.isEmpty) return null;
    final total = items.fold(0.0, (s, i) => s + i.grams);
    if (total == 0) return null;

    double r = 0, g = 0, b = 0;
    for (final item in items) {
      final w = item.grams / total;
      r += item.color.r * w;
      g += item.color.g * w;
      b += item.color.b * w;
    }
    return Color.from(alpha: 1.0, red: r, green: g, blue: b);
  }
}
