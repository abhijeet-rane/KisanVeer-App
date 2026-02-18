/// Constants used throughout the app
class AppConstants {
  // App Information
  static const String appName = 'Kisan Veer';
  static const String appTagline = 'Empowering farmers, connecting markets';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.kisanveer.app';
  
  // SharedPreferences Keys
  static const String userPrefKey = 'user_data';
  static const String tokenPrefKey = 'auth_token';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String userLanguageKey = 'user_language';
  
  // Maps & Location
  static const double defaultMapZoom = 14.0;
  static const double indiaLatitude = 20.5937;  // Center of India
  static const double indiaLongitude = 78.9629; // Center of India
  
  // Pagination
  static const int defaultPageSize = 10;
  
  // Timeout durations
  static const int connectionTimeoutSeconds = 30;
  static const int receiveTimeoutSeconds = 30;
  
  // Image quality
  static const int imageQuality = 85;
  static const double maxImageWidth = 1080;
  
  // Supported languages
  static const List<String> supportedLanguages = [
    'English',
    'Hindi',
    'Bengali',
    'Telugu',
    'Marathi',
    'Tamil',
    'Gujarati',
    'Kannada',
    'Malayalam',
    'Punjabi',
  ];
  
  // Format constants
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String currencySymbol = '₹';
  
  // Asset paths
  static const String logoPath = 'assets/images/logo.png';
  static const String placeholderImagePath = 'assets/images/placeholder.png';
  static const String loadingAnimationPath = 'assets/animations/loading.json';
  static const String successAnimationPath = 'assets/animations/success.json';
  static const String errorAnimationPath = 'assets/animations/error.json';
  
  // OAuth callback scheme (must match AndroidManifest.xml)
  static const String oauthCallbackScheme = 'com.kisanveer.app';
  static const String oauthCallbackHost = 'login-callback';
  static const String oauthRedirectUrl = '$oauthCallbackScheme://$oauthCallbackHost/';
}
