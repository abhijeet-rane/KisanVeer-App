import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/services/market_service.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:kisan_veer/screens/market/price_trend_screen.dart';

class PriceFinderScreen extends StatefulWidget {
  const PriceFinderScreen({Key? key}) : super(key: key);

  @override
  State<PriceFinderScreen> createState() => _PriceFinderScreenState();
}

class _PriceFinderScreenState extends State<PriceFinderScreen> {
  final MarketService _marketService = MarketService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _priceAlertController = TextEditingController();

  bool _isLoading = true;
  bool _isSearching = false;
  bool _hasSearched = false;
  String? _errorMessage;
  String _alertType = 'above'; // Default alert type

  // Selected values
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedMarket;
  String? _selectedCommodity;

  // Data lists
  List<String> _states = [];
  List<String> _districts = [];
  List<String> _markets = [];
  List<String> _commodities = [];

  // Search results
  List<MarketRecord> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Get list of states
      final states = await _marketService.getStates();

      setState(() {
        _states = states;

        // Default to Maharashtra if available
        if (states.contains('Maharashtra')) {
          _selectedState = 'Maharashtra';
          _loadDistricts();
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDistricts() async {
    if (_selectedState == null) return;

    try {
      setState(() {
        _isLoading = true;
        _districts = [];
        _selectedDistrict = null;
        _markets = [];
        _selectedMarket = null;
      });

      final districts = await _marketService.getDistricts(_selectedState!);

      setState(() {
        _districts = districts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading districts: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMarkets() async {
    if (_selectedState == null || _selectedDistrict == null) return;

    try {
      setState(() {
        _isLoading = true;
        _markets = [];
        _selectedMarket = null;
      });

      final markets = await _marketService.getMarkets(
        _selectedState!,
        _selectedDistrict!,
      );

      setState(() {
        _markets = markets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading markets: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCommodities() async {
    try {
      setState(() {
        _isLoading = true;
        _commodities = [];
        _selectedCommodity = null;
      });

      final commodities = await _marketService.getCommodities(
        state: _selectedState,
        district: _selectedDistrict,
        market: _selectedMarket,
      );

      setState(() {
        _commodities = commodities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading commodities: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchPrices() async {
    if (_selectedState == null) {
      setState(() {
        _errorMessage = 'Please select a state';
      });
      return;
    }

    try {
      setState(() {
        _isSearching = true;
        _hasSearched = true;
        _errorMessage = null;
      });

      Map<String, String> filters = {
        'state': _selectedState!,
      };

      if (_selectedDistrict != null) {
        filters['district'] = _selectedDistrict!;
      }

      if (_selectedMarket != null) {
        filters['market'] = _selectedMarket!;
      }

      if (_selectedCommodity != null) {
        filters['commodity'] = _selectedCommodity!;
      } else if (_searchController.text.isNotEmpty) {
        filters['commodity'] = _searchController.text;
      }

      final response = await _marketService.fetchMarketData(filters: filters);

      setState(() {
        _searchResults = response.records;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Price Finder'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Search filters
        _buildSearchFilters(),

        // Error message if any
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Card(
              color: Colors.red.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade400),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Results section
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _hasSearched
                  ? _searchResults.isEmpty
                      ? _buildNoResultsView()
                      : _buildSearchResults()
                  : _buildInitialView(),
        ),
      ],
    );
  }

  Widget _buildSearchFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location section
          Text('Location', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),

          // State, District, Market selectors
          Row(
            children: [
              // State dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(right: 4),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'State',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    isExpanded: true,
                    value: _selectedState,
                    items: _states.map((state) {
                      return DropdownMenuItem<String>(
                        value: state,
                        child: Text(
                          state,
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedState = value;
                      });
                      _loadDistricts();
                      _loadCommodities();
                    },
                  ),
                ),
              ),

              // District dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'District',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    isExpanded: true,
                    value: _selectedDistrict,
                    items: _districts.map((district) {
                      return DropdownMenuItem<String>(
                        value: district,
                        child: Text(
                          district,
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedDistrict = value;
                      });
                      _loadMarkets();
                      _loadCommodities();
                    },
                    hint: Text(
                      'Any',
                      style:
                          AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                    ),
                  ),
                ),
              ),

              // Market dropdown
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(left: 4),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Market',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    isExpanded: true,
                    value: _selectedMarket,
                    items: _markets.map((market) {
                      return DropdownMenuItem<String>(
                        value: market,
                        child: Text(
                          market,
                          style: AppTextStyles.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedMarket = value;
                      });
                      _loadCommodities();
                    },
                    hint: Text(
                      'Any',
                      style:
                          AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Commodity selector
          Text('Commodity', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          Row(
            children: [
              // Commodity dropdown
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Select Commodity',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  isExpanded: true,
                  value: _selectedCommodity,
                  items: _commodities.map((commodity) {
                    return DropdownMenuItem<String>(
                      value: commodity,
                      child: Text(
                        commodity,
                        style: AppTextStyles.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCommodity = value;
                      _searchController.clear();
                    });
                  },
                  hint: Text(
                    'Select a commodity',
                    style:
                        AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                  ),
                ),
              ),
              const Text('  OR  '),
              // Search by text
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Commodity',
                    hintText: 'e.g. Rice, Wheat',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  ),
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _selectedCommodity = null;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _searchPrices,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.search, color: Colors.white),
              label: Text(
                'Search Prices',
                style: AppTextStyles.buttonText.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PriceTrendScreen(
                      initialState: _selectedState,
                      initialDistrict: _selectedDistrict,
                      initialMarket: _selectedMarket,
                      initialCommodity: _selectedCommodity ?? _searchController.text,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.show_chart, color: Colors.white),
              label: Text(
                'View Price Trends',
                style: AppTextStyles.buttonText.copyWith(
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Find Latest Commodity Prices',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a location and commodity to get the latest market prices.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Results Found',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Try adjusting your search criteria or select a different commodity.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    String locationString = _selectedState ?? '';
    if (_selectedDistrict != null) {
      locationString += ', $_selectedDistrict';
    }
    if (_selectedMarket != null) {
      locationString += ', $_selectedMarket';
    }

    String commodityString = _selectedCommodity ?? _searchController.text;

    return Column(
      children: [
        // Info bar
        Container(
          width: double.infinity,
          color: Colors.grey.shade100,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Showing ${_searchResults.length} results',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      commodityString.isNotEmpty
                          ? 'Prices for "$commodityString"'
                          : 'All commodities',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '(as of ${DateFormat('dd MMM yyyy').format(DateTime.now())})',
                    style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              Text(
                'in $locationString',
                style: AppTextStyles.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // Results list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final record = _searchResults[index];
              return _buildResultCard(record, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(MarketRecord record, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Commodity name and price
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Commodity info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.commodity,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${record.variety} (${record.grade})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Price
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '₹${record.modalPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'per Qtl',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 16),

            // Market info
            Row(
              children: [
                Icon(Icons.store, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${record.market}, ${record.district}, ${record.state}',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Date and quantity
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  record.arrivalDateFormatted,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(width: 12),
              ],
            ),
            const SizedBox(height: 4),

            // Price range
            Row(
              children: [
                Text(
                  'Range: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
                Text(
                  '₹${record.minPrice.toStringAsFixed(2)} - ₹${record.maxPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Pin button
                IconButton(
                  onPressed: () => _pinCommodity(record),
                  icon: const Icon(Icons.push_pin_outlined, size: 18),
                  tooltip: 'Pin',
                  color: AppColors.primary,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                // Alert button
                IconButton(
                  onPressed: () => _createPriceAlert(record),
                  icon: const Icon(Icons.notifications_outlined, size: 18),
                  tooltip: 'Set Alert',
                  color: AppColors.primary,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(8),
                ),
                // Trends button
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon,
      {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pinCommodity(MarketRecord record) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to be logged in to pin commodities'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // Use modalPrice, fallback to minPrice or maxPrice if modalPrice is 0
      double price = record.modalPrice;
      if (price == 0.0) {
        price = record.minPrice != 0.0 ? record.minPrice : record.maxPrice;
      }
      await _marketService.pinCommodity(
        commodity: record.commodity,
        state: record.state,
        district: record.district,
        market: record.market,
        currentPrice: price,
      );

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${record.commodity} pinned successfully'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Pinned',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/pinned_commodities');
              },
            )),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error pinning commodity: ${e.toString()}';
      });
    }
  }

  Future<void> _createPriceAlert(MarketRecord record) async {
    final userId = _authService.currentUser?.id;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to be logged in to set price alerts'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show dialog to set price alert threshold
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Price Alert for ${record.commodity}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Current price: ₹${record.modalPrice.toStringAsFixed(2)} per Quintal',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  children: [
                    // Alert type selector
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Above'),
                            value: 'above',
                            groupValue: _alertType,
                            onChanged: (value) {
                              setDialogState(() {
                                _alertType = value!;
                              });
                            },
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Below'),
                            value: 'below',
                            groupValue: _alertType,
                            onChanged: (value) {
                              setDialogState(() {
                                _alertType = value!;
                              });
                            },
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                    // Price threshold input
                    TextField(
                      controller: _priceAlertController,
                      decoration: InputDecoration(
                        labelText: 'Price Threshold (₹)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final priceThreshold =
                  double.tryParse(_priceAlertController.text);
              if (priceThreshold == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid price'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context, {
                'type': _alertType,
                'threshold': priceThreshold,
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Set Alert'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        setState(() {
          _isLoading = true;
        });

        await _marketService.createPriceAlert(
          commodity: record.commodity,
          state: record.state,
          district: record.district,
          market: record.market,
          alertCondition: result['type'],
          thresholdPrice: result['threshold'],
        );

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Price alert set for ${record.commodity} ${result['type']} ₹${result['threshold'].toStringAsFixed(2)}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error creating price alert: ${e.toString()}';
        });
      }
    }
  }
}
