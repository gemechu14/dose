import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../providers/products_provider.dart';

class BrandsScreen extends ConsumerWidget {
  const BrandsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Color Brands')),
      body: ResponsiveConstraint(
        child: brandsAsync.when(
        loading: () => const SkeletonList(),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(brandsProvider),
        ),
        data: (brands) {
          if (brands.isEmpty) {
            return const EmptyState(
              icon: Icons.palette_outlined,
              title: 'No brands available',
            );
          }
          return GridView.builder(
            padding: Responsive.pagePadding(context).copyWith(top: 16, bottom: 16),
            gridDelegate: Responsive.adaptiveGridDelegate(
              context,
              compact: 2,
              medium: 3,
              expanded: 4,
              large: 5,
              childAspectRatio: 1.4,
            ),
            itemCount: brands.length,
            itemBuilder: (_, i) {
              final brand = brands[i];
              return AppCard(
                onTap: () => context.push(
                    '/products/brands/lines/${brand.id}'),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.palette_outlined,
                          color: AppColors.primary, size: 22),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          brand.name,
                          style: AppTextStyles.labelBold,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (brand.description != null)
                          Text(
                            brand.description!,
                            style: AppTextStyles.caption,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
        ),
      ),
    );
  }
}
