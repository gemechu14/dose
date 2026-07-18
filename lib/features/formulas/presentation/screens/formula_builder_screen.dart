import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/utils/responsive.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tenants/presentation/providers/tenant_provider.dart';
import '../../data/models/formula_model.dart';
import '../../data/repositories/formulas_repository_impl.dart';
import '../../domain/mix_models.dart';
import '../providers/formulas_provider.dart';
import '../providers/mix_builder_provider.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../widgets/formula_droplet.dart';
import '../widgets/product_picker_sheet.dart';

List<String> _candidateFormulaIdsFromVisitResponse(Map<String, dynamic> body) {
  final ids = <String>{};

  void addId(Object? value) {
    if (value is String && value.isNotEmpty) ids.add(value);
  }

  addId(body['formula_id']);
  addId(body['id']);

  for (final key in ['formulas', 'items', 'formula_ids']) {
    final value = body[key];
    if (value is! List) continue;
    for (final entry in value) {
      if (entry is String) {
        addId(entry);
      } else if (entry is Map<String, dynamic>) {
        addId(entry['id']);
        addId(entry['formula_id']);
      } else if (entry is Map) {
        addId(entry['id']);
        addId(entry['formula_id']);
      }
    }
  }

  return ids.toList();
}

// ─────────────────────────────────────────────────────────────────────────────
//  FormulaBuilderScreen
// ─────────────────────────────────────────────────────────────────────────────

class FormulaBuilderScreen extends ConsumerStatefulWidget {
  final String? preloadFormulaId;
  const FormulaBuilderScreen({super.key, this.preloadFormulaId});

  @override
  ConsumerState<FormulaBuilderScreen> createState() =>
      _FormulaBuilderScreenState();
}

