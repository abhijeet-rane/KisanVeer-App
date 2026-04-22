import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/screens/auth/login_screen.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/utils/validators.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 registration screen.
///
/// Staged visual rhythm: app-bar with back → heading → identity fields
/// → role selector → password fields → primary CTA → social / login
/// prompt. Focuses on clarity and progression rather than density.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _errorMessage;
  String _selectedUserType = 'farmer';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _phoneController.text.trim(),
        _selectedUserType,
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

  Future<void> _handleGoogleSignUp() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const AppAppBar(showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space24,
            vertical: AppSpacing.space8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create your account',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(duration: AppMotion.slow),
              const SizedBox(height: AppSpacing.space8),
              Text(
                "Let's set you up in a minute.",
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _nameController,
                      label: 'Full name',
                      hint: 'As it appears on your records',
                      prefixIcon: Icons.person_outline_rounded,
                      keyboardType: TextInputType.name,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: Validators.validateName,
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 200),
                    ),
                    const SizedBox(height: AppSpacing.space16),
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
                      controller: _phoneController,
                      label: 'Phone number',
                      hint: '10-digit mobile number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      validator: Validators.validatePhone,
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 400),
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    Text(
                      'I am a',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    Row(
                      children: [
                        Expanded(
                          child: _UserTypeTile(
                            value: 'farmer',
                            icon: Icons.agriculture_rounded,
                            label: 'Farmer',
                            selected: _selectedUserType == 'farmer',
                            onTap: () =>
                                setState(() => _selectedUserType = 'farmer'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space12),
                        Expanded(
                          child: _UserTypeTile(
                            value: 'buyer',
                            icon: Icons.shopping_cart_outlined,
                            label: 'Buyer',
                            selected: _selectedUserType == 'buyer',
                            onTap: () =>
                                setState(() => _selectedUserType = 'buyer'),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 500),
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Password',
                      hint: '8+ chars, 1 uppercase, 1 number',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
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
                      validator: Validators.validatePassword,
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 600),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    AppTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirm password',
                      hint: 'Re-enter password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleRegister(),
                      suffix: IconButton(
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.onSurfaceVariant,
                          size: 20,
                        ),
                        tooltip: _obscureConfirm
                            ? 'Show password'
                            : 'Hide password',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 700),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    _ErrorBanner(message: _errorMessage),
                    AppButton(
                      label: 'Create account',
                      size: AppButtonSize.lg,
                      isFullWidth: true,
                      isLoading: _isLoading,
                      trailingIcon: Icons.arrow_forward_rounded,
                      onPressed: _handleRegister,
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 800),
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
                      onPressed: _handleGoogleSignUp,
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 900),
                    ),
                    const SizedBox(height: AppSpacing.space32),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            AppPageRoute.of(const LoginScreen()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Already have an account? ',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                              TextSpan(
                                text: 'Sign in',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 1000),
                    ),
                    const SizedBox(height: AppSpacing.space24),
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

class _UserTypeTile extends StatelessWidget {
  const _UserTypeTile({
    required this.value,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String value;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.brLg,
          child: AnimatedContainer(
            duration: AppMotion.base,
            curve: AppMotion.emphasized,
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.space16,
              horizontal: AppSpacing.space16,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerLow,
              borderRadius: AppRadii.brLg,
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.outlineVariant,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: selected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.space12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: selected
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurface,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: selected
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: const ValueKey('sel'),
                          color: AppColors.primary,
                          size: 20,
                        )
                      : const SizedBox(
                          key: ValueKey('unsel'),
                          width: 20,
                          height: 20,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
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
