import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

abstract class AppTextStyles {
  static const TextStyle displayLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.foreground,
    height: 1.2,
  );

  static const TextStyle displaySm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.foreground,
    height: 1.3,
  );

  static const TextStyle headingLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
    height: 1.4,
  );

  static const TextStyle headingMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
    height: 1.4,
  );

  static const TextStyle headingSm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
    height: 1.5,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.foreground,
    height: 1.5,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.foreground,
    height: 1.5,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.foreground,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.muted,
    height: 1.4,
  );

  static const TextStyle label = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.muted,
    height: 1.4,
  );

  static const TextStyle labelBold = TextStyle(
    fontFamily: 'Inter',
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.foreground,
    height: 1.4,
  );

  static const TextStyle button = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: 'monospace',
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.foreground,
  );
}
