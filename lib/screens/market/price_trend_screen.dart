import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/services/market_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class PriceTrendScreen extends StatefulWidget {
  final String? initialCommodity;
  final String? initialState;
  final String? initialDistrict;
  final String? initialMarket;

  const PriceTrendScreen({
    Key? key,
    this.initialCommodity,
    this.initialState,
    this.initialDistrict,
    this.initialMarket,
  }) : super(key: key);

  @override
  State<PriceTrendScreen> createState() => _PriceTrendScreenState();
}

class _PriceTrendScreenState extends State<PriceTrendScreen> {
  final MarketService _marketService = MarketService();

  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;

  // Selected values
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedMarket;
  String? _selectedCommodity;
  int _selectedDays = 7; // Default to 7 days

  // Data lists
  List<String> _states = [];
  List<String> _districts = [];
  List<String> _markets = [];
  List<String> _commodities = [];

  // Trend data
  List<PriceTrend> _trendData = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Map) {
      setState(() {
        if (args['state'] != null) _selectedState = args['state'];
        if (args['district'] != null) _selectedDistrict = args['district'];
        if (args['market'] != null) _selectedMarket = args['market'];
        if (args['commodity'] != null) _selectedCommodity = args['commodity'];
      });
    }
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final states = await _marketService.getStates();

      _states = states;

      if (widget.initialState != null &&
          _states.contains(widget.initialState)) {
        _selectedState = widget.initialState;
      } else if (_states.contains('Maharashtra')) {
        _selectedState = 'Maharashtra';
      }

      if (_selectedState != null) {
        await _loadDistricts();
        if (widget.initialDistrict != null &&
            _districts.contains(widget.initialDistrict)) {
          _selectedDistrict = widget.initialDistrict;
          await _loadMarkets();
          if (widget.initialMarket != null &&
              _markets.contains(widget.initialMarket)) {
            _selectedMarket = widget.initialMarket;
          }
        }
        await _loadCommodities();
        if (widget.initialCommodity != null &&
            _commodities.contains(widget.initialCommodity)) {
          _selectedCommodity = widget.initialCommodity;
        }
      }

      setState(() {
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
        _commodities = [];
        _selectedCommodity = null;
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
        _commodities = [];
        _selectedCommodity = null;
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

  Future<void> _loadPriceTrend() async {
    if (_selectedState == null || _selectedCommodity == null) {
      setState(() {
        _errorMessage = 'Please select a state and commodity';
      });
      return;
    }

    try {
      setState(() {
        _isSearching = true;
        _errorMessage = null;
      });

      final trends = await _marketService.getPriceTrends(
        commodity: _selectedCommodity!,
        state: _selectedState!,
        district: _selectedDistrict,
        market: _selectedMarket,
        days: _selectedDays,
      );

      setState(() {
        _trendData = trends;
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
        title: const Text('Price Trend Visualization'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters card
          _buildFiltersCard(),

          // Error message if any
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
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

          // Period selector
          const SizedBox(height: 16),
          Text('Select Period', style: AppTextStyles.subtitle),
          const SizedBox(height: 8),
          _buildPeriodSelector(),

          // Trend chart
          const SizedBox(height: 24),
          if (_isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_trendData.isNotEmpty)
            _buildTrendChart()
          else if (_selectedCommodity != null)
            _buildNoDataView()
        ],
      ),
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Location & Commodity', style: AppTextStyles.subtitle),
            const SizedBox(height: 16),

            // State dropdown
            DropdownButtonFormField<String>(
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
              value: _selectedState,
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
                _loadCommodities();
              },
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
                _loadCommodities();
              },
              hint: const Text('Select District (Optional)'),
            ),
            const SizedBox(height: 16),

            // Market dropdown (only if district is selected)
            if (_selectedDistrict != null)
              Column(
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
                      _loadCommodities();
                    },
                    hint: const Text('Select Market (Optional)'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),

            // Commodity dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Commodity',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 0,
                  vertical: 12,
                ),
              ),
              value: _selectedCommodity,
              items: _commodities.map((commodity) {
                return DropdownMenuItem<String>(
                  value: commodity,
                  child: Text(commodity),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCommodity = value;
                });
              },
              hint: const Text('Select Commodity'),
            ),
            const SizedBox(height: 24),

            // Search button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadPriceTrend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'View Price Trend',
                  style: AppTextStyles.buttonText.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
          begin: 0.1,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildPeriodSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _periodButton(7, '7 Days'),
        _periodButton(14, '14 Days'),
        _periodButton(30, '30 Days'),
      ],
    );
  }

  Widget _periodButton(int days, String label) {
    final isSelected = _selectedDays == days;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedDays = days;
        });
        if (_selectedState != null && _selectedCommodity != null) {
          _loadPriceTrend();
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isSelected ? Colors.white : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendChart() {
    // Calculate min and max prices for Y axis
    final prices = _trendData.map((e) => e.price).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b) * 0.9;
    final maxPrice = prices.reduce((a, b) => a > b ? a : b) * 1.1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          children: [
            Expanded(
              child: Text(
                'Price Trend for $_selectedCommodity',
                style: AppTextStyles.h3,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _showInfoDialog();
              },
            ),
          ],
        ),

        // Subtitle with location
        Text(
          _buildLocationString(),
          style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        // Chart
        SizedBox(
          height: 300,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    drawHorizontalLine: true,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          if (value.toInt() >= _trendData.length) {
                            return const SizedBox.shrink();
                          }
                          final date = _trendData[value.toInt()].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              DateFormat('d MMM').format(date),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              value.toInt().toString(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  minX: 0,
                  maxX: _trendData.length - 1.0,
                  minY: minPrice,
                  maxY: maxPrice,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(_trendData.length, (index) {
                        return FlSpot(
                          index.toDouble(),
                          _trendData[index].price,
                        );
                      }),
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipRoundedRadius: 8,
                      getTooltipItems: (List<LineBarSpot> lineBarsSpot) {
                        return lineBarsSpot.map((lineBarSpot) {
                          final index = lineBarSpot.x.toInt();
                          if (index >= _trendData.length) {
                            return null;
                          }
                          final trend = _trendData[index];
                          return LineTooltipItem(
                            '${DateFormat('dd MMM').format(trend.date)}\n',
                            AppTextStyles.bodySmall.copyWith(
                              color: Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    '₹${trend.price.toStringAsFixed(2)}/Qtl\n',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text:
                                    'Qty: ${trend.quantity.toStringAsFixed(0)} Qtl',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
                // Animation duration handled by fl_chart internally
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Price statistics
        _buildPriceStatistics(),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(
          begin: 0.1,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutQuad,
        );
  }

  Widget _buildPriceStatistics() {
    if (_trendData.isEmpty) return const SizedBox.shrink();

    // Calculate statistics
    final prices = _trendData.map((e) => e.price).toList();
    final avgPrice = prices.reduce((a, b) => a + b) / prices.length;
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);

    // Calculate price change
    final firstPrice = _trendData.first.price;
    final lastPrice = _trendData.last.price;
    final priceChange = lastPrice - firstPrice;
    final priceChangePercent = (priceChange / firstPrice) * 100;

    final isPositive = priceChange >= 0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price Statistics', style: AppTextStyles.subtitle),
            const SizedBox(height: 16),

            // Price change
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price Change (${_selectedDays} days)',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
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
                            '₹${priceChange.abs().toStringAsFixed(2)} (${priceChangePercent.abs().toStringAsFixed(2)}%)',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isPositive ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Price',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '₹${avgPrice.toStringAsFixed(2)}/Qtl',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Min and Max
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minimum Price',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '₹${minPrice.toStringAsFixed(2)}/Qtl',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
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
                        'Maximum Price',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '₹${maxPrice.toStringAsFixed(2)}/Qtl',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Price Data Available',
              style: AppTextStyles.h3.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No price data found for the selected criteria.\nTry a different commodity or location.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _buildLocationString() {
    String location = _selectedState ?? '';

    if (_selectedDistrict != null && _selectedDistrict!.isNotEmpty) {
      location += ', $_selectedDistrict';
    }

    if (_selectedMarket != null && _selectedMarket!.isNotEmpty) {
      location += ', $_selectedMarket';
    }

    return location;
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About Price Trends', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This chart shows the daily modal price trend for $_selectedCommodity over the selected period.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Data Source:',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 4),
            Text(
              'AGMARKNET - A Government of India Portal for Agricultural Marketing Information',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Note: Market data is subject to availability from the source. Some days may not have recorded prices.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
