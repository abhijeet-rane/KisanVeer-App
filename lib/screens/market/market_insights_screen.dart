import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/screens/market/daily_dashboard_screen.dart';
import 'package:kisan_veer/screens/market/market_comparison_screen.dart';
import 'package:kisan_veer/screens/market/pinned_commodities_screen.dart';
import 'package:kisan_veer/screens/market/price_alerts_screen.dart';
import 'package:kisan_veer/screens/market/price_finder_screen.dart';
import 'package:kisan_veer/screens/market/price_heatmap_screen.dart';
import 'package:kisan_veer/screens/market/price_trend_screen.dart';
import 'package:kisan_veer/screens/market/smart_recommendations_screen.dart';
import 'package:kisan_veer/services/market_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 market insights hub.
///
/// Hero-style brand gradient header, quick-action pills, horizontal
/// pinned-commodities strip, and a tinted feature grid for every
/// module under the Market umbrella.
class MarketInsightsScreen extends StatefulWidget {
  const MarketInsightsScreen({super.key});

  @override
  State<MarketInsightsScreen> createState() => _MarketInsightsScreenState();
}

class _MarketInsightsScreenState extends State<MarketInsightsScreen> {
  final MarketService _marketService = MarketService();

  bool _isLoading = true;
  String? _errorMessage;
  List<PinnedCommodity> _pinnedCommodities = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final pinned = await _marketService.getPinnedCommodities();
      if (!mounted) return;
      setState(() {
        _pinnedCommodities = pinned;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Market insights load failed', tag: 'MarketHub', error: e);
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(AppPageRoute.of(screen));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const AppLoadingState(message: 'Loading market data…')
          : _errorMessage != null
          ? AppErrorState(
              title: 'Could not load market data',
              message: _errorMessage,
              onRetry: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(
                    child: _HeroHeader(onBack: () => Navigator.pop(context)),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space16,
                      AppSpacing.space20,
                      AppSpacing.space16,
                      AppSpacing.space24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _QuickActionRow(
                          actions: [
                            _QuickAction(
                              icon: Icons.dashboard_rounded,
                              label: 'Daily\ndashboard',
                              tint: const Color(0xFFE65100),
                              bg: const Color(0xFFFFF3E0),
                              onTap: () => _open(const DailyDashboardScreen()),
                            ),
                            _QuickAction(
                              icon: Icons.search_rounded,
                              label: 'Find\nprices',
                              tint: const Color(0xFFC62828),
                              bg: const Color(0xFFFFEBEE),
                              onTap: () => _open(const PriceFinderScreen()),
                            ),
                            _QuickAction(
                              icon: Icons.trending_up_rounded,
                              label: 'Price\ntrends',
                              tint: const Color(0xFF2E7D32),
                              bg: const Color(0xFFE8F5E9),
                              onTap: () => _open(const PriceTrendScreen()),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.space28),
                        _SectionTitle(
                          title: 'Your pinned commodities',
                          subtitle: _pinnedCommodities.isEmpty
                              ? 'Pin crops in Price finder to see them here'
                              : '${_pinnedCommodities.length} items tracked',
                          action: _pinnedCommodities.isEmpty ? null : 'Manage',
                          onAction: _pinnedCommodities.isEmpty
                              ? null
                              : () => _open(const PinnedCommoditiesScreen()),
                        ),
                        const SizedBox(height: AppSpacing.space12),
                        _PinnedStrip(
                          items: _pinnedCommodities,
                          onAddPressed: () => _open(const PriceFinderScreen()),
                        ),
                        const SizedBox(height: AppSpacing.space28),
                        const _SectionTitle(
                          title: 'Explore the market',
                          subtitle: 'Deeper tools for insights',
                        ),
                        const SizedBox(height: AppSpacing.space12),
                        _FeatureGrid(onOpen: _open),
                        const SizedBox(height: AppSpacing.space16),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ─── Hero ────────────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space20,
        MediaQuery.of(context).padding.top + AppSpacing.space8,
        AppSpacing.space20,
        AppSpacing.space24,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.brandGradient,
        ),
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(AppRadii.xxl),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                tooltip: 'Back',
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Market',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(duration: AppMotion.base),
                      const SizedBox(height: 2),
                      Text(
                        'Insights',
                        style: AppTextStyles.displaySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ).animate().fadeIn(
                        duration: AppMotion.base,
                        delay: const Duration(milliseconds: 100),
                      ),
                      const SizedBox(height: AppSpacing.space8),
                      Text(
                        'Real-time mandi prices, trends, and alerts '
                        'for smarter farming decisions.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ).animate().fadeIn(
                        duration: AppMotion.base,
                        delay: const Duration(milliseconds: 200),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space16),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: AppRadii.brLg,
                  ),
                  child: const Icon(
                    Icons.analytics_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ).animate().scale(
                  duration: AppMotion.slow,
                  curve: Curves.easeOutBack,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick actions ──────────────────────────────────────────────────────────

class _QuickActionRow extends StatelessWidget {
  const _QuickActionRow({required this.actions});

  final List<_QuickAction> actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < actions.length; i++) ...[
          Expanded(child: actions[i]),
          if (i < actions.length - 1) const SizedBox(width: AppSpacing.space12),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.tint,
    required this.bg,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color tint;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space8,
        vertical: AppSpacing.space16,
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: AppRadii.brMd),
            child: Icon(icon, color: tint, size: 22),
          ),
          const SizedBox(height: AppSpacing.space8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section title ──────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null && onAction != null)
          AppButton(
            label: action!,
            variant: AppButtonVariant.ghost,
            size: AppButtonSize.sm,
            trailingIcon: Icons.chevron_right_rounded,
            onPressed: onAction,
          ),
      ],
    );
  }
}

// ─── Pinned strip ───────────────────────────────────────────────────────────

class _PinnedStrip extends StatelessWidget {
  const _PinnedStrip({required this.items, required this.onAddPressed});

