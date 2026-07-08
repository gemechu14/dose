import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/auth_models.dart';

abstract class AuthRemoteDataSource {
  Future<TokenResponse> login(String email, String password);
  Future<UserModel> getMe();
  Future<void> forgotPassword(String email);
  Future<void> resetPassword(String token, String password);
  Future<({String authUrl, String state})> getGoogleStartUrl(
      String redirectUri);
  Future<TokenResponse> googleCallback(String code, String state);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  const AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<TokenResponse> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );
      return TokenResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  @override
  Future<UserModel> getMe() async {
    try {
      final response = await _dio.get(ApiConstants.me);
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  @override
  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(
        ApiConstants.forgotPassword,
        data: {'email': email},
      );
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  @override
  Future<void> resetPassword(String token, String password) async {
    try {
      await _dio.post(
        ApiConstants.resetPassword,
        data: {'token': token, 'password': password},
      );
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  @override
  Future<({String authUrl, String state})> getGoogleStartUrl(
      String redirectUri) async {
    try {
      final response = await _dio.get(
        ApiConstants.googleStart,
        queryParameters: {'redirect_uri': redirectUri},
        options: Options(headers: {'Authorization': ''}),
      );
      final data = response.data as Map<String, dynamic>;
      final authUrl = data['auth_url'] as String? ?? '';
      final state = data['state'] as String? ?? '';
      if (authUrl.isEmpty) {
        throw const AuthException(
            message: 'Google sign-in is not configured on the server.');
      }
      return (authUrl: authUrl, state: state);
    } on DioException catch (e) {
      if (e.response?.statusCode == 503) {
        throw const AuthException(
            message: 'Google sign-in is not configured on the server.');
      }
      throw parseDioError(e);
    }
  }

  @override
  Future<TokenResponse> googleCallback(String code, String state) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.googleCallback}?code=$code&state=$state',
      );
      return TokenResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}

final authRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.read(dioProvider));
});
