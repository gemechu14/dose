import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/product_model.dart';

// ─── Favorites (local state) ─────────────────────────────────────────────────
final favoriteProductsProvider =
    StateProvider<Set<String>>((ref) => {});

// ─── Brands ──────────────────────────────────────────────────────────────────
final brandsProvider = FutureProvider<List<BrandModel>>((ref) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get(ApiConstants.productBrands,
        queryParameters: {'page': 1, 'page_size': 100});
    return PaginatedBrands.fromJson(res.data as Map<String, dynamic>)
        .results;
  } on DioException catch (e) {
    throw parseDioError(e);
  }
});

// ─── Product lines ───────────────────────────────────────────────────────────
final productLinesProvider =
    FutureProvider.family<List<ProductLineModel>, String>((ref, brandId) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get(ApiConstants.productLines,
        queryParameters: {
          'brand_id': brandId,
          'page': 1,
          'page_size': 100
        });
    return PaginatedProductLines.fromJson(
            res.data as Map<String, dynamic>)
        .results;
  } on DioException catch (e) {
    throw parseDioError(e);
  }
});

// ─── Products ────────────────────────────────────────────────────────────────
class ProductsFilter {
  final String lineId;
  final String? toneFamily;
  final int? level;
  final String? colorFamily;

  const ProductsFilter({
    required this.lineId,
    this.toneFamily,
    this.level,
    this.colorFamily,
  });

  @override
  bool operator ==(Object other) =>
      other is ProductsFilter &&
      other.lineId == lineId &&
      other.toneFamily == toneFamily &&
      other.level == level &&
      other.colorFamily == colorFamily;

  @override
  int get hashCode =>
      Object.hash(lineId, toneFamily, level, colorFamily);
}

final productsFilterProvider =
    StateProvider.family<ProductsFilter, String>(
  (ref, lineId) => ProductsFilter(lineId: lineId),
);

final productsProvider =
    FutureProvider.family<List<ProductModel>, ProductsFilter>(
        (ref, filter) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get(ApiConstants.products, queryParameters: {
      'product_line_id': filter.lineId,
      if (filter.toneFamily != null) 'tone_family': filter.toneFamily,
      if (filter.level != null) 'level': filter.level,
      if (filter.colorFamily != null) 'color_family': filter.colorFamily,
      'page': 1,
      'page_size': 100,
    });
    return PaginatedProducts.fromJson(res.data as Map<String, dynamic>)
        .results;
  } on DioException catch (e) {
    throw parseDioError(e);
  }
});

final productDetailProvider =
    FutureProvider.family<ProductModel, String>((ref, id) async {
  final dio = ref.read(dioProvider);
  try {
    final res = await dio.get(ApiConstants.productById(id));
    return ProductModel.fromJson(res.data as Map<String, dynamic>);
  } on DioException catch (e) {
    throw parseDioError(e);
  }
});