  final List<PinnedCommodity> items;
  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return AppCard(
        child: Column(
          children: [
            const Icon(
              Icons.push_pin_outlined,
              color: AppColors.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.space8),
            Text(
              'Nothing pinned yet',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Open Price finder and pin the crops you care about.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.space12),
            AppButton(
              label: 'Open price finder',
              variant: AppButtonVariant.tertiary,
              size: AppButtonSize.sm,
              leadingIcon: Icons.search_rounded,
              onPressed: onAddPressed,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 128,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.space12),
        itemBuilder: (context, index) =>
            _PinnedTile(item: items[index]).animate().fadeIn(
              duration: AppMotion.base,
              delay: Duration(milliseconds: 60 * index),
            ),
      ),
    );
  }
}

class _PinnedTile extends StatelessWidget {
  const _PinnedTile({required this.item});

  final PinnedCommodity item;

  @override
  Widget build(BuildContext context) {
    final pct = item.initialPrice != 0
        ? ((item.currentPrice - item.initialPrice) / item.initialPrice) * 100
        : 0.0;
    final isUp = pct >= 0;
    final trendColor = isUp ? AppColors.success : AppColors.danger;

    final marketLine = [
      if ((item.market ?? '').isNotEmpty) item.market!,
      if (item.state.isNotEmpty) item.state,
    ].join(' · ');

    return Container(
      width: 180,
      padding: const EdgeInsets.all(AppSpacing.space12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: AppRadii.brSm,
                ),
                child: const Icon(
                  Icons.eco_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space8,
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
                      color: trendColor,
                      size: 12,
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
            ],
          ),
          const Spacer(),
          Text(
            item.commodity,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '₹${item.currentPrice.toStringAsFixed(0)}/qtl',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          if (marketLine.isNotEmpty)
            Text(
              marketLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Feature grid ───────────────────────────────────────────────────────────

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.onOpen});

  final ValueChanged<Widget> onOpen;

  @override
  Widget build(BuildContext context) {
    final features = <_Feature>[
      _Feature(
        title: 'Daily dashboard',
        description: 'Daily mandi summary',
        icon: Icons.dashboard_rounded,
        tint: const Color(0xFFE65100),
        bg: const Color(0xFFFFF3E0),
        screen: const DailyDashboardScreen(),
      ),
      _Feature(
        title: 'Price finder',
        description: 'Search by location',
        icon: Icons.search_rounded,
        tint: const Color(0xFFC62828),
        bg: const Color(0xFFFFEBEE),
        screen: const PriceFinderScreen(),
      ),
      _Feature(
        title: 'Price trends',
        description: 'Visual charts',
        icon: Icons.show_chart_rounded,
        tint: const Color(0xFF2E7D32),
        bg: const Color(0xFFE8F5E9),
        screen: const PriceTrendScreen(),
      ),
      _Feature(
        title: 'Price alerts',
        description: 'Custom thresholds',
        icon: Icons.notifications_active_rounded,
        tint: const Color(0xFF6A1B9A),
        bg: const Color(0xFFF3E5F5),
        screen: const PriceAlertsScreen(),
      ),
      _Feature(
        title: 'Smart picks',
        description: 'Crop recommendations',
        icon: Icons.lightbulb_rounded,
        tint: const Color(0xFFF9A825),
        bg: const Color(0xFFFFF8E1),
        screen: const SmartRecommendationsScreen(),
      ),
      _Feature(
        title: 'Heatmap',
        description: 'Regional price map',
        icon: Icons.map_rounded,
        tint: const Color(0xFF1565C0),
        bg: const Color(0xFFE3F2FD),
        screen: const PriceHeatmapScreen(),
      ),
      _Feature(
        title: 'Compare markets',
        description: 'Side-by-side view',
        icon: Icons.compare_arrows_rounded,
        tint: const Color(0xFF00695C),
        bg: const Color(0xFFE0F2F1),
        screen: const MarketComparisonScreen(),
      ),
      _Feature(
        title: 'Pinned crops',
        description: 'Your watchlist',
        icon: Icons.push_pin_rounded,
        tint: const Color(0xFF283593),
        bg: const Color(0xFFE8EAF6),
        screen: const PinnedCommoditiesScreen(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.space12,
        mainAxisSpacing: AppSpacing.space12,
        childAspectRatio: 1.35,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final f = features[index];
        return AppCard(
          onTap: () => onOpen(f.screen),
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: f.bg,
                  borderRadius: AppRadii.brMd,
                ),
                child: Icon(f.icon, color: f.tint, size: 22),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(
          duration: AppMotion.base,
          delay: Duration(milliseconds: 50 * index),
        );
      },
    );
  }
}

class _Feature {
  const _Feature({
    required this.title,
    required this.description,
    required this.icon,
    required this.tint,
    required this.bg,
    required this.screen,
  });
  final String title;
  final String description;
  final IconData icon;
  final Color tint;
  final Color bg;
  final Widget screen;
}
