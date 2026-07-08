// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_model.dart';

BrandModel _$BrandModelFromJson(Map<String, dynamic> json) => BrandModel(
      id: json['id'] as String,
      name: json['name'] as String,
      logo: json['logo'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$BrandModelToJson(BrandModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'logo': instance.logo,
      'description': instance.description,
    };

ProductLineModel _$ProductLineModelFromJson(Map<String, dynamic> json) =>
    ProductLineModel(
      id: json['id'] as String,
      brandId: json['brand_id'] as String,
      brandName: json['brand_name'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ProductLineModelToJson(ProductLineModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'brand_id': instance.brandId,
      'brand_name': instance.brandName,
      'name': instance.name,
      'description': instance.description,
    };

ProductModel _$ProductModelFromJson(Map<String, dynamic> json) => ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String?,
      colorHex: json['color_hex'] as String?,
      toneFamily: json['tone_family'] as String?,
      level: (json['level'] as num?)?.toInt(),
      colorFamily: json['color_family'] as String?,
      unitCost: (json['unit_cost'] as num?)?.toDouble(),
      productLineId: json['product_line_id'] as String?,
      productLineName: json['product_line_name'] as String?,
      brandName: json['brand_name'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$ProductModelToJson(ProductModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'code': instance.code,
      'color_hex': instance.colorHex,
      'tone_family': instance.toneFamily,
      'level': instance.level,
      'color_family': instance.colorFamily,
      'unit_cost': instance.unitCost,
      'product_line_id': instance.productLineId,
      'product_line_name': instance.productLineName,
      'brand_name': instance.brandName,
      'description': instance.description,
    };

PaginatedBrands _$PaginatedBrandsFromJson(Map<String, dynamic> json) =>
    PaginatedBrands(
      count: (json['count'] as num).toInt(),
      next: json['next'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => BrandModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaginatedBrandsToJson(PaginatedBrands instance) =>
    <String, dynamic>{
      'count': instance.count,
      'next': instance.next,
      'results': instance.results,
    };

PaginatedProductLines _$PaginatedProductLinesFromJson(
        Map<String, dynamic> json) =>
    PaginatedProductLines(
      count: (json['count'] as num).toInt(),
      next: json['next'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) =>
              ProductLineModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaginatedProductLinesToJson(
        PaginatedProductLines instance) =>
    <String, dynamic>{
      'count': instance.count,
      'next': instance.next,
      'results': instance.results,
    };

PaginatedProducts _$PaginatedProductsFromJson(Map<String, dynamic> json) =>
    PaginatedProducts(
      count: (json['count'] as num).toInt(),
      next: json['next'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaginatedProductsToJson(PaginatedProducts instance) =>
    <String, dynamic>{
      'count': instance.count,
      'next': instance.next,
      'results': instance.results,
    };
