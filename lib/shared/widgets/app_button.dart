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
        return _buildFilled(context, disabled);
      case AppButtonVariant.outline:
        return _buildOutline(context, disabled);
      case AppButtonVariant.ghost:
        return _buildGhost(context, disabled);
      case AppButtonVariant.destructive:
        return _buildDestructive(context, disabled);
    }
  }

  Widget _buildFilled(BuildContext context, bool disabled) {
    final cs = Theme.of(context).colorScheme;
    final useSolid = backgroundColor != null;
    // While loading keep the primary gradient at reduced opacity (not grey)
    final isLoadingState = isLoading && onPressed == null;
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Opacity(
        opacity: isLoadingState ? 0.75 : 1.0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: (disabled && !isLoadingState) || useSolid
                ? null
                : AppColors.primaryGradient,
            color: (disabled && !isLoadingState)
                ? cs.onSurfaceVariant.withValues(alpha: 0.3)
                : (useSolid ? backgroundColor : null),
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: disabled || !useSolid
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
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
      ),
    );
  }

  Widget _buildOutline(BuildContext context, bool disabled) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(
            color: disabled
                ? cs.onSurfaceVariant.withValues(alpha: 0.3)
                : cs.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          minimumSize: Size(width ?? double.infinity, height),
        ),
        child: _buildContent(cs.primary),
      ),
    );
  }

  Widget _buildGhost(BuildContext context, bool disabled) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: cs.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          minimumSize: Size(width ?? double.infinity, height),
        ),
        child: _buildContent(cs.primary),
      ),
    );
  }

  Widget _buildDestructive(BuildContext context, bool disabled) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              disabled ? AppColors.destructive.withValues(alpha: 0.4) : AppColors.destructive,
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
