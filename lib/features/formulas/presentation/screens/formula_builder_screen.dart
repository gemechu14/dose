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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  Future<void> _init() async {
    // Load draft if no preload
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
      final formula =
          await ref.read(formulaDetailProvider(id).future);
      final catalog = await ref.read(tenantCatalogProvider.future);
      ref.read(mixBuilderProvider.notifier).applyFormula(
            formula,
            ReuseMode.use,
            catalog,
          );
      _serviceCtrl.text = formula.serviceType ?? '';
      _notesCtrl.text = formula.notes ?? '';
    } catch (_) {}
  }

  @override
  void dispose() {
    _serviceCtrl.dispose();
    _notesCtrl.dispose();
    _sessionCtrl.dispose();
    super.dispose();
  }

  // ── Draft auto-save ────────────────────────────────────────────────────────

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
      _snack('Add at least one product with an amount greater than 0.');
      return;
    }

    setState(() => _saving = true);
    try {
      final tenantId = await ref.read(currentTenantIdProvider.future);
      final user = ref.read(currentUserProvider);
      final userId = user?.id ?? '';
      final payload = st.toVisitPayload(
        tenantId: tenantId,
        locationId: st.locationId!,
        userId: userId,
      );

      final dio = ref.read(dioProvider);
      await dio.post('/formulas/visit', data: payload);

      // Invalidate caches
      ref.invalidate(formulasProvider);
      ref.invalidate(builderInventoryProvider);

      // Clear draft
      final key = await ref.read(mixDraftKeyProvider.future);
      final storage = ref.read(secureStorageProvider);
      await ref
          .read(mixBuilderProvider.notifier)
          .clearDraft(storage, key);

      ref.read(mixBuilderProvider.notifier).resetMix();
      _serviceCtrl.clear();
      _notesCtrl.clear();
      _sessionCtrl.clear();

      if (mounted) {
        final bowlCount = payload['bowls'] is List
            ? (payload['bowls'] as List).length
            : 1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Visit saved — $bowlCount bowl${bowlCount > 1 ? 's' : ''}'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _snack('Save failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
            _buildHeader(context),
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
                      onAutosave: _autosave,
                    ),
                    const SizedBox(height: 16),
                    // Bowls
                    ...List.generate(st.bowls.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _BowlCard(
                          bowlIndex: i,
                          onAutosave: _autosave,
                        ),
                      );
                    }),
                    // Add bowl
                    _AddBowlButton(
                      onAdd: (label) {
                        ref
                            .read(mixBuilderProvider.notifier)
                            .addBowl(label);
                        _autosave();
                      },
                    ),
                    const SizedBox(height: 16),
                    // Preview
                    if (!st.isValid || st.totalGrams > 0)
                      _PreviewCard(state: st),
                    const SizedBox(height: 16),
                    // Notes
                    _NotesCard(ctrl: _notesCtrl, onAutosave: _autosave),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      padding:
          const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_new,
                size: 20, color: AppColors.foreground),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Formula',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.foreground,
              ),
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
            child: const Text(
              'AI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // New mix
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('New Mix'),
                  content: const Text(
                      'Clear all bowls and start a new mix?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear')),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(mixBuilderProvider.notifier).resetMix();
                _serviceCtrl.clear();
                _notesCtrl.clear();
                _sessionCtrl.clear();
                final key =
                    await ref.read(mixDraftKeyProvider.future);
                final storage = ref.read(secureStorageProvider);
                await ref
                    .read(mixBuilderProvider.notifier)
                    .clearDraft(storage, key);
              }
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
          // ── Customer picker ───────────────────────────────────────────
          const Text('Client',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () =>
                setState(() => _showCustomerList = !_showCustomerList),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F6F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
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
          // Customer search + list
          if (_showCustomerList)
            Container(
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
                            const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: const Color(0xFFF4F6F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: widget.onSearchChanged,
                    ),
                  ),
                  ConstrainedBox(
                    constraints:
                        const BoxConstraints(maxHeight: 200),
                    child: customersAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                            child: CircularProgressIndicator()),
                      ),
                      error: (e, _) =>
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Error: $e'),
                          ),
                      data: (customers) {
                        final q = (widget.customerSearch ?? '')
                            .toLowerCase();
                        final filtered = q.isEmpty
                            ? customers
                            : customers
                                .where((c) => c.fullName
                                    .toLowerCase()
                                    .contains(q))
                                .toList();
                        if (filtered.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No clients found',
                                style:
                                    TextStyle(color: Colors.grey)),
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
                                backgroundColor: AppColors.primary
                                    .withValues(alpha: 0.12),
                                child: Text(
                                  c.avatarLetter,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              title: Text(c.fullName,
                                  style: const TextStyle(
                                      fontSize: 14)),
                              onTap: () {
                                ref
                                    .read(mixBuilderProvider.notifier)
                                    .setCustomer(c);
                                setState(
                                    () => _showCustomerList = false);
                                widget.onAutosave();
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // ── History panel (formulas for selected customer) ─────────────
          if (st.customerId != null) ...[
            const SizedBox(height: 12),
            _CustomerHistoryPanel(
                customerId: st.customerId!),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Location picker ───────────────────────────────────────────
          const Text('Location',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted)),
          const SizedBox(height: 6),
          locationsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (e, _) =>
                Text('Location error: $e',
                    style: const TextStyle(color: Colors.red)),
            data: (locations) {
              if (locations.isEmpty) {
                return const Text('No locations found',
                    style: TextStyle(color: Colors.grey));
              }
              // Auto-select first location if none chosen
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (st.locationId == null && locations.isNotEmpty) {
                  ref
                      .read(mixBuilderProvider.notifier)
                      .setLocation(locations.first);
                }
              });
              return DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: st.locationId ?? locations.first.id,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF4F6F9),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
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
                items: locations
                    .map((l) => DropdownMenuItem(
                          value: l.id,
                          child: Text(l.name,
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (id) {
                  final loc = locations.firstWhere(
                      (l) => l.id == id);
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

          // ── Service type ──────────────────────────────────────────────
          const Text('Service type',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted)),
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
          height: 40,
          child: Center(child: LinearProgressIndicator())),
      error: (_, __) => const SizedBox.shrink(),
      data: (formulas) {
        if (formulas.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Past formulas',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.muted)),
            const SizedBox(height: 8),
            SizedBox(
              height: 80,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: formulas.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: 10),
                itemBuilder: (ctx, i) {
                  final f = formulas[i];
                  return _HistoryChip(formula: f);
                },
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
            Text(
              formula.displayTitle,
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              formula.displayService,
              style: TextStyle(
                  fontSize: 11, color: Colors.grey.shade500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                Text(
                  '${formula.items.length} items',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400),
                ),
                const Spacer(),
                const Icon(Icons.expand_more,
                    size: 14, color: AppColors.muted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.play_arrow_outlined),
              title: const Text('Use'),
              subtitle:
                  const Text('Load name, service, notes & items'),
              onTap: () async {
                Navigator.pop(context);
                final catalog =
                    await ref.read(tenantCatalogProvider.future);
                ref
                    .read(mixBuilderProvider.notifier)
                    .applyFormula(formula, ReuseMode.use, catalog);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.copy_outlined),
              title: const Text('Copy'),
              subtitle:
                  const Text('Load items & service, clear name/notes'),
              onTap: () async {
                Navigator.pop(context);
                final catalog =
                    await ref.read(tenantCatalogProvider.future);
                ref
                    .read(mixBuilderProvider.notifier)
                    .applyFormula(formula, ReuseMode.copy, catalog);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.edit_outlined),
              title: const Text('Remix'),
              subtitle: const Text(
                  'Load for edit, track original source'),
              onTap: () async {
                Navigator.pop(context);
                final catalog =
                    await ref.read(tenantCatalogProvider.future);
                ref
                    .read(mixBuilderProvider.notifier)
                    .applyFormula(formula, ReuseMode.remix, catalog);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bowl card
// ─────────────────────────────────────────────────────────────────────────────

class _BowlCard extends ConsumerStatefulWidget {
  final int bowlIndex;
  final VoidCallback onAutosave;
  const _BowlCard({required this.bowlIndex, required this.onAutosave});

  @override
  ConsumerState<_BowlCard> createState() => _BowlCardState();
}

class _BowlCardState extends ConsumerState<_BowlCard> {
  @override
  Widget build(BuildContext context) {
    final st = ref.watch(mixBuilderProvider);
    if (widget.bowlIndex >= st.bowls.length) {
      return const SizedBox.shrink();
    }
    final bowl = st.bowls[widget.bowlIndex];
    const ratios = ['1:1', '1:1.5', '1:2', 'manual'];

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Bowl header ───────────────────────────────────────────────
          Row(
            children: [
              // Label pill
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
              const Spacer(),
              if (st.bowls.length > 1)
                Text(
                  '\$${bowl.totalCost.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Ratio selector ────────────────────────────────────────────
          const Text('Developer ratio',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted)),
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
                    padding:
                        const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : const Color(0xFFF4F6F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Text(
                      r,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: active
                            ? Colors.white
                            : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // ── Batches ───────────────────────────────────────────────────
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

          // ── Mix more ──────────────────────────────────────────────────
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Mix more'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    ref
                        .read(mixBuilderProvider.notifier)
                        .mixMore(widget.bowlIndex, copyItems: true);
                    widget.onAutosave();
                  },
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
                Text(
                  'Batch $batchNumber',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted),
                ),
                if (batch.isLocked) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.lock_outline,
                      size: 14, color: Colors.grey.shade400),
                ],
              ],
            ),
          ),

        // Items
        ...List.generate(batch.items.length, (ii) {
          final item = batch.items[ii];
          return _ItemRow(
            bowlIndex: bowlIndex,
            batchIndex: batchIndex,
            item: item,
            locked: batch.isLocked,
            ratio: ratio,
            batchPigmentGrams: batch.items
                .where((i) => !i.product.isDeveloper)
                .fold(0.0, (s, i) => s + i.amount),
            onAutosave: onAutosave,
          );
        }),

        // Add product button
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
                      .addItemToBatch(
                          bowlIndex, batchIndex, product);
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
                      color:
                          AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add,
                        size: 16,
                        color: AppColors.primary
                            .withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Text(
                      'Add product',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary
                            .withValues(alpha: 0.8),
                      ),
                    ),
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
  final double batchPigmentGrams;
  final VoidCallback onAutosave;

  const _ItemRow({
    required this.bowlIndex,
    required this.batchIndex,
    required this.item,
    required this.locked,
    required this.ratio,
    required this.batchPigmentGrams,
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
    // Sync value from state if it changed externally (e.g. auto-calc dev)
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
            widget.bowlIndex,
            widget.batchIndex,
            widget.item.id,
            amount,
          );

      // Auto-calc developer if ratio mode
      if (widget.ratio != 'manual' &&
          !widget.item.product.isDeveloper) {
        _autoCalcDeveloper(amount);
      }
      widget.onAutosave();
    });
  }

  void _autoCalcDeveloper(double pigmentAmount) {
    final st = ref.read(mixBuilderProvider);
    if (widget.bowlIndex >= st.bowls.length) return;
    final bowl = st.bowls[widget.bowlIndex];
    if (widget.batchIndex >= bowl.batches.length) return;
    final batch = bowl.batches[widget.batchIndex];

    final totalPigment = batch.items
        .where((i) => !i.product.isDeveloper)
        .fold(0.0, (s, i) => s + i.amount);

    final devAmount = calcDeveloperAmount(totalPigment, widget.ratio);

    for (final item in batch.items) {
      if (item.product.isDeveloper) {
        ref.read(mixBuilderProvider.notifier).updateItemAmount(
              widget.bowlIndex,
              widget.batchIndex,
              item.id,
              devAmount,
            );
      }
    }
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
          // Swatch
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
          // Product label
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (product.isDeveloper)
                  Text(
                    isDevAutoCalc
                        ? 'Auto-calculated'
                        : 'Developer',
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
          // Amount field
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
                hintStyle: TextStyle(color: Colors.grey.shade400),
                suffixText: 'g',
                suffixStyle:
                    TextStyle(color: Colors.grey.shade500, fontSize: 12),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 8),
                filled: true,
                fillColor: widget.locked || isDevAutoCalc
                    ? Colors.grey.shade100
                    : const Color(0xFFF4F6F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
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
          // Remove button
          if (!widget.locked)
            GestureDetector(
              onTap: () {
                ref.read(mixBuilderProvider.notifier).removeItemFromBatch(
                      widget.bowlIndex,
                      widget.batchIndex,
                      widget.item.id,
                    );
                widget.onAutosave();
              },
              child: Icon(Icons.remove_circle_outline,
                  size: 20, color: Colors.grey.shade400),
            ),
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
            Text(
              'Add another bowl',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    const labels = ['roots', 'toner', 'highlights', 'gloss', 'custom'];
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
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
                    Navigator.pop(context);
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

  void _showCustom(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Custom bowl label'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. mid-lengths'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                if (ctrl.text.trim().isNotEmpty) {
                  Navigator.pop(context);
                  onAdd(ctrl.text.trim());
                }
              },
              child: const Text('Add')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Live preview card
// ─────────────────────────────────────────────────────────────────────────────

class _PreviewCard extends StatelessWidget {
  final MixBuilderState state;
  const _PreviewCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final allItems = state.bowls.expand((b) => b.allItems).toList();
    final mix = mixColors(allItems);
    final mixColor = Color(mix.argbColor);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              // Droplet preview
              Container(
                width: 52,
                height: 72,
                decoration: BoxDecoration(
                  color: mixColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(26),
                    topRight: Radius.circular(26),
                    bottomLeft: Radius.circular(26),
                    bottomRight: Radius.circular(4),
                  ),
                  border: Border.all(
                      color: Colors.grey.shade200, width: 1.5),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live preview',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.foreground)),
                    const SizedBox(height: 4),
                    Text(
                      mix.hexString,
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _Stat(
                          label: 'Total',
                          value:
                              '${state.totalGrams.toStringAsFixed(1)}g',
                        ),
                        const SizedBox(width: 16),
                        _Stat(
                          label: 'Cost',
                          value:
                              '\$${state.totalCost.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (allItems.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            // Per-item breakdown
            ...allItems.where((i) => i.amount > 0).map((item) {
              final bowlTotal = state.bowls
                  .firstWhere((b) =>
                      b.allItems.any((i) => i.id == item.id))
                  .totalGrams;
              final pct = bowlTotal == 0
                  ? 0.0
                  : (item.amount / bowlTotal) * 100;

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
                      child: Text(
                        item.product.label,
                        style: const TextStyle(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${item.amount.toStringAsFixed(1)}g · ${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }),
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
          const Text('Notes',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted)),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Timing, developer notes, aftercare…',
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

class _SaveBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  const _SaveBar({required this.saving, required this.onSave});

  @override
  Widget build(BuildContext context) {
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
              : const Text(
                  'Save visit',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Shared card widget
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

