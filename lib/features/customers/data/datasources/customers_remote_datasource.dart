import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/customer_model.dart';

abstract class CustomersRemoteDataSource {
  Future<PaginatedCustomers> getCustomers({
    int page = 1,
    int pageSize = 20,
    String? search,
  });
  Future<CustomerModel> getCustomer(String id);
  Future<CustomerModel> createCustomer(CustomerCreateRequest request);
  Future<CustomerModel> updateCustomer(
      String id, Map<String, dynamic> fields);
  Future<void> deleteCustomer(String id);
}

class CustomersRemoteDataSourceImpl implements CustomersRemoteDataSource {
  final Dio _dio;
  const CustomersRemoteDataSourceImpl(this._dio);

  @override
  Future<PaginatedCustomers> getCustomers({
    int page = 1,
    int pageSize = 20,
    String? search,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.customers,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );
      return PaginatedCustomers.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  @override
  Future<CustomerModel> getCustomer(String id) async {
    try {
      final response =
          await _dio.get(ApiConstants.customerById(id));
      return CustomerModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  @override
  Future<CustomerModel> createCustomer(
      CustomerCreateRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.customers,
        data: request.toJson(),
      );
      return CustomerModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  @override
  Future<CustomerModel> updateCustomer(
      String id, Map<String, dynamic> fields) async {
    try {
      final response = await _dio.patch(
        ApiConstants.customerById(id),
        data: fields,
      );
      return CustomerModel.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }

  @override
  Future<void> deleteCustomer(String id) async {
    try {
      await _dio.delete(ApiConstants.customerById(id));
    } on DioException catch (e) {
      throw parseDioError(e);
    }
  }
}

final customersRemoteDataSourceProvider =
    Provider<CustomersRemoteDataSource>((ref) {
  return CustomersRemoteDataSourceImpl(ref.read(dioProvider));
});
