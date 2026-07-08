import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/user_entity.dart';
import '../datasources/auth_remote_datasource.dart';

abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> login(String email, String password);
  Future<Either<Failure, UserEntity>> getCurrentUser();
  Future<Either<Failure, void>> forgotPassword(String email);
  Future<Either<Failure, void>> resetPassword(String token, String password);
  Future<Either<Failure, UserEntity>> googleLogin(String code, String state);
  Future<void> logout();
}

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remote;
  final SecureStorageService _storage;

  const AuthRepositoryImpl({
    required AuthRemoteDataSource remote,
    required SecureStorageService storage,
  })  : _remote = remote,
        _storage = storage;

  @override
  Future<Either<Failure, UserEntity>> login(
      String email, String password) async {
    try {
      final tokens = await _remote.login(email, password);
      await _storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      if (tokens.user != null) {
        return Right(UserEntity.fromModel(tokens.user!));
      }
      final user = await _remote.getMe();
      return Right(UserEntity.fromModel(user));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on FormatException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    try {
      final user = await _remote.getMe();
      return Right(UserEntity.fromModel(user));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> forgotPassword(String email) async {
    try {
      await _remote.forgotPassword(email);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(
      String token, String password) async {
    try {
      await _remote.resetPassword(token, password);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, UserEntity>> googleLogin(
      String code, String state) async {
    try {
      final tokens = await _remote.googleCallback(code, state);
      await _storage.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      if (tokens.user != null) {
        return Right(UserEntity.fromModel(tokens.user!));
      }
      final user = await _remote.getMe();
      return Right(UserEntity.fromModel(user));
    } on AuthException catch (e) {
      return Left(AuthFailure(message: e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on FormatException catch (e) {
      return Left(ServerFailure(message: e.message));
    }
  }

  @override
  Future<void> logout() => _storage.clearTokens();
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    remote: ref.read(authRemoteDataSourceProvider),
    storage: ref.read(secureStorageProvider),
  );
});
