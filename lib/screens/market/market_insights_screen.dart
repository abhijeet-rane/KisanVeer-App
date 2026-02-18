import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/screens/market/daily_dashboard_screen.dart';
import 'package:kisan_veer/screens/market/pinned_commodities_screen.dart';
import 'package:kisan_veer/screens/market/price_finder_screen.dart';
import 'package:kisan_veer/screens/market/price_trend_screen.dart';
import 'package:kisan_veer/screens/market/price_alerts_screen.dart';
import 'package:kisan_veer/screens/market/smart_recommendations_screen.dart';
import 'package:kisan_veer/screens/market/price_heatmap_screen.dart';
import 'package:kisan_veer/screens/market/market_comparison_screen.dart';
import 'package:kisan_veer/services/market_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MarketInsightsScreen extends StatefulWidget {
  const MarketInsightsScreen({Key? key}) : super(key: key);

  @override
  State<MarketInsightsScreen> createState() => _MarketInsightsScreenState();
}

class _MarketInsightsScreenState extends State<MarketInsightsScreen> {
  final MarketService _marketService = MarketService();
  bool _isLoading = true;
  String? _errorMessage;

  // Data for popular commodities
  List<PinnedCommodity> _pinnedCommodities = [];


  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get daily market summary for top commodities
      final summary = await _marketService.getDailyMarketSummary();
      final pinned = await _marketService.getPinnedCommodities();


      setState(() {
        _pinnedCommodities = pinned;
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildMainView(),
    );
  }

  Widget _buildErrorView() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load market data',
                    style: AppTextStyles.h3,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage ?? 'Unknown error',
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadInitialData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainView() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(),

            // Quick actions
            _buildQuickActions(),

            // Top commodities
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Popular Commodities',
                style: AppTextStyles.h3,
              ),
            ),
            _buildTopCommodities(),

            // Feature cards
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
              child: Text(
                'Market Insights Features',
                style: AppTextStyles.h3,
              ),
            ),
            _buildFeatureCards(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 8),
              Text(
                'Market Insights',
                style: AppTextStyles.h2.copyWith(color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Track real-time agricultural market prices, trends, and insights to make informed decisions for your farming business.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: Colors.white.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _quickActionButton(
                    icon: Icons.dashboard,
                    label: 'Dashboard',
                    iconColor: Colors.orange,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DailyDashboardScreen(),
                      ),
                    ),
                  ),
                  _quickActionButton(
                    icon: Icons.location_on,
                    label: 'Find Prices',
                    iconColor: Colors.red,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PriceFinderScreen(),
                      ),
                    ),
                  ),
                  _quickActionButton(
                    icon: Icons.trending_up,
                    label: 'Trends',
                    iconColor: Colors.green,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PriceTrendScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap, required MaterialColor iconColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCommodities() {
    if (_pinnedCommodities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text('No pinned commodity data available'),
        ),
      );
    }

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: _pinnedCommodities.length,
        itemBuilder: (context, index) {
          final commodity = _pinnedCommodities[index];
          return _pinnedCommodityCard(commodity, index);
        },
      ),
    );
  }


  Widget _pinnedCommodityCard(PinnedCommodity commodity, [int index = 0]) {
    String marketLocation = commodity.market ?? '';
    if (commodity.district != null && commodity.district!.isNotEmpty) {
      marketLocation = '${commodity.district}, $marketLocation';
    }

    return Container(
      width: 160,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              commodity.commodity,
              style: AppTextStyles.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.currency_rupee,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${commodity.currentPrice.toStringAsFixed(2)}/Qtl',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              marketLocation,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms * index).slideX(
      begin: 0.1,
      end: 0,
      curve: Curves.easeOutQuad,
      duration: 300.ms,
      delay: 100.ms * index,
    );
  }


  Widget _buildFeatureCards() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 0,
      childAspectRatio: 0.9,
      children: [
        _featureCard(
          title: 'Daily Dashboard',
          description: 'Get daily summary of mandi data',
          icon: Icons.dashboard,
          iconColor: Colors.orange,
          index: 0,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DailyDashboardScreen(),
            ),
          ),
        ),
        _featureCard(
          title: 'Price Finder',
          description: 'Find prices by location',
          icon: Icons.location_on,
          iconColor: Colors.red,
          index: 1,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PriceFinderScreen(),
            ),
          ),
        ),
        _featureCard(
          title: 'Price Trends',
          description: 'Visualize price trends',
          icon: Icons.trending_up,
          iconColor: Colors.green,
          index: 2,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PriceTrendScreen(),
            ),
          ),
        ),
        _featureCard(
          title: 'Price Alerts',
          description: 'Get notified when prices change',
          icon: Icons.notifications_active,
          iconColor: Colors.purple,
          index: 3,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PriceAlertsScreen(),
            ),
          ),
        ),
        _featureCard(
          title: 'Recommendation',
          description: 'Get smart crop recommendations',
          icon: Icons.lightbulb,
          iconColor: Colors.amber,
          index: 4,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SmartRecommendationsScreen(),
            ),
          ),
        ),
        _featureCard(
          title: 'Price Heatmap',
          description: 'View prices across regions',
          icon: Icons.map,
          iconColor: Colors.blue,
          index: 5,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PriceHeatmapScreen(),
            ),
          ),
        ),
        _featureCard(
          title: 'Market Comparison',
          description: 'Compare prices across markets',
          icon: Icons.compare_arrows,
          iconColor: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MarketComparisonScreen(),
            ),
          ),
        ),
        _featureCard(
          title: 'Pinned Commodities',
          description: 'Track your favorite commodities',
          icon: Icons.push_pin,
          iconColor: Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PinnedCommoditiesScreen(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _featureCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    int index = 0,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: 10.2),
              Text(
                title,
                style: AppTextStyles.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms, delay: 100.ms * index);
  }
}
