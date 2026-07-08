import 'dart:convert';

// ─── Tenant Product (from catalog) ────────────────────────────────────────────

class TenantProduct {
  final String id; // tenant_product_id
  final String? globalProductId;
  final String name;
  final String? code;
  final String? colorHex;
  final String? productLineName;
  final String? brandName;
  final String? category;
  final double defaultUnitCost;
  final bool isDeveloper;
  final bool isToner;
  final bool isTreatment;

  const TenantProduct({
    required this.id,
    this.globalProductId,
    required this.name,
    this.code,
    this.colorHex,
    this.productLineName,
    this.brandName,
    this.category,
    this.defaultUnitCost = 0,
    this.isDeveloper = false,
    this.isToner = false,
    this.isTreatment = false,
  });

  String get label {
    final base = name.trim();
    if (code != null && code!.trim().isNotEmpty && !base.contains(code!)) {
      return '$base (${code!.trim()})';
    }
    return base;
  }

  bool get contributesToColor =>
      !isDeveloper && !isTreatment && colorHex != null && colorHex!.isNotEmpty;

  factory TenantProduct.fromJson(Map<String, dynamic> json) {
    final global = json['global_product'] as Map<String, dynamic>?;
    final catRaw = ((json['category'] ??
                json['product_category'] ??
                global?['category'] ??
                global?['product_category'] ??
                '') as Object)
        .toString()
        .toUpperCase();

    return TenantProduct(
      id: json['id'].toString(),
      globalProductId:
          (json['global_product_id'] ?? global?['id'])?.toString(),
      name: (json['custom_name'] ??
              json['name'] ??
              global?['name'] ??
              'Unknown')
          .toString(),
      code: (json['code'] ?? global?['code'])?.toString(),
      colorHex:
          (json['color_hex'] ?? global?['color_hex'])?.toString(),
      productLineName: (json['product_line_name'] ??
              global?['product_line_name'])
          ?.toString(),
      brandName:
          (json['brand_name'] ?? global?['brand_name'])?.toString(),
      category: catRaw,
      defaultUnitCost: _asDouble(json['default_unit_cost'] ??
              json['unit_cost'] ??
              global?['unit_cost']) ??
          0,
      isDeveloper:
          catRaw.contains('DEV') || catRaw.contains('DEVELOPER'),
      isToner: catRaw.contains('TON'),
      isTreatment:
          catRaw.contains('TREAT') || catRaw.contains('GLOSS'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'global_product_id': globalProductId,
        'name': name,
        'code': code,
        'color_hex': colorHex,
        'product_line_name': productLineName,
        'brand_name': brandName,
        'category': category,
        'default_unit_cost': defaultUnitCost,
        'is_developer': isDeveloper,
        'is_toner': isToner,
        'is_treatment': isTreatment,
      };

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

// ─── Location ─────────────────────────────────────────────────────────────────

class LocationModel {
  final String id;
  final String name;
  final String? address;

  const LocationModel({
    required this.id,
    required this.name,
    this.address,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'].toString(),
      name:
          (json['name'] ?? json['location_name'] ?? 'Location').toString(),
      address: json['address']?.toString(),
    );
  }
}

// ─── Stock item ───────────────────────────────────────────────────────────────

class StockItem {
  final String tenantProductId;
  final double onHandQty;

  const StockItem({
    required this.tenantProductId,
    required this.onHandQty,
  });

  bool get inStock => onHandQty > 0;

  factory StockItem.fromJson(Map<String, dynamic> json) {
    final productId =
        (json['tenant_product_id'] ?? json['product_id'] ?? '').toString();
    return StockItem(
      tenantProductId: productId,
      onHandQty: _asDouble(json['on_hand_qty'] ??
              json['quantity_on_hand'] ??
              json['quantity'] ??
              0) ??
          0,
    );
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}

// ─── Local mix state ──────────────────────────────────────────────────────────

class MixItem {
  final String id;
  final TenantProduct product;
  final double amount;

  const MixItem({
    required this.id,
    required this.product,
    this.amount = 0,
  });

  MixItem copyWith({TenantProduct? product, double? amount}) => MixItem(
        id: id,
        product: product ?? this.product,
        amount: amount ?? this.amount,
      );

  double get estimatedCost => product.defaultUnitCost * amount;

  Map<String, dynamic> toJson() => {
        'id': id,
        'product': product.toJson(),
        'amount': amount,
      };

  factory MixItem.fromJson(Map<String, dynamic> json) => MixItem(
        id: json['id'] as String,
        product:
            TenantProduct.fromJson(json['product'] as Map<String, dynamic>),
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
      );
}

class MixBatch {
  final String id;
  final List<MixItem> items;
  final bool isLocked;
  final String leftoverG;
  final String leftoverMl;
  final String leftoverOz;

  const MixBatch({
    required this.id,
    this.items = const [],
    this.isLocked = false,
    this.leftoverG = '',
    this.leftoverMl = '',
    this.leftoverOz = '',
  });

  double get totalGrams => items.fold(0, (s, i) => s + i.amount);
  double get totalCost => items.fold(0, (s, i) => s + i.estimatedCost);

  MixBatch copyWith({
    List<MixItem>? items,
    bool? isLocked,
    String? leftoverG,
    String? leftoverMl,
    String? leftoverOz,
  }) =>
      MixBatch(
        id: id,
        items: items ?? this.items,
        isLocked: isLocked ?? this.isLocked,
        leftoverG: leftoverG ?? this.leftoverG,
        leftoverMl: leftoverMl ?? this.leftoverMl,
        leftoverOz: leftoverOz ?? this.leftoverOz,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((i) => i.toJson()).toList(),
        'isLocked': isLocked,
        'leftoverG': leftoverG,
        'leftoverMl': leftoverMl,
        'leftoverOz': leftoverOz,
      };

  factory MixBatch.fromJson(Map<String, dynamic> json) => MixBatch(
        id: json['id'] as String,
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => MixItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        isLocked: json['isLocked'] as bool? ?? false,
        leftoverG: json['leftoverG'] as String? ?? '',
        leftoverMl: json['leftoverMl'] as String? ?? '',
        leftoverOz: json['leftoverOz'] as String? ?? '',
      );
}

class MixBowl {
  final String id;
  final String label;
  final String developerRatio;
  final List<MixBatch> batches;

  const MixBowl({
    required this.id,
    required this.label,
    this.developerRatio = '1:1',
    this.batches = const [],
  });

  List<MixItem> get allItems => batches.expand((b) => b.items).toList();
  double get totalGrams => batches.fold(0, (s, b) => s + b.totalGrams);
  double get totalCost => batches.fold(0, (s, b) => s + b.totalCost);

  MixBowl copyWith({
    String? label,
    String? developerRatio,
    List<MixBatch>? batches,
  }) =>
      MixBowl(
        id: id,
        label: label ?? this.label,
        developerRatio: developerRatio ?? this.developerRatio,
        batches: batches ?? this.batches,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'developerRatio': developerRatio,
        'batches': batches.map((b) => b.toJson()).toList(),
      };

  factory MixBowl.fromJson(Map<String, dynamic> json) {
    List<MixBatch> batches = (json['batches'] as List<dynamic>? ?? [])
        .map((e) => MixBatch.fromJson(e as Map<String, dynamic>))
        .toList();
    if (batches.isEmpty) {
      batches = [MixBatch(id: 'batch-${json['id']}-0')];
    }
    return MixBowl(
      id: json['id'] as String,
      label: json['label'] as String? ?? 'Bowl',
      developerRatio: json['developerRatio'] as String? ?? '1:1',
      batches: batches,
    );
  }

  static MixBowl empty({required String id, required String label}) => MixBowl(
        id: id,
        label: label,
        developerRatio: '1:1',
        batches: [MixBatch(id: 'batch-$id-0')],
      );
}

// ─── Full builder state ───────────────────────────────────────────────────────

class MixBuilderState {
  final String? customerId;
  final String? customerName;
  final String? locationId;
  final String? sessionName;
  final String? serviceType;
  final String? notes;
  final String? remixSourceFormulaId;
  final List<MixBowl> bowls;
  final int activeBowlIndex;

  const MixBuilderState({
    this.customerId,
    this.customerName,
    this.locationId,
    this.sessionName,
    this.serviceType,
    this.notes,
    this.remixSourceFormulaId,
    this.bowls = const [],
    this.activeBowlIndex = 0,
  });

  MixBuilderState copyWith({
    Object? customerId = _sentinel,
    Object? customerName = _sentinel,
    Object? locationId = _sentinel,
    Object? sessionName = _sentinel,
    Object? serviceType = _sentinel,
    Object? notes = _sentinel,
    Object? remixSourceFormulaId = _sentinel,
    List<MixBowl>? bowls,
    int? activeBowlIndex,
  }) =>
      MixBuilderState(
        customerId:
            customerId == _sentinel ? this.customerId : customerId as String?,
        customerName: customerName == _sentinel
            ? this.customerName
            : customerName as String?,
        locationId:
            locationId == _sentinel ? this.locationId : locationId as String?,
        sessionName: sessionName == _sentinel
            ? this.sessionName
            : sessionName as String?,
        serviceType: serviceType == _sentinel
            ? this.serviceType
            : serviceType as String?,
        notes: notes == _sentinel ? this.notes : notes as String?,
        remixSourceFormulaId: remixSourceFormulaId == _sentinel
            ? this.remixSourceFormulaId
            : remixSourceFormulaId as String?,
        bowls: bowls ?? this.bowls,
        activeBowlIndex: activeBowlIndex ?? this.activeBowlIndex,
      );

  double get totalCost => bowls.fold(0, (s, b) => s + b.totalCost);
  double get totalGrams => bowls.fold(0, (s, b) => s + b.totalGrams);

  bool get isValid =>
      customerId != null &&
      locationId != null &&
      bowls.any((b) => b.allItems.any((i) => i.amount > 0));

  MixBowl? get activeBowl =>
      activeBowlIndex < bowls.length ? bowls[activeBowlIndex] : null;

  String toDraftJson() => jsonEncode({
        'customerId': customerId,
        'customerName': customerName,
        'locationId': locationId,
        'sessionName': sessionName,
        'serviceType': serviceType,
        'notes': notes,
        'remixSourceFormulaId': remixSourceFormulaId,
        'bowls': bowls.map((b) => b.toJson()).toList(),
        'activeBowlIndex': activeBowlIndex,
      });

  factory MixBuilderState.fromDraftJson(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final bowls = (json['bowls'] as List<dynamic>? ?? [])
        .map((e) => MixBowl.fromJson(e as Map<String, dynamic>))
        .toList();
    return MixBuilderState(
      customerId: json['customerId'] as String?,
      customerName: json['customerName'] as String?,
      locationId: json['locationId'] as String?,
      sessionName: json['sessionName'] as String?,
      serviceType: json['serviceType'] as String?,
      notes: json['notes'] as String?,
      remixSourceFormulaId: json['remixSourceFormulaId'] as String?,
      bowls: bowls.isEmpty
          ? [MixBowl.empty(id: 'bowl-0', label: 'roots')]
          : bowls,
      activeBowlIndex: json['activeBowlIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toVisitPayload({
    required String tenantId,
    required String locationId,
    required String userId,
  }) {
    final bowlPayloads = <Map<String, dynamic>>[];
    for (var bi = 0; bi < bowls.length; bi++) {
      final bowl = bowls[bi];
      final aggregated = <String, _AggItem>{};
      for (final batch in bowl.batches) {
        for (final item in batch.items) {
          if (item.amount <= 0) continue;
          aggregated.update(
            item.product.id,
            (a) => _AggItem(
              product: a.product,
              amount: a.amount + item.amount,
            ),
            ifAbsent: () =>
                _AggItem(product: item.product, amount: item.amount),
          );
        }
      }
      if (aggregated.isEmpty) continue;
      bowlPayloads.add({
        'bowl_label': bowl.label,
        'bowl_sort_order': bi,
        'notes': null,
        'items': aggregated.values
            .map((a) => {
                  'tenant_product_id': a.product.id,
                  'amount_used': a.amount,
                  'waste_amount': 0,
                  'cost_at_time': a.product.defaultUnitCost,
                })
            .toList(),
      });
    }

    return {
      'tenant_id': tenantId,
      'location_id': locationId,
      'customer_id': customerId,
      'created_by_user_id': userId,
      if (sessionName != null && sessionName!.isNotEmpty)
        'session_name': sessionName,
      if (serviceType != null && serviceType!.isNotEmpty)
        'service_type': serviceType,
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'bowls': bowlPayloads,
    };
  }
}

const _sentinel = Object();

class _AggItem {
  final TenantProduct product;
  final double amount;
  const _AggItem({required this.product, required this.amount});
}

// ─── Color mixing helper ──────────────────────────────────────────────────────

class MixColorResult {
  final String hexString;
  final int argbColor; // 0xFFRRGGBB usable as Flutter Color value

  const MixColorResult({
    required this.hexString,
    required this.argbColor,
  });
}

MixColorResult mixColors(List<MixItem> items) {
  double r = 0, g = 0, b = 0, total = 0;
  for (final item in items) {
    if (!item.product.contributesToColor) continue;
    final hex = (item.product.colorHex ?? '').replaceFirst('#', '');
    if (hex.length < 6) continue;
    final parsed = int.tryParse(hex.substring(0, 6), radix: 16);
    if (parsed == null) continue;
    final rr = (parsed >> 16) & 0xff;
    final gg = (parsed >> 8) & 0xff;
    final bb = parsed & 0xff;
    final w = item.amount;
    r += rr * w;
    g += gg * w;
    b += bb * w;
    total += w;
  }
  if (total == 0) {
    return const MixColorResult(hexString: '#94A3B8', argbColor: 0xFF94A3B8);
  }
  final ri = (r / total).round().clamp(0, 255);
  final gi = (g / total).round().clamp(0, 255);
  final bi = (b / total).round().clamp(0, 255);
  final argb = 0xFF000000 | (ri << 16) | (gi << 8) | bi;
  final hex =
      '#${ri.toRadixString(16).padLeft(2, '0')}${gi.toRadixString(16).padLeft(2, '0')}${bi.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();
  return MixColorResult(hexString: hex, argbColor: argb);
}

/// Developer auto-calc given pigment grams and ratio string.
double calcDeveloperAmount(double pigmentGrams, String ratio) {
  switch (ratio) {
    case '1:1':
      return pigmentGrams;
    case '1:1.5':
      return pigmentGrams * 1.5;
    case '1:2':
      return pigmentGrams * 2;
    default:
      return 0;
  }
}
