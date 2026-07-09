import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../providers/products_provider.dart';

class ProductLinesScreen extends ConsumerWidget {
  final String brandId;

  const ProductLinesScreen({super.key, required this.brandId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linesAsync = ref.watch(productLinesProvider(brandId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Lines'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: linesAsync.when(
        loading: () => const SkeletonList(),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(productLinesProvider(brandId)),
        ),
        data: (lines) {
          if (lines.isEmpty) {
            return const EmptyState(
              icon: Icons.category_outlined,
              title: 'No product lines',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: lines.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final line = lines[i];
              return AppCard(
                onTap: () => context.push(
                  '/products/brands/lines/${brandId}/catalog/${line.id}',
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.category_outlined,
                          color: AppColors.secondary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(line.name, style: AppTextStyles.labelBold),
                          if (line.description != null)
                            Text(
                              line.description!,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: AppColors.muted, size: 20),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
