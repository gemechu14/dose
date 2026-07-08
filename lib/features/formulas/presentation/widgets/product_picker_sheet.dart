import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/mix_models.dart';
import '../providers/mix_builder_provider.dart';

/// Bottom sheet for picking a tenant product.
/// Shows in-stock products first; marks out-of-stock ones.
class ProductPickerSheet extends ConsumerStatefulWidget {
  const ProductPickerSheet({super.key});

  static Future<TenantProduct?> show(BuildContext context) {
    return showModalBottomSheet<TenantProduct>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ProductPickerSheet(),
    );
  }

  @override
  ConsumerState<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<ProductPickerSheet> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(tenantCatalogProvider);
    final stockItems = ref.watch(builderInventoryProvider).valueOrNull ?? [];
    final stockMap = {for (final s in stockItems) s.tenantProductId: s};

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (ctx, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Handle ────────────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            // ── Title ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Select Product',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // ── Search ────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: TextField(
                controller: _search,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search by name or code…',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.search,
                      color: Colors.grey.shade400, size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF4F6F9),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _query = v.trim()),
              ),
            ),
            // ── List ──────────────────────────────────────────────────
            Expanded(
              child: catalogAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (catalog) {
                  final q = _query.toLowerCase();
                  final filtered = catalog.where((p) {
                    if (q.isEmpty) return true;
                    return p.label.toLowerCase().contains(q) ||
                        p.name.toLowerCase().contains(q) ||
                        (p.code?.toLowerCase().contains(q) ?? false) ||
                        (p.brandName?.toLowerCase().contains(q) ?? false);
                  }).toList();

                  // In-stock first
                  filtered.sort((a, b) {
                    final aStock = stockMap[a.id]?.inStock ?? false;
                    final bStock = stockMap[b.id]?.inStock ?? false;
                    if (aStock && !bStock) return -1;
                    if (!aStock && bStock) return 1;
                    return a.name.compareTo(b.name);
                  });

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.builder(
                    controller: scroll,
                    padding: const EdgeInsets.only(
                        top: 4, bottom: 24, left: 20, right: 20),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final product = filtered[i];
                      final stock = stockMap[product.id];
                      final inStock = stock?.inStock ?? false;

                      return _ProductTile(
                        product: product,
                        inStock: inStock,
                        onTap: () => Navigator.pop(context, product),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final TenantProduct product;
  final bool inStock;
  final VoidCallback onTap;

  const _ProductTile({
    required this.product,
    required this.inStock,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hex = (product.colorHex ?? '').replaceFirst('#', '');
    Color? swatch;
    if (hex.length >= 6) {
      final v = int.tryParse('FF${hex.substring(0, 6)}', radix: 16);
      if (v != null) swatch = Color(v);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
              onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              // Color swatch
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: swatch ?? Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: Colors.grey.shade200),
                ),
              ),
              const SizedBox(width: 12),
              // Name + meta
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.label,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (product.brandName != null ||
                        product.productLineName != null)
                      Text(
                        [product.brandName, product.productLineName]
                            .whereType<String>()
                            .join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
              // Stock badge
              if (!inStock)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.orange.shade200),
                  ),
                  child: Text(
                    'Not in stock',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                Icon(Icons.add_circle_outline,
                    color: AppColors.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
