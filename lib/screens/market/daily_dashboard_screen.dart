import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/services/market_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 daily market dashboard.
///
/// Summary of the day's top commodities, most volatile markets, and
/// leading states by arrivals. Charts stay fl_chart-powered but the
/// surrounding chrome (cards, headers, error states) uses v2 tokens.
class DailyDashboardScreen extends StatefulWidget {
  const DailyDashboardScreen({super.key});

  @override
  State<DailyDashboardScreen> createState() => _DailyDashboardScreenState();
}

class _DailyDashboardScreenState extends State<DailyDashboardScreen> {
  final MarketService _marketService = MarketService();

  bool _isLoading = true;
  String? _errorMessage;
  DailyMarketSummary? _summary;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final summary = await _marketService.getDailyMarketSummary();
      if (!mounted) return;
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Daily dashboard load failed', tag: 'DailyDash', error: e);
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Daily dashboard',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _loadDashboardData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const AppLoadingState(message: 'Loading market data…')
          : _errorMessage != null
          ? AppErrorState(
              title: 'Could not load market data',
              message: _errorMessage,
              onRetry: _loadDashboardData,
            )
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    final summary = _summary!;
    String dateLine;
    try {
      dateLine = DateFormat(
        'EEEE, d MMMM yyyy',
      ).format(DateFormat('dd/MM/yyyy').parse(summary.date));
    } catch (_) {
      dateLine = summary.date;
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: AppColors.primary,
      child: ListView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.all(AppSpacing.space16),
        children: [
          _DateBanner(dateLine: dateLine),
          const SizedBox(height: AppSpacing.space20),
          _ChartSection(
            title: 'Top commodities',
            subtitle: 'By average price in ₹ per quintal',
            chart: SizedBox(
              height: 240,
              child: _TopCommoditiesChart(commodities: summary.topCommodities),
            ),
          ).animate().fadeIn(duration: AppMotion.slow),
          const SizedBox(height: AppSpacing.space20),
          _VolatilityCard(markets: summary.topVolatileMarkets).animate().fadeIn(
            duration: AppMotion.slow,
            delay: const Duration(milliseconds: 100),
          ),
          if (summary.stateArrivals.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space20),
            _ChartSection(
              title: 'Top states by arrivals',
              subtitle: 'Quantity in quintals',
              chart: SizedBox(
                height: 240,
                child: _StateArrivalsChart(
                  states: summary.stateArrivals.take(5).toList(),
                ),
              ),
            ).animate().fadeIn(
              duration: AppMotion.slow,
              delay: const Duration(milliseconds: 200),
            ),
          ],
          const SizedBox(height: AppSpacing.space24),
        ],
      ),
    );
  }
}

class _DateBanner extends StatelessWidget {
  const _DateBanner({required this.dateLine});

  final String dateLine;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.6),
              borderRadius: AppRadii.brMd,
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Market data for',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLine,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.title,
    required this.subtitle,
    required this.chart,
  });

  final String title;
  final String subtitle;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          chart,
        ],
      ),
    );
  }
}

class _TopCommoditiesChart extends StatelessWidget {
  const _TopCommoditiesChart({required this.commodities});

  final List<CommoditySummary> commodities;

  @override
  Widget build(BuildContext context) {
    if (commodities.isEmpty) {
      return const Center(
        child: Text(
          'No commodity data',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: commodities.first.averagePrice * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1000,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.space8),
                child: Text(
                  value.toInt().toString(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= commodities.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space8),
                  child: RotatedBox(
                    quarterTurns: 1,
                    child: Text(
                      commodities[idx].commodity,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < commodities.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: commodities[i].averagePrice,
                  color: AppColors.primary,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadii.xs),
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 500),
    );
  }
}

class _StateArrivalsChart extends StatelessWidget {
  const _StateArrivalsChart({required this.states});

  final List<StateArrival> states;

  @override
  Widget build(BuildContext context) {
    if (states.isEmpty) {
      return const Center(
        child: Text(
          'No arrivals data',
          style: TextStyle(color: AppColors.onSurfaceVariant),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: states.first.totalQuantity * 1.2,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1000,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.outlineVariant, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.space8),
                child: Text(
                  '${(value / 1000).toStringAsFixed(1)}K',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= states.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.space8),
                  child: Text(
                    states[idx].state,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (int i = 0; i < states.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: states[i].totalQuantity,
                  color: AppColors.tertiary,
                  width: 18,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadii.xs),
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 500),
    );
  }
}

class _VolatilityCard extends StatelessWidget {
  const _VolatilityCard({required this.markets});

  final List<MarketVolatility> markets;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Most volatile markets',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Where prices swung the most today',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.space16),
          if (markets.isEmpty)
            Text(
              'No volatile markets for today',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            )
          else
            for (int i = 0; i < markets.length; i++) ...[
              _VolatilityRow(rank: i + 1, market: markets[i]),
              if (i < markets.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.space8),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.outlineVariant,
                  ),
                ),
            ],
        ],
      ),
    );
  }
}

class _VolatilityRow extends StatelessWidget {
  const _VolatilityRow({required this.rank, required this.market});

  final int rank;
  final MarketVolatility market;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadii.brFull,
          ),
          child: Text(
            '$rank',
            style: AppTextStyles.labelLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.space12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      market.commodity,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '±₹${market.volatility.toStringAsFixed(0)}',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'at ${market.marketName}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Range: ₹${market.minPrice.toStringAsFixed(0)} – ₹${market.maxPrice.toStringAsFixed(0)}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
