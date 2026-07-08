import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/inventory_model.dart';

final selectedLocationProvider = StateProvider<String?>((ref) => null);

final inventoryItemsProvider =
    FutureProvider<List<InventoryItemModel>>((ref) async {
  final dio = ref.read(dioProvider);
  final locationId = ref.watch(selectedLocationProvider);
  try {
    final res = await dio.get(
      ApiConstants.inventoryItems,
      queryParameters: {
        if (locationId != null) 'location_id': locationId,
      },
    );
    // Handle both paginated and list responses
    final data = res.data;
    if (data is Map) {
      return PaginatedInventory.fromJson(data as Map<String, dynamic>)
          .results;
    }
    return (data as List)
        .map((e) => InventoryItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw parseDioError(e);
  }
});

final lowStockProvider =
    FutureProvider<List<InventoryItemModel>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get(ApiConstants.inventoryLowStock);
    final data = res.data;
    if (data is Map) {
      return PaginatedInventory.fromJson(data as Map<String, dynamic>)
          .results;
    }
    return (data as List)
        .map((e) => InventoryItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } on DioException catch (e) {
    throw parseDioError(e);
  }
});

/// Check if a product has stock concerns based on productId
final stockWarningProvider =
    Provider.family<bool, String>((ref, productId) {
  final items = ref.watch(inventoryItemsProvider).valueOrNull ?? [];
  final item =
      items.where((i) => i.productId == productId).firstOrNull;
  return item?.isLowStock ?? false;
});

extension ListFirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
