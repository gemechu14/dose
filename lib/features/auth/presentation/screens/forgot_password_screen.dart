import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _sent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final error = await ref
        .read(authStateProvider.notifier)
        .forgotPassword(_emailController.text.trim());

    if (mounted) {
      setState(() {
        _loading = false;
        if (error == null) _sent = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveAuthPage(
          child: _sent ? _buildSuccess(context) : _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Enter your email and we\'ll send you a reset link.',
            style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 32),
          AppTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'you@salon.com',
            keyboardType: TextInputType.emailAddress,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 24),
          AppButton(
            label: 'Send Reset Link',
            onPressed: _loading ? null : _submit,
            isLoading: _loading,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mark_email_read_outlined,
            size: 72, color: AppColors.accent),
        const SizedBox(height: 24),
        Text('Check your inbox', style: AppTextStyles.headingLg.copyWith(color: cs.onSurface)),
        const SizedBox(height: 12),
        Text(
          'We\'ve sent a password reset link to ${_emailController.text}',
          style: AppTextStyles.bodyMd.copyWith(color: cs.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        AppButton(
          label: 'Back to Login',
          onPressed: () => context.pop(),
          variant: AppButtonVariant.outline,
        ),
      ],
    );
  }
}
