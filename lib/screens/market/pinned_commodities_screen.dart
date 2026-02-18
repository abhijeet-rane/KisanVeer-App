import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/screens/market/price_alerts_screen.dart';
import 'package:kisan_veer/screens/market/price_finder_screen.dart';
import 'package:kisan_veer/services/market_service.dart';
import 'package:kisan_veer/screens/market/price_trend_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class PinnedCommoditiesScreen extends StatefulWidget {
  const PinnedCommoditiesScreen({Key? key}) : super(key: key);

  @override
  State<PinnedCommoditiesScreen> createState() =>
      _PinnedCommoditiesScreenState();
}

class _PinnedCommoditiesScreenState extends State<PinnedCommoditiesScreen> {
  final MarketService _marketService = MarketService();

  bool _isLoading = true;
  String? _errorMessage;

  // Pinned commodities
  List<PinnedCommodity> _pinnedCommodities = [];

  @override
  void initState() {
    super.initState();
    _loadPinnedCommodities();
    _updatePinnedCommodities();
  }

  Future<void> _loadPinnedCommodities() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final commodities = await _marketService.getPinnedCommodities();

      setState(() {
        _pinnedCommodities = commodities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePinnedCommodities() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _marketService.updatePinnedCommodityPrices();
      await _loadPinnedCommodities();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Prices updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update prices: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _unpinCommodity(String commodityId) async {
    try {
      await _marketService.unpinCommodity(commodityId);

      // Refresh the list
      _loadPinnedCommodities();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commodity unpinned successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to unpin commodity: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Pinned Commodities'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updatePinnedCommodities,
            tooltip: 'Update prices',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _updatePinnedCommodities,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PriceFinderScreen(),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        tooltip: 'Add Commodity',
      ),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _updatePinnedCommodities,
      child: _errorMessage != null
          ? _buildErrorView()
          : _pinnedCommodities.isEmpty
              ? _buildEmptyView()
              : _buildCommoditiesList(),
    );
  }

  Widget _buildErrorView() {
    return SingleChildScrollView(
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
                  'Failed to load pinned commodities',
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
                  onPressed: _loadPinnedCommodities,
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
    );
  }

  Widget _buildEmptyView() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height - 100,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.push_pin_outlined,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 24),
                Text(
                  'No Pinned Commodities',
                  style: AppTextStyles.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Pin your favorite commodities to track their price changes daily.',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PriceFinderScreen(),
                      ),
                    ).then((_) => _loadPinnedCommodities());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Commodity'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCommoditiesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pinnedCommodities.length,
      itemBuilder: (context, index) {
        return _buildCommodityCard(_pinnedCommodities[index], index);
      },
    );
  }

  Widget _buildCommodityCard(PinnedCommodity commodity, int index) {
    final priceChange = commodity.currentPrice - commodity.initialPrice;
    final percentChange = (priceChange / commodity.initialPrice) * 100;
    final isPositive = priceChange >= 0;

    String locationString = commodity.state;
    if (commodity.district != null && commodity.district!.isNotEmpty) {
      locationString += ', ${commodity.district}';
    }
    if (commodity.market != null && commodity.market!.isNotEmpty) {
      locationString += ', ${commodity.market}';
    }

    final lastUpdated =
        DateFormat('dd MMM, h:mm a').format(commodity.lastUpdated);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to price trend screen for this commodity
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PriceTrendScreen(),
              // Pass commodity data for showing trends
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Commodity name and price change
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          commodity.commodity,
                          style: AppTextStyles.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locationString,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isPositive
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: isPositive ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(2)}%',
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPositive ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${priceChange.abs().toStringAsFixed(2)}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Current price and initial price
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Price',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '₹${commodity.currentPrice.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Initial Price',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          '₹${commodity.initialPrice.toStringAsFixed(2)}',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Last Updated',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          lastUpdated,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Set alert button
                  SizedBox(
                    width: 110, // Fixed width to prevent layout issues
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PriceAlertsScreen(
                              initialCommodity: commodity.commodity,
                              initialState: commodity.state,
                              initialDistrict: commodity.district,
                              initialMarket: commodity.market,
                            ),
                          ),
                        );
                      },

                      icon: const Icon(Icons.notifications_outlined, size: 18),
                      label: const Text('Set Alert'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // View trends button
                  SizedBox(
                    width: 122, // Fixed width to prevent layout issues
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Navigate to price trends for this commodity
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PriceTrendScreen(
                              initialCommodity: commodity.commodity,
                              initialState: commodity.state,
                              initialDistrict: commodity.district,
                              initialMarket: commodity.market,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.show_chart, size: 18),
                      label: const Text('View Trends'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Unpin button
                  IconButton(
                    onPressed: () => _showUnpinDialog(commodity),
                    icon: const Icon(Icons.push_pin),
                    color: Colors.grey,
                    tooltip: 'Unpin commodity',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: 50 * index),
        )
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
          delay: Duration(milliseconds: 50 * index),
          curve: Curves.easeOutQuad,
        );
  }

  void _showUnpinDialog(PinnedCommodity commodity) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpin Commodity'),
        content: Text(
          'Are you sure you want to unpin ${commodity.commodity}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _unpinCommodity(commodity.id);
            },
            child: const Text('Unpin'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
