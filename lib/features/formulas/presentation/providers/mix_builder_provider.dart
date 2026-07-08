import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../tenants/presentation/providers/tenant_provider.dart';
import '../../data/models/formula_model.dart';
import '../../domain/mix_models.dart';

const _uuid = Uuid();

// ─── Catalog / location / inventory data ─────────────────────────────────────

final tenantCatalogProvider =
    FutureProvider<List<TenantProduct>>((ref) async {
  final dio = ref.read(dioProvider);
  final products = <TenantProduct>[];
  int page = 1;
  while (true) {
    try {
      final res = await dio.get(
        ApiConstants.tenantCatalog,
        queryParameters: {
          'enabled_only': true,
          'page': page,
          'page_size': 100,
        },
      );
      final data = res.data;
      List<dynamic> items;
      if (data is Map) {
        items = (data['items'] ?? data['results']) as List<dynamic>? ?? [];
      } else if (data is List) {
        items = data;
      } else {
        break;
      }
      for (final e in items) {
        if (e is Map<String, dynamic>) {
          products.add(TenantProduct.fromJson(e));
        }
      }
      if (items.length < 100) break;
      page++;
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
  return products;
});

final tenantLocationsProvider =
    FutureProvider<List<LocationModel>>((ref) async {
  final tenantId = await ref.watch(currentTenantIdProvider.future);
  final dio = ref.read(dioProvider);
  try {
    final res =
        await dio.get(ApiConstants.tenantLocations(tenantId));
    final data = res.data;
    List<dynamic> items;
    if (data is Map) {
      items = (data['items'] ?? data['results']) as List<dynamic>? ?? [];
    } else if (data is List) {
      items = data;
    } else {
      items = [];
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(LocationModel.fromJson)
        .toList();
  } on DioException catch (e) {
    throw parseDioError(e);
  }
});

final builderInventoryProvider =
    FutureProvider<List<StockItem>>((ref) async {
  final locationId = ref.watch(mixBuilderProvider).locationId;
  if (locationId == null) return [];
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get(
      ApiConstants.inventoryItems,
      queryParameters: {'location_id': locationId, 'page_size': 500},
    );
    final data = res.data;
    List<dynamic> items;
    if (data is Map) {
      items = (data['items'] ?? data['results']) as List<dynamic>? ?? [];
    } else if (data is List) {
      items = data;
    } else {
      items = [];
    }
    return items
        .whereType<Map<String, dynamic>>()
        .map(StockItem.fromJson)
        .toList();
  } on DioException catch (e) {
    throw parseDioError(e);
  }
});

final builderCustomersProvider =
    FutureProvider<List<CustomerModel>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get(
      ApiConstants.customers,
      queryParameters: {'page': 1, 'page_size': 100},
    );
    return PaginatedCustomers.fromJson(res.data as Map<String, dynamic>)
        .results;
  } on DioException catch (e) {
    throw parseDioError(e);
  }
});

final customerFormulasForBuilderProvider =
    FutureProvider.family<List<FormulaModel>, String>((ref, customerId) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get(
      ApiConstants.formulas,
      queryParameters: {
        'customer_id': customerId,
        'page': 1,
        'page_size': 20,
      },
    );
    return PaginatedFormulas.fromJson(res.data as Map<String, dynamic>)
        .results;
  } on DioException catch (e) {
    throw parseDioError(e);
  }
});

// ─── Reuse mode enum ─────────────────────────────────────────────────────────

enum ReuseMode { use, copy, remix }

// ─── Mix builder notifier ─────────────────────────────────────────────────────

class MixBuilderNotifier extends Notifier<MixBuilderState> {
  @override
  MixBuilderState build() {
    return MixBuilderState(
      bowls: [MixBowl.empty(id: _uuid.v4(), label: 'roots')],
    );
  }

  // ── Customer / location ───────────────────────────────────────────────────

  void setCustomer(CustomerModel? c) {
    state = state.copyWith(
      customerId: c?.id,
      customerName: c?.fullName,
    );
  }

  void setLocation(LocationModel l) {
    state = state.copyWith(locationId: l.id);
  }

  void setSessionName(String v) =>
      state = state.copyWith(sessionName: v.isEmpty ? null : v);

  void setServiceType(String v) =>
      state = state.copyWith(serviceType: v.isEmpty ? null : v);

  void setNotes(String v) =>
      state = state.copyWith(notes: v.isEmpty ? null : v);

  void setActiveBowl(int index) =>
      state = state.copyWith(activeBowlIndex: index);

  // ── Bowl management ───────────────────────────────────────────────────────

  void addBowl(String label) {
    final bowls = List<MixBowl>.from(state.bowls)
      ..add(MixBowl.empty(id: _uuid.v4(), label: label));
    state = state.copyWith(
      bowls: bowls,
      activeBowlIndex: bowls.length - 1,
    );
  }

  void setBowlLabel(int bowlIndex, String label) {
    final bowls = _updateBowl(
      bowlIndex,
      (b) => b.copyWith(label: label),
    );
    state = state.copyWith(bowls: bowls);
  }

  void setBowlRatio(int bowlIndex, String ratio) {
    final bowls = _updateBowl(
      bowlIndex,
      (b) => b.copyWith(developerRatio: ratio),
    );
    state = state.copyWith(bowls: bowls);
  }

  // ── Batch management ──────────────────────────────────────────────────────

  void addItemToBatch(int bowlIndex, int batchIndex, TenantProduct product) {
    final bowls = _updateBatchItems(
      bowlIndex,
      batchIndex,
      (items) => [
        ...items,
        MixItem(id: _uuid.v4(), product: product, amount: 0),
      ],
    );
    state = state.copyWith(bowls: bowls);
  }

