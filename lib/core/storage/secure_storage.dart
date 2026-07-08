import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _accessTokenKey = 'access_token';
const _refreshTokenKey = 'refresh_token';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService(this._storage);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }

  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  Future<String?> read({required String key}) => _storage.read(key: key);

  Future<void> delete({required String key}) => _storage.delete(key: key);
}

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
  return SecureStorageService(storage);
});
