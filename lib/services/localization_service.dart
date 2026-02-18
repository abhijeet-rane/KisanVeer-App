import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:kisan_veer/services/storage_service.dart';

class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();
  
  // Supported locales
  static final List<Locale> supportedLocales = [
    const Locale('en', 'US'), // English
    const Locale('hi', 'IN'), // Hindi
    const Locale('mr', 'IN'), // Marathi
    const Locale('pa', 'IN'), // Punjabi
    const Locale('gu', 'IN'), // Gujarati
    const Locale('ta', 'IN'), // Tamil
    const Locale('te', 'IN'), // Telugu
    const Locale('kn', 'IN'), // Kannada
    const Locale('bn', 'IN'), // Bengali
  ];
  
  // Locale delegate
  static const LocalizationsDelegate<AppLocalizations> delegate = AppLocalizationsDelegate();
  
  // Localization delegates
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];
  
  // Locale resolution
  static Locale? localeResolutionCallback(Locale? locale, Iterable<Locale> supportedLocales) {
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale?.languageCode &&
          supportedLocale.countryCode == locale?.countryCode) {
        return supportedLocale;
      }
    }
    
    // Default to English if not supported
    return supportedLocales.first;
  }
  
  // Current locale
  Locale _currentLocale = const Locale('en', 'US');
  Locale get currentLocale => _currentLocale;
  
  // Storage service
  final StorageService _storageService = StorageService();
  
  // Initialize service
  Future<void> init() async {
    final languageCode = _storageService.getString('language_code');
    final countryCode = _storageService.getString('country_code');
    
    if (languageCode != null && countryCode != null) {
      _currentLocale = Locale(languageCode, countryCode);
    }
  }
  
  // Change locale
  Future<void> changeLocale(Locale locale) async {
    if (supportedLocales.contains(locale)) {
      _currentLocale = locale;
      await _storageService.saveString('language_code', locale.languageCode);
      await _storageService.saveString('country_code', locale.countryCode ?? '');
    }
  }
  
  // Get language name from locale
  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en': return 'English';
      case 'hi': return 'हिंदी';
      case 'mr': return 'मराठी';
      case 'pa': return 'ਪੰਜਾਬੀ';
      case 'gu': return 'ગુજરાતી';
      case 'ta': return 'தமிழ்';
      case 'te': return 'తెలుగు';
      case 'kn': return 'ಕನ್ನಡ';
      case 'bn': return 'বাংলা';
      default: return 'English';
    }
  }
}

// App localizations class
class AppLocalizations {
  final Locale locale;
  
  AppLocalizations(this.locale);
  
