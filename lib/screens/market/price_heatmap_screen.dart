import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/services/market_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PriceHeatmapScreen extends StatefulWidget {
  const PriceHeatmapScreen({Key? key}) : super(key: key);

  @override
  State<PriceHeatmapScreen> createState() => _PriceHeatmapScreenState();
}

class _PriceHeatmapScreenState extends State<PriceHeatmapScreen> {
  final MarketService _marketService = MarketService();
  final MapController _mapController = MapController();

  bool _isLoading = true;
  bool _isGeneratingHeatmap = false;
  String? _errorMessage;

  // Selected values
  String? _selectedCommodity;

  // Data lists
  List<String> _commodities = [];

  // Heatmap data
  List<CommodityPriceMap> _heatmapData = [];

  // State coordinates map
  final Map<String, LatLng> _stateCoordinates = {
    'Andhra Pradesh': LatLng(15.9129, 79.7400),
    'Arunachal Pradesh': LatLng(28.2180, 94.7278),
    'Assam': LatLng(26.2006, 92.9376),
    'Bihar': LatLng(25.0961, 85.3131),
    'Chhattisgarh': LatLng(21.2787, 81.8661),
    'Goa': LatLng(15.2993, 74.1240),
    'Gujarat': LatLng(22.2587, 71.1924),
    'Haryana': LatLng(29.0588, 76.0856),
    'Himachal Pradesh': LatLng(31.1048, 77.1734),
    'Jharkhand': LatLng(23.6102, 85.2799),
    'Karnataka': LatLng(15.3173, 75.7139),
    'Kerala': LatLng(10.8505, 76.2711),
    'Madhya Pradesh': LatLng(22.9734, 78.6569),
    'Maharashtra': LatLng(19.7515, 75.7139),
    'Manipur': LatLng(24.6637, 93.9063),
    'Meghalaya': LatLng(25.4670, 91.3662),
    'Mizoram': LatLng(23.1645, 92.9376),
    'Nagaland': LatLng(26.1584, 94.5624),
    'Odisha': LatLng(20.9517, 85.0985),
    'Punjab': LatLng(31.1471, 75.3412),
    'Rajasthan': LatLng(27.0238, 74.2179),
    'Sikkim': LatLng(27.5330, 88.5122),
    'Tamil Nadu': LatLng(11.1271, 78.6569),
    'Telangana': LatLng(18.1124, 79.0193),
    'Tripura': LatLng(23.9408, 91.9882),
    'Uttar Pradesh': LatLng(26.8467, 80.9462),
    'Uttarakhand': LatLng(30.0668, 79.0193),
    'West Bengal': LatLng(22.9868, 87.8550),
    'Delhi': LatLng(28.7041, 77.1025),
  };

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

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

