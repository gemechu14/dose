import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/text_styles.dart';

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final Widget? suffix;
  final Widget? prefix;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final String? initialValue;

  const AppTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.suffix,
    this.prefix,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.label.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
          focusNode: focusNode,
          maxLines: obscureText ? 1 : maxLines,
          readOnly: readOnly,
          onTap: onTap,
          style: AppTextStyles.bodyMd.copyWith(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            prefixIcon: prefix,
          ),
        ),
      ],
    );
  }
}
