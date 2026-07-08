import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final error = await ref.read(authStateProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (mounted && error != null) {
        setState(() => _errorMessage = error);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Login failed unexpectedly. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _googleLogin() async {
    // TODO: Implement Google OAuth flow with flutter_web_auth_2
    // 1. Open Google consent URL
    // 2. Capture redirect callback with code + state
    // 3. Call authNotifier.googleLogin(code, state)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google login coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // Logo + branding
                _buildHeader(),

                const SizedBox(height: 48),

                // Email
                AppTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  hint: 'you@salon.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                AppTextField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  hint: '••••••••',
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _login(),
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password too short';
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: Text(
                      AppStrings.forgotPassword,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: AppColors.primary),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Error message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.destructive.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.destructive.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.destructive, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: AppTextStyles.bodySm
                                .copyWith(color: AppColors.destructive),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                ],

                // Login button
                AppButton(
                  label: AppStrings.login,
                  onPressed: _loading ? null : _login,
                  isLoading: _loading,
                  height: 48,
                ),

                const SizedBox(height: 5),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.muted)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),

                const SizedBox(height: 5),

                // Google login
                AppButton(
                  label: AppStrings.continueWithGoogle,
                  onPressed: _googleLogin,
                  backgroundColor: AppColors.success,
                  icon: const _GoogleIcon(),
                  height: 48,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/dose_logo.png',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              AppStrings.appName,
              style: AppTextStyles.displaySm
                  .copyWith(color: AppColors.foreground),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.loginSubtitle,
          style: AppTextStyles.bodyLg.copyWith(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    );
  }
}
