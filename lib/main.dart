import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kisan_veer/constants/app_theme.dart';
import 'package:kisan_veer/screens/auth/login_screen.dart';
import 'package:kisan_veer/screens/home/main_screen.dart';
import 'package:kisan_veer/screens/market/pinned_commodities_screen.dart';
import 'package:kisan_veer/screens/market/price_alerts_screen.dart';
import 'package:kisan_veer/services/localization_service.dart';
import 'package:kisan_veer/screens/onboarding/splash_screen.dart';
import 'package:kisan_veer/services/analytics_service.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/services/notifications_service.dart';
import 'package:kisan_veer/services/storage_service.dart';
import 'package:kisan_veer/widgets/ui/app_page_route.dart';
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

  // Initialize local key/value storage — must happen before any screen
  // that reads from SharedPreferences (profile badge count, cached
  // notification history, language prefs, etc).
  await StorageService().init();

  // Initialize Supabase using the values from .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  // Initialize auth state listener to save sessions for biometric login
  AuthService().initAuthStateListener();

  // Initialize analytics so events are batched & flushed in the background
  AnalyticsService().initialize(
    userId: Supabase.instance.client.auth.currentUser?.id,
  );

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
      themeMode: ThemeMode.light,
      localizationsDelegates: LocalizationService.localizationsDelegates,
      supportedLocales: LocalizationService.supportedLocales,
      localeResolutionCallback: LocalizationService.localeResolutionCallback,
      // Always show premium splash screen first - it handles auth navigation
      home: const SplashScreen(),
      // Custom page transitions for premium feel
      onGenerateRoute: _generateRoute,
      routes: {'/splash': (context) => const SplashScreen()},
    );
  }

  /// Resolve named routes to v2 page transitions. Top-level navigation
  /// destinations (`/main`, `/login`) fade through — they're peer
  /// shells. Deep destinations slide horizontally.
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    Widget page;
    AppPageTransition transition = AppPageTransition.sharedAxisX;

    switch (settings.name) {
      case '/main':
        page = const MainScreen();
        transition = AppPageTransition.fadeThrough;
        break;
      case '/login':
        page = const LoginScreen();
        transition = AppPageTransition.fadeThrough;
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

    return AppPageRoute(
      builder: (_) => page,
      transition: transition,
      settings: settings,
    );
  }
}
