import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/screens/auth/login_screen.dart';
import 'package:kisan_veer/screens/home/home_screen.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/utils/validators.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:kisan_veer/widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

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
  String? _errorMessage;
  String _selectedUserType = 'farmer'; // Default selected user type

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

    if (_formKey.currentState?.validate() ?? false) {
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

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _signUpWithGoogle() async {
    if (_isGoogleLoading) return;

    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();

      if (mounted) {
        // Navigate to home screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _isGoogleLoading = false;
        if (e.toString().contains('sign_in_canceled')) {
          _errorMessage =
              null; // User canceled the sign-in process, don't show error
        } else {
          _errorMessage = e.toString();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Background decorations
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: size.width * 0.5,
                height: size.height * 0.25,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomRight: Radius.circular(300),
                  ),
                ),
              ),
            ),

            // Main content
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ).animate().fadeIn(
                          duration: const Duration(milliseconds: 400),
                        ),

                    const SizedBox(height: 20),

                    // Register heading
                    Text(
                      'Create Account',
                      style: AppTextStyles.h1,
                    )
                        .animate()
                        .fadeIn(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 200),
                        )
                        .moveX(
                          begin: -20,
                          end: 0,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutQuad,
                          delay: const Duration(milliseconds: 200),
                        ),

                    const SizedBox(height: 8),

                    Text(
                      'Sign up to join KisanVeer',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ).animate().fadeIn(
                          duration: const Duration(milliseconds: 600),
                          delay: const Duration(milliseconds: 300),
                        ),

                    const SizedBox(height: 32),

                    // Registration form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name field
                          CustomTextField(
                            label: 'Full Name',
                            hint: 'Enter your full name',
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            prefixIcon: Icons.person_outline,
                            textCapitalization: TextCapitalization.words,
                            validator: Validators.validateName,
                          ).animate().fadeIn(
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 400),
                              ),

                          const SizedBox(height: 20),

                          // Email field
                          CustomTextField(
                            label: 'Email',
                            hint: 'Enter your email',
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: Validators.validateEmail,
                          ).animate().fadeIn(
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 500),
                              ),

                          const SizedBox(height: 20),

                          // Phone field
                          CustomTextField(
                            label: 'Phone Number',
                            hint: 'Enter your 10-digit phone number',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
                            validator: Validators.validatePhone,
                          ).animate().fadeIn(
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 600),
                              ),

                          const SizedBox(height: 20),

                          // User type selection
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'I am a',
                                style: AppTextStyles.label,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildUserTypeOption(
                                      title: 'Farmer',
                                      value: 'farmer',
                                      icon: Icons.agriculture,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildUserTypeOption(
                                      title: 'Buyer',
                                      value: 'buyer',
                                      icon: Icons.shopping_cart,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ).animate().fadeIn(
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 700),
                              ),

                          const SizedBox(height: 20),

                          // Password field
                          CustomTextField(
                            label: 'Password',
                            hint: 'Create a strong password',
                            controller: _passwordController,
                            obscureText: true,
                            prefixIcon: Icons.lock_outline,
                            validator: Validators.validatePassword,
                          ).animate().fadeIn(
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 800),
                              ),

                          const SizedBox(height: 20),

                          // Confirm password field
                          CustomTextField(
                            label: 'Confirm Password',
                            hint: 'Confirm your password',
                            controller: _confirmPasswordController,
                            obscureText: true,
                            prefixIcon: Icons.lock_outline,
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
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 900),
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

                          // Register button
                          CustomButton(
                            text: 'Create Account',
                            isLoading: _isLoading,
                            onPressed: _handleRegister,
                          ).animate().fadeIn(
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 1000),
                              ),

                          const SizedBox(height: 24),

                          // Or separator
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: AppColors.textLight,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                  color: AppColors.textLight,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 1100),
                              ),

                          const SizedBox(height: 24),

                          // Google sign up button
                          CustomButton(
                            text: 'Sign up with Google',
                            isLoading: _isGoogleLoading,
                            buttonType: ButtonType.outlined,
                            onPressed: _signUpWithGoogle,
                            leadingIcon: Icons.g_mobiledata,
                          ).animate().fadeIn(
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 1200),
                              ),

                          const SizedBox(height: 40),

                          // Login link
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginScreen(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Already have an account? ',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Login',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(
                                duration: const Duration(milliseconds: 600),
                                delay: const Duration(milliseconds: 1300),
                              ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeOption({
    required String title,
    required String value,
    required IconData icon,
  }) {
    final isSelected = _selectedUserType == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
