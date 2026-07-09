import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../tenants/presentation/providers/tenant_provider.dart';

// Current authenticated user state
final authStateProvider =
    AsyncNotifierProvider<AuthNotifier, UserEntity?>(() => AuthNotifier());

class AuthNotifier extends AsyncNotifier<UserEntity?> {
  @override
  Future<UserEntity?> build() async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.getAccessToken();
    if (token == null) return null;

    final repo = ref.read(authRepositoryProvider);
    final result = await repo.getCurrentUser();
    return result.fold((_) => null, (user) => user);
  }

  Future<String?> login(String email, String password) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.login(email, password);
    return result.fold(
      (failure) {
        state = const AsyncData(null);
        return failure.message;
      },
      (user) {
        state = AsyncData(user);
        return null;
      },
    );
  }

  Future<String?> googleLogin(String code, String state_) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.googleLogin(code, state_);
    return result.fold(
      (failure) {
        state = const AsyncData(null);
        return failure.message;
      },
      (user) {
        state = AsyncData(user);
        return null;
      },
    );
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    final storage = ref.read(secureStorageProvider);
    await repo.logout();
    await storage.delete(key: 'tenant_id');
    ref.invalidate(currentTenantIdProvider);
    state = const AsyncData(null);
  }

  Future<String?> forgotPassword(String email) async {
    final repo = ref.read(authRepositoryProvider);
    final result = await repo.forgotPassword(email);
    return result.fold((f) => f.message, (_) => null);
  }
}

// Convenience: current user (non-nullable guard)
final currentUserProvider = Provider<UserEntity?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
