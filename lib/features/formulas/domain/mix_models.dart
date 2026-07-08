import 'dart:convert';

// ─── Mix-More mode ────────────────────────────────────────────────────────────

/// Copy = same bowl, new batch pre-filled with same products (amounts zeroed).
/// Edit = lock current batch in current bowl, add a fresh new bowl.
enum MixMoreMode { copyFormula, editFormula }

// ─── Global product (GET /products/) ─────────────────────────────────────────

class GlobalProduct {
  final String id;
  final String name;
  final String? code;
  final String? hexCode;
  final String? productLineName;
  final String? brandName;
  final String? lineCategory;
  final double? unitCost;

  const GlobalProduct({
    required this.id,
    required this.name,
    this.code,
    this.hexCode,
    this.productLineName,
    this.brandName,
    this.lineCategory,
    this.unitCost,
  });

  factory GlobalProduct.fromJson(Map<String, dynamic> json) {
    final productLine = TenantProduct._asMap(json['product_line']);
    final brand = TenantProduct._asMap(productLine?['brand']);
    return GlobalProduct(
      id: json['id'].toString(),
      name: (TenantProduct._str(json['name']) ?? '').trim(),
      code: TenantProduct._str(json['code']),
      hexCode: TenantProduct._str(json['hex_code']) ??
          TenantProduct._str(json['color_hex']),
      productLineName: TenantProduct._str(json['product_line_name']) ??
          TenantProduct._str(productLine?['name']),
      brandName: TenantProduct._str(json['brand_name']) ??
          TenantProduct._str(brand?['name']),
      lineCategory: TenantProduct._str(json['line_category']) ??
          TenantProduct._str(productLine?['category']),
      unitCost: TenantProduct._asDouble(json['unit_cost']),
    );
  }
}

// ─── Tenant Product ───────────────────────────────────────────────────────────

class TenantProduct {
  final String id;
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

  /// COLOR + TONER-with-hex contribute to the mixed color swatch.
  bool get contributesToColor {
    if (isDeveloper || isTreatment) return false;
    final hex = colorHex ?? '';
    return hex.isNotEmpty;
  }

  /// Goes inside the flask liquid layers (COLOR + TONER with valid hex).
  bool get goesInFlask {
    if (isDeveloper || isTreatment) return false;
    final hex = colorHex ?? '';
    return hex.isNotEmpty;
  }

  /// COLOR + TONER grams drive developer auto-calc (not dev or treatment).
  bool get countsTowardDeveloperRatio => !isDeveloper && !isTreatment;

  /// Join tenant-catalog row with global product (web builder pattern).
  factory TenantProduct.fromTenantCatalog(
    Map<String, dynamic> json,
    GlobalProduct? global,
  ) {
    final customName = _str(json['custom_name']);
    final hasCustomName =
        customName != null && customName.trim().isNotEmpty;
    final productId = _str(json['product_id']) ??
        _str(json['global_product_id']) ??
        global?.id;

    final name = hasCustomName
        ? customName.trim()
        : (global?.name.trim().isNotEmpty == true
            ? global!.name.trim()
            : 'Unknown');
    // Code only shown for non-custom labels: "Name (code)".
    final code = hasCustomName ? null : global?.code;

    final catRaw = (global?.lineCategory ?? _str(json['line_category']) ?? '')
        .toUpperCase();

    return TenantProduct(
      id: json['id'].toString(),
      globalProductId: productId,
      name: name,
      code: code,
      colorHex: global?.hexCode ??
          _str(json['hex_code']) ??
          _str(json['color_hex']),
      productLineName:
          global?.productLineName ?? _str(json['product_line_name']),
      brandName: global?.brandName ?? _str(json['brand_name']),
      category: catRaw,
      defaultUnitCost: _asDouble(json['default_unit_cost']) ??
          global?.unitCost ??
          0,
      isDeveloper: catRaw.contains('DEV') || catRaw.contains('DEVELOPER'),
      isToner: catRaw.contains('TON'),
      isTreatment: catRaw.contains('TREAT') || catRaw.contains('GLOSS'),
    );
  }