  Future<void> _generateHeatmap() async {
    if (_selectedCommodity == null) {
      setState(() {
        _errorMessage = 'Please select a commodity';
      });
      return;
    }

    try {
      setState(() {
        _isGeneratingHeatmap = true;
        _errorMessage = null;
      });

      final data =
          await _marketService.getCommodityPriceMap(_selectedCommodity!);

      setState(() {
        _heatmapData = data;
        _isGeneratingHeatmap = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isGeneratingHeatmap = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Crop Price Heatmap'),
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

        // Results section
        Expanded(
          child: _isGeneratingHeatmap
              ? const Center(child: CircularProgressIndicator())
              : _heatmapData.isEmpty
                  ? _buildInitialView()
                  : _buildHeatmapView(),
        ),
      ],
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
            Text('View Price Distribution', style: AppTextStyles.subtitle),
            const SizedBox(height: 8),
            Text(
              'Select a commodity to see its price distribution across states',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.grey),
            ),
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
                });
              },
              hint: const Text('Select a commodity'),
            ),
            const SizedBox(height: 16),

            // Generate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedCommodity != null ? _generateHeatmap : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: Text(
                  'Generate Heatmap',
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

  Widget _buildInitialView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              'Price Heatmap Visualization',
              style: AppTextStyles.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Select a commodity and generate a heatmap to visualize price variations across different states.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeatmapView() {
    // Find min and max prices for the color scale
    double minPrice = double.infinity;
    double maxPrice = 0;

    for (var data in _heatmapData) {
      if (data.averagePrice < minPrice) minPrice = data.averagePrice;
      if (data.averagePrice > maxPrice) maxPrice = data.averagePrice;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Price Heatmap for $_selectedCommodity',
                  style: AppTextStyles.h3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.info_outline),
                onPressed: _showInfoDialog,
              ),
            ],
          ),
        ),

        // Legend
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildPriceLegend(minPrice, maxPrice),
        ),
        const SizedBox(height: 4),
        // Map
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(22.5937, 78.9629), // Center of India
                  initialZoom: 4.5,
                  maxZoom: 10.0,
                  minZoom: 3.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.kisan.veer.app',
                  ),
                  MarkerLayer(
                    markers: _buildMarkers(minPrice, maxPrice),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      child: const Text(
                        '© OpenStreetMap contributors',
                        style: TextStyle(fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),

              // Zoom controls
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  children: [
                    FloatingActionButton.small(
                      heroTag: 'zoomIn',
                      onPressed: () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom + 0.5,
                        );
                      },
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'zoomOut',
                      onPressed: () {
                        _mapController.move(
                          _mapController.camera.center,
                          _mapController.camera.zoom - 0.5,
                        );
                      },
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      child: const Icon(Icons.remove),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // State price list
        SizedBox(
          height: 140,
          child: _buildStatePriceList(),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(
          begin: 0.1,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutQuad,
        );
  }

  List<Marker> _buildMarkers(double minPrice, double maxPrice) {
    final markers = <Marker>[];

    for (var data in _heatmapData) {
      final coordinates = _stateCoordinates[data.state];
      if (coordinates != null) {
        final color = _getPriceColor(data.averagePrice, minPrice, maxPrice);

        markers.add(
          Marker(
            point: coordinates,
            width: 50,
            height: 50,
            child: GestureDetector(
              onTap: () {
                _showStateDetails(data);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '₹${data.averagePrice.toInt()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  Color _getPriceColor(double price, double minPrice, double maxPrice) {
    // Normalize price between 0 and 1
    final normalized = (price - minPrice) / (maxPrice - minPrice);

    // Color gradient from green to red
    if (normalized < 0.25) {
      return Colors.green.shade700;
    } else if (normalized < 0.5) {
      return Colors.green.shade500;
    } else if (normalized < 0.75) {
      return Colors.orange.shade500;
    } else {
      return Colors.red.shade500;
    }
  }

  Widget _buildPriceLegend(double minPrice, double maxPrice) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Price Range:',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 16,
            height: 16,
            color: Colors.green.shade700,
          ),
          Flexible(
            child: Container(
              height: 16,
              width: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade700,
                    Colors.green.shade500,
                    Colors.orange.shade500,
                    Colors.red.shade500,
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 16,
            height: 16,
            color: Colors.red.shade500,
          ),
          const SizedBox(width: 8),
          Text(
            '₹${minPrice.toInt()}',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(' - '),
          Text(
            '₹${maxPrice.toInt()}',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.red.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatePriceList() {
    // Sort states by price
    _heatmapData.sort((a, b) => a.averagePrice.compareTo(b.averagePrice));

    return Card(
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Price by State (Lowest to Highest)',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 3),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _heatmapData.length,
                itemBuilder: (context, index) {
                  final data = _heatmapData[index];
                  final minPrice = _heatmapData.first.averagePrice;
                  final maxPrice = _heatmapData.last.averagePrice;
                  final color =
                      _getPriceColor(data.averagePrice, minPrice, maxPrice);

                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.only(left: 7, right: 5, top: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.state,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        Text(
                          '₹${data.averagePrice.toStringAsFixed(2)}/Qtl',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStateDetails(CommodityPriceMap data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(data.state, style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$_selectedCommodity Price',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '₹${data.averagePrice.toStringAsFixed(2)}',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '/Qtl',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Data Sample Size',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 4),
            Text(
              '${data.count} market records',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Note: This is the average price across all markets in ${data.state}.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
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

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About Price Heatmap', style: AppTextStyles.h3),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This heatmap shows the average price of $_selectedCommodity across different states in India.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Color Key:',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Lower prices'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: Colors.green.shade500,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Below average prices'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: Colors.orange.shade500,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Above average prices'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  color: Colors.red.shade500,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Higher prices'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Data Source:',
              style: AppTextStyles.subtitle,
            ),
            const SizedBox(height: 4),
            const Text(
              'AGMARKNET - A Government of India Portal for Agricultural Marketing Information',
            ),
            const SizedBox(height: 16),
            Text(
              'Note: The prices shown are averaged across all markets in each state.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
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
