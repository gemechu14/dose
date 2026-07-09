import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final firstName = (user?.firstName.trim().isNotEmpty == true)
        ? user!.firstName
        : 'Sam';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _Header(firstName: firstName),
                  const SizedBox(height: 18),
                  const _TodayCard(),
                  const SizedBox(height: 14),
                  const _QuickActions(),
                  const SizedBox(height: 22),
                  const _ThisMonth(),
                  const SizedBox(height: 22),
                  // const _MostUsedShades(),
                  // const SizedBox(height: 22),
                  const _LowStockSection(),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String firstName;
  const _Header({required this.firstName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              'Hi, $firstName',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
                height: 1.15,
                letterSpacing: -0.4,
              ),
            ),
          ),
          // Stack(
          //   clipBehavior: Clip.none,
          //   children: [
          //     IconButton(
          //       icon: const Icon(Icons.notifications_none_rounded, size: 26),
          //       onPressed: () {},
          //       color: const Color(0xFF0F172A),
          //     ),
          //     Positioned(
          //       top: 12,
          //       right: 12,
          //       child: Container(
          //         width: 8,
          //         height: 8,
          //         decoration: BoxDecoration(
          //           color: const Color(0xFFEF4444),
          //           shape: BoxShape.circle,
          //           border: Border.all(color: Colors.white, width: 1.5),
          //         ),
          //       ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}

// ─── Today Card ──────────────────────────────────────────────────────────────

class _TodayCard extends StatelessWidget {
  const _TodayCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2563EB), Color(0xFF3B82F6), Color(0xFF60A5FA)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2563EB).withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'TODAY',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.75),
                    letterSpacing: 1.3,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Let\'s create formula.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.15,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a new formula to start your next mix.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.88),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => context.go(AppRoutes.mix),
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.science_rounded,
                        color: Color(0xFF2563EB),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'New formula',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quick Actions ────────────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _QuickCard(
              icon: Icons.search_rounded,
              iconBgColor: const Color(0xFFEFF6FF),
              iconColor: const Color(0xFF2563EB),
              label: 'Find client',
              onTap: () => context.go(AppRoutes.customers),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickCard(
              icon: Icons.history_rounded,
              iconBgColor: const Color(0xFFECFDF5),
              iconColor: const Color(0xFF10B981),
              label: 'History',
              onTap: () => context.go(AppRoutes.formulaHistory),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.iconBgColor,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE8EEF5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 19),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── This Week ────────────────────────────────────────────────────────────────

class _ThisMonth extends StatelessWidget {
  const _ThisMonth();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THIS MONTH',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              Expanded(child: _StatCard(label: 'SERVICES', value: '5')),
              SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'AVG COST', value: '\$26.96')),
              SizedBox(width: 10),
              Expanded(child: _StatCard(label: 'CLIENTS', value: '5')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Most-Used Shades (temporarily hidden) ───────────────────────────────────
/*
class _MostUsedShades extends StatelessWidget {
  const _MostUsedShades();

  static const _shades = [
    _ShadeItem(code: '9.1', name: 'Very Light Ash', hex: 'D4C4A8'),
    _ShadeItem(code: '8.3', name: 'Golden Blonde', hex: 'C68642'),
    _ShadeItem(code: '4.0', name: 'Medium Brown', hex: '5C3317'),
    _ShadeItem(code: '7.1', name: 'Ash Blonde', hex: 'B8A898'),
    _ShadeItem(code: '6.0', name: 'Dark Blonde', hex: '8B6914'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(Icons.show_chart_rounded, size: 16, color: Color(0xFF94A3B8)),
              SizedBox(width: 6),
              Text(
                'MOST-USED SHADES',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.25,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _shades.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) => _ShadeChip(shade: _shades[i]),
          ),
        ),
      ],
    );
  }
}

class _ShadeItem {
  final String code;
  final String name;
  final String hex;
  const _ShadeItem({
    required this.code,
    required this.name,
    required this.hex,
  });
}

class _ShadeChip extends StatelessWidget {
  final _ShadeItem shade;
  const _ShadeChip({required this.shade});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF${shade.hex}', radix: 16));

    return Container(
      width: 168,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  shade.code,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  shade.name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
*/

// ─── Low Stock ────────────────────────────────────────────────────────────────

class _LowStockSection extends StatelessWidget {
  const _LowStockSection();

  static const _items = [
    _LowStockItem(
      code: '7.1',
      name: 'Ash Blonde',
      hex: 'B8A898',
      onHand: 90,
      reorderAt: 150,
    ),
    _LowStockItem(
      code: '9.1',
      name: 'Very Light Ash',
      hex: 'D4C4A8',
      onHand: 45,
      reorderAt: 120,
    ),
    _LowStockItem(
      code: '10.21',
      name: 'Platinum Pearl',
      hex: 'E8E4D9',
      onHand: 30,
      reorderAt: 100,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  size: 16, color: Color(0xFFF59E0B)),
              SizedBox(width: 6),
              Text(
                'LOW STOCK',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                  letterSpacing: 1.25,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LowStockCard(item: item),
            ),
          ),
        ],
      ),
    );
  }
}

class _LowStockItem {
  final String code;
  final String name;
  final String hex;
  final int onHand;
  final int reorderAt;

  const _LowStockItem({
    required this.code,
    required this.name,
    required this.hex,
    required this.onHand,
    required this.reorderAt,
  });
}

class _LowStockCard extends StatelessWidget {
  final _LowStockItem item;
  const _LowStockCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse('FF${item.hex}', radix: 16));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.code} · ${item.name}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${item.onHand}g on hand · reorder at ${item.reorderAt}g',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF59E0B)),
            ),
            child: const Text(
              'Low',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
