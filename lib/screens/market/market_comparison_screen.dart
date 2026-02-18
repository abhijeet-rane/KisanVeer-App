import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/services/market_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';


class MarketComparisonScreen extends StatefulWidget {
  const MarketComparisonScreen({Key? key}) : super(key: key);

  @override
  State<MarketComparisonScreen> createState() => _MarketComparisonScreenState();
}

class _MarketComparisonScreenState extends State<MarketComparisonScreen> {
  final MarketService _marketService = MarketService();
  
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;
  
  // Selected values
  String? _selectedCommodity;
  String? _selectedState;
  late List<String> _selectedMarkets = [];
  
  // Data lists
  List<String> _commodities = [];
  List<String> _availableMarkets = [];
  
  // Comparison data
  List<MarketComparison> _comparisonData = [];
  
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
      
      // Get list of states
      final states = await _marketService.getStates();
      
      // Set default state if available
      if (states.isNotEmpty) {
        _selectedState = states.first;
      }
      
      // Get list of commodities
      final commodities = await _marketService.getCommodities();
      
      setState(() {
        _commodities = commodities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadMarketsForCommodity() async {
    if (_selectedCommodity == null) return;
    
    try {
      setState(() {
        _isLoading = true;
        _selectedMarkets.clear();
        _availableMarkets = [];
      });
      
      final markets = await _marketService.getMarketsForCommodity(_selectedCommodity!);
      
      setState(() {
        _availableMarkets = markets;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading markets: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _compareMarkets() async {
    if (_selectedCommodity == null || _selectedMarkets.length < 2) {
      setState(() {
        _errorMessage = 'Please select a commodity and at least two markets';
      });
      return;
    }
    
    try {
      setState(() {
        _isSearching = true;
        _errorMessage = null;
      });
      
      final comparison = await _marketService.compareMarkets(
        commodity: _selectedCommodity!,
        markets: _selectedMarkets,
        state: _selectedState!, // Added missing required parameter
      );
      
      setState(() {
        _comparisonData = comparison;
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
        title: const Text('Market Comparison'),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selection card
          _buildSelectionCard(),
          
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
          
          // Results
          if (_isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_comparisonData.isNotEmpty)
            _buildComparisonResults()
          else if (_selectedCommodity != null && _selectedMarkets.length >= 2)
            _buildNoDataView()
        ],
      ),
    );
  }
  
  Widget _buildSelectionCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compare Commodity Prices', style: AppTextStyles.subtitle),
            const SizedBox(height: 16),
            
            // Commodity dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Commodity',
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
                  _selectedMarkets.clear();
                  _comparisonData = [];
                });
                _loadMarketsForCommodity();
              },
              hint: const Text('Select a commodity'),
            ),
            const SizedBox(height: 24),
            
            // Markets section
            if (_availableMarkets.isNotEmpty) ...[
              Text('Select Markets to Compare', style: AppTextStyles.subtitle),
              const SizedBox(height: 8),
              Text(
                'Choose at least 2 markets for comparison',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              
              // Markets selection
              MultiSelectDialogField(
                items: _availableMarkets.map((market) => MultiSelectItem(market, market)).toList(),
                title: const Text("Markets"),
                selectedColor: AppColors.primary,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.shade400,
                    width: 1,
                  ),
                ),
                buttonIcon: const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.grey,
                ),
                buttonText: const Text(
                  "Select Markets",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                  ),
                ),
                onConfirm: (results) {
                  setState(() {
                    _selectedMarkets = List<String>.from(results);
                  });
                },
                initialValue: _selectedMarkets,
              ),

              const SizedBox(height: 24),
              
              // Compare button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedMarkets.length >= 2 ? _compareMarkets : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    'Compare Markets',
                    style: AppTextStyles.buttonText.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
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
  
