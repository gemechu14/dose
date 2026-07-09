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
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => _PromptDialogContent(
      title: title,
      hint: hint,
      initialValue: initialValue,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
    ),
  );
}

class _PromptDialogContent extends StatefulWidget {
  final String title;
  final String? hint;
  final String initialValue;
  final String confirmLabel;
  final String cancelLabel;

  const _PromptDialogContent({
    required this.title,
    required this.hint,
    required this.initialValue,
    required this.confirmLabel,
    required this.cancelLabel,
  });

  @override
  State<_PromptDialogContent> createState() => _PromptDialogContentState();
}

class _PromptDialogContentState extends State<_PromptDialogContent> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AppDialogShell(
      title: widget.title,
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: widget.hint,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        onSubmitted: (v) {
          final value = v.trim();
          if (value.isNotEmpty) Navigator.pop(context, value);
        },
      ),
      actions: [
        Expanded(
          child: AppButton(
            label: widget.cancelLabel,
            onPressed: () => Navigator.pop(context),
            variant: AppButtonVariant.outline,
            height: 48,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AppButton(
            label: widget.confirmLabel,
            onPressed: () {
              final value = _controller.text.trim();
              if (value.isEmpty) return;
              Navigator.pop(context, value);
            },
            variant: AppButtonVariant.filled,
            height: 48,
          ),
        ),
      ],
    );
  }
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
    final cs = Theme.of(context).colorScheme;
    return Dialog(
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
                color: cs.onSurface,
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: cs.onSurfaceVariant,
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
