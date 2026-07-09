import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../customers/data/repositories/customers_repository_impl.dart';
import '../../data/models/formula_model.dart';
import '../../data/repositories/formulas_repository_impl.dart';

// ─── Formula list ────────────────────────────────────────────────────────────

final formulasProvider =
    AsyncNotifierProvider<FormulasNotifier, List<FormulaModel>>(
        FormulasNotifier.new);

class FormulasNotifier extends AsyncNotifier<List<FormulaModel>> {
  @override
  Future<List<FormulaModel>> build() => _fetch(reset: true);

  Future<List<FormulaModel>> _fetch({bool reset = false}) async {
    final repo = ref.read(formulasRepositoryProvider);
    final result = await repo.getFormulas(page: reset ? 1 : 1);
    return result.fold(
      (f) => throw Exception(f.message),
      (p) => p.results,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(reset: true));
  }

  Future<String?> saveVisit(FormulaVisitRequest request) async {
    final repo = ref.read(formulasRepositoryProvider);
    final result = await repo.saveVisit(request);
    return result.fold(
      (f) => f.message,
      (formula) {
        final current = state.valueOrNull ?? [];
        state = AsyncData([formula, ...current]);
        return null;
      },
    );
  }

  Future<String?> deleteFormula(String id) async {
    final repo = ref.read(formulasRepositoryProvider);
    final result = await repo.deleteFormula(id);
    return result.fold(
      (f) => f.message,
      (_) {
        state = AsyncData(
          (state.valueOrNull ?? []).where((f) => f.id != id).toList(),
        );
        return null;
      },
    );
  }
}

// ─── Customer formulas ───────────────────────────────────────────────────────

final customerFormulasProvider =
    FutureProvider.family<List<FormulaModel>, String>((ref, customerId) async {
  final repo = ref.read(formulasRepositoryProvider);
  final result = await repo.getFormulas(customerId: customerId, pageSize: 50);
  return result.fold(
    (f) => throw Exception(f.message),
    (p) => p.results,
  );
});

// ─── Formula detail ──────────────────────────────────────────────────────────

final formulaDetailProvider =
    FutureProvider.family<FormulaModel, String>((ref, id) async {
  final repo = ref.read(formulasRepositoryProvider);
  final result = await repo.getFormula(id);
  return result.fold(
    (f) => throw Exception(f.message),
    (formula) => formula,
  );
});

/// Resolves customer names for formulas when API returns only customer_id.
final formulaCustomerNamesProvider =
    FutureProvider<Map<String, String>>((ref) async {
  final formulas = await ref.watch(formulasProvider.future);
  final ids = formulas
      .map((f) => f.customerId)
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet();
  if (ids.isEmpty) return const {};

  final repo = ref.read(customersRepositoryProvider);
  final map = <String, String>{};
  var page = 1;
  const pageSize = 100;

  while (true) {
    final result = await repo.getCustomers(page: page, pageSize: pageSize);
    final paginated = result.fold(
      (f) => throw Exception(f.message),
      (p) => p,
    );

    for (final c in paginated.results) {
      if (ids.contains(c.id) && c.fullName.trim().isNotEmpty) {
        map[c.id] = c.fullName.trim();
      }
    }

    if (paginated.next == null || map.length >= ids.length) break;
    page++;
  }

  return map;
});

// ─── Formula builder state ───────────────────────────────────────────────────

class FormulaBuilderState {
  final String? customerId;
  final String? serviceType;
  final String? notes;
  final List<ColorItemModel> items;

  const FormulaBuilderState({
    this.customerId,
    this.serviceType,
    this.notes,
    this.items = const [],
  });

  FormulaBuilderState copyWith({
    String? customerId,
    String? serviceType,
    String? notes,
    List<ColorItemModel>? items,
  }) =>
      FormulaBuilderState(
        customerId: customerId ?? this.customerId,
        serviceType: serviceType ?? this.serviceType,
        notes: notes ?? this.notes,
        items: items ?? this.items,
      );

  double get totalCost =>
      items.fold(0.0, (sum, item) => sum + item.totalCost);

  double get totalWeight =>
      items.fold(0.0, (sum, item) => sum + item.amountUsed);

  Map<int, List<ColorItemModel>> get itemsByBowl {
    final map = <int, List<ColorItemModel>>{};
    for (final item in items) {
      map.putIfAbsent(item.bowlIndex, () => []).add(item);
    }
    return map;
  }

  /// Returns percent contribution of each item in its bowl
  double percentInBowl(ColorItemModel item) {
    final bowlItems =
        items.where((i) => i.bowlIndex == item.bowlIndex).toList();
    final bowlTotal =
        bowlItems.fold(0.0, (s, i) => s + i.amountUsed);
    return bowlTotal == 0 ? 0 : (item.amountUsed / bowlTotal) * 100;
  }

  /// Rule-based tone incompatibility heuristic
  bool hasToneMismatch(int bowlIndex) {
    final bowlItems =
        items.where((i) => i.bowlIndex == bowlIndex).toList();
    if (bowlItems.length < 2) return false;
    // Heuristic: mixing warm (orange/red) with cool (blue/violet) tones
    bool hasWarm = false;
    bool hasCool = false;
    for (final item in bowlItems) {
      if (item.colorHex != null) {
        final color = _hexToColor(item.colorHex!);
        final hue = HSVColor.fromColor(color).hue;
        if (hue >= 0 && hue < 60 || hue >= 300) hasWarm = true;
        if (hue >= 180 && hue < 300) hasCool = true;
      }
    }
    return hasWarm && hasCool;
  }

  Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

final formulaBuilderProvider =
    StateNotifierProvider<FormulaBuilderNotifier, FormulaBuilderState>(
  (ref) => FormulaBuilderNotifier(),
);

class FormulaBuilderNotifier
    extends StateNotifier<FormulaBuilderState> {
  FormulaBuilderNotifier() : super(const FormulaBuilderState());

  void setCustomer(String? id) =>
      state = state.copyWith(customerId: id);

  void setServiceType(String? type) =>
      state = state.copyWith(serviceType: type);

  void setNotes(String? notes) => state = state.copyWith(notes: notes);

  void addItem(ColorItemModel item) =>
      state = state.copyWith(items: [...state.items, item]);

  void updateItem(int index, ColorItemModel updated) {
    final items = [...state.items];
    items[index] = updated;
    state = state.copyWith(items: items);
  }

  void removeItem(int index) {
    final items = [...state.items];
    items.removeAt(index);
    state = state.copyWith(items: items);
  }

  void updateAmount(int index, double amount) {
    final items = [...state.items];
    items[index] = ColorItemModel(
      productId: items[index].productId,
      productName: items[index].productName,
      productCode: items[index].productCode,
      colorHex: items[index].colorHex,
      amountUsed: amount,
      unit: items[index].unit,
      unitCost: items[index].unitCost,
      bowlIndex: items[index].bowlIndex,
    );
    state = state.copyWith(items: items);
  }

  void loadFromFormula(FormulaModel formula) {
    state = FormulaBuilderState(
      customerId: formula.customerId,
      serviceType: formula.serviceType,
      notes: formula.notes,
      items: formula.items,
    );
  }

  void reset() => state = const FormulaBuilderState();
}

// Preview mode enum
enum MixPreviewMode { chips, blended, beforeAfter }

final mixPreviewModeProvider =
    StateProvider<MixPreviewMode>((ref) => MixPreviewMode.chips);
