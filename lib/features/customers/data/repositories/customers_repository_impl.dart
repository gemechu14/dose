import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/customers_remote_datasource.dart';
import '../models/customer_model.dart';

abstract class CustomersRepository {
  Future<Either<Failure, PaginatedCustomers>> getCustomers({
    int page,
    int pageSize,
    String? search,
  });
  Future<Either<Failure, CustomerModel>> getCustomer(String id);
  Future<Either<Failure, CustomerModel>> createCustomer(
      CustomerCreateRequest request);
  Future<Either<Failure, CustomerModel>> updateCustomer(
      String id, Map<String, dynamic> fields);
  Future<Either<Failure, void>> deleteCustomer(String id);
}

class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersRemoteDataSource _remote;
  const CustomersRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedCustomers>> getCustomers({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final result = await _remote.getCustomers(
          page: page, pageSize: pageSize, search: search);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, CustomerModel>> getCustomer(String id) async {
    try {
      return Right(await _remote.getCustomer(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, CustomerModel>> createCustomer(
      CustomerCreateRequest request) async {
    try {
      return Right(await _remote.createCustomer(request));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, CustomerModel>> updateCustomer(
      String id, Map<String, dynamic> fields) async {
    try {
      return Right(await _remote.updateCustomer(id, fields));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      await _remote.deleteCustomer(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }
}

final customersRepositoryProvider = Provider<CustomersRepository>((ref) {
  return CustomersRepositoryImpl(ref.read(customersRemoteDataSourceProvider));
});
