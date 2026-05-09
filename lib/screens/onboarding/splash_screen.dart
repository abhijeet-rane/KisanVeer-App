import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_constants.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/screens/auth/login_screen.dart';
import 'package:kisan_veer/screens/home/main_screen.dart';
import 'package:kisan_veer/widgets/ui/app_page_route.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Brand-first splash screen.
///
/// Shows the KisanVeer mark and tagline on a brand-gradient background
/// for a short, deliberate moment, then routes to either [MainScreen]
/// or [LoginScreen] depending on the Supabase session.
///
/// Total visible time target: ~1.6 s on a warm start. The previous
/// v1 splash ran particle animations, rotating rings, and a pulse
/// effect that pushed the total to ~2.8 s and felt busy; this version
/// favours a single, confident brand moment.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _contentController;

  /// Guards against double-navigation if the async check finishes
  /// while the widget is being torn down.
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    _logoController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _contentController = AnimationController(
      vsync: this,
      duration: AppMotion.base,
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Let the frame settle before kicking off the logo reveal.
    await Future.delayed(AppMotion.fast);
    if (!mounted) return;
    _logoController.forward();

    await Future.delayed(AppMotion.base);
    if (!mounted) return;
    _contentController.forward();

    // Keep the brand moment visible for ~1 s after content lands so
    // users don't feel yanked to the next screen.
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() {
    if (_isNavigating || !mounted) return;
    _isNavigating = true;

    final session = Supabase.instance.client.auth.currentSession;
    final Widget next = session != null
        ? const MainScreen()
        : const LoginScreen();

    Navigator.of(context).pushReplacement(
      AppPageRoute<void>(
        builder: (_) => next,
        transition: AppPageTransition.fadeThrough,
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.primary,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: AppColors.brandGradient,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 5),
                _LogoReveal(controller: _logoController),
                const SizedBox(height: AppSpacing.space24),
                _BrandText(controller: _contentController),
                const Spacer(flex: 4),
                _ProgressStrip(controller: _contentController),
                const SizedBox(height: AppSpacing.space32),
                _Footer(controller: _contentController),
                const SizedBox(height: AppSpacing.space24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoReveal extends StatelessWidget {
  const _LogoReveal({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final scale = Tween<double>(begin: 0.85, end: 1.0)
        .chain(CurveTween(curve: AppMotion.emphasizedDecelerate))
        .animate(controller);
    final fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Opacity(
          opacity: fade.value,
          child: Transform.scale(
            scale: scale.value,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: AppRadii.brXxl,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.24),
                  width: 1,
                ),
              ),
              child: Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.space16),
                    child: Image.asset(
                      AppConstants.logoPath,
                      errorBuilder: (context, error, stack) {
                        return const Icon(
                          Icons.eco_rounded,
                          size: 36,
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _BrandText extends StatelessWidget {
  const _BrandText({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: controller, curve: Curves.easeOut);
    final rise = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .chain(CurveTween(curve: AppMotion.emphasizedDecelerate))
        .animate(controller);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: rise,
        child: Column(
          children: [
            Text(
              AppConstants.appName,
              style: AppTextStyles.headlineLarge.copyWith(
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppSpacing.space8),
            Container(
              width: 48,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: AppRadii.brFull,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space32,
              ),
              child: Text(
                AppConstants.appTagline,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: controller, curve: Curves.easeIn),
      child: SizedBox(
        width: 140,
        child: ClipRRect(
          borderRadius: AppRadii.brFull,
          child: LinearProgressIndicator(
            minHeight: 3,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: CurvedAnimation(parent: controller, curve: Curves.easeIn),
      child: Column(
        children: [
          Text(
            'v${AppConstants.appVersion}',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.space4),
          Text(
            'Built with care for Indian farmers',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
