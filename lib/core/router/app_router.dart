import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/customers/presentation/screens/customers_list_screen.dart';
import '../../features/customers/presentation/screens/customer_form_screen.dart';
import '../../features/customers/presentation/screens/customer_profile_screen.dart';
import '../../features/formulas/presentation/screens/formula_builder_screen.dart';
import '../../features/formulas/presentation/screens/formulas_history_screen.dart';
import '../../features/formulas/presentation/screens/formula_detail_screen.dart';
import '../../features/products/presentation/screens/brands_screen.dart';
import '../../features/products/presentation/screens/product_lines_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/products/presentation/screens/product_detail_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../shared/widgets/main_shell.dart';

abstract class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const customers = '/customers';
  static const newCustomer = '/customers/new';
  static const customerProfile = '/customers/:customerId';
  static const editCustomer = '/customers/:customerId/edit';
  // Mix = formula builder tab (center nav)
  static const mix = '/mix';
  // History = past formulas
  static const formulaHistory = '/formulas';
  static const formulaDetail = '/formulas/:formulaId';
  static const brands = '/products/brands';
  static const productLines = '/products/lines/:brandId';
  static const products = '/products/catalog/:lineId';
  static const productDetail = '/products/:productId';
  static const inventory = '/inventory';
  static const profile = '/profile';
}

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.value != null;
      final isSplash = loc == AppRoutes.splash;
      final isAuthRoute =
          loc.startsWith('/login') || loc.startsWith('/forgot');

      // While auth is resolving, show splash
      if (isLoading) {
        return isSplash ? null : AppRoutes.splash;
      }

      // Auth resolved — navigate away from splash / auth screens
      if (isSplash || isAuthRoute) {
        return isLoggedIn ? AppRoutes.home : AppRoutes.login;
      }

      // Protected routes: redirect to login if not authenticated
      if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;

      return null;
    },
    routes: [
      // Splash (initial, no shell)
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      // Auth routes (no shell)
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      // Formula detail — full page over shell (like forgot password)
      GoRoute(
        path: '/formulas/:formulaId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) => FormulaDetailScreen(
          formulaId: state.pathParameters['formulaId']!,
        ),
      ),

      // Shell routes (with bottom nav)
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.customers,
            builder: (_, __) => const CustomersListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const CustomerFormScreen(),
              ),
              GoRoute(
                path: ':customerId',
                builder: (_, state) => CustomerProfileScreen(
                  customerId: state.pathParameters['customerId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (_, state) => CustomerFormScreen(
                      customerId: state.pathParameters['customerId'],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Mix tab = formula builder
          GoRoute(
            path: AppRoutes.mix,
            builder: (_, __) => const FormulaBuilderScreen(),
          ),
          // History tab = past formulas
          GoRoute(
            path: AppRoutes.formulaHistory,
            builder: (_, __) => const FormulasHistoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.brands,
            builder: (_, __) => const BrandsScreen(),
            routes: [
              GoRoute(
                path: 'lines/:brandId',
                builder: (_, state) => ProductLinesScreen(
                  brandId: state.pathParameters['brandId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'catalog/:lineId',
                    builder: (_, state) => ProductsScreen(
                      lineId: state.pathParameters['lineId']!,
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'detail/:productId',
                builder: (_, state) => ProductDetailScreen(
                  productId: state.pathParameters['productId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.inventory,
            builder: (_, __) => const InventoryScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route not found: ${state.matchedLocation}'),
      ),
    ),
  );
});