  void removeItemFromBatch(
      int bowlIndex, int batchIndex, String itemId) {
    final bowls = _updateBatchItems(
      bowlIndex,
      batchIndex,
      (items) => items.where((i) => i.id != itemId).toList(),
    );
    state = state.copyWith(bowls: bowls);
  }

  void updateItemAmount(
      int bowlIndex, int batchIndex, String itemId, double amount) {
    final bowls = _updateBatchItems(
      bowlIndex,
      batchIndex,
      (items) => items
          .map((i) => i.id == itemId ? i.copyWith(amount: amount) : i)
          .toList(),
    );
    state = state.copyWith(bowls: bowls);
  }

  /// Lock current batch and append a new empty one (Mix more).
  void mixMore(int bowlIndex, {bool copyItems = false}) {
    final bowl = state.bowls[bowlIndex];
    final activeBatch = bowl.batches.last;
    final locked = activeBatch.copyWith(isLocked: true);
    final newBatch = MixBatch(
      id: _uuid.v4(),
      items: copyItems
          ? activeBatch.items
              .map((i) => i.copyWith(amount: 0))
              .toList()
          : [],
    );
    final updatedBatches = [...bowl.batches.take(bowl.batches.length - 1), locked, newBatch];
    final bowls = _updateBowl(
      bowlIndex,
      (b) => b.copyWith(batches: updatedBatches),
    );
    state = state.copyWith(bowls: bowls);
  }

  // ── History reuse ─────────────────────────────────────────────────────────

  void applyFormula(FormulaModel formula, ReuseMode mode,
      List<TenantProduct> catalog) {
    final bowls = List<MixBowl>.from(state.bowls);
    final bowlId = _uuid.v4();
    final batchId = _uuid.v4();

    final items = formula.items.map((ci) {
      final product = catalog.firstWhereOrNull(
            (p) => p.id == ci.productId || p.globalProductId == ci.productId,
          ) ??
          TenantProduct(
            id: ci.productId,
            name: ci.productName ?? ci.productCode ?? 'Product',
            code: ci.productCode,
            colorHex: ci.colorHex,
            defaultUnitCost: ci.unitCost ?? 0,
          );
      return MixItem(
        id: _uuid.v4(),
        product: product,
        amount: ci.amountUsed,
      );
    }).toList();

    final bowl = MixBowl(
      id: bowlId,
      label: formula.bowlLabel ?? 'Bowl',
      developerRatio: '1:1',
      batches: [MixBatch(id: batchId, items: items)],
    );

    // If first bowl is empty, replace it; otherwise add.
    if (bowls.length == 1 && bowls.first.allItems.isEmpty) {
      bowls[0] = bowl;
    } else {
      bowls.add(bowl);
    }

    state = state.copyWith(
      sessionName: mode == ReuseMode.use ? formula.formulaName : null,
      serviceType: mode != ReuseMode.copy ? formula.serviceType : null,
      notes: mode == ReuseMode.use ? formula.notes : null,
      remixSourceFormulaId:
          mode == ReuseMode.remix ? formula.id : null,
      bowls: bowls,
      activeBowlIndex: bowls.length - 1,
    );
  }

  // ── Draft ──────────────────────────────────────────────────────────────────

  Future<void> saveDraft(SecureStorageService storage, String key) async {
    await storage.write(key: key, value: state.toDraftJson());
  }

  Future<void> loadDraft(SecureStorageService storage, String key) async {
    final raw = await storage.read(key: key);
    if (raw == null) return;
    try {
      state = MixBuilderState.fromDraftJson(raw);
    } catch (_) {
      // corrupted draft – ignore
    }
  }

  Future<void> clearDraft(SecureStorageService storage, String key) async {
    await storage.delete(key: key);
  }

  void resetMix() {
    state = MixBuilderState(
      locationId: state.locationId,
      bowls: [MixBowl.empty(id: _uuid.v4(), label: 'roots')],
    );
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  List<MixBowl> _updateBowl(int index, MixBowl Function(MixBowl) fn) {
    final bowls = List<MixBowl>.from(state.bowls);
    if (index < 0 || index >= bowls.length) return bowls;
    bowls[index] = fn(bowls[index]);
    return bowls;
  }

  List<MixBowl> _updateBatchItems(
    int bowlIndex,
    int batchIndex,
    List<MixItem> Function(List<MixItem>) fn,
  ) {
    return _updateBowl(bowlIndex, (bowl) {
      final batches = List<MixBatch>.from(bowl.batches);
      if (batchIndex < 0 || batchIndex >= batches.length) return bowl;
      batches[batchIndex] =
          batches[batchIndex].copyWith(items: fn(batches[batchIndex].items));
      return bowl.copyWith(batches: batches);
    });
  }
}

final mixBuilderProvider =
    NotifierProvider<MixBuilderNotifier, MixBuilderState>(
  MixBuilderNotifier.new,
);

// ─── Save visit provider ──────────────────────────────────────────────────────

final saveVisitProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, Map<String, dynamic>>((ref, payload) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.post(ApiConstants.formulaVisit, data: payload);
    return res.data as Map<String, dynamic>;
  } on DioException catch (e) {
    throw parseDioError(e);
  }
});

// ─── Draft key helper ─────────────────────────────────────────────────────────

final mixDraftKeyProvider = FutureProvider<String>((ref) async {
  final tenantId = await ref.watch(currentTenantIdProvider.future);
  final user = ref.watch(currentUserProvider);
  final userId = user?.id ?? 'anon';
  return 'formula-draft:v1:$tenantId:$userId';
});

// ─── Extension ────────────────────────────────────────────────────────────────

extension ListFirstWhereOrNull<T> on List<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    for (final e in this) {
      if (test(e)) return e;
    }
    return null;
  }
}
