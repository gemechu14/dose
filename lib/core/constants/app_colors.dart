import 'package:flutter/material.dart';

abstract class AppColors {
  // Brand
  static const Color primary = Color(0xFF2563EB);
  static const Color secondary = Color(0xFF38BDF8);
  static const Color accent = Color(0xFF10B981);

  // Backgrounds
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Text
  static const Color foreground = Color(0xFF0F172A);
  static const Color muted = Color(0xFF64748B); // slate-500
  static const Color mutedLight = Color(0xFF94A3B8); // slate-400

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color destructive = Color(0xFFEF4444); // red-500
  static const Color info = Color(0xFF38BDF8);

  // Borders
  static const Color border = Color(0xFFE2E8F0); // slate-200
  static const Color borderFocus = Color(0xFF2563EB);

  // Dark mode equivalents
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceVariant = Color(0xFF334155);
  static const Color darkForeground = Color(0xFFF8FAFC);
  static const Color darkMuted = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF334155);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );
}