class _FormulaBuilderScreenState
    extends ConsumerState<FormulaBuilderScreen> {
  final _serviceCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _sessionCtrl = TextEditingController();
  bool _saving = false;
  bool _draftLoaded = false;
  String? _customerSearch;
  Timer? _autosaveTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    if (widget.preloadFormulaId == null) {
      await _loadDraft();
    } else {
      await _preloadFormula(widget.preloadFormulaId!);
    }
  }

  Future<void> _loadDraft() async {
    if (_draftLoaded) return;
    _draftLoaded = true;
    try {
      final key = await ref.read(mixDraftKeyProvider.future);
      final storage = ref.read(secureStorageProvider);
      await ref.read(mixBuilderProvider.notifier).loadDraft(storage, key);
      final st = ref.read(mixBuilderProvider);
      if (st.serviceType != null) _serviceCtrl.text = st.serviceType!;
      if (st.notes != null) _notesCtrl.text = st.notes!;
      if (st.sessionName != null) _sessionCtrl.text = st.sessionName!;
    } catch (_) {}
  }

  Future<void> _preloadFormula(String id) async {
    try {
      final formula = await ref.read(formulaDetailProvider(id).future);
      final catalog = await ref.read(tenantCatalogProvider.future);
      ref.read(mixBuilderProvider.notifier).applyFormula(
            formula, ReuseMode.use, catalog);
      _serviceCtrl.text = formula.serviceType ?? '';
      _notesCtrl.text = formula.notes ?? '';
    } catch (_) {}
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _serviceCtrl.dispose();
    _notesCtrl.dispose();
    _sessionCtrl.dispose();
    super.dispose();
  }

  void _scheduleSave() {
    _autosaveTimer?.cancel();
    _autosaveTimer =
        Timer(const Duration(milliseconds: 700), _autosave);
  }

  void _autosave() async {
    try {
      final key = await ref.read(mixDraftKeyProvider.future);
      final storage = ref.read(secureStorageProvider);
      await ref.read(mixBuilderProvider.notifier).saveDraft(storage, key);
    } catch (_) {}
  }

  // ── Finalize ───────────────────────────────────────────────────────────────

  Future<void> _saveVisit() async {
    final st = ref.read(mixBuilderProvider);
    if (st.customerId == null) {
      _snack('Please select a client first.');
      return;
    }
    if (st.locationId == null) {
      _snack('Please select a location first.');
      return;
    }
    if (!st.isValid) {
      _snack('Add at least one product with an amount > 0.');
      return;
    }

    // Always require finalize dialog (waste per bowl) before save.
    final confirmed = await _showFinalizeDialog(st);
    if (!confirmed) return;

    setState(() => _saving = true);
    try {
      final tenantId = await ref.read(currentTenantIdProvider.future);
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? '';
      final updatedSt = ref.read(mixBuilderProvider);
      final payload = updatedSt.toVisitPayload(
        tenantId: tenantId,
        locationId: updatedSt.locationId!,
        userId: userId,
      );

      final dio = ref.read(dioProvider);
      final response = await dio.post('/formulas/visit', data: payload);
      String? savedFormulaId;
      final formulasRepo = ref.read(formulasRepositoryProvider);
      final formulaName = (payload['formula_name'] ?? '').toString().trim();
      final body = response.data;
      if (body is Map<String, dynamic>) {
        for (final id in _candidateFormulaIdsFromVisitResponse(body)) {
          final check = await formulasRepo.getFormula(id);
          await check.fold(
            (_) async {},
            (formula) async {
              savedFormulaId ??= id;
              final currentName = (formula.formulaName ?? '').trim();
              if (currentName != formulaName) {
                await formulasRepo.updateFormula(
                  id,
                  {'formula_name': formulaName},
                );
              }
            },
          );
        }
      }

      if (savedFormulaId == null) {
        final customerId = (payload['customer_id'] ?? '').toString();
        final listResult = await formulasRepo.getFormulas(page: 1, pageSize: 20);
        listResult.fold(
          (_) {},
          (page) {
            for (final f in page.results) {
              final sameCustomer = f.customerId == customerId;
              final sameName = (f.formulaName ?? '').trim() == formulaName;
              if (sameCustomer && sameName) {
                savedFormulaId = f.id;
                break;
              }
            }
            if (savedFormulaId == null && page.results.isNotEmpty) {
              savedFormulaId = page.results.first.id;
            }
          },
        );
      }

      ref.invalidate(formulasProvider);
      ref.invalidate(builderInventoryProvider);

      final key = await ref.read(mixDraftKeyProvider.future);
      final storage = ref.read(secureStorageProvider);
      await ref.read(mixBuilderProvider.notifier).clearDraft(storage, key);
      ref.read(mixBuilderProvider.notifier).resetMix();
      _serviceCtrl.clear();
      _notesCtrl.clear();
      _sessionCtrl.clear();

      if (!mounted) return;
      final bowlCount = payload['bowls'] is List
          ? (payload['bowls'] as List).length
          : 1;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Formula finalized — $bowlCount bowl${bowlCount > 1 ? 's' : ''} saved'),
        backgroundColor: AppColors.success,
      ));
      if (savedFormulaId != null) {
        context.push('/formulas/$savedFormulaId');
      } else {
        context.push(AppRoutes.formulaHistory);
      }
    } on DioException catch (e) {
      _snack(_stockAwareErrorMessage(e));
    } catch (e) {
      _snack('Finalize failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _stockAwareErrorMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final shortages =
          data['shortages'] ?? data['stock_shortages'] ?? data['insufficient_stock'];
      if (shortages is List && shortages.isNotEmpty) {
        final details = shortages.take(4).map((s) {
          if (s is! Map) return null;
          final m = Map<String, dynamic>.from(s);
          final name = (m['product_name'] ??
                  m['name'] ??
                  m['product_code'] ??
                  m['tenant_product_id'] ??
                  'Product')
              .toString();
          final needed = (m['required_qty'] ?? m['required'] ?? m['needed'] ?? '?')
              .toString();
          final onHand = (m['on_hand_qty'] ?? m['available'] ?? m['on_hand'] ?? '?')
              .toString();
          return '$name (need $needed, have $onHand)';
        }).whereType<String>().toList();
        if (details.isNotEmpty) {
          return 'Not enough stock for: ${details.join('; ')}';
        }
      }

      final message = data['detail'] ?? data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) {
        return 'Finalize failed: $message';
      }
    }
    return 'Finalize failed: ${parseDioError(e)}';
  }

  Future<bool> _showFinalizeDialog(MixBuilderState st) async {
    final indexedBowls = st.bowls
        .asMap()
        .entries
        .where((e) => e.value.allItems.any((i) => i.amount > 0))
        .toList();
    if (indexedBowls.isEmpty) return false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _FinalizeFormulaDialog(
        indexedBowls: indexedBowls,
        onSaved: _scheduleSave,
        initialFormulaName: st.sessionName ?? '',
      ),
    );
    return confirmed ?? false;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(mixBuilderProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, st),
            Expanded(
              child: ResponsiveConstraint(
                child: SingleChildScrollView(
                  padding: Responsive.pagePadding(context).copyWith(
                    top: 16,
                    bottom: 16,
                  ),
                  child: Column(
                  children: [
                    _ClientServiceCard(
                      serviceCtrl: _serviceCtrl,
                      sessionCtrl: _sessionCtrl,
                      customerSearch: _customerSearch,
                      onSearchChanged: (v) =>
                          setState(() => _customerSearch = v),
                      onAutosave: _scheduleSave,
                    ),
                    if (st.bowls.length > 1) ...[
                      const SizedBox(height: 10),
                      _BowlTabs(state: st),
                    ],
                    const SizedBox(height: 16),
                    // Only the ACTIVE bowl card is shown.
                    // All bowls shown as tabs above.
                    if (st.bowls.isNotEmpty)
                      _BowlCard(
                        bowlIndex: st.activeBowlIndex,
                        onAutosave: _scheduleSave,
                        canRemove: st.bowls.length > 1,
                      ),
                    const SizedBox(height: 16),
                    _AddBowlButton(
                      onAdd: (label) {
                        ref
                            .read(mixBuilderProvider.notifier)
                            .addBowl(label);
                        _scheduleSave();
                      },
                    ),
                    const SizedBox(height: 16),
                    _PreviewCard(state: st),
                    const SizedBox(height: 16),
                    _NotesCard(ctrl: _notesCtrl, onAutosave: _scheduleSave),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _SaveBar(saving: _saving, onSave: _saveVisit),
    );
  }

  Widget _buildHeader(BuildContext context, MixBuilderState st) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Formula',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface),
            ),
          ),
          // AI badge — hidden
          // const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              final confirm = await showConfirmDialog(
                context,
                title: 'Start a new mix?',
                message:
                    'This clears all bowls, products, and notes from the current session.',
                confirmLabel: 'Clear & start',
                isDestructive: false,
                icon: Icons.refresh_rounded,
              );
              if (!confirm) return;
              if (!context.mounted) return;
              ref.read(mixBuilderProvider.notifier).resetMix();
              _serviceCtrl.clear();
              _notesCtrl.clear();
              _sessionCtrl.clear();
              final key = await ref.read(mixDraftKeyProvider.future);
              final storage = ref.read(secureStorageProvider);
              await ref
                  .read(mixBuilderProvider.notifier)
                  .clearDraft(storage, key);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ready for a new mix'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('New mix',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bowl tabs
// ─────────────────────────────────────────────────────────────────────────────

