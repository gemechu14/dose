import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage.dart';

const _tenantIdKey = 'tenant_id';

/// Resolves the current user's tenant id (cached in secure storage).
final currentTenantIdProvider = FutureProvider<String>((ref) async {
  final storage = ref.read(secureStorageProvider);
  final cached = await storage.read(key: _tenantIdKey);
  if (cached != null && cached.isNotEmpty) return cached;

  final dio = ref.read(dioProvider);
  try {
    final response = await dio.get(ApiConstants.tenantsMine);
    final id = _extractTenantId(response.data);
    if (id == null || id.isEmpty) {
      throw Exception('No tenant found for this account');
    }
    await storage.write(key: _tenantIdKey, value: id);
    return id;
  } on DioException catch (e) {
    throw parseDioError(e);
  }
});

String? _extractTenantId(dynamic data) {
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    final direct = map['id'] ?? map['tenant_id'];
    if (direct != null) return direct.toString();

    final items = map['items'] ?? map['results'] ?? map['tenants'];
    if (items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is Map) {
        return (first['id'] ?? first['tenant_id'])?.toString();
      }
    }
  }
  if (data is List && data.isNotEmpty) {
    final first = data.first;
    if (first is Map) {
      return (first['id'] ?? first['tenant_id'])?.toString();
    }
  }
  return null;
}
