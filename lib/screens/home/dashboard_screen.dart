import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/models/user_model.dart';
import 'package:kisan_veer/screens/weather/weather_screen.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/services/market_service.dart';
import 'package:kisan_veer/services/weather_service.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:kisan_veer/widgets/custom_card.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kisan_veer/screens/marketplace/marketplace_screen_fixed.dart';

import '../community/community_screen.dart';
import '../finance/finance_screen.dart';
import '../market/market_insights_screen.dart';
import '../market/price_finder_screen.dart';
import '../monitoring/gas_sensor_monitor_screen.dart';
import '../schemes/schemes_listing_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final WeatherService _weatherService = WeatherService();
  UserModel? _currentUser;
  bool _isLoading = true;
  Map<String, dynamic>? _weatherData;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadWeatherData();
  }

  Future<void> _loadWeatherData() async {
    try {
      setState(() {
        _isLoadingWeather = true;
      });
      final weatherData = await _weatherService.getAllWeatherData();
      setState(() {
        _weatherData = weatherData;
        _isLoadingWeather = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.getCurrentUserModel();

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildServiceCard(IconData icon, String title, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade400,
              Colors.green.shade700
            ], // Gradient effect
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 38, color: Colors.white), // Larger white icon
            SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white, // White text for contrast
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTime = DateTime.now();
    final greeting = _getGreeting(currentTime.hour);
    final dayName = DateFormat('EEEE').format(currentTime);
    final dateFormatted = DateFormat('d MMMM, yyyy').format(currentTime);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadUserData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header section with greeting and user info
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: AppColors.greenGradient,
                          ),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(30),
                            bottomRight: Radius.circular(30),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$greeting,',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ).animate().fadeIn(
                                          duration:
                                              const Duration(milliseconds: 500),
                                        ),
                                    const SizedBox(height: 5),
                                    Text(
                                      _currentUser?.name ?? 'User',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ).animate().fadeIn(
                                          duration:
                                              const Duration(milliseconds: 500),
                                          delay:
                                              const Duration(milliseconds: 200),
                                        ),
                                  ],
                                ),
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.white,
                                  child: _currentUser
                                              ?.profileImageUrl.isNotEmpty ==
                                          true
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          child: Image.network(
                                            _currentUser!.profileImageUrl,
                                            width: 60,
                                            height: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    _buildInitialsAvatar(),
                                          ),
                                        )
                                      : _buildInitialsAvatar(),
                                ).animate().scale(
                                      duration:
                                          const Duration(milliseconds: 600),
                                      curve: Curves.easeOutBack,
                                    ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$dayName, $dateFormatted',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(
                                  duration: const Duration(milliseconds: 500),
                                  delay: const Duration(milliseconds: 400),
                                ),
                          ],
                        ),
                      ),

                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Weather card
                            _buildWeatherCard().animate().fadeIn(
                                  duration: const Duration(milliseconds: 600),
                                  delay: const Duration(milliseconds: 500),
                                ),

                            const SizedBox(height: 24),

                            // Services Section (Advanced UI)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 5.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Services",
                                    style: TextStyle(
                                      fontSize: 23,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.9,
                                    ),
                                  ),
                                  const SizedBox(
                                      height: 4), // Space before underline
                                  Container(
                                    width: 112, // Small underline effect
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.blue, // Highlight color
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Grid Layout for Services
                            GridView.count(
                              crossAxisCount: 2, // Two services per row
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.2,
                              children: [
                                _buildServiceCard(Icons.store, "Marketplace",
                                    const MarketplaceScreen()),
                                _buildServiceCard(
                                    Icons.trending_up,
                                    "Market Insights",
                                    const MarketInsightsScreen()),
                                _buildServiceCard(Icons.calculate,
                                    "Financial Tools", const FinanceScreen()),
                                _buildServiceCard(
                                    Icons.wb_sunny,
                                    "Weather\n Forecasts",
                                    const WeatherScreen()),
                                _buildServiceCard(
                                    Icons.groups,
                                    "Community Network",
                                    const CommunityScreen()),
                                _buildServiceCard(
                                    Icons.account_balance,
                                    "Government Schemes\n& Subsidies",
                                    const SchemesListingScreen()),
                                _buildServiceCard(
                                    Icons.monitor,
                                    "Smart Farm\nMonitor",
                                    const GasSensorMonitorScreen(),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 30),

                            // Market insights
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Market Insights',
                                  style: AppTextStyles.h3,
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MarketInsightsScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text('See All'),
                                ),
                              ],
                            ).animate().fadeIn(
                                  duration: const Duration(milliseconds: 600),
                                  delay: const Duration(milliseconds: 800),
                                ),

                            const SizedBox(height: 16),

                            _buildMarketInsightsCard().animate().fadeIn(
                                  duration: const Duration(milliseconds: 600),
                                  delay: const Duration(milliseconds: 900),
                                ),

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInitialsAvatar() {
    String initials = 'U';
    if (_currentUser?.name != null && _currentUser!.name.isNotEmpty) {
      initials = _currentUser!.name
          .split(' ')
          .map((e) => e.isNotEmpty ? e[0] : '')
          .join('');
      if (initials.length > 2) {
        initials = initials.substring(0, 2);
      }
    }
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  // Get appropriate weather icon based on condition
  IconData _getWeatherIcon(String? condition) {
    if (condition == null) return Icons.cloud;

    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return Icons.wb_sunny;
      case 'rain':
      case 'rainy':
      case 'drizzle':
        return Icons.beach_access;
      case 'thunderstorm':
        return Icons.flash_on;
      case 'snow':
        return Icons.ac_unit;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.cloud;
      default:
        return Icons.cloud;
    }
  }

  // Get weather background gradient based on condition
  List<Color> _getWeatherGradient(String? condition) {
    if (condition == null) {
      return [const Color(0xFF1E88E5), const Color(0xFF3686FF)];
    }
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return [
          const Color(0xFFFFA726),
          const Color(0xFFFF7043)
        ]; // Orange gradient
      case 'rain':
      case 'rainy':
      case 'drizzle':
        return [
          const Color(0xFF42A5F5),
          const Color(0xFF1976D2)
        ]; // Blue gradient
      case 'thunderstorm':
        return [
          const Color(0xFF5E35B1),
          const Color(0xFF3949AB)
        ]; // Purple-blue gradient
      case 'snow':
        return [
          const Color(0xFF78909C),
          const Color(0xFF546E7A)
        ]; // Gray-blue gradient
      case 'clouds':
      case 'partly cloudy':
      case 'mostly cloudy':
        return [
          const Color(0xFF5C6BC0),
          const Color(0xFF3949AB)
        ]; // Indigo gradient
      default:
        return [
          const Color(0xFF1E88E5),
          const Color(0xFF3686FF)
        ]; // Default blue gradient
    }
  }

  // Get crop advice based on weather
  String _getCropAdvice(Map<String, dynamic>? weatherData) {
    if (weatherData == null || !weatherData.containsKey('currentWeather')) {
      return 'Check weather for farming advice';
    }
    final currentWeather = weatherData['currentWeather'];
    final condition =
        currentWeather['condition']?.toString().toLowerCase() ?? '';
    final temp = currentWeather['temperature'] as int? ?? 0;
    final humidity = currentWeather['humidity'] as int? ?? 0;

    if (condition.contains('rain')) {
      return 'Avoid field work and protect harvested crops';
    } else if (condition.contains('clear') || condition.contains('sunny')) {
      if (temp > 35) {
        return 'Hot day - irrigate crops in the evening';
      } else if (temp > 25 && temp <= 35) {
        return 'Good day for field work and crop management';
      } else {
        return 'Ideal for crop maintenance activities';
      }
    } else if (condition.contains('cloud')) {
      return 'Good conditions for fertilizer application';
    } else if (condition.contains('mist') || condition.contains('fog')) {
      return 'Monitor for fungal diseases due to humidity';
    } else if (humidity > 80) {
      return 'High humidity - watch for pest infestations';
    } else if (humidity < 30) {
      return 'Low humidity - increase irrigation';
    }
    return 'Check weather details for farming advice';
  }

  Widget _buildWeatherCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WeatherScreen(),
          ),
        ).then((_) => _loadWeatherData()); // Refresh data when returning
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isLoadingWeather
                ? [
                    const Color(0xFF3686FF),
                    const Color(0xFF3686FF).withOpacity(0.7),
                  ]
                : _getWeatherGradient(
                    _weatherData?['currentWeather']?['condition']),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isLoadingWeather
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_weatherData?['currentWeather']?['temperature'] ?? '--'}°C',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _weatherData?['location'] ?? 'Your Location',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _weatherData?['currentWeather']?['condition'] ??
                                'Weather Data',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getCropAdvice(_weatherData),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getWeatherIcon(
                                _weatherData?['currentWeather']?['condition']),
                            color: Colors.white,
                            size: 50,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomButton(
                          text: 'View Details',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Scaffold(
                                  backgroundColor: Colors.white,
                                  body: WeatherScreen(),
                                ),
                              ),
                            ).then((_) => _loadWeatherData());
                          },
                          buttonType: ButtonType.filled,
                          backgroundColor: Colors.white,
                          textColor: const Color(0xFF3686FF),
                          height: 40,
                          width: 120,
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String title, Color color) {
    return GestureDetector(
      onTap: () {
        // Navigate based on action
      },
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Import the necessary services and models at the top if not already imported:
  // import 'package:kisan_veer/services/market_service.dart';
  // import 'package:kisan_veer/models/market_models.dart';

  Widget _buildMarketInsightsCard() {
    final MarketService _marketService = MarketService();
    return FutureBuilder<List<PinnedCommodity>>(
      future: _marketService.getPinnedCommodities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CustomCard(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return CustomCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text("No pinned commodities found."),
            ),
          );
        }
        final pinnedList = snapshot.data!;
        // Sort by percentage increase in price (descending)
        pinnedList.sort((a, b) {
          double aPercent = a.initialPrice != 0 ? ((a.currentPrice - a.initialPrice) / a.initialPrice) * 100 : 0;
          double bPercent = b.initialPrice != 0 ? ((b.currentPrice - b.initialPrice) / b.initialPrice) * 100 : 0;
          return bPercent.compareTo(aPercent);
        });
        return CustomCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: Icon(Icons.insights, color: AppColors.primary),
                title: Text(
                  'Current Market Prices',
                  style: AppTextStyles.titleMedium,
                ),
                subtitle: Text(
                  'Updated just now',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                ),
              ),
              Divider(height: 1),
              ...pinnedList.take(4).map((pinned) {
                final isProfit = ((pinned.currentPrice - pinned.initialPrice) / pinned.initialPrice) * 100 >= 0;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pinned.commodity,
                              style: AppTextStyles.bodyLarge
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            if ((pinned.market != null &&
                                pinned.market!.isNotEmpty))
                              Text(
                                pinned.market!,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: Colors.grey[700]),
                              ),
                            if ((pinned.state != null &&
                                pinned.state.isNotEmpty))
                              Text(
                                pinned.state!,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: Colors.grey[500]),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${pinned.currentPrice.toStringAsFixed(0)}',
                              style: AppTextStyles.bodyLarge
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isProfit
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                (() {
                                  double percent = pinned.initialPrice != 0 ? ((pinned.currentPrice - pinned.initialPrice) / pinned.initialPrice) * 100 : 0;
                                  String sign = percent >= 0 ? '+' : '';
                                  return '$sign${percent.toStringAsFixed(1)}%';
                                })(),
                                style: TextStyle(
                                  color: isProfit ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PriceFinderScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'View more crop prices',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGovernmentSchemesCard() {
    return CustomCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance,
                color: Colors.blue,
              ),
            ),
            title: const Text('PM-KISAN Scheme'),
            subtitle: const Text('Income support of ₹6000 per year'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to scheme details
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.water_drop_outlined,
                color: Colors.orange,
              ),
            ),
            title: const Text('Pradhan Mantri Krishi Sinchai Yojana'),
            subtitle: const Text('Irrigation support for farmers'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Navigate to scheme details
            },
          ),
          const Divider(height: 1),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              'View all schemes',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
