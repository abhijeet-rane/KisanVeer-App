import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/sensor_service.dart';

const Map<String, Map<String, int>> cropMoistureThresholds = {
  'Cotton': {'min': 35, 'max': 60},
  'Soybean': {'min': 30, 'max': 60},
  'Sugarcane': {'min': 50, 'max': 80},
  'Wheat': {'min': 40, 'max': 60},
  'Rice': {'min': 60, 'max': 80},
  'Chickpea': {'min': 25, 'max': 50},
};

class GasSensorMonitorScreen extends StatefulWidget {
  const GasSensorMonitorScreen({Key? key}) : super(key: key);

  @override
  State<GasSensorMonitorScreen> createState() => _GasSensorMonitorScreenState();
}

class _GasSensorMonitorScreenState extends State<GasSensorMonitorScreen> {
  static const Duration refreshInterval = Duration(seconds: 5);
  Timer? _timer;
  Map<String, dynamic>? _latestData;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _hasError = false;
  String _selectedCrop = 'Cotton';

  @override
  void initState() {
    super.initState();
    _fetchData(initial: true);
    _timer = Timer.periodic(refreshInterval, (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData({bool initial = false}) async {
    if (initial) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    } else {
      setState(() {
        _isRefreshing = true;
      });
    }
    try {
      final latest = await SensorService.fetchLatestSensorData();
      final history = await SensorService.fetchSensorHistory(count: 10);
      setState(() {
        _latestData = latest;
        _history = history;
        _isLoading = false;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Color _getStatusColor(int value) {
    if (value <= 300) return Colors.green;
    if (value <= 600) return Colors.yellow.shade700;
    return Colors.red;
  }

  String _getStatusText(int value) {
    if (value <= 300) return 'Safe';
    if (value <= 600) return 'Warning';
    return 'Dangerous';
  }

  bool _isLive() {
    if (_latestData == null) return false;
    final String? tsStr = _latestData!['created_at'] ?? _latestData!['timestamp'];
    if (tsStr == null) return false;
    final DateTime ts = DateTime.parse(tsStr);
    return DateTime.now().difference(ts).inSeconds <= 10;
  }

  Color _getMoistureColor(int value) {
    if (value >= 700) return Colors.blue; // Very wet
    if (value >= 400) return Colors.green; // Optimal
    if (value >= 200) return Colors.orange; // Slightly dry
    return Colors.red; // Very dry
  }

  String _getMoistureStatus(int value) {
    final thresholds = cropMoistureThresholds[_selectedCrop]!;
    if (value < thresholds['min']!) {
      return 'Very Dry – Water immediately!';
    } else if (value > thresholds['max']!) {
      return 'Too Wet – Avoid irrigation!';
    } else {
      return 'Optimal – No irrigation needed!';
    }
  }

  int? _parseInt(Map<String, dynamic>? map, String key) {
    if (map == null) return null;
    final value = map[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Widget _buildLivePanel() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return const Center(child: Text('Failed to load data.'));
    }
    if (_latestData == null) {
      return const Center(child: Text('No sensor data available.'));
    }
    final int mq2Value = _parseInt(_latestData, 'mq2') ?? _parseInt(_latestData, 'mq2_value') ?? 0;
    final int moistureValue = _parseInt(_latestData, 'moisture') ?? 0;
    final String timeStr = DateFormat('hh:mm:ss a, dd MMM')
        .format(DateTime.parse(_latestData!['created_at'] ?? _latestData!['timestamp']));
    final Color statusColor = _getStatusColor(mq2Value);
    final String statusText = _getStatusText(mq2Value);
    final bool isLive = _isLive();
    final Color moistureColor = _getMoistureColor(moistureValue);
    final String moistureStatus = _getMoistureStatus(moistureValue);
    print("Live moisture value: $moistureValue, status: $moistureStatus, crop: $_selectedCrop");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Crop selection dropdown
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Row(
            children: [
              const Text('Crop:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              DropdownButton<String>(
                value: _selectedCrop,
                items: cropMoistureThresholds.keys.map((crop) {
                  return DropdownMenuItem<String>(
                    value: crop,
                    child: Text(crop),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCrop = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.grass, color: moistureColor),
                    const SizedBox(width: 10),
                    const Text('Soil Moisture',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 10),
                Text('Current: $moistureValue%',
                    style: TextStyle(
                        color: moistureColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 24)),
                const SizedBox(height: 6),
                Text(
                  moistureStatus,
                  style: TextStyle(
                    color: moistureColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text('Threshold for $_selectedCrop: '
                    '${cropMoistureThresholds[_selectedCrop]!['min']}% - '
                    '${cropMoistureThresholds[_selectedCrop]!['max']}%',
                    style: const TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 4),
                Text('Last updated: $timeStr',
                    style: const TextStyle(fontSize: 12, color: Colors.black54)),
              ],
            ),
          ),
        ),
        Stack(
          children: [
            Card(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              color: statusColor.withOpacity(0.12),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.sensors, color: statusColor, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Real-Time\nAir Quality',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                        if ((!isLive &&
                            !_isLoading &&
                            (_latestData == null ||
                                mq2Value == 0)))
                          Row(
                            children: const [
                              Icon(Icons.error, color: Colors.red, size: 18),
                              SizedBox(width: 4),
                              Text('No Data',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          mq2Value.toString(),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 18),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusText,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              timeStr,
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black54),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (mq2Value > 600)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Row(
                          children: const [
                            Icon(Icons.warning, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'High Gas Concentration Detected!',
                              style: TextStyle(
                                  color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            if (_isRefreshing)
              Positioned(
                top: 16,
                right: 16,
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: statusColor),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistoryGraph() {
    // Line chart for recent gas sensor readings
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.show_chart, color: Colors.green),
                SizedBox(width: 10),
                Text('Recent Air Quality Readings',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            _history.isEmpty
                ? const Text('No historical data.')
                : SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData:
                            FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 48,
                              getTitlesWidget: (value, meta) {
                                // Show vertical axis labels at 200, 400, 600, 800, etc.
                                if (value % 200 == 0) {
                                  return Text(value.toInt().toString(),
                                      style: const TextStyle(fontSize: 12));
                                }
                                return const SizedBox.shrink();
                              },
                              interval: 200,
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
                                int idx = value.toInt();
                                if (idx < 0 || idx >= _history.length)
                                  return const SizedBox.shrink();
                                final String time = DateFormat('HH:mm').format(
                                    DateTime.parse(_history[idx]['created_at'] ?? _history[idx]['timestamp'] ?? ''));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(time,
                                      style: const TextStyle(fontSize: 10)),
                                );
                              },
                              interval: 1,
                              reservedSize: 32,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.black12)),
                        minX: 0,
                        maxX: (_history.length - 1).toDouble(),
                        minY: 0,
                        maxY: [
                          (_history
                                  .map((e) => _parseInt(e, 'mq2')?.toDouble() ?? _parseInt(e, 'mq2_value')?.toDouble() ?? 0)
                                  .reduce((a, b) => a > b ? a : b)
                                  + 20),
                          800.0
                        ].reduce((a, b) => a > b ? a : b), // always at least 800 for better scaling
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < _history.length; i++)
                                FlSpot(
                                    i.toDouble(),
                                    _parseInt(_history[i], 'mq2')?.toDouble() ?? _parseInt(_history[i], 'mq2_value')?.toDouble() ?? 0),
                            ],
                            isCurved: true,
                            color: Colors.green.shade700,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                                show: true,
                                color: Colors.green.withOpacity(0.2)),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoistureHistoryGraph() {
    // Line chart for recent soil moisture readings
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.show_chart, color: Colors.blue),
                SizedBox(width: 10),
                Text('Recent Soil Moisture Readings',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 10),
            _history.isEmpty
                ? const Text('No historical data.')
                : SizedBox(
                    height: 180,
                    child: LineChart(
                      LineChartData(
                        gridData:
                            FlGridData(show: true, drawVerticalLine: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 48,
                              getTitlesWidget: (value, meta) {
                                // Show Y-axis as percentage
                                if (value % 20 == 0 && value >= 0 && value <= 100) {
                                  return Text('${value.toInt()}%',
                                      style: const TextStyle(fontSize: 12));
                                }
                                return const SizedBox.shrink();
                              },
                              interval: 20,
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
                                int idx = value.toInt();
                                if (idx < 0 || idx >= _history.length)
                                  return const SizedBox.shrink();
                                final String time = DateFormat('HH:mm').format(
                                    DateTime.parse(_history[idx]['created_at'] ?? _history[idx]['timestamp'] ?? ''));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(time,
                                      style: const TextStyle(fontSize: 10)),
                                );
                              },
                              interval: 1,
                              reservedSize: 32,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                            show: true,
                            border: Border.all(color: Colors.black12)),
                        minX: 0,
                        maxX: (_history.length - 1).toDouble(),
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              for (int i = 0; i < _history.length; i++)
                                FlSpot(
                                    i.toDouble(),
                                    _parseInt(_history[i], 'moisture')?.toDouble() ?? 0),
                            ],
                            isCurved: true,
                            color: Colors.blue.shade700,
                            barWidth: 3,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                                show: true,
                                color: Colors.blue.withOpacity(0.2)),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Farm Monitor'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      backgroundColor: Colors.green.shade50,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildLivePanel(),
            _buildHistoryGraph(),
            _buildMoistureHistoryGraph(),
          ],
        ),
      ),
    );
  }
}
