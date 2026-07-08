import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../errors/exceptions.dart';
import '../storage/secure_storage.dart';
import 'interceptors/auth_interceptor.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  final secureStorage = ref.read(secureStorageProvider);
  dio.interceptors.addAll([
    AuthInterceptor(secureStorage: secureStorage, dio: dio),
    LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint('[API] $obj'),
    ),
  ]);

  return dio;
});

void debugPrint(String message) {
  // ignore: avoid_print
  print(message);
}

/// Parses a [DioException] into a typed [AppException].
Exception parseDioError(DioException e) {
  if (e.type == DioExceptionType.connectionError ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout) {
    return const NetworkException();
  }

  final statusCode = e.response?.statusCode;
  final data = e.response?.data;

  if (statusCode == 401) {
    return const AuthException();
  }

  String message = 'An error occurred';
  if (data is Map<String, dynamic>) {
    final detail = data['detail'];
    if (detail is List && detail.isNotEmpty) {
      final parts = detail.map((e) {
        if (e is Map) {
          final loc = (e['loc'] is List)
              ? (e['loc'] as List).whereType<String>().join('.')
              : '';
          final msg = e['msg']?.toString() ?? '';
          if (loc.isNotEmpty && msg.isNotEmpty) return '$loc: $msg';
          return msg.isNotEmpty ? msg : e.toString();
        }
        return e.toString();
      }).where((s) => s.isNotEmpty);
      message = parts.join('\n');
    } else {
      message = detail?.toString() ??
          data['message']?.toString() ??
          data['error']?.toString() ??
          message;
    }
  }

  return ServerException(message: message, statusCode: statusCode);
}
