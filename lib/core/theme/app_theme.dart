import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

abstract class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        tertiary: AppColors.accent,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.foreground,
        onSurfaceVariant: AppColors.muted,
        error: AppColors.destructive,
        outline: AppColors.border,
        outlineVariant: AppColors.border,
        surfaceContainerHighest: AppColors.surfaceVariant,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.foreground,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: AppColors.border,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.foreground,
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.destructive),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle:
            const TextStyle(color: AppColors.mutedLight, fontFamily: 'Inter'),
        labelStyle:
            const TextStyle(color: AppColors.muted, fontFamily: 'Inter'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: AppColors.primary),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceVariant,
        selectedColor: AppColors.primary.withOpacity(0.15),
        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.muted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withValues(alpha: 0.12),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.muted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = const TextStyle(fontFamily: 'Inter', fontSize: 12);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w600);
          }
          return base.copyWith(color: AppColors.muted);
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontFamily: 'Inter', color: AppColors.foreground, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(
            fontFamily: 'Inter', color: AppColors.foreground, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(
            fontFamily: 'Inter', color: AppColors.foreground, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(
            fontFamily: 'Inter', color: AppColors.foreground, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(
            fontFamily: 'Inter', color: AppColors.foreground, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(
            fontFamily: 'Inter', color: AppColors.foreground, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            fontFamily: 'Inter', color: AppColors.foreground, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            fontFamily: 'Inter', color: AppColors.foreground, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(
            fontFamily: 'Inter', color: AppColors.foreground, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'Inter', color: AppColors.foreground),
        bodyMedium: TextStyle(fontFamily: 'Inter', color: AppColors.foreground),
        bodySmall: TextStyle(fontFamily: 'Inter', color: AppColors.muted),
        labelLarge: TextStyle(
            fontFamily: 'Inter', color: AppColors.foreground, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontFamily: 'Inter', color: AppColors.muted),
        labelSmall: TextStyle(fontFamily: 'Inter', color: AppColors.muted),
      ),
    );
  }

  static ThemeData get dark {
    const darkPrimary = Color(0xFF3B82F6); // blue-500, brighter for dark bg
    const darkSurface = AppColors.darkSurface;
    const darkBg = AppColors.darkBackground;
    const darkSurfaceVar = AppColors.darkSurfaceVariant;
    const darkFg = AppColors.darkForeground;
    const darkMuted = AppColors.darkMuted;
    const darkBorder = AppColors.darkBorder;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: darkPrimary,
        onPrimary: Color(0xFF1E3A5F),
        primaryContainer: Color(0xFF1E3A8A),
        onPrimaryContainer: Color(0xFFDEEBFF),
        secondary: AppColors.secondary,
        onSecondary: Color(0xFF0C2A47),
        secondaryContainer: Color(0xFF0C3954),
        onSecondaryContainer: Color(0xFFBAE6FD),
        tertiary: AppColors.accent,
        onTertiary: Color(0xFF052E16),
        tertiaryContainer: Color(0xFF052E16),
        onTertiaryContainer: Color(0xFFA7F3D0),
        error: Color(0xFFF87171),
        onError: Color(0xFF7F1D1D),
        errorContainer: Color(0xFF450A0A),
        onErrorContainer: Color(0xFFFECACA),
        surface: darkSurface,
        onSurface: darkFg,
        surfaceContainerHighest: darkSurfaceVar,
        onSurfaceVariant: darkMuted,
        outline: darkBorder,
        outlineVariant: Color(0xFF1E293B),
        shadow: Colors.black,
        scrim: Colors.black,
        inverseSurface: Color(0xFFF1F5F9),
        onInverseSurface: Color(0xFF1E293B),
        inversePrimary: AppColors.primary,
        surfaceTint: darkPrimary,
      ),
      scaffoldBackgroundColor: darkBg,
      fontFamily: 'Inter',
      appBarTheme: const AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkFg,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: darkBorder,
        titleTextStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkFg,
        ),
        iconTheme: IconThemeData(color: darkFg),
        actionsIconTheme: IconThemeData(color: darkFg),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarBrightness: Brightness.dark,
          statusBarIconBrightness: Brightness.light,
        ),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceVar,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFF87171)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: darkMuted, fontFamily: 'Inter'),
        labelStyle: const TextStyle(color: darkMuted, fontFamily: 'Inter'),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: const BorderSide(color: darkPrimary),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPrimary,
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurfaceVar,
        selectedColor: darkPrimary.withOpacity(0.2),
        labelStyle: const TextStyle(
            fontFamily: 'Inter', fontSize: 13, color: darkFg),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: darkBorder),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      dividerTheme: const DividerThemeData(
        color: darkBorder,
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: darkPrimary,
        unselectedItemColor: darkMuted,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: darkPrimary.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkPrimary);
          }
          return const IconThemeData(color: darkMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          const base = TextStyle(fontFamily: 'Inter', fontSize: 12);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(
                color: darkPrimary, fontWeight: FontWeight.w600);
          }
          return base.copyWith(color: darkMuted);
        }),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
      ),
      listTileTheme: const ListTileThemeData(
        textColor: darkFg,
        iconColor: darkMuted,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: darkPrimary,
        unselectedLabelColor: darkMuted,
        indicatorColor: darkPrimary,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: darkPrimary,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
            fontFamily: 'Inter', color: darkFg, fontWeight: FontWeight.w700),
        displayMedium: TextStyle(
            fontFamily: 'Inter', color: darkFg, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(
            fontFamily: 'Inter', color: darkFg, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(
            fontFamily: 'Inter', color: darkFg, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(
            fontFamily: 'Inter', color: darkFg, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(
            fontFamily: 'Inter', color: darkFg, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(
            fontFamily: 'Inter', color: darkFg, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            fontFamily: 'Inter', color: darkFg, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(
            fontFamily: 'Inter', color: darkFg, fontWeight: FontWeight.w500),
        bodyLarge:
            TextStyle(fontFamily: 'Inter', color: darkFg),
        bodyMedium:
            TextStyle(fontFamily: 'Inter', color: darkFg),
        bodySmall:
            TextStyle(fontFamily: 'Inter', color: darkMuted),
        labelLarge: TextStyle(
            fontFamily: 'Inter', color: darkFg, fontWeight: FontWeight.w500),
        labelMedium:
            TextStyle(fontFamily: 'Inter', color: darkMuted),
        labelSmall:
            TextStyle(fontFamily: 'Inter', color: darkMuted),
      ),
    );
  }
}