class _BowlTabs extends ConsumerWidget {
  final MixBuilderState state;
  const _BowlTabs({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: state.bowls.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final bowl = state.bowls[i];
          final active = i == state.activeBowlIndex;
          return GestureDetector(
            onTap: () =>
                ref.read(mixBuilderProvider.notifier).setActiveBowl(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: active ? cs.primary : cs.surface,
                borderRadius: BorderRadius.circular(20),
                border: active
                    ? null
                    : Border.all(color: cs.outline),
              ),
              alignment: Alignment.center,
              child: Text(
                bowl.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : cs.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Client + Service card
// ─────────────────────────────────────────────────────────────────────────────

class _ClientServiceCard extends ConsumerStatefulWidget {
  final TextEditingController serviceCtrl;
  final TextEditingController sessionCtrl;
  final String? customerSearch;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAutosave;

  const _ClientServiceCard({
    required this.serviceCtrl,
    required this.sessionCtrl,
    required this.customerSearch,
    required this.onSearchChanged,
    required this.onAutosave,
  });

  @override
  ConsumerState<_ClientServiceCard> createState() =>
      _ClientServiceCardState();
}

class _ClientServiceCardState
    extends ConsumerState<_ClientServiceCard> {
  bool _showCustomerList = false;

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(mixBuilderProvider);
    final cs = Theme.of(context).colorScheme;
    final customersAsync = ref.watch(builderCustomersProvider);
    final locationsAsync = ref.watch(tenantLocationsProvider); // used silently

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Client picker ─────────────────────────────────────────────
          const _Label('Client'),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () =>
                setState(() => _showCustomerList = !_showCustomerList),
            child: _PickerBox(
              child: Row(
                children: [
                  Icon(Icons.person_outline,
                      size: 18, color: cs.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      st.customerName ?? 'Select client…',
                      style: TextStyle(
                        fontSize: 14,
                        color: st.customerName != null
                            ? cs.onSurface
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (st.customerId != null)
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(mixBuilderProvider.notifier)
                            .setCustomer(null);
                        widget.onAutosave();
                      },
                      child: Icon(Icons.close,
                          size: 18, color: cs.onSurfaceVariant),
                    )
                  else
                    Icon(Icons.expand_more,
                        size: 18, color: cs.onSurfaceVariant),
                ],
              ),
            ),
          ),

          // Customer dropdown
          if (_showCustomerList)
            _CustomerDropdown(
              search: widget.customerSearch,
              customersAsync: customersAsync,
              onSearch: widget.onSearchChanged,
              onSelect: (c) {
                ref.read(mixBuilderProvider.notifier).setCustomer(c);
                setState(() => _showCustomerList = false);
                widget.onAutosave();
              },
            ),

          // ── Location (hidden — auto-selected) ─────────────────────────
          // History for selected customer
          if (st.customerId != null) ...[
            const SizedBox(height: 12),
            _CustomerHistoryPanel(customerId: st.customerId!),
          ],

          // ── Location (hidden — auto-selected) ─────────────────────────
          // ignore: unused_local_variable
          // ignore: dead_code
          // Location is silently auto-selected from the first available.
          // Rebuild trigger only.
          Builder(builder: (_) {
            locationsAsync.whenData((locations) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (st.locationId == null && locations.isNotEmpty) {
                  ref
                      .read(mixBuilderProvider.notifier)
                      .setLocation(locations.first);
                }
              });
            });
            return const SizedBox.shrink();
          }),

          // ── Service type is hidden ─────────────────────────────────────
        ],
      ),
    );
  }
}

class _CustomerDropdown extends ConsumerWidget {
  final String? search;
  final AsyncValue<dynamic> customersAsync;
  final ValueChanged<String> onSearch;
  final Function(dynamic) onSelect;

