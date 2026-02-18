import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_constants.dart';
import 'package:kisan_veer/screens/auth/login_screen.dart';
import 'package:kisan_veer/screens/home/main_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

/// Premium animated splash screen with glassmorphism effects
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _backgroundController;
  late AnimationController _pulseController;
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _pulseAnimation;
  
  bool _showContent = false;
  bool _showLoader = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimationSequence();
    
    // Set status bar style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Background particle animation
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Pulse animation for logo glow
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    _logoRotation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeOutBack,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _startAnimationSequence() async {
    // Start logo animation
    await Future.delayed(const Duration(milliseconds: 300));
    _logoController.forward();

    // Show content after logo animation
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      setState(() => _showContent = true);
    }

    // Show loader
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _showLoader = true);
    }

    // Navigate after splash
    await Future.delayed(const Duration(milliseconds: 2000));
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    // Check if user is logged in
    final session = Supabase.instance.client.auth.currentSession;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            session != null ? const MainScreen() : const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _backgroundController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(size),
          
          // Floating particles
          _buildFloatingParticles(size),
          
          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // Animated logo with glow
                  _buildAnimatedLogo(),
                  
                  const SizedBox(height: 40),
                  
                  // App name with gradient
                  if (_showContent) _buildAppName(),
                  
                  const SizedBox(height: 12),
                  
                  // Tagline
                  if (_showContent) _buildTagline(),
                  
                  const Spacer(flex: 2),
                  
                  // Premium loader
                  if (_showLoader) _buildPremiumLoader(),
                  
                  const SizedBox(height: 40),
                  
                  // Version info
                  if (_showContent) _buildVersionInfo(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground(Size size) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.9),
                AppColors.primary,
                const Color(0xFF064E2B),
                const Color(0xFF032615),
              ],
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingParticles(Size size) {
    return AnimatedBuilder(
      animation: _backgroundController,
      builder: (context, child) {
        return CustomPaint(
          size: size,
          painter: ParticlesPainter(
            animation: _backgroundController.value,
          ),
        );
      },
    );
  }

  Widget _buildAnimatedLogo() {
    return AnimatedBuilder(
      animation: Listenable.merge([_logoController, _pulseController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _logoScale.value * _pulseAnimation.value,
          child: Transform.rotate(
            angle: _logoRotation.value,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 60,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Center(
                child: ClipOval(
                  child: Image.asset(
                    AppConstants.logoPath,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to styled initials
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: AppColors.greenGradient,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'KV',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppName() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Color(0xFFE8F5E9)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(bounds),
      child: const Text(
        'Kisan Veer',
        style: TextStyle(
          color: Colors.white,
          fontSize: 42,
          fontWeight: FontWeight.bold,
          fontFamily: 'Poppins',
          letterSpacing: 2,
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 200.ms)
        .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildTagline() {
    return Text(
      AppConstants.appTagline,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.85),
        fontSize: 16,
        fontFamily: 'Poppins',
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
      ),
    )
        .animate()
        .fadeIn(duration: 600.ms, delay: 400.ms)
        .slideY(begin: 0.3, end: 0, duration: 600.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildPremiumLoader() {
    return Column(
      children: [
        // Custom animated loader
        SizedBox(
          width: 50,
          height: 50,
          child: Stack(
            children: [
              // Outer ring
              _buildAnimatedRing(50, 3, 0),
              // Middle ring
              Center(child: _buildAnimatedRing(35, 2.5, 0.3)),
              // Inner ring
              Center(child: _buildAnimatedRing(20, 2, 0.6)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Loading your farm assistant...',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 14,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }

  Widget _buildAnimatedRing(double size, double strokeWidth, double delay) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withValues(alpha: 0.8 - delay),
        ),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .rotate(duration: Duration(milliseconds: (1500 + delay * 1000).toInt()));
  }

  Widget _buildVersionInfo() {
    return Text(
      'Version ${AppConstants.appVersion}',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 12,
        fontFamily: 'Poppins',
      ),
    ).animate().fadeIn(duration: 500.ms, delay: 600.ms);
  }
}

/// Custom painter for floating particles effect
class ParticlesPainter extends CustomPainter {
  final double animation;
  final List<Particle> particles;
  
  ParticlesPainter({required this.animation})
      : particles = List.generate(30, (index) => Particle(index));

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var particle in particles) {
      final progress = (animation + particle.offset) % 1.0;
      final x = particle.x * size.width;
      final y = (particle.y + progress) % 1.0 * size.height;
      
      paint.color = Colors.white.withValues(
        alpha: particle.opacity * (1 - progress) * 0.3,
      );
      
      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ParticlesPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Particle data class
class Particle {
  final double x;
  final double y;
  final double size;
  final double opacity;
  final double offset;

  Particle(int seed)
      : x = _random(seed * 1),
        y = _random(seed * 2),
        size = 1 + _random(seed * 3) * 3,
        opacity = 0.3 + _random(seed * 4) * 0.7,
        offset = _random(seed * 5);

  static double _random(int seed) {
    return ((math.sin(seed.toDouble()) * 10000) % 1).abs();
  }
}
