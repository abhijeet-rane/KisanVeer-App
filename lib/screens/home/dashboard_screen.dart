import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/market_models.dart';
import 'package:kisan_veer/models/user_model.dart';
import 'package:kisan_veer/screens/community/community_screen.dart';
import 'package:kisan_veer/screens/finance/finance_screen.dart';
import 'package:kisan_veer/screens/market/market_insights_screen.dart';
import 'package:kisan_veer/screens/market/price_finder_screen.dart';
import 'package:kisan_veer/screens/marketplace/marketplace_screen_fixed.dart';
import 'package:kisan_veer/screens/monitoring/gas_sensor_monitor_screen.dart';
import 'package:kisan_veer/screens/notifications/notifications_screen.dart';
import 'package:kisan_veer/screens/schemes/schemes_listing_screen.dart';
import 'package:kisan_veer/screens/weather/weather_screen.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/services/market_service.dart';
import 'package:kisan_veer/services/weather_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 home dashboard.
///
/// Layout rhythm: brand-gradient greeting header → condition-tinted
/// weather hero → services grid in elevated cards → market-insights
/// preview → schemes preview. All navigation uses [AppPageRoute].
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final WeatherService _weatherService = WeatherService();
  final MarketService _marketService = MarketService();

  UserModel? _currentUser;
  Map<String, dynamic>? _weatherData;
  bool _isLoadingUser = true;
  bool _isLoadingWeather = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadWeatherData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoadingUser = true);
    try {
      final user = await _authService.getCurrentUserModel();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoadingUser = false;
      });
    } catch (e) {
      AppLogger.e('Dashboard user load failed', tag: 'Dashboard', error: e);
      if (!mounted) return;
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _loadWeatherData() async {
    setState(() => _isLoadingWeather = true);
    try {
      final weatherData = await _weatherService.getAllWeatherData();
      if (!mounted) return;
      setState(() {
        _weatherData = weatherData;
        _isLoadingWeather = false;
      });
    } catch (e) {
      AppLogger.e('Dashboard weather load failed', tag: 'Dashboard', error: e);
      if (!mounted) return;
      setState(() => _isLoadingWeather = false);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([_loadUserData(), _loadWeatherData()]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoadingUser
          ? const AppLoadingState(message: 'Preparing your dashboard…')
          : RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _HeroHeader(user: _currentUser)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.space16,
                      AppSpacing.space20,
                      AppSpacing.space16,
                      AppSpacing.space24,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _WeatherCard(
                          data: _weatherData,
                          loading: _isLoadingWeather,
                          onTap: () async {
                            await Navigator.of(
                              context,
                            ).push(AppPageRoute.of(const WeatherScreen()));
                            _loadWeatherData();
                          },
                        ),
                        const SizedBox(height: AppSpacing.space24),
                        const _SectionTitle(
                          title: 'Services',
                          subtitle: 'Jump into any module',
                        ),
                        const SizedBox(height: AppSpacing.space12),
                        _ServicesGrid(
                          onNavigate: (screen) => Navigator.of(
                            context,
                          ).push(AppPageRoute.of(screen)),
                        ),
                        const SizedBox(height: AppSpacing.space28),
                        _SectionTitle(
                          title: 'Market insights',
                          subtitle: "Today's top movers from your pins",
                          action: 'See all',
                          onAction: () => Navigator.of(
                            context,
                          ).push(AppPageRoute.of(const MarketInsightsScreen())),
                        ),
                        const SizedBox(height: AppSpacing.space12),
                        _MarketInsightsCard(
                          marketService: _marketService,
                          onViewMore: () => Navigator.of(
                            context,
                          ).push(AppPageRoute.of(const PriceFinderScreen())),
                        ),
                        const SizedBox(height: AppSpacing.space28),
                        _SectionTitle(
                          title: 'Schemes for you',
                          subtitle: 'Government benefits worth a look',
                          action: 'See all',
                          onAction: () => Navigator.of(
                            context,
                          ).push(AppPageRoute.of(const SchemesListingScreen())),
                        ),
                        const SizedBox(height: AppSpacing.space12),
                        _SchemesCard(
                          onOpen: () => Navigator.of(
                            context,
                          ).push(AppPageRoute.of(const SchemesListingScreen())),
                        ),
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

// ─── Hero header ────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.user});

  final UserModel? user;

  String _greetingFor(int hour) {
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final greeting = _greetingFor(now.hour);
    final dateLine = DateFormat('EEEE · d MMMM').format(now);
    final name = user?.name.split(' ').first ?? 'there';
    final photoUrl = user?.photoUrl ?? '';

    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.space20,
        MediaQuery.of(context).padding.top + AppSpacing.space16,
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(duration: AppMotion.base),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ).animate().fadeIn(
                      duration: AppMotion.base,
                      delay: const Duration(milliseconds: 100),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              _HeroIconButton(
                icon: Icons.notifications_outlined,
                tooltip: 'Notifications',
                onTap: () => Navigator.of(
                  context,
                ).push(AppPageRoute.of(const NotificationsScreen())),
              ),
              const SizedBox(width: AppSpacing.space8),
              _HeroAvatar(
                photoUrl: photoUrl,
                initials: _initials(user?.name ?? 'User'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space20),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: AppRadii.brFull,
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: AppSpacing.space8),
                Text(
                  dateLine,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(
            duration: AppMotion.base,
            delay: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  String _initials(String fullName) {
    if (fullName.isEmpty) return 'U';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadii.brFull,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.brFull,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.space8),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
      ),
    );
  }
}

class _HeroAvatar extends StatelessWidget {
  const _HeroAvatar({required this.photoUrl, required this.initials});

  final String photoUrl;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: photoUrl.isNotEmpty
            ? Image.network(
                photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => _initialsText(),
              )
            : _initialsText(),
      ),
    ).animate().scale(duration: AppMotion.slow, curve: Curves.easeOutBack);
  }

  Widget _initialsText() {
    return Center(
      child: Text(
        initials,
        style: AppTextStyles.titleMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── Weather card ───────────────────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.data,
    required this.loading,
    required this.onTap,
  });

  final Map<String, dynamic>? data;
  final bool loading;
  final VoidCallback onTap;

  static const _defaultGradient = [Color(0xFF1E88E5), Color(0xFF3686FF)];

  List<Color> _gradientFor(String? condition) {
    if (condition == null) return _defaultGradient;
    switch (condition.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return const [Color(0xFFFFA726), Color(0xFFFB8C00)];
      case 'rain':
      case 'rainy':
      case 'drizzle':
        return const [Color(0xFF42A5F5), Color(0xFF1976D2)];
      case 'thunderstorm':
        return const [Color(0xFF5E35B1), Color(0xFF3949AB)];
      case 'snow':
        return const [Color(0xFF78909C), Color(0xFF546E7A)];
      case 'clouds':
      case 'partly cloudy':
      case 'mostly cloudy':
        return const [Color(0xFF5C6BC0), Color(0xFF3949AB)];
      default:
        return _defaultGradient;
    }
  }

  IconData _iconFor(String? condition) {
    switch (condition?.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return Icons.wb_sunny_rounded;
      case 'rain':
      case 'rainy':
      case 'drizzle':
        return Icons.umbrella_rounded;
      case 'thunderstorm':
        return Icons.flash_on_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      case 'mist':
      case 'fog':
      case 'haze':
        return Icons.foggy;
      default:
        return Icons.cloud_rounded;
    }
  }

  String _cropAdvice(Map<String, dynamic>? weather) {
    if (weather == null || !weather.containsKey('currentWeather')) {
      return 'Open for today\'s forecast and advice';
    }
    final current = weather['currentWeather'];
    final condition = current['condition']?.toString().toLowerCase() ?? '';
    final temp = current['temperature'] as int? ?? 0;
    final humidity = current['humidity'] as int? ?? 0;

    if (condition.contains('rain')) {
      return 'Avoid field work and cover harvested crops';
    }
    if (condition.contains('clear') || condition.contains('sunny')) {
      if (temp > 35) return 'Hot day — irrigate in the evening';
      if (temp > 25) return 'Good day for field work';
      return 'Ideal for crop maintenance';
    }
    if (condition.contains('cloud')) {
      return 'Good conditions for fertilizer application';
    }
    if (condition.contains('mist') || condition.contains('fog')) {
      return 'Monitor for fungal disease';
    }
    if (humidity > 80) return 'High humidity — watch for pests';
    if (humidity < 30) return 'Low humidity — increase irrigation';
    return 'Check weather details for advice';
  }

  @override
  Widget build(BuildContext context) {
    final condition = data?['currentWeather']?['condition'] as String?;
    final gradient = _gradientFor(condition);
    final icon = _iconFor(condition);

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.brLg,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brLg,
        child: AnimatedContainer(
          duration: AppMotion.base,
          curve: AppMotion.standard,
          padding: const EdgeInsets.all(AppSpacing.space20),
          decoration: BoxDecoration(
            borderRadius: AppRadii.brLg,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: loading
                  ? [
                      _defaultGradient[0].withValues(alpha: 0.6),
                      _defaultGradient[1].withValues(alpha: 0.6),
                    ]
                  : gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: loading
              ? const SizedBox(
                  height: 140,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : _buildContent(context, icon, condition),
        ),
      ),
    ).animate().fadeIn(duration: AppMotion.slow);
  }

  Widget _buildContent(BuildContext context, IconData icon, String? condition) {
    final temp = data?['currentWeather']?['temperature'];
    final location = data?['location'] ?? 'Your area';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${temp ?? '--'}°C',
                style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: AppSpacing.space8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      location,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space12),
              Text(
                condition ?? 'Weather',
                style: AppTextStyles.titleSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _cropAdvice(data),
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.space16),
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 44),
        ),
      ],
    );
  }
}

