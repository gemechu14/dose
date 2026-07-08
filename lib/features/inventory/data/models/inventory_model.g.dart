// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_model.dart';

InventoryItemModel _$InventoryItemModelFromJson(Map<String, dynamic> json) =>
    InventoryItemModel(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String?,
      productCode: json['product_code'] as String?,
      colorHex: json['color_hex'] as String?,
      quantityOnHand: (json['quantity_on_hand'] as num).toDouble(),
      reorderPoint: (json['reorder_point'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      locationId: json['location_id'] as String?,
      locationName: json['location_name'] as String?,
    );

Map<String, dynamic> _$InventoryItemModelToJson(
        InventoryItemModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'product_id': instance.productId,
      'product_name': instance.productName,
      'product_code': instance.productCode,
      'color_hex': instance.colorHex,
      'quantity_on_hand': instance.quantityOnHand,
      'reorder_point': instance.reorderPoint,
      'unit': instance.unit,
      'location_id': instance.locationId,
      'location_name': instance.locationName,
    };

PaginatedInventory _$PaginatedInventoryFromJson(Map<String, dynamic> json) =>
    PaginatedInventory(
      count: (json['count'] as num).toInt(),
      next: json['next'] as String?,
      results: (json['results'] as List<dynamic>)
          .map((e) =>
              InventoryItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PaginatedInventoryToJson(
        PaginatedInventory instance) =>
    <String, dynamic>{
      'count': instance.count,
      'next': instance.next,
      'results': instance.results,
    };
