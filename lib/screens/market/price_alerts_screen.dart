import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/services/market_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class PriceAlertsScreen extends StatefulWidget {
  final String? initialCommodity;
  final String? initialState;
  final String? initialDistrict;
  final String? initialMarket;

  const PriceAlertsScreen({
    Key? key,
    this.initialCommodity,
    this.initialState,
    this.initialDistrict,
    this.initialMarket,
  }) : super(key: key);

  @override
  State<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends State<PriceAlertsScreen> {
  late TextEditingController _commodityController;
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedMarket;

  @override
  void initState() {
    super.initState();
    _commodityController = TextEditingController(text: widget.initialCommodity ?? '');
    _selectedState = widget.initialState;
    _selectedDistrict = widget.initialDistrict;
    _selectedMarket = widget.initialMarket;
    _loadAlerts();

    _loadStates().then((_) {
      // Ensure selected state is valid and exists in the list
      if (_selectedState != null && _states.contains(_selectedState)) {
        _loadDistricts().then((_) {
          if (_selectedDistrict != null && _districts.contains(_selectedDistrict)) {
            _loadMarkets();
          }
        });
      }
    });
  }
  final MarketService _marketService = MarketService();

  bool _isLoading = true;
  String? _errorMessage;

  // Active alerts
  List<PriceAlert> _alerts = [];

  // Form controllers

  String? _selectedCondition = 'above';
  final _priceController = TextEditingController();

  // Data lists
  List<String> _states = [];
  List<String> _districts = [];
  List<String> _markets = [];


  @override
  void dispose() {
    _commodityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final alerts = await _marketService.getPriceAlerts();

      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStates() async {
    try {
      final states = await _marketService.getStates();

      setState(() {
        _states = states;

        // Ensure selected state is valid and exists in the fetched list
        if (_selectedState != null && states.contains(_selectedState)) {
          _selectedState = _selectedState; // keep as is
        } else {
          _selectedState = null; // clear if invalid
        }
      });
    } catch (e) {
      print('Error loading states: $e');
    }
  }

  Future<void> _loadDistricts() async {
    if (_selectedState == null) return;

    try {
      final districts = await _marketService.getDistricts(_selectedState!);

      setState(() {
        _districts = districts;

        // Only reset district if it wasn't pre-selected
        if (_selectedDistrict == null || !_districts.contains(_selectedDistrict)) {
          _selectedDistrict = null;
          _markets = [];
          _selectedMarket = null;
        }


      });
    } catch (e) {
      print('Error loading districts: $e');
    }
  }

  Future<void> _loadMarkets() async {
    if (_selectedState == null || _selectedDistrict == null) return;

    try {
      final markets = await _marketService.getMarkets(
        _selectedState!,
        _selectedDistrict!,
      );

      setState(() {
        _markets = markets;

        // Only reset market if it wasn't pre-selected
        if (_selectedMarket == null || !_markets.contains(_selectedMarket)) {
          _selectedMarket = null;
        }
      });
    } catch (e) {
      print('Error loading markets: $e');
    }
  }

  Future<void> _createAlert() async {
    if (_commodityController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedState == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final price = double.tryParse(_priceController.text);
      if (price == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid price'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final alert = PriceAlert(
        id: 0.toString(), // Will be set by the database
        userId: '', // Will be set by the service
        commodity: _commodityController.text,
        state: _selectedState!,
        district: _selectedDistrict,
        market: _selectedMarket,
        alertCondition: _selectedCondition!,
        thresholdPrice: price,
        createdAt: DateTime.now(),
        lastNotified: null,
        isActive: true,
      );

      await _marketService.createPriceAlert(
        commodity: alert.commodity,
        state: alert.state,
        district: alert.district,
        market: alert.market,
        thresholdPrice: alert.thresholdPrice,
        alertCondition: alert.alertCondition,
      );

      // Reset form and refresh
      _commodityController.clear();
      _priceController.clear();

      // Close the bottom sheet
      Navigator.pop(context);

      // Refresh alerts
      _loadAlerts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Price alert created successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create alert: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteAlert(PriceAlert alert) async {
    try {
      await _marketService.deletePriceAlert(alert.id.toString());

      // Refresh alerts
      _loadAlerts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Price alert deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete alert: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleAlert(PriceAlert alert) async {
    try {
      await _marketService.updatePriceAlert(
        alertId: alert.id.toString(),
        isActive: !alert.isActive,
      );

      // Refresh alerts
      _loadAlerts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update alert: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Price Alerts'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildAlertsView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateAlertSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
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
              'Failed to load alerts',
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
              onPressed: _loadAlerts,
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
    );
  }

  Widget _buildAlertsView() {
    return _alerts.isEmpty ? _buildNoAlertsView() : _buildAlertsList();
  }

  Widget _buildNoAlertsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Price Alerts',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Create price alerts to get notified when commodity prices meet your criteria.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showCreateAlertSheet,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Create Alert'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _alerts.length,
      itemBuilder: (context, index) {
        return _buildAlertCard(_alerts[index], index);
      },
    );
  }

  Widget _buildAlertCard(PriceAlert alert, int index) {
    final dateFormat = DateFormat('MMM d, yyyy');

    String locationString = alert.state;
    if (alert.district != null) {
      locationString += ', ${alert.district}';
    }
    if (alert.market != null) {
      locationString += ', ${alert.market}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Commodity name and alert status
            Row(
              children: [
                Expanded(
                  child: Text(
                    alert.commodity,
                    style: AppTextStyles.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Switch(
                  value: alert.isActive,
                  onChanged: (_) => _toggleAlert(alert),
                  activeColor: AppColors.primary,
                ),
              ],
            ),

            // Alert condition
            Row(
              children: [
                Icon(
                  alert.condition == 'above'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  color: alert.condition == 'above' ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${alert.condition == 'above' ? 'Above' : 'Below'} ₹${alert.targetPrice.toStringAsFixed(2)}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        alert.condition == 'above' ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Location
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    locationString,
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Created date
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  'Created on ${dateFormat.format(alert.createdAt)}',
                  style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Delete button
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _deleteAlert(alert),
                icon: Icon(Icons.delete_outline,
                    color: Colors.red.shade400, size: 18),
                label: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red.shade400),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
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

  void _showCreateAlertSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Create Price Alert', style: AppTextStyles.h3),
                const SizedBox(height: 8),
                Text(
                  'Get notified when a commodity price meets your criteria.',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Commodity
                Text('Commodity', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                TextField(
                  controller: _commodityController,
                  decoration: InputDecoration(
                    labelText: 'Commodity Name',
                    hintText: 'e.g. Rice, Wheat, Tomato',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Location section
                Text('Location', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),

                // State dropdown
                DropdownButtonFormField<String>(
                  value: _states.contains(_selectedState) ? _selectedState : null,
                  items: _states.map((state) {
                    return DropdownMenuItem<String>(
                      value: state,
                      child: Text(state),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedState = value;
                    });
                    _loadDistricts();
                  },
                  decoration: InputDecoration(
                    labelText: 'State',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  hint: const Text('Select State'),
                ),
                const SizedBox(height: 16),

                // District dropdown
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'District (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  value: _selectedDistrict,
                  items: _districts.map((district) {
                    return DropdownMenuItem<String>(
                      value: district,
                      child: Text(district),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value;
                    });
                    _loadMarkets();
                  },
                  hint: const Text('Select District (Optional)'),
                ),
                const SizedBox(height: 16),

                // Market dropdown
                if (_districts.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Market (Optional)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        value: _selectedMarket,
                        items: _markets.map((market) {
                          return DropdownMenuItem<String>(
                            value: market,
                            child: Text(market),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedMarket = value;
                          });
                        },
                        hint: const Text('Select Market (Optional)'),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),

                // Alert condition
                Text('Price Condition', style: AppTextStyles.subtitle),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Condition',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        value: _selectedCondition,
                        items: const [
                          DropdownMenuItem(
                            value: 'above',
                            child: Text('Above'),
                          ),
                          DropdownMenuItem(
                            value: 'below',
                            child: Text('Below'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCondition = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: 'Price (₹)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixText: '₹ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Create button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _createAlert,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Create Alert',
                      style: AppTextStyles.buttonText.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}
