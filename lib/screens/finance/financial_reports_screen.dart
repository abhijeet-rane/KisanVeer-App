import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/financial_service.dart';

class FinancialReportsScreen extends StatefulWidget {
  const FinancialReportsScreen({Key? key}) : super(key: key);

  @override
  _FinancialReportsScreenState createState() => _FinancialReportsScreenState();
}

class _FinancialReportsScreenState extends State<FinancialReportsScreen> {
  final FinancialService _financialService = FinancialService();
  bool _isLoading = true;
  Map<String, double> _monthlyTotals = {};
  Map<String, List<double>> _trends = {};
  int _selectedMonths = 6;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final monthlyData =
          await _financialService.getMonthlyTotals(DateTime.now());
      final trendsData =
          await _financialService.getMonthlyTrends(_selectedMonths);

      setState(() {
        _monthlyTotals = {
          'income': monthlyData['income'] ?? 0.0,
          'expense': monthlyData['expense'] ?? 0.0,
          'balance': (monthlyData['income'] ?? 0.0) - (monthlyData['expense'] ?? 0.0),
        };
        _trends = trendsData;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading financial data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Financial Reports'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMonthlyOverview(),
                  SizedBox(height: 24),
                  _buildTrendsChart(),
                  SizedBox(height: 24),
                  _buildMonthSelector(),
                ],
              ),
            ),
    );
  }

  Widget _buildMonthlyOverview() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Overview',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Divider(),
            _buildOverviewItem(
              'Total Income',
              _monthlyTotals['income'] ?? 0,
              Colors.green,
              Icons.arrow_upward,
            ),
            SizedBox(height: 12),
            _buildOverviewItem(
              'Total Expenses',
              _monthlyTotals['expense'] ?? 0,
              Colors.red,
              Icons.arrow_downward,
            ),
            Divider(),
            _buildOverviewItem(
              'Net Balance',
              _monthlyTotals['balance'] ?? 0,
              (_monthlyTotals['balance'] ?? 0) >= 0 ? Colors.green : Colors.red,
              (_monthlyTotals['balance'] ?? 0) >= 0
                  ? Icons.trending_up
                  : Icons.trending_down,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(
      String label, double amount, Color color, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsChart() {
    if (_trends.isEmpty ||
        !_trends.containsKey('income') ||
        !_trends.containsKey('expense')) {
      return _buildEmptyCard();
    }

    final incomeData = _trends['income'] as List<double>;
    final expenseData = _trends['expense'] as List<double>;

    if (incomeData.isEmpty || expenseData.isEmpty) {
      return _buildEmptyCard();
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Income vs Expenses Trend',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 24),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.isFinite && !value.isNaN) {
                            int intValue = value.toInt();
                            if (intValue >= 0 &&
                                intValue < _selectedMonths) {
                              final date = DateTime.now().subtract(
                                Duration(
                                    days: 30 *
                                        (_selectedMonths - value.toInt() - 1)),
                              );
                              return Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text(
                                  '${date.month}/${date.year.toString()
                                      .substring(2)}',
                                  style: TextStyle(fontSize: 10),
                                ),
                              );
                            }
                          }
                          return Text('');
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  minX: 0,
                  maxX: (_selectedMonths - 1).toDouble(),
                  minY: 0,
                  maxY: [
                        ...incomeData,
                        ...expenseData,
                      ].reduce((max, value) => value > max ? value : max) *
                      1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        _selectedMonths,
                        (index) => FlSpot(index.toDouble(), incomeData[index]),
                      ),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 2,
                      dotData: FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: List.generate(
                        _selectedMonths,
                        (index) => FlSpot(index.toDouble(), expenseData[index]),
                      ),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 2,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Income', Colors.green),
                SizedBox(width: 24),
                _buildLegendItem('Expenses', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text('No trend data available'),
        ),
      ),
    );
  }

  LineChartBarData _createLineBarsData(
      List<double> data, Color color, String label) {
    return LineChartBarData(
      spots: List.generate(
        data.length,
        (index) => FlSpot(index.toDouble(), data[index]),
      ),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: true),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Period',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            DropdownButton<int>(
              value: _selectedMonths,
              isExpanded: true,
              items: [3, 6, 12].map((months) {
                return DropdownMenuItem<int>(
                  value: months,
                  child: Text('Last $months months'),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMonths = value;
                  });
                  _loadData();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
