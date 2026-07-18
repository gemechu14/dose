import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/responsive.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    if (Responsive.useSideNavigation(context)) {
      return Scaffold(
        body: Row(
          children: [
            const _SideNav(),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: const _BottomNav(),
    );
  }
}

String _activeRoute(String location) {
  if (location.startsWith('/customers')) return AppRoutes.customers;
  if (location.startsWith('/mix')) return AppRoutes.mix;
  if (location.startsWith('/formulas')) return AppRoutes.formulaHistory;
  if (location.startsWith('/profile')) return AppRoutes.profile;
  return AppRoutes.home;
}

class _SideNav extends StatelessWidget {
  const _SideNav();

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final active = _activeRoute(location);
    final extended = Responsive.isLarge(context);
    final cs = Theme.of(context).colorScheme;

    int selectedIndex(String route) {
      switch (route) {
        case AppRoutes.customers:
          return 1;
        case AppRoutes.mix:
          return 2;
        case AppRoutes.formulaHistory:
          return 3;
        case AppRoutes.profile:
          return 4;
        default:
          return 0;
      }
    }

    void onDestinationSelected(int index) {
      switch (index) {
        case 0:
          context.go(AppRoutes.home);
        case 1:
          context.go(AppRoutes.customers);
        case 2:
          context.go(AppRoutes.mix);
        case 3:
          context.go(AppRoutes.formulaHistory);
        case 4:
          context.go(AppRoutes.profile);
      }
    }

    return NavigationRail(
      extended: extended,
      minExtendedWidth: 180,
      selectedIndex: selectedIndex(active),
      onDestinationSelected: onDestinationSelected,
      labelType: extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
      backgroundColor: cs.surface,
      indicatorColor: AppColors.primary.withValues(alpha: 0.12),
      selectedIconTheme: IconThemeData(color: cs.primary),
      unselectedIconTheme: IconThemeData(color: cs.onSurfaceVariant),
      selectedLabelTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: cs.primary,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: cs.onSurfaceVariant,
      ),
      leading: Padding(
        padding: EdgeInsets.only(
          top: extended ? 16 : 12,
          bottom: extended ? 8 : 4,
        ),
        child: extended
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.palette_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'dose',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              )
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.palette_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Home'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: Text('Clients'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.science_outlined),
          selectedIcon: Icon(Icons.science_rounded),
          label: Text('Mix'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.history_rounded),
          selectedIcon: Icon(Icons.history_rounded),
          label: Text('History'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: Text('Profile'),
        ),
      ],
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final location = GoRouterState.of(context).matchedLocation;
    final cs = Theme.of(context).colorScheme;
    final isSmall = mq.size.width < 360 ||
        mq.textScaler.scale(1.0) > 1.12 ||
        mq.size.height < 720;

    final navHeight = isSmall ? 64.0 : 72.0;
    final sideIconSize = isSmall ? 20.0 : 22.0;
    final sideLabelSize = isSmall ? 9.0 : 10.0;

    final centerDiameter = isSmall ? 48.0 : 54.0;
    final centerIconSize = isSmall ? 22.0 : 26.0;

    final active = _activeRoute(location);
    final isMixActive = active == AppRoutes.mix;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: Theme.of(context).brightness == Brightness.dark ? 0.35 : 0.06,
            ),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: navHeight,
          child: Row(
            children: [
              _NavItem(
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                route: AppRoutes.home,
                isActive: active == AppRoutes.home,
                iconSize: sideIconSize,
                labelFontSize: sideLabelSize,
              ),
              _NavItem(
                label: 'Clients',
                icon: Icons.people_outline_rounded,
                activeIcon: Icons.people_rounded,
                route: AppRoutes.customers,
                isActive: active == AppRoutes.customers,
                iconSize: sideIconSize,
                labelFontSize: sideLabelSize,
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => context.go(AppRoutes.mix),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: centerDiameter,
                        height: centerDiameter,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isMixActive
                                ? [
                                    const Color(0xFF1D4ED8),
                                    const Color(0xFF1E40AF),
                                  ]
                                : [
                                    const Color(0xFF2563EB),
                                    const Color(0xFF1D4ED8),
                                  ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: isMixActive ? 16 : 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.science_rounded,
                          color: Colors.white,
                          size: centerIconSize,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Mix',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: sideLabelSize,
                          fontWeight:
                              isMixActive ? FontWeight.w600 : FontWeight.w400,
                          color: isMixActive ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _NavItem(
                label: 'History',
                icon: Icons.history_rounded,
                activeIcon: Icons.history_rounded,
                route: AppRoutes.formulaHistory,
                isActive: active == AppRoutes.formulaHistory,
                iconSize: sideIconSize,
                labelFontSize: sideLabelSize,
              ),
              _NavItem(
                label: 'Profile',
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                route: AppRoutes.profile,
                isActive: active == AppRoutes.profile,
                iconSize: sideIconSize,
                labelFontSize: sideLabelSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  final bool isActive;
  final double iconSize;
  final double labelFontSize;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
    required this.isActive,
    required this.iconSize,
    required this.labelFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isActive ? cs.primary : cs.onSurfaceVariant;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isActive) context.go(route);
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: isActive
                  ? BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    )
                  : null,
              child: Icon(
                isActive ? activeIcon : icon,
                color: color,
                size: iconSize,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: labelFontSize,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
