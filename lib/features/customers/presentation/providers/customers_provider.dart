import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/customer_model.dart';
import '../../data/repositories/customers_repository_impl.dart';

// Search query state
final customerSearchQueryProvider = StateProvider<String>((ref) => '');

// Paginated customers list
final customersProvider =
    AsyncNotifierProvider<CustomersNotifier, List<CustomerModel>>(
        CustomersNotifier.new);

class CustomersNotifier extends AsyncNotifier<List<CustomerModel>> {
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  Future<List<CustomerModel>> build() async {
    _page = 1;
    _hasMore = true;
    return _fetch(reset: true);
  }

  Future<List<CustomerModel>> _fetch({bool reset = false}) async {
    final search = ref.read(customerSearchQueryProvider);
    final repo = ref.read(customersRepositoryProvider);
    final result = await repo.getCustomers(
      page: reset ? 1 : _page,
      search: search.isEmpty ? null : search,
    );

    return result.fold(
      (failure) => throw Exception(failure.message),
      (paginated) {
        _hasMore = paginated.next != null;
        if (reset) {
          _page = 2;
          return paginated.results;
        } else {
          _page++;
          return [...(state.valueOrNull ?? []), ...paginated.results];
        }
      },
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(reset: true));
  }

  Future<void> search(String query) async {
    ref.read(customerSearchQueryProvider.notifier).state = query;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetch(reset: true));
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    final next = await AsyncValue.guard(() => _fetch());
    _isLoadingMore = false;
    state = next;
  }

  bool get hasMore => _hasMore;

  Future<String?> createCustomer(CustomerCreateRequest request) async {
    final repo = ref.read(customersRepositoryProvider);
    final result = await repo.createCustomer(request);
    return result.fold(
      (f) => f.message,
      (customer) {
        final current = state.valueOrNull ?? [];
        state = AsyncData([customer, ...current]);
        return null;
      },
    );
  }

  Future<String?> updateCustomer(
      String id, Map<String, dynamic> fields) async {
    final repo = ref.read(customersRepositoryProvider);
    final result = await repo.updateCustomer(id, fields);
    return result.fold(
      (f) => f.message,
      (updated) {
        final current = state.valueOrNull ?? [];
        state = AsyncData(
          current.map((c) => c.id == id ? updated : c).toList(),
        );
        return null;
      },
    );
  }

  Future<String?> deleteCustomer(String id) async {
    final repo = ref.read(customersRepositoryProvider);
    final result = await repo.deleteCustomer(id);
    return result.fold(
      (f) => f.message,
      (_) {
        final current = state.valueOrNull ?? [];
        state = AsyncData(current.where((c) => c.id != id).toList());
        return null;
      },
    );
  }
}

// Single customer detail
final customerDetailProvider =
    FutureProvider.family<CustomerModel, String>((ref, id) async {
  final repo = ref.read(customersRepositoryProvider);
  final result = await repo.getCustomer(id);
  return result.fold(
    (f) => throw Exception(f.message),
    (customer) => customer,
  );
});