// ─── Services grid ──────────────────────────────────────────────────────────

class _ServicesGrid extends StatelessWidget {
  const _ServicesGrid({required this.onNavigate});

  final ValueChanged<Widget> onNavigate;

  static const List<_Service> _services = [
    _Service(
      icon: Icons.storefront_rounded,
      label: 'Marketplace',
      tint: Color(0xFF2E7D32),
      bg: Color(0xFFE8F5E9),
    ),
    _Service(
      icon: Icons.trending_up_rounded,
      label: 'Insights',
      tint: Color(0xFF1565C0),
      bg: Color(0xFFE3F2FD),
    ),
    _Service(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Finance',
      tint: Color(0xFF6A1B9A),
      bg: Color(0xFFF3E5F5),
    ),
    _Service(
      icon: Icons.wb_sunny_rounded,
      label: 'Weather',
      tint: Color(0xFFE65100),
      bg: Color(0xFFFFF3E0),
    ),
    _Service(
      icon: Icons.groups_rounded,
      label: 'Community',
      tint: Color(0xFFD84315),
      bg: Color(0xFFFBE9E7),
    ),
    _Service(
      icon: Icons.account_balance_rounded,
      label: 'Schemes',
      tint: Color(0xFF00695C),
      bg: Color(0xFFE0F2F1),
    ),
    _Service(
      icon: Icons.sensors_rounded,
      label: 'Sensors',
      tint: Color(0xFF455A64),
      bg: Color(0xFFECEFF1),
    ),
    _Service(
      icon: Icons.search_rounded,
      label: 'Prices',
      tint: Color(0xFF1565C0),
      bg: Color(0xFFE3F2FD),
    ),
  ];

