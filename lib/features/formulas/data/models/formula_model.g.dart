// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-maintained partial for FormulaVisitRequest serializers.

part of 'formula_model.dart';

FormulaVisitRequest _$FormulaVisitRequestFromJson(Map<String, dynamic> json) =>
    FormulaVisitRequest(
      customerId: json['customer_id'] as String?,
      serviceType: json['service_type'] as String?,
      notes: json['notes'] as String?,
      items: ((json['items'] as List<dynamic>?) ?? const [])
          .whereType<Map>()
          .map((e) => ColorItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );

Map<String, dynamic> _$FormulaVisitRequestToJson(FormulaVisitRequest instance) =>
    <String, dynamic>{
      'customer_id': instance.customerId,
      'service_type': instance.serviceType,
      'notes': instance.notes,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };
