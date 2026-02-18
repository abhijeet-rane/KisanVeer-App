import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:kisan_veer/constants/app_theme.dart';
import 'package:kisan_veer/screens/auth/login_screen.dart';
import 'package:kisan_veer/screens/home/main_screen.dart';
import 'package:kisan_veer/screens/market/pinned_commodities_screen.dart';
import 'package:kisan_veer/screens/market/price_alerts_screen.dart';
import 'package:kisan_veer/services/localization_service.dart';
import 'package:kisan_veer/screens/onboarding/splash_screen.dart';
import 'package:kisan_veer/services/notifications_service.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase using the values from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  
  // Initialize auth state listener to save sessions for biometric login
  AuthService().initAuthStateListener();
  
  await NotificationsService.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kisan Veer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      localizationsDelegates: LocalizationService.localizationsDelegates,
      supportedLocales: LocalizationService.supportedLocales,
      localeResolutionCallback: LocalizationService.localeResolutionCallback,
      // Always show premium splash screen first - it handles auth navigation
      home: const SplashScreen(),
      // Custom page transitions for premium feel
      onGenerateRoute: _generateRoute,
      routes: {
        '/splash': (context) => const SplashScreen(),
      },
    );
  }

  /// Generate routes with premium transitions
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    Widget page;
    
    switch (settings.name) {
      case '/main':
        page = const MainScreen();
        break;
      case '/login':
        page = const LoginScreen();
        break;
      case '/pinned_commodities':
        page = const PinnedCommoditiesScreen();
        break;
      case '/market/price-alerts':
        page = const PriceAlertsScreen();
        break;
      default:
        return null;
    }

    return PremiumPageRoute(
      builder: (context) => page,
      settings: settings,
    );
  }
}

/// Custom page route with premium transition animation
class PremiumPageRoute<T> extends MaterialPageRoute<T> {
  PremiumPageRoute({
    required super.builder,
    super.settings,
  });

  @override
  Duration get transitionDuration => const Duration(milliseconds: 400);

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Fade + slight scale transition
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      ),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.95, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
        ),
        child: child,
      ),
    );
  }
}