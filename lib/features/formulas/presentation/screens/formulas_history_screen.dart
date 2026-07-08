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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
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
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'Formulas',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F2744),
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
                style: const TextStyle(fontFamily: 'Inter', fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Search by client, service or date',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.mutedLight,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.muted,
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
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: formulasAsync.when(
                loading: () => const SkeletonList(),
                error: (err, _) => ErrorState(
                  message: err.toString().replaceFirst('Exception: ', ''),
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
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _FormulaListTile(
                        formula: filtered[i],
                        onTap: () =>
                            context.push('/formulas/${filtered[i].id}'),
                      ),
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
  final VoidCallback? onTap;

  const _FormulaListTile({
    required this.formula,
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
    if (date.isEmpty) return service;
    return '$service · $date';
  }

  @override
  Widget build(BuildContext context) {
    final cost = formula.computedCost;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EEF5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
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
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F2744),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.muted,
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
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.mutedLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