  /// Draft / locally serialized product (name + code already resolved).
  factory TenantProduct.fromJson(Map<String, dynamic> json) {
    final catRaw = (_str(json['category']) ?? '').toUpperCase();
    return TenantProduct(
      id: json['id'].toString(),
      globalProductId: _str(json['global_product_id']),
      name: _str(json['name']) ?? 'Unknown',
      code: _str(json['code']),
      colorHex: _str(json['color_hex']),
      productLineName: _str(json['product_line_name']),
      brandName: _str(json['brand_name']),
      category: catRaw,
      defaultUnitCost: _asDouble(json['default_unit_cost']) ?? 0,
      isDeveloper: json['is_developer'] as bool? ??
          catRaw.contains('DEV') ||
              catRaw.contains('DEVELOPER'),
      isToner:
          json['is_toner'] as bool? ?? catRaw.contains('TON'),
      isTreatment: json['is_treatment'] as bool? ??
          catRaw.contains('TREAT') ||
              catRaw.contains('GLOSS'),
    );
  }

  static Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  static String? _str(dynamic value) {
    if (value == null) return null;
    final s = value.toString().trim();
    return s.isEmpty ? null : s;
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
      name: (json['name'] ?? json['location_name'] ?? 'Location').toString(),
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
  final String leftoverG; // total bowl waste in grams (user-entered)
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

  /// Sum of COLOR + TONER amounts (excludes developer and treatment).
  double get pigmentGrams => items
      .where((i) => i.product.countsTowardDeveloperRatio)
      .fold(0.0, (s, i) => s + i.amount);

  double get developerGrams => items
      .where((i) => i.product.isDeveloper)
      .fold(0.0, (s, i) => s + i.amount);

  /// Apply ratio to developer line(s); splits equally if multiple developers.
  List<MixItem> itemsWithDeveloperRatio(String ratio) =>
      applyDeveloperRatio(items, ratio);

  double get wasteGrams =>
      double.tryParse(leftoverG) ?? 0;

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

  /// Split total waste proportionally across products.
  /// Returns a map of productId → wasteAmount.
  Map<String, double> computeWasteByProduct() {
    final totalWaste = wasteGrams;
    if (totalWaste <= 0) return {};
    final total = totalGrams;
    if (total <= 0) return {};
    final result = <String, double>{};
    for (final item in items) {
      if (item.amount <= 0) continue;
      result[item.product.id] = (item.amount / total) * totalWaste;
    }
    return result;
  }

  /// "Waste: 5g (07N:2g · DEV20:3g)"
  String wasteSplitNotes(String ratio) {
    final totalWaste = wasteGrams;
    if (totalWaste <= 0) return '';
    final waste = computeWasteByProduct();
    if (waste.isEmpty) return '';
    final parts = waste.entries
        .map((e) {
          final item = items.firstWhere((i) => i.product.id == e.key);
          return '${item.product.code ?? item.product.name}:${e.value.toStringAsFixed(1)}g';
        })
        .toList()
        .join(' · ');
    return 'Waste: ${totalWaste.toStringAsFixed(1)}g ($parts)';
  }

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
  MixBatch get currentBatch => batches.isNotEmpty ? batches.last : MixBatch(id: '$id-0');
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

  /// Items from the CURRENT BATCH of the ACTIVE BOWL only (for preview).
  List<MixItem> get previewItems {
    final bowl = activeBowl;
    if (bowl == null) return [];
    return bowl.currentBatch.items;
  }

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

      // Aggregate amounts per tenant_product_id across all batches.
      final amounts = <String, _AggItem>{};
      final wastes = <String, double>{};
      final batchNotes = <String>[];

      for (var batchIdx = 0; batchIdx < bowl.batches.length; batchIdx++) {
        final batch = bowl.batches[batchIdx];
        for (final item in batch.items) {
          if (item.amount <= 0) continue;
          amounts.update(
            item.product.id,
            (a) => _AggItem(
                product: a.product, amount: a.amount + item.amount),
            ifAbsent: () =>
                _AggItem(product: item.product, amount: item.amount),
          );
        }
        // Distribute waste proportionally across this batch's products.
        final wasteMap = batch.computeWasteByProduct();
        for (final e in wasteMap.entries) {
          wastes[e.key] = (wastes[e.key] ?? 0) + e.value;
        }
        final note =
            batch.wasteSplitNotes(bowl.developerRatio);
        if (note.isNotEmpty) {
          batchNotes.add('Batch ${batchIdx + 1}: $note');
        }
      }

      if (amounts.isEmpty) continue;

      final items = amounts.values.map((a) => {
            'tenant_product_id': a.product.id,
            'amount_used': a.amount,
            'waste_amount': wastes[a.product.id] ?? 0,
            'cost_at_time': a.product.defaultUnitCost,
          }).toList();

      final bowlNotes = batchNotes.isEmpty ? null : batchNotes.join(' | ');

      bowlPayloads.add({
        'bowl_label': bowl.label,
        'bowl_sort_order': bi,
        if (bowlNotes != null) 'notes': bowlNotes,
        'items': items,
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
  final int argbColor;

  const MixColorResult({
    required this.hexString,
    required this.argbColor,
  });
}

/// Weighted RGB average. Only COLOR + TONER-with-hex contribute.
MixColorResult mixColors(List<MixItem> items) {
  double r = 0, g = 0, b = 0, total = 0;
  for (final item in items) {
    if (!item.product.contributesToColor) continue;
    if (item.amount <= 0) continue;
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
    return const MixColorResult(hexString: '#CCCCCC', argbColor: 0xFFCCCCCC);
  }
  final ri = (r / total).round().clamp(0, 255);
  final gi = (g / total).round().clamp(0, 255);
  final bi = (b / total).round().clamp(0, 255);
  final argb = 0xFF000000 | (ri << 16) | (gi << 8) | bi;
  final hexOut =
      '#${ri.toRadixString(16).padLeft(2, '0')}${gi.toRadixString(16).padLeft(2, '0')}${bi.toRadixString(16).padLeft(2, '0')}'
          .toUpperCase();
  return MixColorResult(hexString: hexOut, argbColor: argb);
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

/// Update developer line amounts from COLOR+TONER pigment and bowl ratio.
List<MixItem> applyDeveloperRatio(List<MixItem> items, String ratio) {
  if (ratio == 'manual') return items;
  final devItems = items.where((i) => i.product.isDeveloper).toList();
  if (devItems.isEmpty) return items;
  final pigment = items
      .where((i) => i.product.countsTowardDeveloperRatio)
      .fold(0.0, (s, i) => s + i.amount);
  final totalDev = calcDeveloperAmount(pigment, ratio);
  final perDev = totalDev / devItems.length;
  return items
      .map((i) => i.product.isDeveloper ? i.copyWith(amount: perDev) : i)
      .toList();
}

/// Build display info for each item in the preview / flask.
class DropletItem {
  final MixItem source;
  final bool goesInFlask;
  final bool contributesToMix;
  final int argbColor; // for flask layer / chip

  const DropletItem({
    required this.source,
    required this.goesInFlask,
    required this.contributesToMix,
    required this.argbColor,
  });

  double get amount => source.amount;
  String get label => source.product.label;
}

// Developer accent palette (cycles by product id index).
const _devAccents = [
  0xFF38BDF8, // sky
  0xFFA78BFA, // purple
  0xFF2DD4BF, // teal
  0xFFFBBF24, // amber
  0xFFF472B6, // pink
  0xFFA3E635, // lime
];

List<DropletItem> buildDropletItems(
    List<MixItem> items, List<TenantProduct> devCatalog) {
  int devColorIdx = 0;
  final devColorMap = <String, int>{};
  final result = <DropletItem>[];
  for (final item in items) {
    if (item.amount <= 0) continue;
    final p = item.product;
    int argb;
    bool flask;
    bool mix;
    if (p.isDeveloper || p.isTreatment) {
      // Assign an accent color for this developer
      argb = devColorMap.putIfAbsent(p.id, () {
        final c = _devAccents[devColorIdx % _devAccents.length];
        devColorIdx++;
        return c;
      });
      flask = false;
      mix = false;
    } else {
      final hex = (p.colorHex ?? '').replaceFirst('#', '');
      if (hex.length >= 6) {
        final parsed = int.tryParse(hex.substring(0, 6), radix: 16);
        argb = parsed != null ? (0xFF000000 | parsed) : 0xFF94A3B8;
      } else {
        // COLOR without hex → gray in flask, no mix contribution
        argb = 0xFF94A3B8;
      }
      flask = p.goesInFlask;
      mix = p.contributesToColor;
    }
    result.add(DropletItem(
      source: item,
      goesInFlask: flask,
      contributesToMix: mix,
      argbColor: argb,
    ));
  }
  return result;
}