  Widget _screenFor(_Service s) {
    switch (s.label) {
      case 'Marketplace':
        return const MarketplaceScreen();
      case 'Insights':
        return const MarketInsightsScreen();
      case 'Finance':
        return const FinanceScreen();
      case 'Weather':
        return const WeatherScreen();
      case 'Community':
        return const CommunityScreen();
      case 'Schemes':
        return const SchemesListingScreen();
      case 'Sensors':
        return const GasSensorMonitorScreen();
      case 'Prices':
        return const PriceFinderScreen();
      default:
        return const MarketplaceScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive columns: 4 on typical phones, 3 when really narrow
    // (< 360dp). `mainAxisExtent` gives every tile a fixed height so a
    // 2-line label never overflows no matter how wide the tile ends up.
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 360 ? 3 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: AppSpacing.space12,
            mainAxisSpacing: AppSpacing.space12,
            mainAxisExtent: 108,
          ),
          itemCount: _services.length,
          itemBuilder: (context, index) {
            final s = _services[index];
            return _ServiceTile(
              service: s,
              onTap: () => onNavigate(_screenFor(s)),
            ).animate().fadeIn(
              duration: AppMotion.base,
              delay: Duration(milliseconds: 50 * index),
            );
          },
        );
      },
    );
  }
}

class _Service {
  const _Service({
    required this.icon,
    required this.label,
    required this.tint,
    required this.bg,
  });
  final IconData icon;
  final String label;
  final Color tint;
  final Color bg;
}

class _ServiceTile extends StatelessWidget {
  const _ServiceTile({required this.service, required this.onTap});

