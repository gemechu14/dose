import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/text_styles.dart';
import 'app_button.dart';

/// Standard confirmation dialog used across the app.
Future<bool> showConfirmDialog(
  BuildContext context, {
  String title = AppStrings.deleteConfirmTitle,
  String message = AppStrings.deleteConfirmMessage,
  String confirmLabel = AppStrings.delete,
  String cancelLabel = AppStrings.cancel,
  bool isDestructive = true,
  IconData? icon,
  Color? iconColor,
  Color? iconBackgroundColor,
  bool barrierDismissible = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => _AppDialogShell(
      title: title,
      message: message,
      icon: icon ??
          (isDestructive
              ? Icons.warning_amber_rounded
              : Icons.help_outline_rounded),
      iconColor: iconColor ??
          (isDestructive ? AppColors.destructive : AppColors.primary),
      iconBackgroundColor: iconBackgroundColor ??
          (isDestructive
              ? AppColors.destructive.withValues(alpha: 0.1)
              : AppColors.primary.withValues(alpha: 0.1)),
      actions: [
        Expanded(
          child: AppButton(
            label: cancelLabel,
            onPressed: () => Navigator.pop(dialogContext, false),
            variant: AppButtonVariant.outline,
            height: 48,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: confirmLabel,
            onPressed: () => Navigator.pop(dialogContext, true),
            variant: isDestructive
                ? AppButtonVariant.destructive
                : AppButtonVariant.filled,
            height: 48,
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Dialog with custom body content (e.g. finalize summary).
Future<bool> showAppDialog(
  BuildContext context, {
  required String title,
  String? message,
  required Widget content,
  String confirmLabel = 'Confirm',
  String cancelLabel = AppStrings.cancel,
  bool isDestructive = false,
  IconData? icon,
  Color? iconColor,
  Color? iconBackgroundColor,
  bool barrierDismissible = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) => _AppDialogShell(
      title: title,
      message: message,
      icon: icon ?? Icons.info_outline_rounded,
      iconColor: iconColor ?? AppColors.primary,
      iconBackgroundColor:
          iconBackgroundColor ?? AppColors.primary.withValues(alpha: 0.1),
      content: content,
      actions: [
        Expanded(
          child: AppButton(
            label: cancelLabel,
            onPressed: () => Navigator.pop(dialogContext, false),
            variant: AppButtonVariant.outline,
            height: 48,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: confirmLabel,
            onPressed: () => Navigator.pop(dialogContext, true),
            variant: isDestructive
                ? AppButtonVariant.destructive
                : AppButtonVariant.filled,
            height: 48,
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Simple text-input dialog (e.g. bowl label).
Future<String?> showPromptDialog(
  BuildContext context, {
  required String title,
  String? hint,
  String initialValue = '',
  String confirmLabel = 'Save',
  String cancelLabel = AppStrings.cancel,
}) async {
  final controller = TextEditingController(text: initialValue);

  final result = await showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _AppDialogShell(
      title: title,
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: AppColors.surfaceVariant,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        onSubmitted: (v) {
          if (v.trim().isNotEmpty) Navigator.pop(dialogContext, v.trim());
        },
      ),
      actions: [
        Expanded(
          child: AppButton(
            label: cancelLabel,
            onPressed: () => Navigator.pop(dialogContext),
            variant: AppButtonVariant.outline,
            height: 48,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: confirmLabel,
            onPressed: () {
              final value = controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(dialogContext, value);
            },
            variant: AppButtonVariant.filled,
            height: 48,
          ),
        ),
      ],
    ),
  );

  controller.dispose();
  return result;
}

class _AppDialogShell extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBackgroundColor;
  final Widget? content;
  final List<Widget> actions;

  const _AppDialogShell({
    required this.title,
    this.message,
    this.icon,
    this.iconColor,
    this.iconBackgroundColor,
    this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.headingSm.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.muted,
                  height: 1.45,
                ),
              ),
            ],
            if (content != null) ...[
              const SizedBox(height: 16),
              content!,
            ],
            const SizedBox(height: 24),
            Row(children: actions),
          ],
        ),
      ),
    );
  }
}
