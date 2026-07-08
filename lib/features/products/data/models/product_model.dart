import 'package:json_annotation/json_annotation.dart';

part 'product_model.g.dart';

@JsonSerializable()
class BrandModel {
  final String id;
  final String name;
  final String? logo;
  final String? description;

  const BrandModel({
    required this.id,
    required this.name,
    this.logo,
    this.description,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) =>
      _$BrandModelFromJson(json);
  Map<String, dynamic> toJson() => _$BrandModelToJson(this);
}

@JsonSerializable()
class ProductLineModel {
  final String id;
  @JsonKey(name: 'brand_id')
  final String brandId;
  @JsonKey(name: 'brand_name')
  final String? brandName;
  final String name;
  final String? description;

  const ProductLineModel({
    required this.id,
    required this.brandId,
    this.brandName,
    required this.name,
    this.description,
  });

  factory ProductLineModel.fromJson(Map<String, dynamic> json) =>
      _$ProductLineModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductLineModelToJson(this);
}

@JsonSerializable()
class ProductModel {
  final String id;
  final String name;
  final String? code;
  @JsonKey(name: 'color_hex')
  final String? colorHex;
  @JsonKey(name: 'tone_family')
  final String? toneFamily;
  final int? level;
  @JsonKey(name: 'color_family')
  final String? colorFamily;
  @JsonKey(name: 'unit_cost')
  final double? unitCost;
  @JsonKey(name: 'product_line_id')
  final String? productLineId;
  @JsonKey(name: 'product_line_name')
  final String? productLineName;
  @JsonKey(name: 'brand_name')
  final String? brandName;
  final String? description;

  const ProductModel({
    required this.id,
    required this.name,
    this.code,
    this.colorHex,
    this.toneFamily,
    this.level,
    this.colorFamily,
    this.unitCost,
    this.productLineId,
    this.productLineName,
    this.brandName,
    this.description,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);
}

@JsonSerializable()
class PaginatedBrands {
  final int count;
  final String? next;
  final List<BrandModel> results;

  const PaginatedBrands({
    required this.count,
    this.next,
    required this.results,
  });

  factory PaginatedBrands.fromJson(Map<String, dynamic> json) =>
      _$PaginatedBrandsFromJson(json);
}

@JsonSerializable()
class PaginatedProductLines {
  final int count;
  final String? next;
  final List<ProductLineModel> results;

  const PaginatedProductLines({
    required this.count,
    this.next,
    required this.results,
  });

  factory PaginatedProductLines.fromJson(Map<String, dynamic> json) =>
      _$PaginatedProductLinesFromJson(json);
}

@JsonSerializable()
class PaginatedProducts {
  final int count;
  final String? next;
  final List<ProductModel> results;

  const PaginatedProducts({
    required this.count,
    this.next,
    required this.results,
  });

  factory PaginatedProducts.fromJson(Map<String, dynamic> json) =>
      _$PaginatedProductsFromJson(json);
}
