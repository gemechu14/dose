import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/text_styles.dart';
import 'app_button.dart';

Future<bool> showConfirmDialog(
  BuildContext context, {
  String title = AppStrings.deleteConfirmTitle,
  String message = AppStrings.deleteConfirmMessage,
  String confirmLabel = AppStrings.delete,
  bool isDestructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _ConfirmDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      isDestructive: isDestructive,
    ),
  );
  return result ?? false;
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDestructive;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.isDestructive,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(title, style: AppTextStyles.headingSm),
      content: Text(
        message,
        style: AppTextStyles.bodyMd.copyWith(color: AppColors.muted),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: AppButton(
                  label: AppStrings.cancel,
                  onPressed: () => Navigator.pop(context, false),
                  variant: AppButtonVariant.outline,
                  height: 44,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: confirmLabel,
                  onPressed: () => Navigator.pop(context, true),
                  variant: isDestructive
                      ? AppButtonVariant.destructive
                      : AppButtonVariant.filled,
                  height: 44,
                ),
              ),
            ],
          ),
        ),
      ],
      actionsPadding: EdgeInsets.zero,
    );
  }
}
