import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../providers/products_provider.dart';
import '../../../../features/formulas/presentation/providers/formulas_provider.dart';
import '../../../../features/formulas/data/models/formula_model.dart';

class ProductDetailScreen extends ConsumerWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailProvider(productId));
    final favorites = ref.watch(favoriteProductsProvider);

    return Scaffold(
      body: productAsync.when(
        loading: () => Scaffold(
          appBar: AppBar(),
          body: const SkeletonList(count: 3),
        ),
        error: (err, _) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text(err.toString())),
        ),
        data: (product) {
          Color chipColor = AppColors.muted;
          if (product.colorHex != null) {
            final hex = product.colorHex!.replaceFirst('#', '');
            chipColor = Color(int.parse('FF$hex', radix: 16));
          }
          final isFav = favorites.contains(product.id);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                backgroundColor: chipColor,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded,
                      color: Colors.white),
                  onPressed: () => context.pop(),
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      isFav
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      color:
                          isFav ? Colors.red : Colors.white,
                    ),
                    onPressed: () {
                      final favs = ref
                          .read(favoriteProductsProvider.notifier);
                      if (isFav) {
                        favs.state = favs.state
                            .where((id) => id != product.id)
                            .toSet();
                      } else {
                        favs.state = {
                          ...favs.state,
                          product.id
                        };
                      }
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: chipColor,
                    child: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withOpacity(0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white
                                        .withOpacity(0.4),
                                    width: 2),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (product.colorHex != null)
                              Text(
                                product.colorHex!.toUpperCase(),
                                style:
                                    AppTextStyles.caption.copyWith(
                                  color:
                                      Colors.white.withOpacity(0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(product.name, style: AppTextStyles.displaySm),
                    if (product.code != null) ...[
                      const SizedBox(height: 4),
                      Text(product.code!,
                          style: AppTextStyles.caption),
                    ],
                    const SizedBox(height: 20),
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _InfoRow('Brand', product.brandName ?? '—'),
                          _InfoRow('Line',
                              product.productLineName ?? '—'),
                          _InfoRow('Tone', product.toneFamily ?? '—'),
                          _InfoRow(
                              'Level',
                              product.level?.toString() ?? '—'),
                          _InfoRow('Family',
                              product.colorFamily ?? '—'),
                          if (product.unitCost != null)
                            _InfoRow('Cost per gram',
                                '\$${product.unitCost!.toStringAsFixed(4)}'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppButton(
                      label: 'Add to Current Formula',
                      icon: const Icon(Icons.science_outlined,
                          color: Colors.white, size: 18),
                      onPressed: () {
                        ref
                            .read(formulaBuilderProvider.notifier)
                            .addItem(
                              ColorItemModel(
                                productId: product.id,
                                productName: product.name,
                                productCode: product.code,
                                colorHex: product.colorHex,
                                amountUsed: 30,
                              ),
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${product.name} added to formula'),
                            backgroundColor: AppColors.accent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.label),
          Text(value, style: AppTextStyles.labelBold),
        ],
      ),
    );
  }
}
