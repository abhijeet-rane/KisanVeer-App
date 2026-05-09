import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_constants.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/screens/auth/forgot_password_screen.dart';
import 'package:kisan_veer/screens/auth/register_screen.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/utils/validators.dart';
import 'package:kisan_veer/widgets/biometric_login_button.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 login screen.
///
/// Brand-gradient hero on top, card-lifted form below. Each interactive
/// element uses the v2 design system (AppTextField, AppButton,
/// AppPageRoute) so the whole auth flow feels coherent.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading) return;
    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGoogleLoading = false;
        _errorMessage = e.toString().contains('sign_in_canceled')
            ? null
            : e.toString();
      });
    }
  }

  Future<void> _handleBiometricSuccess() async {
    final ok = await _authService.restoreSessionForBiometric();
    if (!mounted) return;
    if (ok) {
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      setState(() {
        _errorMessage =
            'Please login with password once to refresh your session. '
            'Biometric will work again afterward.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: AppSpacing.space16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.space16),
              const _BrandHero(),
              const SizedBox(height: AppSpacing.space32),
              _HeadingBlock()
                  .animate()
                  .fadeIn(duration: AppMotion.slow, delay: AppMotion.fast)
                  .moveY(
                    begin: 8,
                    end: 0,
                    duration: AppMotion.slow,
                    curve: AppMotion.emphasizedDecelerate,
                  ),
              const SizedBox(height: AppSpacing.space32),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _emailController,
                      label: 'Email',
                      hint: 'you@example.com',
                      prefixIcon: Icons.mail_outline_rounded,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validators.validateEmail,
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 300),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: 'Your password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      suffix: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Password is required'
                          : null,
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 400),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppButton(
                        label: 'Forgot password?',
                        variant: AppButtonVariant.ghost,
                        size: AppButtonSize.sm,
                        onPressed: () {
                          Navigator.of(
                            context,
                          ).push(AppPageRoute.of(const ForgotPasswordScreen()));
                        },
                      ),
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 500),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    _ErrorBanner(message: _errorMessage),
                    AppButton(
                      label: 'Sign in',
                      size: AppButtonSize.lg,
                      isFullWidth: true,
                      isLoading: _isLoading,
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: _handleLogin,
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 600),
                    ),
                    const SizedBox(height: AppSpacing.space20),
                    const _OrDivider(),
                    const SizedBox(height: AppSpacing.space20),
                    AppButton(
                      label: 'Continue with Google',
                      variant: AppButtonVariant.tertiary,
                      size: AppButtonSize.lg,
                      isFullWidth: true,
                      isLoading: _isGoogleLoading,
                      leadingIcon: Icons.g_mobiledata_rounded,
                      onPressed: _handleGoogleSignIn,
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 700),
                    ),
                    const SizedBox(height: AppSpacing.space20),
                    Center(
                      child: BiometricLoginButton(
                        onSuccess: _handleBiometricSuccess,
                        onFailed: () {
                          if (!mounted) return;
                          setState(() {
                            _errorMessage = 'Biometric authentication failed';
                          });
                        },
                      ),
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 800),
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    _RegisterPrompt().animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 900),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  const _BrandHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.brandGradient,
            ),
            borderRadius: AppRadii.brXxl,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(AppSpacing.space12),
              child: Image.asset(
                AppConstants.logoPath,
                errorBuilder: (context, error, stack) => const Icon(
                  Icons.eco_rounded,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
        ).animate().scale(duration: AppMotion.slow, curve: Curves.easeOutBack),
      ],
    );
  }
}

class _HeadingBlock extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Welcome back',
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          'Sign in to continue to ${AppConstants.appName}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AppColors.outlineVariant, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space16),
          child: Text(
            'OR',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.onSurfaceVariant,
              letterSpacing: 1.4,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AppColors.outlineVariant, thickness: 1),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppMotion.fast,
      curve: AppMotion.standard,
      alignment: Alignment.topCenter,
      child: (message == null)
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.space16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: AppSpacing.space12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.danger.withValues(alpha: 0.08),
                  borderRadius: AppRadii.brMd,
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.danger,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.space8),
                    Expanded(
                      child: Text(
                        message!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().shake(hz: 3, duration: AppMotion.base),
            ),
    );
  }
}

class _RegisterPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(AppPageRoute.of(const RegisterScreen()));
        },
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: "Don't have an account? ",
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              TextSpan(
                text: 'Create one',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
