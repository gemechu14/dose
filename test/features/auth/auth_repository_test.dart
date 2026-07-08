import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:chroma_inventory_pro/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:chroma_inventory_pro/features/auth/data/models/auth_models.dart';
import 'package:chroma_inventory_pro/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:chroma_inventory_pro/core/storage/secure_storage.dart';
import 'package:chroma_inventory_pro/core/errors/exceptions.dart';

class MockAuthRemoteDataSource extends Mock
    implements AuthRemoteDataSource {}

class MockSecureStorageService extends Mock
    implements SecureStorageService {}

void main() {
  late MockAuthRemoteDataSource mockRemote;
  late MockSecureStorageService mockStorage;
  late AuthRepository repository;

  setUp(() {
    mockRemote = MockAuthRemoteDataSource();
    mockStorage = MockSecureStorageService();
    repository = AuthRepositoryImpl(
        remote: mockRemote, storage: mockStorage);
  });

  const testTokens = TokenResponse(
    accessToken: 'access_token',
    refreshToken: 'refresh_token',
  );
  const testUser = UserModel(
    id: '1',
    email: 'test@test.com',
    firstName: 'Jane',
    lastName: 'Smith',
    role: 'stylist',
  );

  group('login', () {
    test('returns user on success', () async {
      when(() => mockRemote.login(any(), any()))
          .thenAnswer((_) async => testTokens);
      when(() => mockRemote.getMe())
          .thenAnswer((_) async => testUser);
      when(() => mockStorage.saveTokens(
            accessToken: any(named: 'accessToken'),
            refreshToken: any(named: 'refreshToken'),
          )).thenAnswer((_) async {});

      final result =
          await repository.login('test@test.com', 'password');

      expect(result.isRight(), isTrue);
      result.fold((_) {}, (user) {
        expect(user.email, 'test@test.com');
        expect(user.fullName, 'Jane Smith');
      });
    });

    test('returns AuthFailure on 401', () async {
      when(() => mockRemote.login(any(), any()))
          .thenThrow(const AuthException(message: 'Invalid credentials'));

      final result =
          await repository.login('bad@test.com', 'wrong');

      expect(result.isLeft(), isTrue);
    });

    test('returns NetworkFailure on network error', () async {
      when(() => mockRemote.login(any(), any()))
          .thenThrow(const NetworkException());

      final result = await repository.login('a@b.com', 'p');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.message, 'No internet connection'),
        (_) {},
      );
    });
  });

  group('logout', () {
    test('clears tokens', () async {
      when(() => mockStorage.clearTokens())
          .thenAnswer((_) async {});

      await repository.logout();

      verify(() => mockStorage.clearTokens()).called(1);
    });
  });
}
