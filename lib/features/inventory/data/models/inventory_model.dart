import 'package:json_annotation/json_annotation.dart';

part 'inventory_model.g.dart';

@JsonSerializable()
class InventoryItemModel {
  final String id;
  @JsonKey(name: 'product_id')
  final String productId;
  @JsonKey(name: 'product_name')
  final String? productName;
  @JsonKey(name: 'product_code')
  final String? productCode;
  @JsonKey(name: 'color_hex')
  final String? colorHex;
  @JsonKey(name: 'quantity_on_hand')
  final double quantityOnHand;
  @JsonKey(name: 'reorder_point')
  final double? reorderPoint;
  final String? unit;
  @JsonKey(name: 'location_id')
  final String? locationId;
  @JsonKey(name: 'location_name')
  final String? locationName;

  const InventoryItemModel({
    required this.id,
    required this.productId,
    this.productName,
    this.productCode,
    this.colorHex,
    required this.quantityOnHand,
    this.reorderPoint,
    this.unit,
    this.locationId,
    this.locationName,
  });

  bool get isLowStock =>
      reorderPoint != null && quantityOnHand <= reorderPoint!;

  factory InventoryItemModel.fromJson(Map<String, dynamic> json) =>
      _$InventoryItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$InventoryItemModelToJson(this);
}

@JsonSerializable()
class PaginatedInventory {
  final int count;
  final String? next;
  final List<InventoryItemModel> results;

  const PaginatedInventory({
    required this.count,
    this.next,
    required this.results,
  });

  factory PaginatedInventory.fromJson(Map<String, dynamic> json) =>
      _$PaginatedInventoryFromJson(json);
}
