import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/color_chip_widget.dart';
import '../../data/models/formula_model.dart';
import '../providers/formulas_provider.dart';

class MixPreviewPanel extends ConsumerWidget {
  final FormulaBuilderState builderState;

  const MixPreviewPanel({super.key, required this.builderState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final previewMode = ref.watch(mixPreviewModeProvider);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.auto_awesome_rounded,
                  size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('Mix Preview', style: AppTextStyles.headingSm),
              const Spacer(),
              // Total cost badge
              if (builderState.totalCost > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${builderState.totalCost.toStringAsFixed(2)}',
                    style: AppTextStyles.labelBold
                        .copyWith(color: AppColors.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Mode selector
          Row(
            children: MixPreviewMode.values.map((mode) {
              final isSelected = previewMode == mode;
              final label = switch (mode) {
                MixPreviewMode.chips => 'Shades',
                MixPreviewMode.blended => 'Blend',
                MixPreviewMode.beforeAfter => 'Before/After',
              };
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => ref
                      .read(mixPreviewModeProvider.notifier)
                      .state = mode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.primary
                          : cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Preview content
          _buildPreviewContent(context, previewMode),
        ],
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context, MixPreviewMode mode) {
    switch (mode) {
      case MixPreviewMode.chips:
        return _buildChipsView();
      case MixPreviewMode.blended:
        return _buildBlendedView(context);
      case MixPreviewMode.beforeAfter:
        return _buildBeforeAfterView(context);
    }
  }

  Widget _buildChipsView() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: builderState.items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final item = builderState.items[i];
          Color chipColor = AppColors.muted;
          if (item.colorHex != null) {
            final hex = item.colorHex!.replaceFirst('#', '');
            chipColor = Color(int.parse('FF$hex', radix: 16));
          }
          final percent = builderState.percentInBowl(item);

          return Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: chipColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: chipColor.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: AppTextStyles.caption,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBlendedView(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final coloredItems = builderState.items
        .where((i) => i.colorHex != null)
        .map((i) => (
              color: Color(int.parse(
                  'FF${i.colorHex!.replaceFirst('#', '')}',
                  radix: 16)),
              grams: i.amountUsed,
            ))
        .toList();

    return Row(
      children: [
        MixPreviewSwatch(items: coloredItems, size: 80),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Blended Result',
                  style: AppTextStyles.labelBold),
              const SizedBox(height: 4),
              Text(
                '${builderState.totalWeight.toStringAsFixed(1)}g total',
                style: AppTextStyles.caption,
              ),
              const SizedBox(height: 8),
              // Per-item bars
              ...builderState.items.map((item) {
                final percent = builderState.percentInBowl(item);
                Color itemColor = cs.primary;
                if (item.colorHex != null) {
                  final hex =
                      item.colorHex!.replaceFirst('#', '');
                  itemColor =
                      Color(int.parse('FF$hex', radix: 16));
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: itemColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent / 100,
                            backgroundColor: cs.surfaceContainerHighest,
                            color: itemColor,
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${percent.toStringAsFixed(0)}%',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBeforeAfterView(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _BeforeAfterCard(label: 'Before', icon: Icons.face_outlined),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward_rounded,
              color: cs.onSurfaceVariant, size: 20),
        ),
        Expanded(
          child: _BeforeAfterCard(
            label: 'After',
            icon: Icons.auto_fix_high_rounded,
            hasColor: builderState.items.isNotEmpty,
            items: builderState.items,
          ),
        ),
      ],
    );
  }
}

class _BeforeAfterCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool hasColor;
  final List<ColorItemModel> items;

  const _BeforeAfterCard({
    required this.label,
    required this.icon,
    this.hasColor = false,
    this.items = const [],
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final coloredItems = items
        .where((i) => i.colorHex != null)
        .map((i) => (
              color: Color(int.parse(
                  'FF${i.colorHex!.replaceFirst('#', '')}',
                  radix: 16)),
              grams: i.amountUsed,
            ))
        .toList();

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasColor && coloredItems.isNotEmpty)
            MixPreviewSwatch(items: coloredItems, size: 44)
          else
            Icon(icon, color: cs.onSurfaceVariant, size: 28),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
