import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/services/market_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class SmartRecommendationsScreen extends StatefulWidget {
  const SmartRecommendationsScreen({Key? key}) : super(key: key);

  @override
  State<SmartRecommendationsScreen> createState() => _SmartRecommendationsScreenState();
}

class _SmartRecommendationsScreenState extends State<SmartRecommendationsScreen> {
  final MarketService _marketService = MarketService();
  
  bool _isLoading = true;
  String? _errorMessage;
  
  // User preferences
  String? _selectedState;
  List<String> _selectedCrops = [];
  
  // Data lists
  List<String> _states = [];
  List<String> _availableCrops = [];
  
  // Recommendations
  List<CropRecommendation> _recommendations = [];
  
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
      
      // Get states and user preferences
      final states = await _marketService.getStates();
      final userPrefs = await _marketService.getUserPreferences();
      
      setState(() {
        _states = states;
        
        // Set default state to user's state or Maharashtra if available
        final preferredState = userPrefs['preferred_state'] as String?;
        if (preferredState != null && preferredState.isNotEmpty) {
          _selectedState = preferredState;
        } else if (states.contains('Maharashtra')) {
          _selectedState = 'Maharashtra';
        } else if (states.isNotEmpty) {
          _selectedState = states.first;
        }
        
        // Set user's selected crops
        _selectedCrops = List<String>.from(userPrefs['preferred_crops'] ?? []);
        
        _isLoading = false;
      });
      
      // Load available crops for the selected state
      if (_selectedState != null) {
        _loadAvailableCrops();
      }
      
      // Generate recommendations if state is selected
      if (_selectedState != null) {
        _generateRecommendations();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadAvailableCrops() async {
    if (_selectedState == null) return;
    
    try {
      setState(() {
        _isLoading = true;
      });
      
      final crops = await _marketService.getCommodities(state: _selectedState);
      
      setState(() {
        _availableCrops = crops;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading crops: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _generateRecommendations() async {
    if (_selectedState == null) {
      setState(() {
        _errorMessage = 'Please select a state';
      });
      return;
    }
    
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      final recommendations = await _marketService.getCropRecommendations(
        state: _selectedState!,
        userCrops: _selectedCrops,
      );
      
      setState(() {
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<void> _savePreferences() async {
    try {
      await _marketService.updateUserPreferences(
        preferredState: _selectedState ?? '',
        preferredCrops: _selectedCrops,
        priceSensitivity: 'medium',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save preferences: $e'),
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
        title: const Text('Smart Recommendations'),
        backgroundColor: AppColors.primary,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _generateRecommendations,
            tooltip: 'Refresh recommendations',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }
  
  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _generateRecommendations,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preferences card
            _buildPreferencesCard(),
            
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
            
            // Recommendations
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Recommendations Based on Price Trends',
                style: AppTextStyles.h3,
              ),
            ),
            _recommendations.isEmpty
                ? _buildNoRecommendationsView()
                : _buildRecommendationsList(),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPreferencesCard() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your Preferences', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            Text(
              'Select your state and crops of interest to get personalized recommendations',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // State dropdown
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Your State',
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
                _loadAvailableCrops();
              },
              hint: const Text('Select your state'),
            ),
            const SizedBox(height: 16),
            
            // Crops selection
            Text('Your Crops of Interest', style: AppTextStyles.bodyMedium),
            const SizedBox(height: 8),
            if (_availableCrops.isEmpty)
              Text(
                'Select a state first to see available crops',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableCrops.map((crop) {
                  final isSelected = _selectedCrops.contains(crop);
                  return FilterChip(
                    selected: isSelected,
                    label: Text(crop),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          if (!_selectedCrops.contains(crop)) {
                            _selectedCrops.add(crop);
                          }
                        } else {
                          _selectedCrops.remove(crop);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                    backgroundColor: Colors.grey.shade100,
                  );
                }).toList(),
              ),
            const SizedBox(height: 16),
            
            // Save button
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _savePreferences,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Save Preferences'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _generateRecommendations,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Generate Recommendations'),
                  ),
                ),
              ],
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
  
  Widget _buildNoRecommendationsView() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.eco_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'No Recommendations Yet',
              style: AppTextStyles.h3.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Select your state and crops of interest, then click "Generate Recommendations" to get personalized suggestions.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecommendationsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _recommendations.length,
      itemBuilder: (context, index) {
        return _buildRecommendationCard(_recommendations[index], index);
      },
    );
  }
  
