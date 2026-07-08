import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../datasources/formulas_remote_datasource.dart';
import '../models/formula_model.dart';

abstract class FormulasRepository {
  Future<Either<Failure, PaginatedFormulas>> getFormulas({
    String? customerId,
    int page,
    int pageSize,
  });
  Future<Either<Failure, FormulaModel>> getFormula(String id);
  Future<Either<Failure, FormulaModel>> saveVisit(
      FormulaVisitRequest request);
  Future<Either<Failure, FormulaModel>> updateFormula(
      String id, Map<String, dynamic> fields);
  Future<Either<Failure, void>> deleteFormula(String id);
}

class FormulasRepositoryImpl implements FormulasRepository {
  final FormulasRemoteDataSource _remote;
  const FormulasRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, PaginatedFormulas>> getFormulas({
    String? customerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final r = await _remote.getFormulas(
          customerId: customerId, page: page, pageSize: pageSize);
      return Right(r);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on FormatException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FormulaModel>> getFormula(String id) async {
    try {
      return Right(await _remote.getFormula(id));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on FormatException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FormulaModel>> saveVisit(
      FormulaVisitRequest request) async {
    try {
      return Right(await _remote.saveVisit(request));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on FormatException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, FormulaModel>> updateFormula(
      String id, Map<String, dynamic> fields) async {
    try {
      return Right(await _remote.updateFormula(id, fields));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on FormatException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteFormula(String id) async {
    try {
      await _remote.deleteFormula(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException {
      return const Left(NetworkFailure());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

final formulasRepositoryProvider = Provider<FormulasRepository>((ref) {
  return FormulasRepositoryImpl(ref.read(formulasRemoteDataSourceProvider));
});
