import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/formula_model.dart';

abstract class FormulasRemoteDataSource {
  Future<PaginatedFormulas> getFormulas({
    String? customerId,
    int page,
    int pageSize,
  });
  Future<FormulaModel> getFormula(String id);
  Future<FormulaModel> saveVisit(FormulaVisitRequest request);
  Future<FormulaModel> updateFormula(String id, Map<String, dynamic> fields);
  Future<void> deleteFormula(String id);
}

class FormulasRemoteDataSourceImpl implements FormulasRemoteDataSource {
  final Dio _dio;
  const FormulasRemoteDataSourceImpl(this._dio);

  @override
  Future<PaginatedFormulas> getFormulas({
    String? customerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.formulas,
        queryParameters: {
          if (customerId != null) 'customer_id': customerId,
          'page': page,
          'page_size': pageSize,
        },
      );
      return PaginatedFormulas.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  @override
  Future<FormulaModel> getFormula(String id) async {
    try {
      final response =
          await _dio.get(ApiConstants.formulaById(id));
      return FormulaModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  @override
  Future<FormulaModel> saveVisit(FormulaVisitRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.formulaVisit,
        data: request.toJson(),
      );
      return FormulaModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  @override
  Future<FormulaModel> updateFormula(
      String id, Map<String, dynamic> fields) async {
    try {
      final response = await _dio.patch(
        ApiConstants.formulaById(id),
        data: fields,
      );
      return FormulaModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  @override
  Future<void> deleteFormula(String id) async {
    try {
      await _dio.delete(ApiConstants.formulaById(id));
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}

final formulasRemoteDataSourceProvider =
    Provider<FormulasRemoteDataSource>((ref) {
  return FormulasRemoteDataSourceImpl(ref.read(dioProvider));
});