  Widget _buildRecommendationCard(CropRecommendation recommendation, int index) {
    final isPositiveTrend = _isPositivePriceTrend(recommendation.priceTrend);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with crop name and action
            Row(
              children: [
                Text(
                  recommendation.commodityName ?? recommendation.commodity,
                  style: AppTextStyles.h3,
                ),
                const Spacer(),
                // Pin button
                SizedBox(
                  width: 91,
                  height: 35,// Fixed width to prevent layout issues
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Implement pinning functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Commodity pinned successfully'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.push_pin_outlined, size: 17),
                    label: const Text('Pin'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Confidence tag
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: _getConfidenceColor(recommendation.confidenceScore ?? 0.0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _getConfidenceColor(recommendation.confidenceScore ?? 0.0),
                ),
              ),
              child: Text(
                'Confidence: ${_getConfidenceLabel(recommendation.confidenceScore ?? 0.0)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: _getConfidenceColor(recommendation.confidenceScore ?? 0.0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Price trend
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
                        '₹${recommendation.currentPrice?.toStringAsFixed(2) ?? '0.00'}/Qtl',
                        style: AppTextStyles.h3.copyWith(
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
                        '30-Day Trend',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            isPositiveTrend
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: isPositiveTrend
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${isPositiveTrend ? '+' : ''}${_formatPriceTrend(recommendation.priceTrend)}%',
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isPositiveTrend
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Mini chart
            SizedBox(
              height: 100,
              child: _buildMiniTrendChart(recommendation),
            ),
            const SizedBox(height: 16),
            
            // Recommendation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getBackgroundColor(recommendation.recommendation ?? ''),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getRecommendationIcon(recommendation.recommendation ?? ''),
                    color: _getIconColor(recommendation.recommendation ?? ''),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      recommendation.recommendationText ?? 'No recommendation available',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Reasoning
            Text(
              'Market Analysis',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 8),
            Text(
              recommendation.reasoningText ?? 'No detailed analysis available.',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(
      duration: 300.ms,
      delay: Duration(milliseconds: 100 * index),
    ).slideY(
      begin: 0.1,
      end: 0,
      duration: 300.ms,
      delay: Duration(milliseconds: 100 * index),
      curve: Curves.easeOutQuad,
    );
  }
  
  bool _isPositivePriceTrend(dynamic priceTrend) {
    if (priceTrend == null) return false;
    
    if (priceTrend is double) {
      return priceTrend > 0;
    } else if (priceTrend is int) {
      return priceTrend > 0;
    } else if (priceTrend is String) {
      // Check for 'up' or 'positive' strings
      if (priceTrend.toLowerCase() == 'up' || priceTrend.toLowerCase() == 'positive') {
        return true;
      }
      
      // Try to parse as double
      try {
        return double.parse(priceTrend) > 0;
      } catch (_) {
        // If not parseable, default to false
        return false;
      }
    }
    
    return false;
  }

  String _formatPriceTrend(dynamic priceTrend) {
    if (priceTrend == null) return '0.00';
    
    if (priceTrend is double) {
      return priceTrend.toStringAsFixed(2);
    } else if (priceTrend is int) {
      return priceTrend.toStringAsFixed(2);
    } else if (priceTrend is String) {
      // Try to parse as double if it's a numeric string
      try {
        return double.parse(priceTrend).toStringAsFixed(2);
      } catch (_) {
        // If it's not a numeric string, just return it
        return priceTrend;
      }
    }
    
    return '0.00';
  }

  Widget _buildMiniTrendChart(CropRecommendation recommendation) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          drawHorizontalLine: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: recommendation.priceHistory?.isNotEmpty == true ? (recommendation.priceHistory!.length - 1.0) : 0,
        minY: recommendation.priceHistory?.isNotEmpty == true 
            ? (recommendation.priceHistory!.reduce((a, b) => a < b ? a : b) * 0.9)
            : 0,
        maxY: recommendation.priceHistory?.isNotEmpty == true 
            ? (recommendation.priceHistory!.reduce((a, b) => a > b ? a : b) * 1.1)
            : 100,
        lineBarsData: [
          LineChartBarData(
            spots: recommendation.priceHistory?.isNotEmpty == true 
                ? List.generate(recommendation.priceHistory!.length, (index) {
                    return FlSpot(
                      index.toDouble(),
                      recommendation.priceHistory![index],
                    );
                  })
                : [FlSpot(0, 0)],
            isCurved: true,
            color: AppColors.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),
        ],
        lineTouchData: LineTouchData(enabled: false),
      ),
      // Animation duration parameter removed as it's not supported in this version
    );
  }
  
  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green.shade700;
    } else if (confidence >= 0.6) {
      return Colors.green.shade500;
    } else if (confidence >= 0.4) {
      return Colors.orange.shade500;
    } else {
      return Colors.red.shade500;
    }
  }
  
  String _getConfidenceLabel(double confidence) {
    if (confidence >= 0.8) {
      return 'Very High';
    } else if (confidence >= 0.6) {
      return 'High';
    } else if (confidence >= 0.4) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }
  
  Color _getBackgroundColor(String recommendation) {
    switch (recommendation.toLowerCase()) {
      case 'buy':
        return Colors.green.shade50;
      case 'sell':
        return Colors.red.shade50;
      case 'hold':
        return Colors.amber.shade50;
      case 'watch':
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade50;
    }
  }
  
  Color _getIconColor(String recommendation) {
    switch (recommendation.toLowerCase()) {
      case 'buy':
        return Colors.green.shade700;
      case 'sell':
        return Colors.red.shade700;
      case 'hold':
        return Colors.amber.shade700;
      case 'watch':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }
  
  IconData _getRecommendationIcon(String recommendation) {
    switch (recommendation.toLowerCase()) {
      case 'buy':
        return Icons.shopping_cart;
      case 'sell':
        return Icons.attach_money;
      case 'hold':
        return Icons.access_time;
      case 'watch':
        return Icons.visibility;
      default:
        return Icons.info_outline;
    }
  }
}
