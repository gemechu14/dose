import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../providers/formulas_provider.dart';
import '../../data/models/formula_model.dart';

class FormulasHistoryScreen extends ConsumerStatefulWidget {
  const FormulasHistoryScreen({super.key});

  @override
  ConsumerState<FormulasHistoryScreen> createState() =>
      _FormulasHistoryScreenState();
}

class _FormulasHistoryScreenState
    extends ConsumerState<FormulasHistoryScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<FormulaModel> _filtered(List<FormulaModel> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((f) {
      return f.displayTitle.toLowerCase().contains(q) ||
          f.displayService.toLowerCase().contains(q) ||
          (f.formulaName?.toLowerCase().contains(q) ?? false) ||
          (f.notes?.toLowerCase().contains(q) ?? false) ||
          (f.createdAt?.contains(q) ?? false) ||
          f.items.any((i) =>
              (i.productCode?.toLowerCase().contains(q) ?? false) ||
              (i.productName?.toLowerCase().contains(q) ?? false));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final formulasAsync = ref.watch(formulasProvider);
    final customerNamesAsync = ref.watch(formulaCustomerNamesProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go(AppRoutes.mix),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'Formulas',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: -0.4,
                  height: 1.15,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search by client, service or date',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: cs.onSurfaceVariant,
                    size: 22,
                  ),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            Expanded(
              child: formulasAsync.when(
                loading: () => const SkeletonList(),
                error: (err, _) => ErrorState(
                  message:
                      err.toString().replaceFirst('Exception: ', ''),
                  onRetry: () =>
                      ref.read(formulasProvider.notifier).refresh(),
                ),
                data: (formulas) {
                  final filtered = _filtered(formulas);
                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.history_rounded,
                      title: _query.isEmpty
                          ? 'No formulas yet'
                          : 'No results',
                      subtitle: _query.isEmpty
                          ? 'Save your first formula to see history'
                          : 'Try a different search term',
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () =>
                        ref.read(formulasProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding:
                          const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final formula = filtered[i];
                        final customerId = formula.customerId;
                        final customerMap =
                            customerNamesAsync.valueOrNull ?? const <String, String>{};
                        final resolvedClient = customerId != null
                            ? customerMap[customerId]
                            : null;
                        return _FormulaListTile(
                          formula: formula,
                          clientName: resolvedClient ?? formula.customerName,
                          onTap: () => context.push('/formulas/${formula.id}'),
                        );
                      },
                    ),
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

class _FormulaListTile extends StatelessWidget {
  final FormulaModel formula;
  final String? clientName;
  final VoidCallback? onTap;

  const _FormulaListTile({
    required this.formula,
    this.clientName,
    this.onTap,
  });

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso).toLocal();
      final y = d.year.toString().padLeft(4, '0');
      final m = d.month.toString().padLeft(2, '0');
      final day = d.day.toString().padLeft(2, '0');
      return '$y-$m-$day';
    } catch (_) {
      return iso.length >= 10 ? iso.substring(0, 10) : iso;
    }
  }

  String get _subtitle {
    final date = _formatDate(formula.createdAt);
    final service = formula.displayService;
    final client = clientName?.trim();
    final title = formula.displayTitle.trim().toLowerCase();
    final normalizedService = service.trim().toLowerCase();
    final parts = <String>[
      (client != null && client.isNotEmpty) ? client : 'Unknown client',
      if (normalizedService.isNotEmpty && normalizedService != title) service,
      if (date.isNotEmpty) date,
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final cost = formula.computedCost;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: isDark ? 0.15 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.science_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formula.displayTitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${cost.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
