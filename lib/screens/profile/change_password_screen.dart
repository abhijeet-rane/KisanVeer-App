import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// V2 change password screen.
///
/// Single-column form with live password-strength checklist below the
/// new-password field. The checklist turns green as each rule is met
/// so the user gets continuous feedback rather than a terse error.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _newPasswordController.addListener(_onNewPasswordChanged);
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_onNewPasswordChanged);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onNewPasswordChanged() {
    setState(() {});
  }

  bool _hasMinLength(String p) => p.length >= 8;
  bool _hasUpper(String p) => p.contains(RegExp(r'[A-Z]'));
  bool _hasLower(String p) => p.contains(RegExp(r'[a-z]'));
  bool _hasDigit(String p) => p.contains(RegExp(r'\d'));
  bool _hasSpecial(String p) => p.contains(RegExp(r'[@$!%*?&#]'));

  bool _isPasswordValid(String p) =>
      _hasMinLength(p) &&
      _hasUpper(p) &&
      _hasLower(p) &&
      _hasDigit(p) &&
      _hasSpecial(p);

  String? _validateCurrentPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter your current password';
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) return 'Enter a new password';
    if (value == _currentPasswordController.text) {
      return 'New password must differ from current password';
    }
    if (!_isPasswordValid(value)) {
      return 'Password does not meet the requirements below';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Re-enter your new password';
    if (value != _newPasswordController.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _changePassword() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null || currentUser.email == null) {
        throw Exception('Not signed in');
      }

      try {
        await _supabase.auth.signInWithPassword(
          email: currentUser.email!,
          password: _currentPasswordController.text,
        );
      } catch (_) {
        throw Exception('Current password is incorrect');
      }

      await _supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: AppColors.success,
        ),
      );

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      AppLogger.e('Change password failed', tag: 'ChangePassword', error: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final newP = _newPasswordController.text;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Change password', showBack: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space16,
            AppSpacing.space32,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Set a new password',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.space8),
                Text(
                  'For security, enter your current password before '
                  'choosing a new one.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.space24),
                AppTextField(
                  controller: _currentPasswordController,
                  label: 'Current password',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscureCurrent,
                  textInputAction: TextInputAction.next,
                  suffix: _ObscureToggle(
                    obscured: _obscureCurrent,
                    onToggle: () =>
                        setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  validator: _validateCurrentPassword,
                ),
                const SizedBox(height: AppSpacing.space16),
                AppTextField(
                  controller: _newPasswordController,
                  label: 'New password',
                  prefixIcon: Icons.lock_reset_rounded,
                  obscureText: _obscureNew,
                  textInputAction: TextInputAction.next,
                  suffix: _ObscureToggle(
                    obscured: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  validator: _validateNewPassword,
                ),
                const SizedBox(height: AppSpacing.space12),
                _PasswordChecklist(
                  minLength: _hasMinLength(newP),
                  upper: _hasUpper(newP),
                  lower: _hasLower(newP),
                  digit: _hasDigit(newP),
                  special: _hasSpecial(newP),
                ),
                const SizedBox(height: AppSpacing.space16),
                AppTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm new password',
                  prefixIcon: Icons.check_circle_outline_rounded,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _changePassword(),
                  suffix: _ObscureToggle(
                    obscured: _obscureConfirm,
                    onToggle: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: AppSpacing.space32),
                AppButton(
                  label: _isLoading ? 'Updating…' : 'Update password',
                  size: AppButtonSize.lg,
                  isFullWidth: true,
                  isLoading: _isLoading,
                  leadingIcon: Icons.shield_rounded,
                  onPressed: _changePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ObscureToggle extends StatelessWidget {
  const _ObscureToggle({required this.obscured, required this.onToggle});

  final bool obscured;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onToggle,
      icon: Icon(
        obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        color: AppColors.onSurfaceVariant,
        size: 20,
      ),
      tooltip: obscured ? 'Show password' : 'Hide password',
    );
  }
}

class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({
    required this.minLength,
    required this.upper,
    required this.lower,
    required this.digit,
    required this.special,
  });

  final bool minLength;
  final bool upper;
  final bool lower;
  final bool digit;
  final bool special;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.space8),
          _RuleRow(text: 'At least 8 characters', met: minLength),
          _RuleRow(text: 'One uppercase letter (A–Z)', met: upper),
          _RuleRow(text: 'One lowercase letter (a–z)', met: lower),
          _RuleRow(text: 'One digit (0–9)', met: digit),
          _RuleRow(text: 'One special character (@, \$, !, …)', met: special),
        ],
      ),
    );
  }
}

class _RuleRow extends StatelessWidget {
  const _RuleRow({required this.text, required this.met});

  final String text;
  final bool met;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: AppMotion.fast,
            child: Icon(
              met
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey<bool>(met),
              color: met ? AppColors.success : AppColors.onSurfaceVariant,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: met ? AppColors.onSurface : AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
