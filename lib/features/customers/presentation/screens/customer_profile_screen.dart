import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../data/models/customer_model.dart';
import '../providers/customers_provider.dart';
import '../../../formulas/presentation/providers/formulas_provider.dart';

class CustomerProfileScreen extends ConsumerWidget {
  final String customerId;

  const CustomerProfileScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          color: AppColors.foreground,
          onPressed: () => context.pop(),
        ),
      ),
      body: customerAsync.when(
        loading: () => const _ProfileSkeleton(),
        error: (err, _) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
          ),
          body: Center(
            child: Text(err.toString(),
                style:
                    AppTextStyles.bodyMd.copyWith(color: AppColors.muted)),
          ),
        ),
        data: (customer) => _ProfileBody(customer: customer),
      ),
    );
  }
}

class _ProfileBody extends ConsumerWidget {
  final CustomerModel customer;

  const _ProfileBody({required this.customer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formulasAsync =
        ref.watch(customerFormulasProvider(customer.id));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + Email full-width card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          customer.fullName,
                          style: AppTextStyles.headingSm.copyWith(
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.mail_outline_rounded,
                        size: 20,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          customer.email ?? '—',
                          style: AppTextStyles.headingSm.copyWith(
                            color: AppColors.foreground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quick info cards (Formulas + Phone)
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.science_outlined,
                            size: 20, color: AppColors.primary),
                        const SizedBox(height: 6),
                        formulasAsync.when(
                          loading: () => Text(
                            '—',
                            style: AppTextStyles.headingMd.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          error: (err, _) => Text(
                            '${customer.formulaCount ?? 0}',
                            style: AppTextStyles.headingMd.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          data: (formulas) => Text(
                            '${formulas.length}',
                            style: AppTextStyles.headingMd.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        Text('Formulas', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 20, color: AppColors.accent),
                        const SizedBox(height: 6),
                        Text(
                          customer.phone ?? '—',
                          style: AppTextStyles.headingSm.copyWith(
                            color: AppColors.foreground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text('Phone', style: AppTextStyles.caption),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Notes
            if (customer.notes != null && customer.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Notes', style: AppTextStyles.headingSm),
                    const SizedBox(height: 8),
                    Text(
                      customer.notes!,
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // New formula CTA
            AppButton(
              label: 'New Formula for ${customer.firstName}',
              icon: const Icon(Icons.add_rounded,
                  color: Colors.white, size: 18),
              onPressed: () {
                ref
                    .read(formulaBuilderProvider.notifier)
                    .setCustomer(customer.id);
                context.go('/mix');
              },
            ),

            const SizedBox(height: 24),

            // Color history timeline
            Text(AppStrings.colorHistory,
                style: AppTextStyles.headingSm),
            const SizedBox(height: 12),

            formulasAsync.when(
              loading: () => const SkeletonList(count: 3),
              error: (err, _) => Text(
                err.toString(),
                style:
                    AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
              ),
              data: (formulas) {
                if (formulas.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No formulas yet',
                      style: AppTextStyles.bodyMd.copyWith(
                        color: AppColors.muted,
                      ),
                    ),
                  );
                }
                return Column(
                  children: formulas
                      .map(
                        (f) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _FormulaHistoryTile(
                            formula: f,
                            onTap: () => context.push('/formulas/${f.id}'),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}

class _FormulaHistoryTile extends StatelessWidget {
  final dynamic formula;
  final VoidCallback? onTap;

  const _FormulaHistoryTile({required this.formula, this.onTap});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.science_outlined,
                color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formula.serviceType ?? 'Color Service',
                  style: AppTextStyles.labelBold,
                ),
                if (formula.createdAt != null)
                  Text(
                    formula.createdAt.toString().substring(0, 10),
                    style: AppTextStyles.caption,
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.muted, size: 18),
        ],
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          SkeletonBox(width: double.infinity, height: 200, borderRadius: 0),
          Expanded(child: SkeletonList(count: 4)),
        ],
      ),
    );
  }
}
