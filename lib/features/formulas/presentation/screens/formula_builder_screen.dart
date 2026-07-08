import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../tenants/presentation/providers/tenant_provider.dart';
import '../../data/models/formula_model.dart';
import '../../domain/mix_models.dart';
import '../providers/formulas_provider.dart';
import '../providers/mix_builder_provider.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../widgets/formula_droplet.dart';
import '../widgets/product_picker_sheet.dart';

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

    // Show finalize dialog for waste entry.
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
      await dio.post('/formulas/visit', data: payload);

      ref.invalidate(formulasProvider);
      ref.invalidate(builderInventoryProvider);

      final key = await ref.read(mixDraftKeyProvider.future);
      final storage = ref.read(secureStorageProvider);
      await ref.read(mixBuilderProvider.notifier).clearDraft(storage, key);
      ref.read(mixBuilderProvider.notifier).resetMix();
      _serviceCtrl.clear();
      _notesCtrl.clear();
      _sessionCtrl.clear();

      if (mounted) {
        final bowlCount = payload['bowls'] is List
            ? (payload['bowls'] as List).length
            : 1;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Visit saved — $bowlCount bowl${bowlCount > 1 ? 's' : ''}'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _showFinalizeDialog(MixBuilderState st) async {
    final bowls = st.bowls
        .where((b) => b.allItems.any((i) => i.amount > 0))
        .toList();

    return showAppDialog(
      context,
      title: bowls.length > 1
          ? 'Finalize ${bowls.length} bowls'
          : 'Finalize formula',
      message: 'Inventory deducts the full mixed amount for each bowl.',
      icon: Icons.science_outlined,
      confirmLabel: 'Save visit',
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ...bowls.map((bowl) {
              final totalMixed = bowl.totalGrams;
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bowl.label.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bowl.batches.length} batch${bowl.batches.length > 1 ? 'es' : ''}'
                      ' · ${totalMixed.toStringAsFixed(1)}g mixed'
                      ' · \$${bowl.totalCost.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              );
            }),
            Text(
              'Total: ${st.totalGrams.toStringAsFixed(1)}g  ·  '
              '\$${st.totalCost.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
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
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, st),
            // Bowl tabs
            if (st.bowls.length > 1) _BowlTabs(state: st),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
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
          ],
        ),
      ),
      bottomNavigationBar: _SaveBar(saving: _saving, onSave: _saveVisit),
    );
  }

  Widget _buildHeader(BuildContext context, MixBuilderState st) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Formula',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.foreground),
            ),
          ),
          // AI badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('AI',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
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
    return Container(
      color: Colors.white,
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                color: active
                    ? AppColors.primary
                    : const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                bowl.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : AppColors.muted,
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
    final customersAsync = ref.watch(builderCustomersProvider);
    final locationsAsync = ref.watch(tenantLocationsProvider);

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
                  const Icon(Icons.person_outline,
                      size: 18, color: AppColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      st.customerName ?? 'Select client…',
                      style: TextStyle(
                        fontSize: 14,
                        color: st.customerName != null
                            ? AppColors.foreground
                            : AppColors.muted,
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
                      child: const Icon(Icons.close,
                          size: 18, color: AppColors.muted),
                    )
                  else
                    const Icon(Icons.expand_more,
                        size: 18, color: AppColors.muted),
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

          // History for selected customer
          if (st.customerId != null) ...[
            const SizedBox(height: 12),
            _CustomerHistoryPanel(customerId: st.customerId!),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Location ───────────────────────────────────────────────────
          const _Label('Location'),
          const SizedBox(height: 6),
          locationsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) => Text('Location error: $e',
                style: const TextStyle(color: Colors.red)),
            data: (locations) {
              if (locations.isEmpty) {
                return const Text('No locations found',
                    style: TextStyle(color: Colors.grey));
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (st.locationId == null && locations.isNotEmpty) {
                  ref
                      .read(mixBuilderProvider.notifier)
                      .setLocation(locations.first);
                }
              });
              final selectedId =
                  st.locationId ?? locations.first.id;
              return DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: selectedId,
                decoration: _fieldDecoration(),
                items: locations
                    .map((l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(l.name,
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (id) {
                  final loc =
                      locations.firstWhere((l) => l.id == id);
                  ref
                      .read(mixBuilderProvider.notifier)
                      .setLocation(loc);
                  widget.onAutosave();
                },
              );
            },
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Formula name ───────────────────────────────────────────────
          const _Label('Formula name (optional)'),
          const SizedBox(height: 6),
          TextField(
            controller: widget.sessionCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Summer balayage…',
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF4F6F9),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            onChanged: (v) {
              ref
                  .read(mixBuilderProvider.notifier)
                  .setSessionName(v);
              widget.onAutosave();
            },
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Service type ───────────────────────────────────────────────
          const _Label('Service type'),
          const SizedBox(height: 6),
          TextField(
            controller: widget.serviceCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. Full color, Balayage…',
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF4F6F9),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
            onChanged: (v) {
              ref
                  .read(mixBuilderProvider.notifier)
                  .setServiceType(v);
              widget.onAutosave();
            },
          ),
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
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
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
                fillColor: const Color(0xFFF4F6F9),
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
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Label('Past formulas'),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: formulas.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, i) =>
                    _HistoryChip(formula: formulas[i]),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showMenu(context, ref),
      child: Container(
        width: 130,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(formula.displayTitle,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(formula.displayService,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(children: [
              Text('${formula.items.length} items',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400)),
              const Spacer(),
              const Icon(Icons.expand_more,
                  size: 14, color: AppColors.muted),
            ]),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow_outlined),
              title: const Text('Use'),
              subtitle: const Text('Load name, service, notes & items'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final catalog =
                    await ref.read(tenantCatalogProvider.future);
                ref.read(mixBuilderProvider.notifier).applyFormula(
                      formula, ReuseMode.use, catalog);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy'),
              subtitle: const Text('Load items & service, clear name/notes'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final catalog =
                    await ref.read(tenantCatalogProvider.future);
                ref.read(mixBuilderProvider.notifier).applyFormula(
                      formula, ReuseMode.copy, catalog);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Remix'),
              subtitle: const Text('Load for edit, track original source'),
              onTap: () async {
                Navigator.pop(sheetContext);
                final catalog =
                    await ref.read(tenantCatalogProvider.future);
                ref.read(mixBuilderProvider.notifier).applyFormula(
                      formula, ReuseMode.remix, catalog);
              },
            ),
          ],
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
    if (widget.bowlIndex >= st.bowls.length) return const SizedBox.shrink();
    final bowl = st.bowls[widget.bowlIndex];
    const ratios = ['1:1', '1:1.5', '1:2', 'manual'];

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
                      color: active
                          ? AppColors.primary
                          : const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: active
                              ? AppColors.primary
                              : AppColors.border),
                    ),
                    child: Text(
                      r,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active ? Colors.white : AppColors.muted,
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
    final label = await showPromptDialog(
      context,
      title: 'Bowl label',
      hint: 'roots, toner, highlights…',
      initialValue: current,
    );
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

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final wasteG = double.tryParse(wasteCtrl.text) ?? 0;
          // Waste split preview by ratio
          final pigment = currentBatch.pigmentGrams;
          final dev = currentBatch.developerGrams;
          String splitPreview = '';
          if (wasteG > 0 && totalMixed > 0) {
            final pigW =
                pigment > 0 ? (wasteG * pigment / totalMixed) : 0.0;
            final devW =
                dev > 0 ? (wasteG * dev / totalMixed) : 0.0;
            splitPreview =
                '${pigW.toStringAsFixed(1)}g color · ${devW.toStringAsFixed(1)}ml dev';
          }

          return AlertDialog(
            title: Text(
              '${bowl.label[0].toUpperCase()}${bowl.label.substring(1)}'
              ' — Batch ${bowl.batches.length} complete?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mixed in bowl: ${totalMixed.toStringAsFixed(1)}g',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Weigh total leftover. Waste is split by your '
                  '${bowl.developerRatio} ratio.',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: wasteCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Total bowl waste (g)',
                    suffixText: 'g',
                    errorText: wasteError.isEmpty ? null : wasteError,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (_) => setDlgState(() {}),
                ),
                if (splitPreview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '≈ $splitPreview',
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('Next mix',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                _ModeOption(
                  selected: mode == MixMoreMode.copyFormula,
                  title: 'Copy formula',
                  subtitle:
                      'Same bowl — new batch with same products',
                  onTap: () => setDlgState(
                      () => mode = MixMoreMode.copyFormula),
                ),
                const SizedBox(height: 6),
                _ModeOption(
                  selected: mode == MixMoreMode.editFormula,
                  title: 'Edit formula',
                  subtitle: 'New bowl — edit a fresh mix',
                  onTap: () => setDlgState(
                      () => mode = MixMoreMode.editFormula),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final waste = double.tryParse(wasteCtrl.text) ?? 0;
                  if (waste < 0) {
                    setDlgState(() => wasteError = 'Cannot be negative');
                    return;
                  }
                  if (waste > totalMixed) {
                    setDlgState(
                        () => wasteError = 'Exceeds mixed total');
                    return;
                  }
                  Navigator.pop(ctx);
                  ref.read(mixBuilderProvider.notifier).mixMore(
                        bowlIndex,
                        mode: mode,
                        leftoverG:
                            waste > 0 ? waste.toString() : '',
                      );
                  widget.onAutosave();
                  final toast = mode == MixMoreMode.copyFormula
                      ? 'Batch ${bowl.batches.length} locked. '
                        'Batch ${bowl.batches.length + 1} ready — '
                        'same formula.'
                      : 'Batch ${bowl.batches.length} locked. '
                        'New bowl ready — edit your mix.';
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(toast)));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.08)
              : const Color(0xFFF4F6F9),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              size: 18,
              color: selected ? AppColors.primary : AppColors.muted,
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
                          color: selected
                              ? AppColors.primary
                              : AppColors.foreground)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
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
  final String ratio;
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
  final String ratio;
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
    final product = widget.item.product;
    final hex = (product.colorHex ?? '').replaceFirst('#', '');
    Color? swatch;
    if (hex.length >= 6) {
      final v = int.tryParse('FF${hex.substring(0, 6)}', radix: 16);
      if (v != null) swatch = Color(v);
    }
    final isDevAutoCalc =
        product.isDeveloper && widget.ratio != 'manual';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: swatch ?? Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (product.isDeveloper)
                  Text(
                    isDevAutoCalc ? 'Auto-calculated' : 'Developer',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDevAutoCalc
                          ? AppColors.primary
                          : Colors.grey.shade400,
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
              enabled: !widget.locked && !isDevAutoCalc,
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*\.?\d*')),
              ],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0',
                hintStyle:
                    TextStyle(color: Colors.grey.shade400),
                suffixText: 'g',
                suffixStyle: TextStyle(
                    color: Colors.grey.shade500, fontSize: 12),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                filled: true,
                fillColor: widget.locked || isDevAutoCalc
                    ? Colors.grey.shade100
                    : const Color(0xFFF4F6F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: AppColors.primary),
                ),
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
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline,
                size: 18, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Add another bowl',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
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
    final label = await showPromptDialog(
      context,
      title: 'Custom bowl label',
      hint: 'e.g. mid-lengths',
      confirmLabel: 'Add',
    );
    if (label != null && label.isNotEmpty) {
      onAdd(label);
    }
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
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label('Notes'),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Timing, developer notes, aftercare…',
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 14),
              filled: true,
              fillColor: const Color(0xFFF4F6F9),
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: AppColors.border),
              ),
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
    final st = ref.watch(mixBuilderProvider);
    final bowlCount =
        st.bowls.where((b) => b.allItems.any((i) => i.amount > 0)).length;
    final label = bowlCount > 1
        ? 'Finalize $bowlCount bowls'
        : 'Save visit';

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3))
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: saving ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: saving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
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
    return Text(text,
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.muted));
  }
}

class _PickerBox extends StatelessWidget {
  final Widget child;
  const _PickerBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F6F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

InputDecoration _fieldDecoration() => InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF4F6F9),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
    );
