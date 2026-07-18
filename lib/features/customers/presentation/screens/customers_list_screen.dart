import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../providers/customers_provider.dart';
import '../widgets/customer_list_tile.dart';

class CustomersListScreen extends ConsumerStatefulWidget {
  const CustomersListScreen({super.key});

  @override
  ConsumerState<CustomersListScreen> createState() =>
      _CustomersListScreenState();
}

class _CustomersListScreenState extends ConsumerState<CustomersListScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(customersProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/customers/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: ResponsiveConstraint(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                'Clients',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: -0.4,
                  height: 1.15,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (q) {
                  setState(() {});
                  ref.read(customersProvider.notifier).search(q);
                },
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search by name or phone',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: cs.onSurfaceVariant,
                    size: 22,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            ref
                                .read(customersProvider.notifier)
                                .search('');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            Expanded(
              child: customersAsync.when(
                loading: () => const SkeletonList(useCustomerTile: true),
                error: (err, _) => ErrorState(
                  message:
                      err.toString().replaceFirst('Exception: ', ''),
                  onRetry: () =>
                      ref.read(customersProvider.notifier).refresh(),
                ),
                data: (customers) {
                  final onRefresh = () =>
                      ref.read(customersProvider.notifier).refresh();

                  if (customers.isEmpty) {
                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: onRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.fromLTRB(16, 24, 16, 88),
                        children: const [
                          EmptyState(
                            icon: Icons.people_outline_rounded,
                            title: 'No clients yet',
                            subtitle:
                                'Add your first client to get started',
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: onRefresh,
                    child: ListView.separated(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      itemCount: customers.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 10),
                      itemBuilder: (_, i) => CustomerListTile(
                        customer: customers[i],
                        onTap: () => context
                            .push('/customers/${customers[i].id}'),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