  // Helper method to get localized strings
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }
  
  // Static method to load localization
  static Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }
  
  // Translation maps for different languages
  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common
      'app_name': 'Kisan Veer',
      'loading': 'Loading...',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search',
      'back': 'Back',
      'next': 'Next',
      'done': 'Done',
      'error': 'Error',
      'success': 'Success',
      
      // Auth
      'login': 'Login',
      'signup': 'Sign Up',
      'logout': 'Logout',
      'email': 'Email',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'reset_password': 'Reset Password',
      'name': 'Name',
      'phone': 'Phone Number',
      'profile': 'Profile',
      
      // Home
      'home': 'Home',
      'dashboard': 'Dashboard',
      'welcome': 'Welcome',
      'recent_activity': 'Recent Activity',
      'view_all': 'View All',
      
      // Weather
      'weather': 'Weather',
      'temperature': 'Temperature',
      'humidity': 'Humidity',
      'wind_speed': 'Wind Speed',
      'precipitation': 'Precipitation',
      'pressure': 'Pressure',
      'visibility': 'Visibility',
      'uv_index': 'UV Index',
      'forecast': 'Forecast',
      'today': 'Today',
      'tomorrow': 'Tomorrow',
      'hourly_forecast': 'Hourly Forecast',
      'daily_forecast': 'Daily Forecast',
      'farming_advice': 'Farming Advice',
      
      // Marketplace
      'marketplace': 'Marketplace',
      'buy': 'Buy',
      'sell': 'Sell',
      'product': 'Product',
      'products': 'Products',
      'price': 'Price',
      'quantity': 'Quantity',
      'description': 'Description',
      'category': 'Category',
      'add_product': 'Add Product',
      'edit_product': 'Edit Product',
      'product_details': 'Product Details',
      'contact_seller': 'Contact Seller',
      'location': 'Location',
      
      // Finance
      'finance': 'Finance',
      'transactions': 'Transactions',
      'expenses': 'Expenses',
      'income': 'Income',
      'loans': 'Loans',
      'savings': 'Savings',
      'add_transaction': 'Add Transaction',
      'transaction_details': 'Transaction Details',
      'amount': 'Amount',
      'date': 'Date',
      'notes': 'Notes',
      'balance': 'Balance',
      
      // Community
      'community': 'Community',
      'posts': 'Posts',
      'create_post': 'Create Post',
      'title': 'Title',
      'content': 'Content',
      'comments': 'Comments',
      'add_comment': 'Add Comment',
      'communities': 'Communities',
      'join': 'Join',
      'members': 'Members',
      
      // Settings
      'settings': 'Settings',
      'account_settings': 'Account Settings',
      'app_settings': 'App Settings',
      'notification_settings': 'Notification Settings',
      'language': 'Language',
      'theme': 'Theme',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'privacy_policy': 'Privacy Policy',
      'terms_of_service': 'Terms of Service',
      'about': 'About',
      'help': 'Help',
      'contact_us': 'Contact Us',
      'version': 'Version',
      
      // Notifications
      'notifications': 'Notifications',
      'no_notifications': 'No notifications',
      'mark_all_read': 'Mark All as Read',
      'clear_all': 'Clear All',
    },
    
    'hi': {
      // Common
      'app_name': 'किसान वीर',
      'loading': 'लोड हो रहा है...',
      'retry': 'पुनः प्रयास करें',
      'cancel': 'रद्द करें',
      'confirm': 'पुष्टि करें',
      'save': 'सहेजें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'search': 'खोजें',
      'back': 'वापस',
      'next': 'अगला',
      'done': 'हो गया',
      'error': 'त्रुटि',
      'success': 'सफलता',
      
      // Auth
      'login': 'लॉगिन',
      'signup': 'साइन अप',
      'logout': 'लॉगआउट',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'confirm_password': 'पासवर्ड की पुष्टि',
      'forgot_password': 'पासवर्ड भूल गए?',
      'reset_password': 'पासवर्ड रीसेट करें',
      'name': 'नाम',
      'phone': 'फ़ोन नंबर',
      'profile': 'प्रोफ़ाइल',
      
      // Home
      'home': 'होम',
      'dashboard': 'डैशबोर्ड',
      'welcome': 'स्वागत है',
      'recent_activity': 'हाल की गतिविधि',
      'view_all': 'सभी देखें',
      
      // Weather
      'weather': 'मौसम',
      'temperature': 'तापमान',
      'humidity': 'आर्द्रता',
      'wind_speed': 'हवा की गति',
      'precipitation': 'वर्षा',
      'pressure': 'दबाव',
      'visibility': 'दृश्यता',
      'uv_index': 'यूवी इंडेक्स',
      'forecast': 'पूर्वानुमान',
      'today': 'आज',
      'tomorrow': 'कल',
      'hourly_forecast': 'घंटों का पूर्वानुमान',
      'daily_forecast': 'दैनिक पूर्वानुमान',
      'farming_advice': 'खेती की सलाह',
      
      // Marketplace
      'marketplace': 'बाज़ार',
      'buy': 'खरीदें',
      'sell': 'बेचें',
      'product': 'उत्पाद',
      'products': 'उत्पाद',
      'price': 'कीमत',
      'quantity': 'मात्रा',
      'description': 'विवरण',
      'category': 'श्रेणी',
      'add_product': 'उत्पाद जोड़ें',
      'edit_product': 'उत्पाद संपादित करें',
      'product_details': 'उत्पाद विवरण',
      'contact_seller': 'विक्रेता से संपर्क करें',
      'location': 'स्थान',
      
      // Finance
      'finance': 'वित्त',
      'transactions': 'लेनदेन',
      'expenses': 'खर्च',
      'income': 'आय',
      'loans': 'ऋण',
      'savings': 'बचत',
      'add_transaction': 'लेनदेन जोड़ें',
      'transaction_details': 'लेनदेन विवरण',
      'amount': 'राशि',
      'date': 'तारीख',
      'notes': 'नोट्स',
      'balance': 'शेष राशि',
      
      // Community
      'community': 'समुदाय',
      'posts': 'पोस्ट',
      'create_post': 'पोस्ट बनाएं',
      'title': 'शीर्षक',
      'content': 'सामग्री',
      'comments': 'टिप्पणियां',
      'add_comment': 'टिप्पणी जोड़ें',
      'communities': 'समुदाय',
      'join': 'जुड़ें',
      'members': 'सदस्य',
      
      // Settings
      'settings': 'सेटिंग्स',
      'account_settings': 'खाता सेटिंग्स',
      'app_settings': 'ऐप सेटिंग्स',
      'notification_settings': 'सूचना सेटिंग्स',
      'language': 'भाषा',
      'theme': 'थीम',
      'dark_mode': 'डार्क मोड',
      'light_mode': 'लाइट मोड',
      'privacy_policy': 'गोपनीयता नीति',
      'terms_of_service': 'सेवा की शर्तें',
      'about': 'के बारे में',
      'help': 'सहायता',
      'contact_us': 'संपर्क करें',
      'version': 'संस्करण',
      
      // Notifications
      'notifications': 'सूचनाएं',
      'no_notifications': 'कोई सूचना नहीं',
      'mark_all_read': 'सभी को पढ़ा हुआ मार्क करें',
      'clear_all': 'सभी हटाएं',
    },
    
    // Add more languages as needed
  };
  
  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? 
           _localizedValues['en']?[key] ?? 
           key;
  }
}

// Localizations delegate
class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'hi', 'mr', 'pa', 'gu', 'ta', 'te', 'kn', 'bn'].contains(locale.languageCode);
  }
  
  @override
  Future<AppLocalizations> load(Locale locale) {
    return AppLocalizations.load(locale);
  }
  
  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
}
