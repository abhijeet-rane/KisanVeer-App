import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/utils/validators.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:kisan_veer/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

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

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await _authService.resetPassword(_emailController.text.trim());

        setState(() {
          _isLoading = false;
          _resetSent = true;
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = _getAuthErrorMessage(e.toString());
        });
      }
    }
  }

  String _getAuthErrorMessage(String errorString) {
    if (errorString.contains('user-not-found')) {
      return 'No user found with this email address.';
    } else if (errorString.contains('invalid-email')) {
      return 'Invalid email format.';
    } else if (errorString.contains('network-request-failed')) {
      return 'Network error. Please check your internet connection.';
    } else {
      return 'An error occurred. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Reset Password',
                style: AppTextStyles.h1,
              )
                  .animate()
                  .fadeIn(
                    duration: const Duration(milliseconds: 600),
                  )
                  .moveX(
                    begin: -20,
                    end: 0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutQuad,
                  ),

              const SizedBox(height: 12),

              Text(
                'Enter your email address and we will send you a link to reset your password.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(
                    duration: const Duration(milliseconds: 600),
                    delay: const Duration(milliseconds: 200),
                  ),

              const SizedBox(height: 40),

              if (!_resetSent)
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email field
                        CustomTextField(
                          label: 'Email',
                          hint: 'Enter your registered email',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: Validators.validateEmail,
                        ).animate().fadeIn(
                              duration: const Duration(milliseconds: 600),
                              delay: const Duration(milliseconds: 300),
                            ),

                        const SizedBox(height: 24),

                        // Error message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: AppColors.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().shake(),

                        if (_errorMessage != null) const SizedBox(height: 24),

                        // Send reset link button
                        CustomButton(
                          text: 'Send Reset Link',
                          isLoading: _isLoading,
                          onPressed: _sendResetLink,
                        ).animate().fadeIn(
                              duration: const Duration(milliseconds: 600),
                              delay: const Duration(milliseconds: 400),
                            ),

                        const Spacer(),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Success icon
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: AppColors.success,
                          size: 50,
                        ),
                      ).animate().scale(
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.elasticOut,
                          ),

                      const SizedBox(height: 24),

                      Text(
                        'Reset Link Sent!',
                        style: AppTextStyles.h2,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 300),
                          ),

                      const SizedBox(height: 16),

                      Text(
                        'We have sent a password reset link to:\n${_emailController.text}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 400),
                          ),

                      const SizedBox(height: 32),

                      Text(
                        'Please check your email and follow the instructions to reset your password.',
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 500),
                          ),

                      const SizedBox(height: 40),

                      CustomButton(
                        text: 'Back to Login',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ).animate().fadeIn(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 600),
                          ),
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
