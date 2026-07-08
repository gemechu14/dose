import 'package:flutter/foundation.dart';

abstract class ApiConstants {
  static const String _prodBaseUrl = 'https://dosecolor.com/api/v1';
  // static const String _devBaseUrl = 'http://localhost:8000/api/v1';
 static const String _devBaseUrl = 'https://dosecolor.com/api/v1';
  static String get baseUrl => kDebugMode ? _devBaseUrl : _prodBaseUrl;

  // Auth
  static const String login = '/users/login';
  static const String refresh = '/users/refresh';
  static const String me = '/users/me';
  static const String googleCallback = '/auth/google/callback';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String setPassword = '/auth/set-password';

  // Customers
  static const String customers = '/customers/';
  static String customerById(String id) => '/customers/$id';

  // Formulas
  static const String formulas = '/formulas/';
  static const String formulaVisit = '/formulas/visit';
  static String formulaVisitById(String id) => '/formulas/visits/$id';
  static String formulaById(String id) => '/formulas/$id';

  // Products
  static const String productBrands = '/products/brands';
  static const String productLines = '/products/lines';
  static const String products = '/products/';
  static String productById(String id) => '/products/$id';
  static const String tenantCatalog = '/products/tenant-catalog';

  // Inventory
  static const String inventoryItems = '/inventory/items';
  static const String inventoryLowStock = '/inventory/items/low-stock';
  static const String inventoryReorderList = '/inventory/items/reorder-list';
  static const String inventoryTransactions = '/inventory/transactions';
  static String inventoryTransactionsByItem(String itemId) =>
      '/inventory/transactions/$itemId';

  // Tenant / Location
  static const String tenantsMine = '/tenants/mine';
  static String tenantLocations(String tenantId) =>
      '/tenants/$tenantId/locations';
  static const String placesAutocomplete = '/places/autocomplete';

  // Pagination defaults
  static const int defaultPageSize = 20;
}
