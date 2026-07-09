import 'package:flutter/material.dart';

/// Semantic colors that preserve light-mode values while adapting in dark mode.
extension AppColorScheme on ColorScheme {
  Color get muted => onSurfaceVariant;

  Color get surfaceVariant => surfaceContainerHighest;
}

extension AppThemeContext on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Input / chip inactive fill — matches light `#F4F6F9` in light mode.
  Color get subtleFill =>
      isDark ? cs.surfaceContainerHighest : const Color(0xFFF4F6F9);

  /// Nested card / list row background — matches light `#F8FAFC` in light mode.
  Color get subtleCard =>
      isDark ? cs.surfaceContainerHighest : const Color(0xFFF8FAFC);

  /// Sheet / dropdown surface — white in light, themed surface in dark.
  Color get sheetSurface => isDark ? cs.surface : Colors.white;

  /// Icon tint backgrounds (e.g. quick-action circles on home).
  Color tintedIconBg(Color accent, {double lightAlpha = 0.08}) =>
      accent.withValues(alpha: isDark ? 0.18 : lightAlpha);
}