  const _CustomerDropdown({
    required this.search,
    required this.customersAsync,
    required this.onSearch,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: context.sheetSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search…',
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                filled: true,
                fillColor: context.subtleFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: onSearch,
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: customersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('$e')),
              data: (customers) {
                final q = (search ?? '').toLowerCase();
                final filtered = q.isEmpty
                    ? customers
                    : (customers as List)
                        .where((c) =>
                            c.fullName.toLowerCase().contains(q))
                        .toList();
                if (filtered.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No clients found',
                        style: TextStyle(color: Colors.grey)),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final c = filtered[i];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor:
                            AppColors.primary.withValues(alpha: 0.12),
                        child: Text(
                          c.avatarLetter,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                      title: Text(c.fullName,
                          style: const TextStyle(fontSize: 14)),
                      onTap: () => onSelect(c),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Customer history panel
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerHistoryPanel extends ConsumerWidget {
  final String customerId;
  const _CustomerHistoryPanel({required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formulasAsync =
        ref.watch(customerFormulasForBuilderProvider(customerId));
    return formulasAsync.when(
      loading: () => const SizedBox(
          height: 40, child: Center(child: LinearProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (formulas) {
        if (formulas.isEmpty) return const SizedBox.shrink();
        final capped = formulas.take(6).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label('Past formulas'),
            const SizedBox(height: 8),
            SizedBox(
              height: 88,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: capped.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) =>
                    _HistoryChip(formula: capped[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HistoryChip extends ConsumerWidget {
  final FormulaModel formula;
  const _HistoryChip({required this.formula});

  bool _hasStartedMix(MixBuilderState st) {
    if (st.bowls.length > 1) return true;
    for (final bowl in st.bowls) {
      if (bowl.batches.length > 1) return true;
      if (bowl.batches.any((b) => b.isLocked)) return true;
      if (bowl.allItems.any((i) => i.amount > 0)) return true;
    }
    return false;
  }

  Future<void> _applyFromHistory(
    BuildContext context,
    WidgetRef ref, {
    required ReuseMode mode,
  }) async {
    final current = ref.read(mixBuilderProvider);
    if (_hasStartedMix(current)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You already started this mix. Tap New mix before using past formulas.',
          ),
        ),
      );
      return;
    }

    final catalog = await ref.read(tenantCatalogProvider.future);
    ref.read(mixBuilderProvider.notifier).applyFormula(formula, mode, catalog);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;
    return GestureDetector(
      onTap: () => context.push('/formulas/${formula.id}'),
      child: Container(
        width: 150,
        padding: const EdgeInsets.fromLTRB(10, 10, 6, 6),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formula.displayTitle,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              formula.displayService,
              style: TextStyle(
                  fontSize: 11, color: cs.onSurfaceVariant),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _ChipAction(
                  tooltip: 'Remix',
                  icon: Icons.edit_rounded,
                  color: AppColors.primary,
                  isPrimary: true,
                  onTap: () => _applyFromHistory(
                    context,
                    ref,
                    mode: ReuseMode.remix,
                  ),
                ),
                const SizedBox(width: 6),
                _ChipAction(
                  tooltip: 'Use',
                  icon: Icons.check_rounded,
                  color: AppColors.primary,
                  label: 'Use',
                  onTap: () => _applyFromHistory(
                    context,
                    ref,
                    mode: ReuseMode.use,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChipAction extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isPrimary;
  final String? label;

  const _ChipAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isPrimary = false,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: label != null ? 44 : (isPrimary ? 34 : 28),
          height: 28,
          decoration: BoxDecoration(
            color: isPrimary ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: label != null
              ? Center(
                  child: Text(
                    label!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isPrimary ? Colors.white : color,
                    ),
                  ),
                )
              : Icon(
                  icon,
                  size: isPrimary ? 16 : 15,
                  color: isPrimary ? Colors.white : color,
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bowl card — shows active bowl only
// ─────────────────────────────────────────────────────────────────────────────

class _BowlCard extends ConsumerStatefulWidget {
  final int bowlIndex;
  final VoidCallback onAutosave;
  final bool canRemove;

  const _BowlCard({
    required this.bowlIndex,
    required this.onAutosave,
    required this.canRemove,
  });

  @override
  ConsumerState<_BowlCard> createState() => _BowlCardState();
}

class _BowlCardState extends ConsumerState<_BowlCard> {
  @override
  Widget build(BuildContext context) {
    final st = ref.watch(mixBuilderProvider);
    final cs = Theme.of(context).colorScheme;
    if (widget.bowlIndex >= st.bowls.length) return const SizedBox.shrink();
    final bowl = st.bowls[widget.bowlIndex];
    const ratios = DeveloperRatio.values;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Bowl header ────────────────────────────────────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  bowl.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Editable label
              GestureDetector(
                onTap: () => _editLabel(context, bowl.label),
                child: Icon(Icons.edit_outlined,
                    size: 15, color: Colors.grey.shade400),
              ),
              const Spacer(),
              Text('\$${bowl.totalCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted)),
              if (widget.canRemove) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    final ok = await showConfirmDialog(
                      context,
                      title: 'Remove bowl?',
                      message:
                          'Remove "${bowl.label}" and all its batches from this mix?',
                      confirmLabel: 'Remove',
                      isDestructive: true,
                      icon: Icons.delete_outline_rounded,
                    );
                    if (ok) {
                      ref
                          .read(mixBuilderProvider.notifier)
                          .removeBowl(widget.bowlIndex);
                      widget.onAutosave();
                    }
                  },
                  child: Icon(Icons.delete_outline,
                      size: 18, color: Colors.red.shade300),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Ratio selector ─────────────────────────────────────────────
          const _Label('Developer ratio'),
          const SizedBox(height: 8),
          Row(
            children: ratios.map((r) {
              final label = ratioLabel(r);
              final active = bowl.developerRatio == r;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    ref
                        .read(mixBuilderProvider.notifier)
                        .setBowlRatio(widget.bowlIndex, r);
                    widget.onAutosave();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? cs.primary : context.subtleFill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: active ? cs.primary : cs.outline),
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Batches ────────────────────────────────────────────────────
          ...List.generate(bowl.batches.length, (bi) {
            return _BatchSection(
              bowlIndex: widget.bowlIndex,
              batchIndex: bi,
              ratio: bowl.developerRatio,
              onAutosave: widget.onAutosave,
              isLast: bi == bowl.batches.length - 1,
              batchNumber: bi + 1,
              totalBatches: bowl.batches.length,
            );
          }),

          // ── Mix more ───────────────────────────────────────────────────
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Mix more'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              minimumSize: const Size(double.infinity, 0),
            ),
            onPressed: () =>
                _showMixMoreDialog(context, bowl, widget.bowlIndex),
          ),
        ],
      ),
    );
  }

  Future<void> _editLabel(BuildContext context, String current) async {
    final label = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.sheetSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _LabelInputSheet(
        title: 'Bowl label',
        hint: 'roots, toner, highlights…',
        confirmText: 'Save',
        initialValue: current,
      ),
    );

    if (!mounted) return;
    if (label != null && label.isNotEmpty) {
      ref
          .read(mixBuilderProvider.notifier)
          .setBowlLabel(widget.bowlIndex, label);
      widget.onAutosave();
    }
  }

  Future<void> _showMixMoreDialog(
      BuildContext context, MixBowl bowl, int bowlIndex) async {
    final currentBatch = bowl.currentBatch;
    final totalMixed = currentBatch.totalGrams;
    if (totalMixed == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Add at least one product with an amount before mixing more.')),
      );
      return;
    }

    final wasteCtrl = TextEditingController();
    MixMoreMode mode = MixMoreMode.copyFormula;
    String wasteError = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final wasteG = double.tryParse(wasteCtrl.text) ?? 0;
          String splitPreview = '';
          if (wasteG > 0) {
            if (bowl.developerRatio == DeveloperRatio.manual) {
              final pigment = currentBatch.pigmentGrams;
              final dev = currentBatch.developerGrams;
              if (totalMixed > 0) {
                final pigW =
                    pigment > 0 ? (wasteG * pigment / totalMixed) : 0.0;
                final devW =
                    dev > 0 ? (wasteG * dev / totalMixed) : 0.0;
                splitPreview =
                    '${pigW.toStringAsFixed(1)}g color · ${devW.toStringAsFixed(1)}g dev';
              }
            } else {
              final split = splitBowlWaste(wasteG, bowl.developerRatio);
              splitPreview =
                  '${split.pigmentWaste.toStringAsFixed(1)}g color · '
                  '${split.developerWaste.toStringAsFixed(1)}g dev';
            }
          }

          final bowlName =
              '${bowl.label[0].toUpperCase()}${bowl.label.substring(1)}';

          return DraggableScrollableSheet(
            initialChildSize: 0.92,
            minChildSize: 0.5,
            maxChildSize: 1.0,
            builder: (_, scrollCtrl) => Container(
              decoration: BoxDecoration(
                color: ctx.sheetSurface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // ── Drag handle
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(ctx).dividerColor.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.science_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bowlName,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(ctx).colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'Batch ${bowl.batches.length} complete?',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(ctx)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: ctx.subtleFill,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),

                  // ── Scrollable body
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                      children: [
                        // Stats row
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: ctx.subtleCard,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Theme.of(ctx).colorScheme.outline),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatPill(
                                  label: 'Mixed',
                                  value:
                                      '${totalMixed.toStringAsFixed(1)}g',
                                  icon: Icons.colorize_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatPill(
                                  label: 'Ratio',
                                  value: ratioLabel(bowl.developerRatio),
                                  icon: Icons.tune_rounded,
                                  color: Colors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Waste input
                        Text(
                          'Leftover waste',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Weigh the total leftover in the bowl and enter it below.',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: wasteCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          style: TextStyle(
                              color: Theme.of(ctx).colorScheme.onSurface),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          decoration: mixInputDecoration(
                            ctx,
                            labelText: 'Total bowl waste',
                            suffixText: 'g',
                            errorText:
                                wasteError.isEmpty ? null : wasteError,
                            borderRadius: 12,
                          ),
                          onChanged: (_) => setDlgState(() {}),
                        ),
                        if (splitPreview.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.18)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 16,
                                    color: AppColors.primary
                                        .withValues(alpha: 0.7)),
                                const SizedBox(width: 8),
                                Text(
                                  '≈ $splitPreview',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),

                        // Next mix options
                        Text(
                          'What next?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ModeOption(
                          selected: mode == MixMoreMode.copyFormula,
                          title: 'Copy formula',
                          subtitle:
                              'Same bowl — new batch with same products',
                          onTap: () => setDlgState(
                              () => mode = MixMoreMode.copyFormula),
                        ),
                        const SizedBox(height: 8),
                        _ModeOption(
                          selected: mode == MixMoreMode.editFormula,
                          title: 'Edit formula',
                          subtitle: 'New bowl — edit a fresh mix',
                          onTap: () => setDlgState(
                              () => mode = MixMoreMode.editFormula),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),

                  // ── Action buttons
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        20, 12, 20, 12 + MediaQuery.of(ctx).padding.bottom),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, -3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            style: OutlinedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              final waste =
                                  double.tryParse(wasteCtrl.text) ?? 0;
                              if (waste < 0) {
                                setDlgState(() =>
                                    wasteError = 'Cannot be negative');
                                return;
                              }
                              if (waste > totalMixed) {
                                setDlgState(() =>
                                    wasteError = 'Exceeds mixed total');
                                return;
                              }
                              Navigator.pop(ctx);
                              ref
                                  .read(mixBuilderProvider.notifier)
                                  .mixMore(
                                    bowlIndex,
                                    mode: mode,
                                    leftoverG: waste > 0
                                        ? waste.toString()
                                        : '',
                                  );
                              widget.onAutosave();
                              final toast = mode == MixMoreMode.copyFormula
                                  ? 'Batch ${bowl.batches.length} locked. '
                                    'Batch ${bowl.batches.length + 1} ready — '
                                    'same formula.'
                                  : 'Batch ${bowl.batches.length} locked. '
                                    'New bowl ready — edit your mix.';
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(toast)));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text('Confirm & continue',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 10, color: color.withValues(alpha: 0.7))),
              Text(value,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeOption extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ModeOption({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.08)
              : context.subtleFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? cs.primary : cs.outline),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 18,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? cs.primary : cs.onSurface)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Batch section within a bowl
// ─────────────────────────────────────────────────────────────────────────────

class _BatchSection extends ConsumerWidget {
  final int bowlIndex;
  final int batchIndex;
  final DeveloperRatio ratio;
  final bool isLast;
  final int batchNumber;
  final int totalBatches;
  final VoidCallback onAutosave;

  const _BatchSection({
    required this.bowlIndex,
    required this.batchIndex,
    required this.ratio,
    required this.isLast,
    required this.batchNumber,
    required this.totalBatches,
    required this.onAutosave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(mixBuilderProvider);
    if (bowlIndex >= st.bowls.length) return const SizedBox.shrink();
    final bowl = st.bowls[bowlIndex];
    if (batchIndex >= bowl.batches.length) return const SizedBox.shrink();
    final batch = bowl.batches[batchIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (totalBatches > 1)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Text('Batch $batchNumber',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted)),
                if (batch.isLocked) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.lock_outline,
                      size: 14, color: Colors.grey.shade400),
                  if (batch.leftoverG.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text('Waste: ${batch.leftoverG}g',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade600)),
                  ],
                ],
              ],
            ),
          ),
        ...List.generate(batch.items.length, (ii) {
          final item = batch.items[ii];
          return _ItemRow(
            bowlIndex: bowlIndex,
            batchIndex: batchIndex,
            item: item,
            locked: batch.isLocked,
            ratio: ratio,
            onAutosave: onAutosave,
          );
        }),
        if (!batch.isLocked)
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: GestureDetector(
              onTap: () async {
                final product =
                    await ProductPickerSheet.show(context);
                if (product != null) {
                  ref
                      .read(mixBuilderProvider.notifier)
                      .addItemToBatch(bowlIndex, batchIndex, product);
                  onAutosave();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add,
                        size: 16,
                        color: AppColors.primary.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Text('Add product',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary.withValues(alpha: 0.8),
                        )),
                  ],
                ),
              ),
            ),
          ),
        if (totalBatches > 1 && !isLast) const Divider(height: 24),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Item row
// ─────────────────────────────────────────────────────────────────────────────

class _ItemRow extends ConsumerStatefulWidget {
  final int bowlIndex;
  final int batchIndex;
  final MixItem item;
  final bool locked;
  final DeveloperRatio ratio;
  final VoidCallback onAutosave;

  const _ItemRow({
    required this.bowlIndex,
    required this.batchIndex,
    required this.item,
    required this.locked,
    required this.ratio,
    required this.onAutosave,
  });

  @override
  ConsumerState<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends ConsumerState<_ItemRow> {
  late final TextEditingController _ctrl;
  late final FocusNode _focus;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    _ctrl = TextEditingController(
      text: widget.item.amount > 0
          ? widget.item.amount.toStringAsFixed(1)
          : '',
    );
  }

  @override
  void didUpdateWidget(_ItemRow old) {
    super.didUpdateWidget(old);
    if (widget.item.amount != old.item.amount && !_focus.hasFocus) {
      _ctrl.text = widget.item.amount > 0
          ? widget.item.amount.toStringAsFixed(1)
          : '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onAmountChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final amount = double.tryParse(v) ?? 0;
      ref.read(mixBuilderProvider.notifier).updateItemAmount(
            widget.bowlIndex, widget.batchIndex, widget.item.id, amount);
      widget.onAutosave();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final product = widget.item.product;
    final hex = (product.colorHex ?? '').replaceFirst('#', '');
    Color? swatch;
    if (hex.length >= 6) {
      final v = int.tryParse('FF${hex.substring(0, 6)}', radix: 16);
      if (v != null) swatch = Color(v);
    }
    final isDevAutoCalc =
        product.isDeveloper && widget.ratio != DeveloperRatio.manual;
    final isDisabled = widget.locked || isDevAutoCalc;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: swatch ?? cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outline),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.label,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (product.isDeveloper)
                  Text(
                    isDevAutoCalc
                        ? 'Auto-calculated from color amount'
                        : 'Developer',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDevAutoCalc
                          ? cs.primary
                          : cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _ctrl,
              focusNode: _focus,
              enabled: !isDisabled,
              style: TextStyle(color: cs.onSurface, fontSize: 14),
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*')),
              ],
              textAlign: TextAlign.center,
              decoration: mixInputDecoration(
                context,
                hintText: '0',
                suffixText: 'g',
                borderRadius: 8,
                fillColor: isDisabled
                    ? cs.onSurface.withValues(alpha: 0.06)
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: _onAmountChanged,
            ),
          ),
          const SizedBox(width: 8),
          if (!widget.locked)
            GestureDetector(
              onTap: () {
                ref
                    .read(mixBuilderProvider.notifier)
                    .removeItemFromBatch(
                        widget.bowlIndex, widget.batchIndex, widget.item.id);
                widget.onAutosave();
              },
              child: Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.destructive.withValues(alpha: 0.75),
              ),
            )
          else
            const SizedBox(width: 28),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Add bowl button
// ─────────────────────────────────────────────────────────────────────────────

class _AddBowlButton extends StatelessWidget {
  final ValueChanged<String> onAdd;
  const _AddBowlButton({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: cs.outline),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                size: 18, color: cs.primary),
            const SizedBox(width: 8),
            Text('Add another bowl',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: cs.primary)),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    const labels = ['roots', 'toner', 'highlights', 'gloss', 'custom'];
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Bowl type',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
            ),
            ...labels.map((l) => ListTile(
                  title: Text(l[0].toUpperCase() + l.substring(1)),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    if (l == 'custom') {
                      _showCustom(context);
                    } else {
                      onAdd(l);
                    }
                  },
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustom(BuildContext context) async {
    final label = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.sheetSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => const _LabelInputSheet(
        title: 'Custom bowl label',
        hint: 'e.g. mid-lengths',
        confirmText: 'Add',
        initialValue: '',
      ),
    );

    if (label != null && label.isNotEmpty) {
      onAdd(label);
    }
  }
}

class _LabelInputSheet extends StatefulWidget {
  final String title;
  final String hint;
  final String confirmText;
  final String initialValue;

  const _LabelInputSheet({
    required this.title,
    required this.hint,
    required this.confirmText,
    required this.initialValue,
  });

  @override
  State<_LabelInputSheet> createState() => _LabelInputSheetState();
}

class _LabelInputSheetState extends State<_LabelInputSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (v) {
              final value = v.trim();
              if (value.isNotEmpty) Navigator.of(context).pop(value);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final value = _controller.text.trim();
                    if (value.isEmpty) return;
                    Navigator.of(context).pop(value);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(widget.confirmText),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Live preview card — active bowl, current batch only
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewCard extends ConsumerWidget {
  final MixBuilderState state;
  const _PreviewCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Preview uses ONLY active bowl → current batch.
    final previewItems = state.previewItems;
    final catalog = ref.watch(tenantCatalogProvider).valueOrNull ?? [];
    final dropletItems = buildDropletItems(previewItems, catalog);
    final mix = mixColors(previewItems);
    final mixColor = Color(mix.argbColor);

    final totalGrams =
        previewItems.fold(0.0, (s, i) => s + i.amount);
    final totalCost =
        previewItems.fold(0.0, (s, i) => s + i.estimatedCost);

    final hasMix = previewItems.any((i) => i.amount > 0);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              const Text('Color preview',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.foreground)),
              const Spacer(),
              Text(
                state.activeBowl?.label ?? '',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted),
              ),
              if (hasMix) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showFullScreenPreview(
                    context,
                    mixColor: mixColor,
                    hexString: mix.hexString,
                    dropletItems: dropletItems,
                    totalGrams: totalGrams,
                    totalCost: totalCost,
                    bowlLabel: state.activeBowl?.label ?? '',
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.fullscreen_rounded,
                        size: 18, color: AppColors.muted),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          if (!hasMix) ...[
            Center(
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCCCCC),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(4),
                      ),
                      border: Border.all(
                          color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Add products to see preview',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400)),
                ],
              ),
            ),
          ] else ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flask visualization
                FormulaDroplet(
                  items: dropletItems,
                  flaskWidth: 70,
                  flaskHeight: 120,
                ),
                const SizedBox(width: 16),
                // Stats
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      // Mixed color swatch
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: mixColor,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.grey.shade200),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            mix.hexString,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _Stat(
                          label: 'Total amount',
                          value:
                              '${totalGrams.toStringAsFixed(1)}g'),
                      const SizedBox(height: 6),
                      _Stat(
                          label: 'Est. cost',
                          value:
                              '\$${totalCost.toStringAsFixed(2)}'),
                    ],
                  ),
                ),
              ],
            ),

            // Per-item percentage breakdown
            if (dropletItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              ...previewItems.where((i) => i.amount > 0).map((item) {
                final pct = totalGrams == 0
                    ? 0.0
                    : (item.amount / totalGrams) * 100;
                final hex = (item.product.colorHex ?? '')
                    .replaceFirst('#', '');
                Color? c;
                if (hex.length >= 6) {
                  final v = int.tryParse('FF${hex.substring(0, 6)}',
                      radix: 16);
                  if (v != null) c = Color(v);
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: c ?? Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(item.product.label,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text(
                        '${item.amount.toStringAsFixed(1)}g · '
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }

  void _showFullScreenPreview(
    BuildContext context, {
    required Color mixColor,
    required String hexString,
    required List<DropletItem> dropletItems,
    required double totalGrams,
    required double totalCost,
    required String bowlLabel,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.sheetSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Color preview',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(ctx).colorScheme.onSurface),
                  ),
                  const Spacer(),
                  if (bowlLabel.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(bowlLabel,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: ctx.subtleFill,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Large flask/cylinder visualization
                    FormulaDroplet(
                      items: dropletItems,
                      flaskWidth: 120,
                      flaskHeight: 190,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      hexString,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _StatPill(
                            label: 'Total',
                            value: '${totalGrams.toStringAsFixed(1)}g',
                            icon: Icons.science_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatPill(
                            label: 'Est. cost',
                            value: '\$${totalCost.toStringAsFixed(2)}',
                            icon: Icons.attach_money_rounded,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    ...dropletItems.map((item) {
                      final pct = totalGrams == 0
                          ? 0.0
                          : item.amount / totalGrams * 100;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Color(item.argbColor),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.label,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '${item.amount.toStringAsFixed(1)}g · '
                              '${pct.toStringAsFixed(0)}%',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      );
                    }),
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

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade400,
                fontWeight: FontWeight.w500)),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Notes card
// ─────────────────────────────────────────────────────────────────────────────

class _NotesCard extends ConsumerWidget {
  final TextEditingController ctrl;
  final VoidCallback onAutosave;
  const _NotesCard({required this.ctrl, required this.onAutosave});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('Notes'),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            maxLines: 4,
            style: TextStyle(color: cs.onSurface, fontSize: 14, height: 1.45),
            decoration: mixInputDecoration(
              context,
              hintText: 'Timing, developer notes, aftercare…',
              contentPadding: const EdgeInsets.all(14),
            ),
            onChanged: (v) {
              ref.read(mixBuilderProvider.notifier).setNotes(v);
              onAutosave();
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Save bar
// ─────────────────────────────────────────────────────────────────────────────

class _SaveBar extends ConsumerWidget {
  final bool saving;
  final VoidCallback onSave;
  const _SaveBar({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;
    final st = ref.watch(mixBuilderProvider);
    final bowlCount =
        st.bowls.where((b) => b.allItems.any((i) => i.amount > 0)).length;
    final label = bowlCount > 1
        ? 'Finalize $bowlCount bowls'
        : 'Finalize formula';

    final hasClient = st.customerId != null;
    final hasProduct =
        st.bowls.any((b) => b.allItems.any((i) => i.amount > 0));
    final canSave = hasClient && hasProduct;

    String? hint;
    if (!hasClient) {
      hint = 'Select a client to save';
    } else if (!hasProduct) {
      hint = 'Add at least one product with an amount';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hint != null)
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            color: isDark
                ? AppColors.warning.withValues(alpha: 0.15)
                : Colors.amber.shade50,
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 16,
                    color: isDark
                        ? AppColors.warning
                        : Colors.amber.shade700),
                const SizedBox(width: 8),
                Text(hint,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.warning
                            : Colors.amber.shade800)),
              ],
            ),
          ),
        Container(
          padding: EdgeInsets.fromLTRB(
              20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
          decoration: BoxDecoration(
            color: cs.surface,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3))
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: (saving || !canSave) ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: isDark
                    ? cs.onSurface.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
                disabledForegroundColor: isDark
                    ? cs.onSurfaceVariant
                    : Colors.grey.shade400,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: saving
                  ? const Text('Finalizing...',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700))
                  : Text(label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

InputDecoration mixInputDecoration(
  BuildContext context, {
  String? labelText,
  String? hintText,
  String? suffixText,
  String? errorText,
  double borderRadius = 10,
  bool filled = true,
  Color? fillColor,
  EdgeInsetsGeometry? contentPadding,
}) {
  final cs = Theme.of(context).colorScheme;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final radius = BorderRadius.circular(borderRadius);
  // In dark mode, fill and outline are often the same hex — use a lighter border
  // and a slightly different fill so fields are visible before focus.
  final enabledBorderColor = isDark
      ? cs.onSurface.withValues(alpha: 0.32)
      : cs.outline;
  final effectiveFill =
      fillColor ?? (isDark ? cs.surface : context.subtleFill);

  OutlineInputBorder outlineBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    suffixText: suffixText,
    errorText: errorText,
    filled: filled,
    fillColor: effectiveFill,
    labelStyle: TextStyle(color: cs.onSurfaceVariant),
    floatingLabelStyle: TextStyle(color: cs.onSurfaceVariant),
    hintStyle: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
    suffixStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
    isDense: true,
    contentPadding: contentPadding ??
        const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: outlineBorder(enabledBorderColor),
    enabledBorder: outlineBorder(enabledBorderColor),
    focusedBorder: outlineBorder(cs.primary, 2),
    errorBorder: outlineBorder(cs.error),
    focusedErrorBorder: outlineBorder(cs.error, 2),
  );
}

class _FinalizeFormulaDialog extends ConsumerStatefulWidget {
  final List<MapEntry<int, MixBowl>> indexedBowls;
  final VoidCallback onSaved;
  final String initialFormulaName;

  const _FinalizeFormulaDialog({
    required this.indexedBowls,
    required this.onSaved,
    this.initialFormulaName = '',
  });

  @override
  ConsumerState<_FinalizeFormulaDialog> createState() =>
      _FinalizeFormulaDialogState();
}

class _FinalizeFormulaDialogState extends ConsumerState<_FinalizeFormulaDialog> {
  late final Map<int, TextEditingController> _controllers;
  late final Map<int, String> _errors;
  late final TextEditingController _formulaNameCtrl;

  @override
  void initState() {
    super.initState();
    _formulaNameCtrl =
        TextEditingController(text: widget.initialFormulaName);
    _controllers = {
      for (final e in widget.indexedBowls)
        e.key: TextEditingController(text: e.value.leftoverG),
    };
    _errors = {for (final e in widget.indexedBowls) e.key: ''};
  }

  @override
  void dispose() {
    _formulaNameCtrl.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasValidationError {
    for (final e in widget.indexedBowls) {
      final bowl = e.value;
      final waste =
          double.tryParse(_controllers[e.key]!.text.trim()) ?? 0;
      if (waste < 0 || waste > bowl.totalGrams) return true;
    }
    return false;
  }

  void _confirm() {
    var valid = true;
    for (final e in widget.indexedBowls) {
      final bowl = e.value;
      final parsed =
          double.tryParse(_controllers[e.key]!.text.trim()) ?? 0;
      if (parsed < 0) {
        _errors[e.key] = 'Waste cannot be negative';
        valid = false;
      } else if (parsed > bowl.totalGrams) {
        _errors[e.key] =
            'Waste cannot exceed ${bowl.totalGrams.toStringAsFixed(1)}g mixed';
        valid = false;
      } else {
        _errors[e.key] = '';
      }
    }
    if (!valid) {
      setState(() {});
      return;
    }

    for (final e in widget.indexedBowls) {
      final text = _controllers[e.key]!.text.trim();
      final parsed = double.tryParse(text) ?? 0;
      ref.read(mixBuilderProvider.notifier).setBowlWaste(
            e.key,
            parsed > 0 ? parsed.toString() : '',
          );
    }
    ref
        .read(mixBuilderProvider.notifier)
        .setSessionName(_formulaNameCtrl.text.trim());
    widget.onSaved();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = context.isDark;

    return Dialog.fullscreen(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.indexedBowls.length > 1
                          ? 'Finalize ${widget.indexedBowls.length} bowls'
                          : 'Finalize formula',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _formulaNameCtrl,
                      style: TextStyle(color: cs.onSurface),
                      textCapitalization: TextCapitalization.sentences,
                      decoration: mixInputDecoration(
                        context,
                        labelText: 'Formula name (optional)',
                        hintText: 'e.g. Sarah — roots touch-up',
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...widget.indexedBowls.map((entry) {
                    final bowlIndex = entry.key;
                    final bowl = entry.value;
                    final wasteText = _controllers[bowlIndex]!.text.trim();
                    final waste = double.tryParse(wasteText) ?? 0;
                    final split = bowl
                        .copyWith(leftoverG: wasteText)
                        .computeWasteByProduct();

                    String splitPreview;
                    if (waste <= 0) {
                      splitPreview = 'No waste entered';
                    } else if (split.isEmpty) {
                      splitPreview = 'No split available';
                    } else {
                      final colorWaste = split.entries
                          .where((e) {
                            final item = bowl.allItems.firstWhere(
                                (i) => i.product.id == e.key,
                                orElse: () => MixItem(
                                    id: 'x',
                                    product: const TenantProduct(
                                        id: 'x', name: 'Unknown'),
                                    amount: 0));
                            return !item.product.isDeveloper;
                          })
                          .fold(0.0, (s, e) => s + e.value);
                      final devWaste =
                          split.values.fold(0.0, (s, v) => s + v) - colorWaste;
                      splitPreview =
                          '${colorWaste.toStringAsFixed(1)}g color · ${devWaste.toStringAsFixed(1)}g developer';
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.subtleCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bowl.label.trim().isEmpty
                                ? 'Bowl ${bowlIndex + 1}'
                                : bowl.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: cs.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mixed ${bowl.totalGrams.toStringAsFixed(1)}g · ${ratioLabel(bowl.developerRatio)} · ${bowl.batches.length} batch${bowl.batches.length > 1 ? 'es' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _controllers[bowlIndex],
                            style: TextStyle(color: cs.onSurface),
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                  RegExp(r'^\d*\.?\d*')),
                            ],
                            decoration: mixInputDecoration(
                              context,
                              labelText: 'Total bowl waste',
                              suffixText: 'g',
                              errorText: _errors[bowlIndex]!.isEmpty
                                  ? null
                                  : _errors[bowlIndex],
                            ),
                            onChanged: (_) => setState(() {
                              _errors[bowlIndex] = '';
                            }),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Waste split preview: $splitPreview',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant
                                  .withValues(alpha: 0.85),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Batches: ${bowl.batches.asMap().entries.map((b) => 'Batch ${b.key + 1} (${b.value.isLocked ? 'locked' : 'current'}): ${b.value.items.where((i) => i.amount > 0).length} items').join('  ·  ')}',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                12,
                16,
                12 + MediaQuery.of(context).padding.bottom,
              ),
              decoration: BoxDecoration(
                color: context.sheetSurface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _hasValidationError ? null : _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Confirm & finalize'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(text,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurfaceVariant));
  }
}

class _PickerBox extends StatelessWidget {
  final Widget child;
  const _PickerBox({required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outline),
      ),
      child: child,
    );
  }
}