  Widget _buildComparisonResults() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Comparison for $_selectedCommodity',
            style: AppTextStyles.h3,
          ),
          const SizedBox(height: 4),
          Text(
            'Data as of ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          // Price comparison chart
          _buildPriceChart(),
          const SizedBox(height: 24),
          
          // Comparison table
          _buildComparisonTable(),
          
          // Best market recommendation
          const SizedBox(height: 24),
          _buildBestMarketCard(),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(
      begin: 0.1,
      end: 0,
      duration: 500.ms,
      curve: Curves.easeOutQuad,
    );
  }
  
  Widget _buildPriceChart() {
    // Filter out markets with no data
    final marketsWithData = _comparisonData.where((m) => m.hasData).toList();
    
    // If no markets have data, show a message instead of a chart
    if (marketsWithData.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bar_chart,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No price data available for chart',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Calculate min and max prices for Y axis
    final prices = marketsWithData.map((e) => e.modalPrice).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b) * 0.9;
    final maxPrice = prices.reduce((a, b) => a > b ? a : b) * 1.1;
    
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxPrice,
          minY: minPrice,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: Colors.grey.shade200, width: 1),
          ),
          titlesData: FlTitlesData(
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
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value >= marketsWithData.length || value < 0) {
                    return const SizedBox.shrink();
                  }
                  final market = marketsWithData[value.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        market.market,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          barGroups: List.generate(
            marketsWithData.length,
            (index) {
              final market = marketsWithData[index];
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: market.modalPrice,
                    color: _getBarColor(index),
                    width: 20,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(4),
                    ),
                  ),
                ],
              );
            },
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final market = marketsWithData[group.x.toInt()];
                return BarTooltipItem(
                  '${market.market}\n',
                  AppTextStyles.bodySmall.copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '₹${market.modalPrice.toStringAsFixed(2)}/Qtl',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _getBarColor(group.x.toInt()),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 500),
      ),
    );
  }
  
  Color _getBarColor(int index) {
    final colors = [
      AppColors.primary,
      Colors.teal,
      Colors.amber.shade700,
      Colors.purple,
      Colors.green.shade600,
      Colors.blue.shade600,
      Colors.orange.shade600,
      Colors.pink.shade300,
    ];
    
    return colors[index % colors.length];
  }
  
  Widget _buildComparisonTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detailed Comparison', style: AppTextStyles.subtitle),
            const SizedBox(height: 16),
            
            // Table header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Market',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Min Price',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Max Price',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Modal Price',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            
            // Table rows
            ...List.generate(
              _comparisonData.length,
              (index) => _buildTableRow(_comparisonData[index], index),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTableRow(MarketComparison market, int index) {
    // If market has no data, display a special row
    if (!market.hasData) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.grey.shade400,
                      size: 16,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      market.market,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                'No data available',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
    
    // For markets with data, sort by modal price
    final marketsWithData = _comparisonData.where((m) => m.hasData).toList();
    marketsWithData.sort((a, b) => a.modalPrice.compareTo(b.modalPrice));
    
    // Find the index of the current market among markets with data
    int sortedIndex = marketsWithData.indexOf(market);
    bool isLowest = sortedIndex == 0;
    bool isHighest = sortedIndex == marketsWithData.length - 1;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isLowest 
            ? Colors.green.shade50 
            : isHighest 
                ? Colors.red.shade50 
                : null,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                if (isLowest)
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Icon(
                      Icons.arrow_downward,
                      color: Colors.green,
                      size: 16,
                    ),
                  )
                else if (isHighest)
                  Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: Icon(
                      Icons.arrow_upward,
                      color: Colors.red,
                      size: 16,
                    ),
                  ),
                Expanded(
                  child: Text(
                    market.market,
                    style: AppTextStyles.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              '₹${market.minPrice.toStringAsFixed(0)}',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '₹${market.maxPrice.toStringAsFixed(0)}',
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              '₹${market.modalPrice.toStringAsFixed(0)}',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: isLowest 
                    ? Colors.green 
                    : isHighest 
                        ? Colors.red 
                        : null,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBestMarketCard() {
    // Filter out markets with no data
    final marketsWithData = _comparisonData.where((m) => m.hasData).toList();
    
    // If no markets have data, show a special card
    if (marketsWithData.isEmpty) {
      return Card(
        elevation: 2,
        color: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.grey.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Market Insight',
                    style: AppTextStyles.subtitle.copyWith(
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'No price data available for $_selectedCommodity in the selected markets.',
                style: AppTextStyles.bodyMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'Try selecting different markets or check back later for updated price information.',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
    
    // Sort the comparisons by modal price to find the highest (best for selling)
    marketsWithData.sort((a, b) => b.modalPrice.compareTo(a.modalPrice));
    final highestMarket = marketsWithData.first;
    final lowestMarket = marketsWithData.last;
    
    final priceDifference = highestMarket.modalPrice - lowestMarket.modalPrice;
    final percentageDifference = (priceDifference / lowestMarket.modalPrice) * 100;
    
    return Card(
      elevation: 2,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights,
                  color: Colors.amber.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'Market Insight for Farmers',
                  style: AppTextStyles.subtitle.copyWith(
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Best Market to Sell $_selectedCommodity:',
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              highestMarket.market,
              style: AppTextStyles.h3.copyWith(
                color: Colors.amber.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Price Comparison Analysis:',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Highest Price:',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '₹${highestMarket.modalPrice.toStringAsFixed(2)}/Qtl',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      Text(
                        'at ${highestMarket.market}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lowest Price:',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        '₹${lowestMarket.modalPrice.toStringAsFixed(2)}/Qtl',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        'at ${lowestMarket.market}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.currency_rupee,
                    color: Colors.amber.shade700,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.black,
                        ),
                        children: [
                          const TextSpan(
                            text: 'You can earn ',
                          ),
                          TextSpan(
                            text: '₹${priceDifference.toStringAsFixed(2)}/Qtl',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                          const TextSpan(
                            text: ' (approx. ',
                          ),
                          TextSpan(
                            text: '${percentageDifference.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                          const TextSpan(
                            text: ') more by selling at the highest-priced market!',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
              Icons.compare_arrows,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No Comparison Data Available',
              style: AppTextStyles.h3.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'No market data found for the selected commodity and markets.\nTry selecting different markets or another commodity.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
