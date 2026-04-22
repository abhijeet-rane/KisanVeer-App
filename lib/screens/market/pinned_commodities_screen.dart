import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/screens/market/price_alerts_screen.dart';
import 'package:kisan_veer/screens/market/price_finder_screen.dart';
import 'package:kisan_veer/screens/market/price_trend_screen.dart';
import 'package:kisan_veer/services/market_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 pinned commodities screen.
///
/// List of commodities the user is tracking. Each card shows the
/// current price, the % change since pinning, and quick actions to
/// set an alert or view trends.
class PinnedCommoditiesScreen extends StatefulWidget {
  const PinnedCommoditiesScreen({super.key});

  @override
  State<PinnedCommoditiesScreen> createState() =>
      _PinnedCommoditiesScreenState();
}

class _PinnedCommoditiesScreenState extends State<PinnedCommoditiesScreen> {
  final MarketService _marketService = MarketService();

  bool _isLoading = true;
  String? _errorMessage;
  List<PinnedCommodity> _items = [];

  @override
  void initState() {
    super.initState();
    _refreshPrices();
  }

  Future<void> _loadPinned() async {
    try {
      final commodities = await _marketService.getPinnedCommodities();
      if (!mounted) return;
      setState(() {
        _items = commodities;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Load pinned failed', tag: 'PinnedCommodities', error: e);
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshPrices() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _marketService.updatePinnedCommodityPrices();
      await _loadPinned();
      if (!mounted) return;
      _toast('Prices updated', color: AppColors.success);
    } catch (e) {
      AppLogger.e('Refresh pinned failed', tag: 'PinnedCommodities', error: e);
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _unpin(PinnedCommodity commodity) async {
    try {
      await _marketService.unpinCommodity(commodity.id);
      if (!mounted) return;
      setState(() => _items.removeWhere((c) => c.id == commodity.id));
      _toast('${commodity.commodity} unpinned', color: AppColors.primary);
    } catch (e) {
      AppLogger.e('Unpin failed', tag: 'PinnedCommodities', error: e);
      if (!mounted) return;
      _toast('Could not unpin', color: AppColors.danger);
    }
  }

  void _toast(String message, {required Color color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  void _open(Widget screen) {
    Navigator.of(context).push(AppPageRoute.of(screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'Pinned commodities',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh prices',
            onPressed: _isLoading ? null : _refreshPrices,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPrices,
        color: AppColors.primary,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(const PriceFinderScreen()),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add crop'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _items.isEmpty) {
      return const AppLoadingState(message: 'Loading your pins…');
    }
    if (_errorMessage != null) {
      return AppErrorState(
        title: 'Could not load pinned commodities',
        message: _errorMessage,
        onRetry: _refreshPrices,
      );
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 96),
          AppEmptyState(
            icon: Icons.push_pin_outlined,
            title: 'No pinned commodities',
            message:
                'Pin the crops you care about so you can watch their '
                'price movement every day.',
            actionLabel: 'Open price finder',
            onAction: () => _open(const PriceFinderScreen()),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space16,
        AppSpacing.space96,
      ),
      itemCount: _items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space12),
      itemBuilder: (context, index) =>
          _CommodityCard(
            commodity: _items[index],
            onViewTrends: () => _open(
              PriceTrendScreen(
                initialCommodity: _items[index].commodity,
                initialState: _items[index].state,
                initialDistrict: _items[index].district,
                initialMarket: _items[index].market,
              ),
            ),
            onSetAlert: () => _open(
              PriceAlertsScreen(
                initialCommodity: _items[index].commodity,
                initialState: _items[index].state,
                initialDistrict: _items[index].district,
                initialMarket: _items[index].market,
              ),
            ),
            onUnpin: () => _confirmUnpin(_items[index]),
          ).animate().fadeIn(
            duration: AppMotion.base,
            delay: Duration(milliseconds: 50 * index.clamp(0, 6)),
          ),
    );
  }

  void _confirmUnpin(PinnedCommodity commodity) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unpin commodity?'),
        content: Text(
          'Remove ${commodity.commodity} from your watchlist? '
          'You can re-pin it from Price finder anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(ctx);
              _unpin(commodity);
            },
            child: const Text('Unpin'),
          ),
        ],
      ),
    );
  }
}

class _CommodityCard extends StatelessWidget {
  const _CommodityCard({
    required this.commodity,
    required this.onViewTrends,
    required this.onSetAlert,
    required this.onUnpin,
  });

  final PinnedCommodity commodity;
  final VoidCallback onViewTrends;
  final VoidCallback onSetAlert;
  final VoidCallback onUnpin;

  @override
  Widget build(BuildContext context) {
    final change = commodity.currentPrice - commodity.initialPrice;
    final pct = commodity.initialPrice != 0
        ? (change / commodity.initialPrice) * 100
        : 0.0;
    final isUp = change >= 0;
    final trendColor = isUp ? AppColors.success : AppColors.danger;

    final location = [
      commodity.state,
      if ((commodity.district ?? '').isNotEmpty) commodity.district,
      if ((commodity.market ?? '').isNotEmpty) commodity.market,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

    final lastUpdated = DateFormat(
      'd MMM, h:mm a',
    ).format(commodity.lastUpdated);

    return AppCard(
      onTap: onViewTrends,
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: AppRadii.brMd,
                ),
                child: const Icon(
                  Icons.eco_rounded,
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
                      commodity.commodity,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    if (location.isNotEmpty)
                      Text(
                        location,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onUnpin,
                icon: const Icon(Icons.push_pin),
                tooltip: 'Unpin',
                color: AppColors.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Current',
                  value: '₹${commodity.currentPrice.toStringAsFixed(0)}',
                  valueColor: AppColors.primary,
                  isEmphasized: true,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Initial',
                  value: '₹${commodity.initialPrice.toStringAsFixed(0)}',
                  valueColor: AppColors.onSurface,
                ),
              ),
              Expanded(
                child: _Metric(
                  label: 'Change',
                  value:
                      '${isUp ? '+' : '−'}₹${change.abs().toStringAsFixed(0)}',
                  valueColor: trendColor,
                  trailing: Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.space6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: trendColor.withValues(alpha: 0.12),
                      borderRadius: AppRadii.brFull,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isUp
                              ? Icons.trending_up_rounded
                              : Icons.trending_down_rounded,
                          size: 12,
                          color: trendColor,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${isUp ? '+' : ''}${pct.toStringAsFixed(1)}%',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: trendColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Set alert',
                  variant: AppButtonVariant.tertiary,
                  size: AppButtonSize.sm,
                  leadingIcon: Icons.notifications_active_outlined,
                  onPressed: onSetAlert,
                ),
              ),
              const SizedBox(width: AppSpacing.space8),
              Expanded(
                child: AppButton(
                  label: 'View trends',
                  size: AppButtonSize.sm,
                  leadingIcon: Icons.show_chart_rounded,
                  onPressed: onViewTrends,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Row(
            children: [
              const Icon(
                Icons.schedule,
                size: 12,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Updated $lastUpdated',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isEmphasized = false,
    this.trailing,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isEmphasized;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style:
              (isEmphasized
                      ? AppTextStyles.titleMedium
                      : AppTextStyles.bodyLarge)
                  .copyWith(color: valueColor, fontWeight: FontWeight.w700),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
