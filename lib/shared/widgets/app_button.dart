import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';

enum AppButtonVariant { filled, outline, ghost, destructive }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final Widget? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.filled,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius = 12,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    switch (variant) {
      case AppButtonVariant.filled:
        return _buildFilled(disabled);
      case AppButtonVariant.outline:
        return _buildOutline(disabled);
      case AppButtonVariant.ghost:
        return _buildGhost(disabled);
      case AppButtonVariant.destructive:
        return _buildDestructive(disabled);
    }
  }

  Widget _buildFilled(bool disabled) {
    final useSolid = backgroundColor != null;
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled || useSolid ? null : AppColors.primaryGradient,
          color: disabled
              ? AppColors.muted.withOpacity(0.3)
              : (useSolid ? backgroundColor : null),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: disabled || !useSolid
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            minimumSize: Size(width ?? double.infinity, height),
          ),
          child: _buildContent(Colors.white),
        ),
      ),
    );
  }

  Widget _buildOutline(bool disabled) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: BorderSide(
            color: disabled
                ? AppColors.muted.withOpacity(0.3)
                : AppColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          minimumSize: Size(width ?? double.infinity, height),
        ),
        child: _buildContent(AppColors.primary),
      ),
    );
  }

  Widget _buildGhost(bool disabled) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          minimumSize: Size(width ?? double.infinity, height),
        ),
        child: _buildContent(AppColors.primary),
      ),
    );
  }

  Widget _buildDestructive(bool disabled) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              disabled ? AppColors.destructive.withOpacity(0.4) : AppColors.destructive,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          minimumSize: Size(width ?? double.infinity, height),
          elevation: 0,
        ),
        child: _buildContent(Colors.white),
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          color: textColor,
          strokeWidth: 2.5,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 10),
          Text(label,
              style: AppTextStyles.button.copyWith(color: textColor)),
        ],
      );
    }

    return Text(label, style: AppTextStyles.button.copyWith(color: textColor));
  }
}
