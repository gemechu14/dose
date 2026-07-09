import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../data/models/product_model.dart';
import '../providers/products_provider.dart';
import '../../../../features/formulas/presentation/providers/formulas_provider.dart';
import '../../../../features/formulas/data/models/formula_model.dart';

class ProductsScreen extends ConsumerWidget {
  final String lineId;

  const ProductsScreen({super.key, required this.lineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(productsFilterProvider(lineId));
    final productsAsync = ref.watch(productsProvider(filter));
    final favorites = ref.watch(favoriteProductsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Shades'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFiltersSheet(context, ref, lineId),
          ),
        ],
      ),
      body: productsAsync.when(
        loading: () => const SkeletonList(),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(productsProvider(filter)),
        ),
        data: (products) {
          if (products.isEmpty) {
            return const EmptyState(
              icon: Icons.palette_outlined,
              title: 'No shades found',
              subtitle: 'Try adjusting your filters',
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (_, i) {
              final p = products[i];
              final isFav = favorites.contains(p.id);
              Color chipColor = AppColors.muted;
              if (p.colorHex != null) {
                final hex = p.colorHex!.replaceFirst('#', '');
                chipColor = Color(int.parse('FF$hex', radix: 16));
              }

              return _ProductShadeCard(
                product: p,
                color: chipColor,
                isFavorite: isFav,
                onFavoriteToggle: () {
                  final favs =
                      ref.read(favoriteProductsProvider.notifier);
                  final current = favs.state;
                  if (isFav) {
                    favs.state = current
                        .where((id) => id != p.id)
                        .toSet();
                  } else {
                    favs.state = {...current, p.id};
                  }
                },
                onAddToFormula: () {
                  ref.read(formulaBuilderProvider.notifier).addItem(
                        ColorItemModel(
                          productId: p.id,
                          productName: p.name,
                          productCode: p.code,
                          colorHex: p.colorHex,
                          amountUsed: 30,
                        ),
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${p.name} added to formula'),
                      backgroundColor: AppColors.accent,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                onTap: () =>
                    context.push('/products/brands/detail/${p.id}'),
              );
            },
          );
        },
      ),
    );
  }

  void _showFiltersSheet(
      BuildContext context, WidgetRef ref, String lineId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ProductFiltersSheet(lineId: lineId),
    );
  }
}

class _ProductShadeCard extends StatelessWidget {
  final ProductModel product;
  final Color color;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAddToFormula;
  final VoidCallback? onTap;

  const _ProductShadeCard({
    required this.product,
    required this.color,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onAddToFormula,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onAddToFormula,
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline),
        ),
        child: Column(
          children: [
            // Swatch
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(14)),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onFavoriteToggle,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_outline_rounded,
                            size: 14,
                            color: isFavorite
                                ? Colors.red
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onAddToFormula,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_rounded,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.code ?? product.name,
                      style: AppTextStyles.labelBold.copyWith(
                          fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.toneFamily != null)
                      Text(
                        product.toneFamily!,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFiltersSheet extends ConsumerWidget {
  final String lineId;
  const _ProductFiltersSheet({required this.lineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(productsFilterProvider(lineId));

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter Shades', style: AppTextStyles.headingMd),
          const SizedBox(height: 16),
          Text('Level', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(10, (i) => i + 1).map((lvl) {
              final selected = currentFilter.level == lvl;
              return FilterChip(
                label: Text('$lvl'),
                selected: selected,
                onSelected: (v) {
                  ref
                      .read(productsFilterProvider(lineId).notifier)
                      .state = ProductsFilter(
                    lineId: lineId,
                    level: v ? lvl : null,
                    toneFamily: currentFilter.toneFamily,
                    colorFamily: currentFilter.colorFamily,
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text('Tone', style: AppTextStyles.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Warm', 'Cool', 'Natural', 'Ash', 'Gold', 'Copper']
                .map((tone) {
              final selected = currentFilter.toneFamily == tone;
              return FilterChip(
                label: Text(tone),
                selected: selected,
                onSelected: (v) {
                  ref
                      .read(productsFilterProvider(lineId).notifier)
                      .state = ProductsFilter(
                    lineId: lineId,
                    level: currentFilter.level,
                    toneFamily: v ? tone : null,
                    colorFamily: currentFilter.colorFamily,
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Apply'),
            ),
          ),
        ],
      ),
    );
  }
}
