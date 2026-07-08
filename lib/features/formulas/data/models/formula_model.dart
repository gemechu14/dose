import 'package:json_annotation/json_annotation.dart';

part 'formula_model.g.dart';

double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

@JsonSerializable()
class ColorItemModel {
  @JsonKey(name: 'product_id')
  final String productId;
  @JsonKey(name: 'product_name')
  final String? productName;
  @JsonKey(name: 'product_code')
  final String? productCode;
  @JsonKey(name: 'color_hex')
  final String? colorHex;
  @JsonKey(name: 'amount_used')
  final double amountUsed;
  final String unit; // 'g' or 'ml'
  @JsonKey(name: 'unit_cost')
  final double? unitCost;
  @JsonKey(name: 'bowl_index')
  final int bowlIndex;
  @JsonKey(name: 'waste_amount')
  final double? wasteAmount;

  const ColorItemModel({
    required this.productId,
    this.productName,
    this.productCode,
    this.colorHex,
    required this.amountUsed,
    this.unit = 'g',
    this.unitCost,
    this.bowlIndex = 0,
    this.wasteAmount,
  });

  double get totalCost => (unitCost ?? 0) * amountUsed;

  /// Parses both mobile builder shape and API `formula_items` shape.
  factory ColorItemModel.fromJson(Map<String, dynamic> json) {
    final productId = (json['tenant_product_id'] ??
            json['product_id'] ??
            '')
        .toString();
    return ColorItemModel(
      productId: productId,
      productName: json['product_name'] as String?,
      productCode: json['product_code'] as String?,
      colorHex: json['color_hex'] as String?,
      amountUsed: _asDouble(json['amount_used']) ?? 0,
      unit: (json['unit'] as String?) ?? 'g',
      unitCost: _asDouble(json['cost_at_time'] ?? json['unit_cost']),
      bowlIndex: _asInt(json['bowl_index'] ?? json['bowl_sort_order']) ?? 0,
      wasteAmount: _asDouble(json['waste_amount']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'tenant_product_id': productId,
        'product_id': productId,
        'product_name': productName,
        'product_code': productCode,
        'color_hex': colorHex,
        'amount_used': amountUsed,
        'unit': unit,
        'unit_cost': unitCost,
        'cost_at_time': unitCost,
        'bowl_index': bowlIndex,
        if (wasteAmount != null) 'waste_amount': wasteAmount,
      };
}

@JsonSerializable()
class FormulaModel {
  final String id;
  @JsonKey(name: 'customer_id')
  final String? customerId;
  @JsonKey(name: 'customer_name')
  final String? customerName;
  @JsonKey(name: 'formula_name')
  final String? formulaName;
  @JsonKey(name: 'service_type')
  final String? serviceType;
  final String? notes;
  @JsonKey(name: 'bowl_label')
  final String? bowlLabel;
  @JsonKey(name: 'bowl_sort_order')
  final int? bowlSortOrder;
  final List<ColorItemModel> items;
  @JsonKey(name: 'total_cost')
  final double? totalCost;
  @JsonKey(name: 'visit_id')
  final String? visitId;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;

  const FormulaModel({
    required this.id,
    this.customerId,
    this.customerName,
    this.formulaName,
    this.serviceType,
    this.notes,
    this.bowlLabel,
    this.bowlSortOrder,
    this.items = const [],
    this.totalCost,
    this.visitId,
    this.createdAt,
    this.updatedAt,
  });

  /// Display title for history cards.
  String get displayTitle {
    if (customerName != null && customerName!.trim().isNotEmpty) {
      return customerName!;
    }
    if (formulaName != null && formulaName!.trim().isNotEmpty) {
      return formulaName!;
    }
    if (bowlLabel != null && bowlLabel!.trim().isNotEmpty) {
      return bowlLabel!;
    }
    return 'Untitled formula';
  }

  String get displayService {
    if (serviceType != null && serviceType!.trim().isNotEmpty) {
      return serviceType!;
    }
    if (formulaName != null && formulaName!.trim().isNotEmpty) {
      return formulaName!;
    }
    return 'Color service';
  }

  double get computedCost {
    if (totalCost != null) return totalCost!;
    return items.fold(0.0, (s, i) => s + i.totalCost);
  }

  double get totalWeight =>
      items.fold(0.0, (s, i) => s + i.amountUsed);

  factory FormulaModel.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['formula_items'] ?? json['items']) as List<dynamic>?;
    final items = rawItems
            ?.whereType<Map>()
            .map((e) => ColorItemModel.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const <ColorItemModel>[];

    final bowlSort = _asInt(json['bowl_sort_order']);

    return FormulaModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String?,
      customerName: json['customer_name'] as String?,
      formulaName: json['formula_name'] as String?,
      serviceType: json['service_type'] as String?,
      notes: json['notes'] as String?,
      bowlLabel: json['bowl_label'] as String?,
      bowlSortOrder: bowlSort,
      items: items
          .map(
            (i) => ColorItemModel(
              productId: i.productId,
              productName: i.productName,
              productCode: i.productCode,
              colorHex: i.colorHex,
              amountUsed: i.amountUsed,
              unit: i.unit,
              unitCost: i.unitCost,
              bowlIndex: bowlSort ?? i.bowlIndex,
              wasteAmount: i.wasteAmount,
            ),
          )
          .toList(),
      totalCost: _asDouble(json['total_cost']),
      visitId: json['visit_id'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'customer_id': customerId,
        'customer_name': customerName,
        'formula_name': formulaName,
        'service_type': serviceType,
        'notes': notes,
        'bowl_label': bowlLabel,
        'bowl_sort_order': bowlSortOrder,
        'items': items.map((e) => e.toJson()).toList(),
        'total_cost': totalCost,
        'visit_id': visitId,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

@JsonSerializable()
class FormulaVisitRequest {
  @JsonKey(name: 'customer_id')
  final String? customerId;
  @JsonKey(name: 'service_type')
  final String? serviceType;
  final String? notes;
  final List<ColorItemModel> items;

  const FormulaVisitRequest({
    this.customerId,
    this.serviceType,
    this.notes,
    required this.items,
  });

  Map<String, dynamic> toJson() => _$FormulaVisitRequestToJson(this);
}

class PaginatedFormulas {
  final int count;
  final String? next;
  final String? previous;
  final List<FormulaModel> results;
  final int page;
  final int pageSize;
  final int totalPages;

  const PaginatedFormulas({
    required this.count,
    this.next,
    this.previous,
    required this.results,
    this.page = 1,
    this.pageSize = 20,
    this.totalPages = 1,
  });

  /// Supports both:
  /// `{ items, page, page_size, total, total_pages }`
  /// and classic `{ results, count, next, previous }`
  factory PaginatedFormulas.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] ?? json['results']) as List<dynamic>? ?? [];
    final results = list
        .whereType<Map>()
        .map((e) => FormulaModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final total = _asInt(json['total'] ?? json['count']) ?? results.length;
    final page = _asInt(json['page']) ?? 1;
    final pageSize = _asInt(json['page_size']) ?? 20;
    final totalPages = _asInt(json['total_pages']) ??
        (pageSize == 0 ? 1 : ((total + pageSize - 1) ~/ pageSize));

    final hasMore = page < totalPages;
    return PaginatedFormulas(
      count: total,
      results: results,
      page: page,
      pageSize: pageSize,
      totalPages: totalPages,
      next: hasMore ? 'page_${page + 1}' : null,
      previous: page > 1 ? 'page_${page - 1}' : null,
    );
  }
}
