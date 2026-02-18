import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/screens/auth/forgot_password_screen.dart';
import 'package:kisan_veer/screens/auth/register_screen.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/utils/validators.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:kisan_veer/widgets/custom_text_field.dart';
import 'package:kisan_veer/widgets/biometric_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

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
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await _authService.signInWithEmailAndPassword(
          _emailController.text.trim(),
          _passwordController.text,
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

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithGoogle();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (e.toString().contains('sign_in_canceled')) {
          _errorMessage = null; // User canceled the sign-in process, don't show error
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
              right: 0,
              child: Container(
                width: size.width * 0.4,
                height: size.height * 0.3,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(300),
                  ),
                ),
              ),
            ),
            
            Positioned(
              bottom: 0,
              left: 0,
              child: Container(
                width: size.width * 0.6,
                height: size.height * 0.2,
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(300),
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
                    const SizedBox(height: 40),
                    
                    // App logo and branding
                    Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo.png',
                            width: 70,
                            height: 70,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 70,
                                height: 70,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    'KV',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ).animate().scale(
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutBack,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Welcome text
                    Text(
                      'Welcome Back!',
                      style: AppTextStyles.h1,
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                    ).moveX(
                      begin: -20,
                      end: 0,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutQuad,
                      delay: const Duration(milliseconds: 200),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Sign in to continue to KisanVeer',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ).animate().fadeIn(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 300),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Login form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            delay: const Duration(milliseconds: 400),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Password field
                          CustomTextField(
                            label: 'Password',
                            hint: 'Enter your password',
                            controller: _passwordController,
                            obscureText: true,
                            prefixIcon: Icons.lock_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                          ).animate().fadeIn(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 500),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Forgot password link
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ForgotPasswordScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 600),
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
                          
                          if (_errorMessage != null)
                            const SizedBox(height: 24),
                          
                          // Login button
                          CustomButton(
                            text: 'Login',
                            isLoading: _isLoading,
                            onPressed: _handleLogin,
                          ).animate().fadeIn(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 700),
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
                                padding: const EdgeInsets.symmetric(horizontal: 16),
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
                            delay: const Duration(milliseconds: 800),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Google sign in button
                          CustomButton(
                            text: 'Sign in with Google',
                            isLoading: _isGoogleLoading,
                            buttonType: ButtonType.outlined,
                            onPressed: _handleGoogleSignIn,
                            leadingIcon: Icons.g_mobiledata,
                          ).animate().fadeIn(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 900),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Biometric login button
                          BiometricLoginButton(
                            onSuccess: () async {
                              // Restore Supabase session from saved tokens
                              final success = await _authService.restoreSessionForBiometric();
                              if (success && mounted) {
                                Navigator.pushReplacementNamed(context, '/main');
                              } else if (mounted) {
                                setState(() {
                                  _errorMessage = 'Please login with password once to refresh your session. Biometric will work again afterward.';
                                });
                              }
                            },
                            onFailed: () {
                              setState(() {
                                _errorMessage = 'Biometric authentication failed';
                              });
                            },
                          ).animate().fadeIn(
                            duration: const Duration(milliseconds: 600),
                            delay: const Duration(milliseconds: 1000),
                          ),
                          
                          // Register link
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const RegisterScreen(),
                                  ),
                                );
                              },
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Don\'t have an account? ',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Register',
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
                            delay: const Duration(milliseconds: 1000),
                          ),
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
}
