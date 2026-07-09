import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _showAbout(BuildContext context, WidgetRef ref) async {
    final info = await PackageInfo.fromPlatform();
    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.science_rounded,
                  size: 26,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'dose',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Stylist workflows for accurate color mixing.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),
              Divider(
                height: 1,
                color: Theme.of(ctx).dividerColor.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                'Version ${info.version} (${info.buildNumber})',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.08),
                  ),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Sign Out?',
      message: 'You will need to sign in again to access your data.',
      confirmLabel: 'Sign Out',
      isDestructive: true,
    );
    if (confirmed && context.mounted) {
      await ref.read(authStateProvider.notifier).logout();
    }
  }

  String _formatRole(String? role) {
    final raw = (role ?? 'stylist').replaceAll('_', ' ');
    return raw
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  Future<void> _showThemePicker(BuildContext context, WidgetRef ref) async {
    final current = ref.read(themeModeProvider);
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        final isDark = Theme.of(ctx).brightness == Brightness.dark;

        Widget option({
          required ThemeMode mode,
          required String title,
          required String subtitle,
          required IconData icon,
          required Color iconBg,
          required Color iconColor,
        }) {
          final isSelected = current == mode;
          return InkWell(
            onTap: () => Navigator.pop(ctx, mode),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : cs.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppColors.primary : cs.outline,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: iconBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: isSelected
                        ? AppColors.primary
                        : cs.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: isDark ? 0.5 : 0.12),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.outline,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Choose theme',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 14),
                option(
                  mode: ThemeMode.system,
                  title: 'System',
                  subtitle: 'Match device appearance',
                  icon: Icons.phone_android_rounded,
                  iconBg: isDark
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : const Color(0xFFEFF6FF),
                  iconColor: AppColors.primary,
                ),
                const SizedBox(height: 8),
                option(
                  mode: ThemeMode.light,
                  title: 'Light',
                  subtitle: 'Bright and clean interface',
                  icon: Icons.light_mode_rounded,
                  iconBg: isDark
                      ? AppColors.warning.withValues(alpha: 0.15)
                      : const Color(0xFFFFF7ED),
                  iconColor: const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 8),
                option(
                  mode: ThemeMode.dark,
                  title: 'Dark',
                  subtitle: 'Low-light friendly interface',
                  icon: Icons.dark_mode_rounded,
                  iconBg: isDark
                      ? const Color(0xFF4338CA).withValues(alpha: 0.2)
                      : const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF6366F1),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null) {
      await ref.read(themeModeProvider.notifier).setMode(selected);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final themeMode = ref.watch(themeModeProvider);
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final name = (user?.fullName.trim().isNotEmpty ?? false)
        ? user!.fullName.trim()
        : 'Stylist';
    final email = user?.email ?? '';
    final initials =
        user?.initials ?? (name.isNotEmpty ? name[0].toUpperCase() : '?');
    final role = _formatRole(user?.role);

    return Scaffold(
      body: Column(
        children: [
          // Blue gradient header — works on both light and dark
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          right: -30,
                          top: -40,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: -20,
                          bottom: -10,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF1E40AF),
                                border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.35),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            if (email.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                email,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  color:
                                      Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white
                                      .withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: Colors.white
                                        .withValues(alpha: 0.95),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    role,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Preferences list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              children: [
                Text(
                  'SETTINGS',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: cs.outline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _SettingsRow(
                        icon: Icons.palette_outlined,
                        iconBg: isDark
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : const Color(0xFFEFF6FF),
                        iconColor: AppColors.primary,
                        title: 'Theme',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _themeLabel(themeMode),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 14,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: cs.onSurfaceVariant,
                              size: 22,
                            ),
                          ],
                        ),
                        onTap: () => _showThemePicker(context, ref),
                      ),
                      _SettingsRow(
                        icon: Icons.info_outline_rounded,
                        iconBg: isDark
                            ? cs.surfaceContainerHighest
                            : const Color(0xFFF1F5F9),
                        iconColor: cs.onSurfaceVariant,
                        title: 'About',
                        showDivider: false,
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: cs.onSurfaceVariant,
                          size: 22,
                        ),
                        onTap: () => _showAbout(context, ref),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Sign out
                SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: isDark
                        ? AppColors.destructive.withValues(alpha: 0.12)
                        : const Color(0xFFFDF2F2),
                    borderRadius: BorderRadius.circular(50),
                    child: InkWell(
                      onTap: () => _logout(context, ref),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: isDark
                                ? AppColors.destructive
                                    .withValues(alpha: 0.4)
                                : const Color(0xFFF5C6C6),
                            width: 1.2,
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              size: 18,
                              color: Color(0xFFDC2626),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Sign out',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Widget trailing;
  final VoidCallback onTap;
  final bool showDivider;

  const _SettingsRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.trailing,
    required this.onTap,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                trailing,
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 14,
            endIndent: 14,
            color: cs.outline.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
