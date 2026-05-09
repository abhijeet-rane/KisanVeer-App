import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/utils/validators.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 forgot password screen.
///
/// Two-state surface: compose-and-send, then success confirmation.
/// Both states share the same header so the transition reads as a
/// state change, not a navigation.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _resetSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _resetSent = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _humanizeError(e.toString());
      });
    }
  }

  String _humanizeError(String raw) {
    if (raw.contains('user-not-found')) {
      return 'No account found with this email address.';
    }
    if (raw.contains('invalid-email')) {
      return 'Please enter a valid email address.';
    }
    if (raw.contains('network-request-failed')) {
      return 'Network error. Check your internet connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppAppBar(showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space24),
          child: AnimatedSwitcher(
            duration: AppMotion.base,
            switchInCurve: AppMotion.emphasizedDecelerate,
            switchOutCurve: AppMotion.accelerate,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.04),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _resetSent ? _buildSuccessView() : _buildFormView(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.space16),
          Text(
            'Reset password',
            style: AppTextStyles.headlineMedium.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ).animate().fadeIn(duration: AppMotion.slow),
          const SizedBox(height: AppSpacing.space8),
          Text(
            'Enter the email you registered with. We will send a link '
            'to reset your password.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ).animate().fadeIn(
            duration: AppMotion.slow,
            delay: const Duration(milliseconds: 100),
          ),
          const SizedBox(height: AppSpacing.space32),
          Form(
            key: _formKey,
            child:
                AppTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'you@example.com',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _sendResetLink(),
                  validator: Validators.validateEmail,
                ).animate().fadeIn(
                  duration: AppMotion.base,
                  delay: const Duration(milliseconds: 200),
                ),
          ),
          const SizedBox(height: AppSpacing.space16),
          _ErrorBanner(message: _errorMessage),
          AppButton(
            label: 'Send reset link',
            size: AppButtonSize.lg,
            isFullWidth: true,
            isLoading: _isLoading,
            trailingIcon: Icons.send_rounded,
            onPressed: _sendResetLink,
          ).animate().fadeIn(
            duration: AppMotion.base,
            delay: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    return Column(
      key: const ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: AppRadii.brFull,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 48,
            ),
          ).animate().scale(duration: AppMotion.slow, curve: Curves.elasticOut),
        ),
        const SizedBox(height: AppSpacing.space24),
        Text(
          'Check your inbox',
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(
          duration: AppMotion.slow,
          delay: const Duration(milliseconds: 200),
        ),
        const SizedBox(height: AppSpacing.space12),
        Text(
          'We have sent a reset link to\n${_emailController.text.trim()}',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(
          duration: AppMotion.slow,
          delay: const Duration(milliseconds: 300),
        ),
        const SizedBox(height: AppSpacing.space8),
        Text(
          'Follow the link in the email to set a new password. '
          'You can close this screen.',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(
          duration: AppMotion.slow,
          delay: const Duration(milliseconds: 400),
        ),
        const Spacer(),
        AppButton(
          label: 'Back to sign in',
          size: AppButtonSize.lg,
          isFullWidth: true,
          leadingIcon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ).animate().fadeIn(
          duration: AppMotion.base,
          delay: const Duration(milliseconds: 500),
        ),
        const SizedBox(height: AppSpacing.space24),
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
