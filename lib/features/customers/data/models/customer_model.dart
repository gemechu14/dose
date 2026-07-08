import 'package:json_annotation/json_annotation.dart';

part 'customer_model.g.dart';

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

@JsonSerializable()
class CustomerModel {
  final String id;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  final String? email;
  final String? phone;
  final String? notes;
  @JsonKey(name: 'created_at')
  final String? createdAt;
  @JsonKey(name: 'updated_at')
  final String? updatedAt;
  @JsonKey(name: 'formula_count')
  final int? formulaCount;
  @JsonKey(name: 'home_location_id')
  final String? homeLocationId;

  const CustomerModel({
    required this.id,
    required this.firstName,
    this.lastName = '',
    this.email,
    this.phone,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.formulaCount,
    this.homeLocationId,
  });

  String get fullName {
    final combined = '$firstName $lastName'.trim();
    return combined.isNotEmpty ? combined : firstName;
  }

  String get initials {
    final name = fullName.trim();
    if (name.isEmpty) return '?';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final f = parts.first.isNotEmpty ? parts.first[0] : '';
      final l = parts.last.isNotEmpty ? parts.last[0] : '';
      return '$f$l'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Single-letter avatar like the design reference.
  String get avatarLetter {
    final name = fullName.trim();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    String first = (json['first_name'] as String?) ?? '';
    String last = (json['last_name'] as String?) ?? '';

    final fullName = json['full_name'] as String?;
    if (fullName != null && fullName.trim().isNotEmpty) {
      final parts = fullName.trim().split(RegExp(r'\s+'));
      first = parts.first;
      last = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }

    return CustomerModel(
      id: json['id'] as String,
      firstName: first,
      lastName: last,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      formulaCount: _asInt(json['formula_count']),
      homeLocationId: json['home_location_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'notes': notes,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'formula_count': formulaCount,
        'home_location_id': homeLocationId,
      };
}

class PaginatedCustomers {
  final int count;
  final String? next;
  final String? previous;
  final List<CustomerModel> results;
  final int page;
  final int pageSize;
  final int totalPages;

  const PaginatedCustomers({
    required this.count,
    this.next,
    this.previous,
    required this.results,
    this.page = 1,
    this.pageSize = 20,
    this.totalPages = 1,
  });

  factory PaginatedCustomers.fromJson(Map<String, dynamic> json) {
    final list = (json['items'] ?? json['results']) as List<dynamic>? ?? [];
    final results = list
        .whereType<Map>()
        .map((e) => CustomerModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final total = _asInt(json['total'] ?? json['count']) ?? results.length;
    final page = _asInt(json['page']) ?? 1;
    final pageSize = _asInt(json['page_size']) ?? 20;
    final totalPages = _asInt(json['total_pages']) ??
        (pageSize == 0 ? 1 : ((total + pageSize - 1) ~/ pageSize));

    final hasMore = page < totalPages;
    return PaginatedCustomers(
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

class CustomerCreateRequest {
  final String fullName;
  final String tenantId;
  final String? email;
  final String? phone;
  final String? notes;
  final String? homeLocationId;

  const CustomerCreateRequest({
    required this.fullName,
    required this.tenantId,
    this.email,
    this.phone,
    this.notes,
    this.homeLocationId,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'full_name': fullName,
        'tenant_id': tenantId,
        if (email != null && email!.isNotEmpty) 'email': email,
        if (phone != null && phone!.isNotEmpty) 'phone': phone,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (homeLocationId != null && homeLocationId!.isNotEmpty)
          'home_location_id': homeLocationId,
      };
}