  final _Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space4,
        vertical: AppSpacing.space8,
      ),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: service.bg,
              borderRadius: AppRadii.brMd,
            ),
            child: Icon(service.icon, color: service.tint, size: 22),
          ),
          const SizedBox(height: AppSpacing.space6),
          Flexible(
            child: Text(
              service.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.onSurface,
                fontWeight: FontWeight.w600,
              ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
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

// ─── Market insights card ───────────────────────────────────────────────────

class _MarketInsightsCard extends StatelessWidget {
  const _MarketInsightsCard({
    required this.marketService,
    required this.onViewMore,
  });

  final MarketService marketService;
  final VoidCallback onViewMore;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PinnedCommodity>>(
      future: marketService.getPinnedCommodities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.space16),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Text(
                    'Loading prices…',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                  'No pinned commodities yet',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pin crops in Price finder to see them here.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.space12),
                AppButton(
                  label: 'Open price finder',
                  variant: AppButtonVariant.tertiary,
                  size: AppButtonSize.sm,
                  onPressed: onViewMore,
                ),
              ],
            ),
          );
        }

        final pinned = [...snapshot.data!];
        pinned.sort((a, b) {
          final aPct = a.initialPrice != 0
              ? ((a.currentPrice - a.initialPrice) / a.initialPrice) * 100
              : 0.0;
          final bPct = b.initialPrice != 0
              ? ((b.currentPrice - b.initialPrice) / b.initialPrice) * 100
              : 0.0;
          return bPct.compareTo(aPct);
        });

        final top = pinned.take(4).toList();
        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < top.length; i++) ...[
                _CommodityRow(pinned: top[i]),
                if (i < top.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: AppSpacing.space16,
                    endIndent: AppSpacing.space16,
                    color: AppColors.outlineVariant,
                  ),
              ],
              const Divider(
                height: 1,
                thickness: 1,
                color: AppColors.outlineVariant,
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onViewMore,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(AppRadii.lg),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.space12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'View more prices',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CommodityRow extends StatelessWidget {
  const _CommodityRow({required this.pinned});

  final PinnedCommodity pinned;

  @override
  Widget build(BuildContext context) {
    final pct = pinned.initialPrice != 0
        ? ((pinned.currentPrice - pinned.initialPrice) / pinned.initialPrice) *
              100
        : 0.0;
    final isUp = pct >= 0;
    final trendColor = isUp ? AppColors.success : AppColors.danger;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space16,
        vertical: AppSpacing.space12,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withValues(alpha: 0.5),
              borderRadius: AppRadii.brMd,
            ),
            child: const Icon(
              Icons.eco_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: AppSpacing.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pinned.commodity,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if ((pinned.market ?? '').isNotEmpty)
                  Text(
                    '${pinned.market}${pinned.state.isNotEmpty ? ' · ${pinned.state}' : ''}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.space8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${pinned.currentPrice.toStringAsFixed(0)}',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.1),
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
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Schemes preview ────────────────────────────────────────────────────────

class _SchemesCard extends StatelessWidget {
  const _SchemesCard({required this.onOpen});

  final VoidCallback onOpen;

  static const List<_SchemePreview> _items = [
    _SchemePreview(
      title: 'PM-KISAN',
      body: 'Income support of ₹6,000 per year',
      icon: Icons.account_balance_rounded,
      tint: Color(0xFF1565C0),
      bg: Color(0xFFE3F2FD),
    ),
    _SchemePreview(
      title: 'PM Krishi Sinchai Yojana',
      body: 'Irrigation support for farmers',
      icon: Icons.water_drop_outlined,
      tint: Color(0xFFE65100),
      bg: Color(0xFFFFF3E0),
    ),
    _SchemePreview(
      title: 'Kisan Credit Card',
      body: 'Short-term credit for farming needs',
      icon: Icons.credit_card_rounded,
      tint: Color(0xFF6A1B9A),
      bg: Color(0xFFF3E5F5),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (int i = 0; i < _items.length; i++) ...[
            InkWell(
              onTap: onOpen,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space16,
                  vertical: AppSpacing.space12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _items[i].bg,
                        borderRadius: AppRadii.brMd,
                      ),
                      child: Icon(
                        _items[i].icon,
                        color: _items[i].tint,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _items[i].title,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: AppColors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _items[i].body,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (i < _items.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: AppSpacing.space16,
                endIndent: AppSpacing.space16,
                color: AppColors.outlineVariant,
              ),
          ],
        ],
      ),
    );
  }
}

class _SchemePreview {
  const _SchemePreview({
    required this.title,
    required this.body,
    required this.icon,
    required this.tint,
    required this.bg,
  });
  final String title;
  final String body;
  final IconData icon;
  final Color tint;
  final Color bg;
}
