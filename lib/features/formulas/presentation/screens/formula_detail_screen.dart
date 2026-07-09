import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../data/models/formula_model.dart';
import '../providers/formulas_provider.dart';
import '../../../customers/presentation/providers/customers_provider.dart';

class FormulaDetailScreen extends ConsumerWidget {
  final String formulaId;

  const FormulaDetailScreen({super.key, required this.formulaId});

  void _remix(BuildContext context, FormulaModel formula) {
    final id = Uri.encodeComponent(formula.id);
    context.go('/mix?preloadFormulaId=$id');
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final d = DateTime.parse(iso).toLocal();
      return DateFormat('EEE, MMM d, yyyy').format(d);
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }

  String _prettyTitle(FormulaModel f) {
    final raw = f.formulaName ?? f.bowlLabel ?? f.displayService;
    return raw
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  String _productLabel(ColorItemModel item, int index) {
    if (item.productName != null && item.productName!.trim().isNotEmpty) {
      final code = item.productCode;
      if (code != null &&
          code.isNotEmpty &&
          !item.productName!.contains(code)) {
        return '${item.productName} ($code)';
      }
      return item.productName!;
    }
    if (item.productCode != null && item.productCode!.trim().isNotEmpty) {
      return item.productCode!;
    }
    final short = item.productId.length > 8
        ? item.productId.substring(0, 8).toUpperCase()
        : item.productId.toUpperCase();
    return 'Product $index · $short';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formulaAsync = ref.watch(formulaDetailProvider(formulaId));
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Formula Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: formulaAsync.when(
        loading: () => const SkeletonList(count: 5),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 48, color: cs.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () =>
                      ref.invalidate(formulaDetailProvider(formulaId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (formula) {
          final resolvedClientName = formula.customerId != null
              ? ref
                  .watch(customerDetailProvider(formula.customerId!))
                  .valueOrNull
                  ?.fullName
                  .trim()
              : null;
          final clientName = (resolvedClientName != null &&
                  resolvedClientName.isNotEmpty)
              ? resolvedClientName
              : ((formula.customerName?.trim().isNotEmpty ?? false)
                  ? formula.customerName!.trim()
                  : 'Unknown client');
          final totalAmount = formula.totalWeight;
          final totalCost = formula.computedCost;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.primary
                                        .withValues(alpha: 0.15)
                                    : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.science_rounded,
                                color: AppColors.primary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _prettyTitle(formula),
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurface,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    clientName,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Client: $clientName  ·  Service: ${formula.serviceType ?? '—'}  ·  Date: ${_formatDate(formula.createdAt)}',
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: cs.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (formula.notes != null &&
                            formula.notes!.trim().isNotEmpty) ...[
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.warning
                                      .withValues(alpha: 0.1)
                                  : const Color(0xFFFFFBEB),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.warning
                                        .withValues(alpha: 0.3)
                                    : const Color(0xFFFDE68A),
                              ),
                            ),
                            child: Text(
                              formula.notes!,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: isDark
                                    ? const Color(0xFFFBBF24)
                                    : const Color(0xFF92400E),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        ...List.generate(formula.items.length, (i) {
                          final item = formula.items[i];
                          final lineCost = item.totalCost;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: i == formula.items.length - 1
                                  ? 0
                                  : 10,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: cs.surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: cs.outline),
                              ),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.primary
                                              .withValues(alpha: 0.15)
                                          : const Color(0xFFEFF6FF),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${i + 1}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                _productLabel(
                                                    item, i + 1),
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w700,
                                                  color: cs.onSurface,
                                                  height: 1.3,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              '\$${lineCost.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Amount: ${item.amountUsed.toStringAsFixed(item.amountUsed == item.amountUsed.roundToDouble() ? 0 : 1)} ${item.unit}  ·  Unit cost: \$${(item.unitCost ?? 0).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            color: cs.onSurfaceVariant,
                                            height: 1.35,
                                          ),
                                        ),
                                        if (item.wasteAmount != null &&
                                            item.wasteAmount! > 0) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Waste: ${item.wasteAmount!.toStringAsFixed(1)} ${item.unit}',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 11,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),

                        const SizedBox(height: 20),
                        Divider(color: cs.outline),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            Text(
                              'Total amount',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${totalAmount.toStringAsFixed(totalAmount == totalAmount.roundToDouble() ? 0 : 1)} g',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Estimated cost',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '\$${totalCost.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Sticky remix button
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _remix(context, formula),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_note_rounded, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Remix in builder',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
