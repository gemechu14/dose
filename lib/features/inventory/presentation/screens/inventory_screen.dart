import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../providers/inventory_provider.dart';
import '../../data/models/inventory_model.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.inventory),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'All Stock'),
            Tab(text: 'Low Stock'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AllStockTab(),
          _LowStockTab(),
        ],
      ),
    );
  }
}

class _AllStockTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(inventoryItemsProvider);

    return itemsAsync.when(
      loading: () => const SkeletonList(),
      error: (err, _) => ErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(inventoryItemsProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No inventory data',
          );
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async =>
              ref.invalidate(inventoryItemsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) => _InventoryTile(item: items[i]),
          ),
        );
      },
    );
  }
}

class _LowStockTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowAsync = ref.watch(lowStockProvider);

    return lowAsync.when(
      loading: () => const SkeletonList(),
      error: (err, _) => ErrorState(
        message: err.toString(),
        onRetry: () => ref.invalidate(lowStockProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const EmptyState(
            icon: Icons.check_circle_outline_rounded,
            title: 'All stocked up!',
            subtitle: 'No low stock items at this location',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) =>
              _InventoryTile(item: items[i], showWarning: true),
        );
      },
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final InventoryItemModel item;
  final bool showWarning;

  const _InventoryTile({required this.item, this.showWarning = false});

  @override
  Widget build(BuildContext context) {
    Color chipColor = AppColors.muted;
    if (item.colorHex != null) {
      final hex = item.colorHex!.replaceFirst('#', '');
      chipColor = Color(int.parse('FF$hex', radix: 16));
    }

    final stockPercent = item.reorderPoint != null && item.reorderPoint! > 0
        ? (item.quantityOnHand / (item.reorderPoint! * 3))
            .clamp(0.0, 1.0)
        : 1.0;

    final stockColor = item.isLowStock
        ? AppColors.destructive
        : stockPercent < 0.5
            ? AppColors.warning
            : AppColors.accent;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: chipColor,
              borderRadius: BorderRadius.circular(12),
              border: item.isLowStock
                  ? Border.all(
                      color: AppColors.destructive, width: 2)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.productName ?? 'Unknown Product',
                        style: AppTextStyles.labelBold,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.destructive
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                size: 11,
                                color: AppColors.destructive),
                            SizedBox(width: 3),
                            Text(
                              'Low',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.destructive,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (item.productCode != null) ...[
                  const SizedBox(height: 2),
                  Text(item.productCode!, style: AppTextStyles.caption),
                ],
                const SizedBox(height: 6),
                // Stock bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: stockPercent,
                          backgroundColor:
                              AppColors.surfaceVariant,
                          color: stockColor,
                          minHeight: 5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${item.quantityOnHand.toStringAsFixed(0)}${item.unit ?? 'g'}',
                      style: AppTextStyles.caption
                          .copyWith(color: stockColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
