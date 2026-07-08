import 'package:dio/dio.dart';
import '../../constants/api_constants.dart';
import '../../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final SecureStorageService _secureStorage;
  final Dio _dio;
  bool _isRefreshing = false;
  final List<RequestOptions> _pendingRequests = [];

  AuthInterceptor({
    required SecureStorageService secureStorage,
    required Dio dio,
  })  : _secureStorage = secureStorage,
        _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    // Debug auth attachment status without exposing the token value.
    // ignore: avoid_print
    print(
      '[API] auth_attached=${token != null && token.isNotEmpty} method=${options.method} path=${options.path}',
    );
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      if (_isRefreshing) {
        _pendingRequests.add(err.requestOptions);
        return;
      }

      _isRefreshing = true;
      try {
        final refreshToken = await _secureStorage.getRefreshToken();
        if (refreshToken == null) {
          handler.next(err);
          return;
        }

        final response = await _dio.post(
          '${ApiConstants.baseUrl}${ApiConstants.refresh}',
          data: {
            'refresh': refreshToken,
            'refresh_token': refreshToken,
          },
          options: Options(headers: {'Authorization': null}),
        );

        final data = response.data as Map<String, dynamic>;
        final newAccess =
            (data['access_token'] ?? data['access']) as String?;
        final newRefresh =
            (data['refresh_token'] ?? data['refresh']) as String?;

        if (newAccess == null) {
          handler.next(err);
          return;
        }

        await _secureStorage.saveTokens(
          accessToken: newAccess,
          refreshToken: newRefresh ?? refreshToken,
        );

        // Retry original
        final retryOptions = err.requestOptions;
        retryOptions.headers['Authorization'] = 'Bearer $newAccess';
        final retryResponse = await _dio.fetch(retryOptions);

        // Replay pending
        for (final pending in _pendingRequests) {
          pending.headers['Authorization'] = 'Bearer $newAccess';
          _dio.fetch(pending);
        }
        _pendingRequests.clear();

        handler.resolve(retryResponse);
      } catch (_) {
        await _secureStorage.clearTokens();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }
}
