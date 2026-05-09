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

/// V2 price alerts screen.
///
/// List of user-configured price alerts. Each alert card shows the
/// condition, threshold, and location. A bottom-sheet form creates
/// new alerts with cascading state → district → market selects.
class PriceAlertsScreen extends StatefulWidget {
  const PriceAlertsScreen({
    super.key,
    this.initialCommodity,
    this.initialState,
    this.initialDistrict,
    this.initialMarket,
  });

  final String? initialCommodity;
  final String? initialState;
  final String? initialDistrict;
  final String? initialMarket;

  @override
  State<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends State<PriceAlertsScreen> {
  final MarketService _marketService = MarketService();

  final _commodityController = TextEditingController();
  final _priceController = TextEditingController();

  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedMarket;
  String _selectedCondition = 'above';

  bool _isLoading = true;
  String? _errorMessage;

  List<PriceAlert> _alerts = [];
  List<String> _states = [];
  List<String> _districts = [];
  List<String> _markets = [];

  @override
  void initState() {
    super.initState();
    _commodityController.text = widget.initialCommodity ?? '';
    _selectedState = widget.initialState;
    _selectedDistrict = widget.initialDistrict;
    _selectedMarket = widget.initialMarket;
    _loadAlerts();
    _loadStates().then((_) {
      if (_selectedState != null && _states.contains(_selectedState)) {
        _loadDistricts().then((_) {
          if (_selectedDistrict != null &&
              _districts.contains(_selectedDistrict)) {
            _loadMarkets();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _commodityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final alerts = await _marketService.getPriceAlerts();
      if (!mounted) return;
      setState(() {
        _alerts = alerts;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Load alerts failed', tag: 'PriceAlerts', error: e);
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStates() async {
    try {
      final states = await _marketService.getStates();
      if (!mounted) return;
      setState(() {
        _states = states;
        if (_selectedState != null && !states.contains(_selectedState)) {
          _selectedState = null;
        }
      });
    } catch (e) {
      AppLogger.e('Load states failed', tag: 'PriceAlerts', error: e);
    }
  }

  Future<void> _loadDistricts() async {
    if (_selectedState == null) return;
    try {
      final districts = await _marketService.getDistricts(_selectedState!);
      if (!mounted) return;
      setState(() {
        _districts = districts;
        if (_selectedDistrict == null ||
            !_districts.contains(_selectedDistrict)) {
          _selectedDistrict = null;
          _markets = [];
          _selectedMarket = null;
        }
      });
    } catch (e) {
      AppLogger.e('Load districts failed', tag: 'PriceAlerts', error: e);
    }
  }

  Future<void> _loadMarkets() async {
    if (_selectedState == null || _selectedDistrict == null) return;
    try {
      final markets = await _marketService.getMarkets(
        _selectedState!,
        _selectedDistrict!,
      );
      if (!mounted) return;
      setState(() {
        _markets = markets;
        if (_selectedMarket == null || !_markets.contains(_selectedMarket)) {
          _selectedMarket = null;
        }
      });
    } catch (e) {
      AppLogger.e('Load markets failed', tag: 'PriceAlerts', error: e);
    }
  }

  Future<void> _createAlert(StateSetter sheetSetState) async {
    if (_commodityController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _selectedState == null) {
      _toast('Fill in commodity, state, and price', color: AppColors.danger);
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null) {
      _toast('Enter a valid price', color: AppColors.danger);
      return;
    }

    try {
      await _marketService.createPriceAlert(
        commodity: _commodityController.text.trim(),
        state: _selectedState!,
        district: _selectedDistrict,
        market: _selectedMarket,
        thresholdPrice: price,
        alertCondition: _selectedCondition,
      );

      _commodityController.clear();
      _priceController.clear();
      if (!mounted) return;
      Navigator.pop(context);
      _loadAlerts();
      _toast('Price alert created', color: AppColors.success);
    } catch (e) {
      AppLogger.e('Create alert failed', tag: 'PriceAlerts', error: e);
      if (!mounted) return;
      _toast('Could not create alert', color: AppColors.danger);
    }
  }

  Future<void> _deleteAlert(PriceAlert alert) async {
    try {
      await _marketService.deletePriceAlert(alert.id.toString());
      if (!mounted) return;
      _loadAlerts();
      _toast('Alert deleted', color: AppColors.primary);
    } catch (e) {
      AppLogger.e('Delete alert failed', tag: 'PriceAlerts', error: e);
      if (!mounted) return;
      _toast('Could not delete alert', color: AppColors.danger);
    }
  }

  Future<void> _toggleAlert(PriceAlert alert) async {
    try {
      await _marketService.updatePriceAlert(
        alertId: alert.id.toString(),
        isActive: !alert.isActive,
      );
      _loadAlerts();
    } catch (e) {
      AppLogger.e('Toggle alert failed', tag: 'PriceAlerts', error: e);
      if (!mounted) return;
      _toast('Could not update alert', color: AppColors.danger);
    }
  }

  void _toast(String message, {required Color color}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Price alerts', showBack: true),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateAlertSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New alert'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _alerts.isEmpty) {
      return const AppLoadingState(message: 'Loading your alerts…');
    }
    if (_errorMessage != null) {
      return AppErrorState(
        title: 'Could not load alerts',
        message: _errorMessage,
        onRetry: _loadAlerts,
      );
    }
    if (_alerts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 96),
          AppEmptyState(
            icon: Icons.notifications_off_outlined,
            title: 'No price alerts yet',
            message:
                'Create alerts to get notified when prices cross your '
                'threshold so you never miss a good sell or buy.',
            actionLabel: 'Create alert',
            onAction: _showCreateAlertSheet,
          ),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _loadAlerts,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space16,
          AppSpacing.space16,
          AppSpacing.space16,
          AppSpacing.space96,
        ),
        itemCount: _alerts.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space12),
        itemBuilder: (context, index) =>
            _AlertCard(
              alert: _alerts[index],
              onToggle: () => _toggleAlert(_alerts[index]),
              onDelete: () => _confirmDelete(_alerts[index]),
            ).animate().fadeIn(
              duration: AppMotion.base,
              delay: Duration(milliseconds: 50 * index.clamp(0, 6)),
            ),
      ),
    );
  }

  void _confirmDelete(PriceAlert alert) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete alert?'),
        content: Text(
          'Remove the ${alert.condition} ₹${alert.targetPrice.toStringAsFixed(0)} '
          'alert for ${alert.commodity}?',
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
              _deleteAlert(alert);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateAlertSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, sheetSetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: AppSpacing.space20,
                right: AppSpacing.space20,
                top: AppSpacing.space16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.outlineVariant,
                          borderRadius: AppRadii.brFull,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    Text(
                      'Create price alert',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Get notified when a commodity price meets your '
                      'chosen threshold.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space20),
                    AppTextField(
                      controller: _commodityController,
                      label: 'Commodity',
                      hint: 'e.g. Rice, Wheat, Tomato',
                      prefixIcon: Icons.eco_outlined,
                    ),
                    const SizedBox(height: AppSpacing.space16),
                    _buildDropdown(
                      label: 'State',
                      value: _states.contains(_selectedState)
                          ? _selectedState
                          : null,
                      items: _states,
                      onChanged: (v) async {
                        sheetSetState(() => _selectedState = v);
                        await _loadDistricts();
                        sheetSetState(() {});
                      },
                      hint: 'Select state',
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    _buildDropdown(
                      label: 'District (optional)',
                      value: _districts.contains(_selectedDistrict)
                          ? _selectedDistrict
                          : null,
                      items: _districts,
                      onChanged: (v) async {
                        sheetSetState(() => _selectedDistrict = v);
                        await _loadMarkets();
                        sheetSetState(() {});
                      },
                      hint: 'Select district',
                    ),
                    if (_markets.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.space12),
                      _buildDropdown(
                        label: 'Market (optional)',
                        value: _markets.contains(_selectedMarket)
                            ? _selectedMarket
                            : null,
                        items: _markets,
                        onChanged: (v) =>
                            sheetSetState(() => _selectedMarket = v),
                        hint: 'Select market',
                      ),
                    ],
                    const SizedBox(height: AppSpacing.space20),
                    Text(
                      'Trigger when price is',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space8),
                    Row(
                      children: [
                        Expanded(
                          child: _ConditionPill(
                            label: 'Above',
                            icon: Icons.arrow_upward_rounded,
                            selected: _selectedCondition == 'above',
                            selectedColor: AppColors.success,
                            onTap: () => sheetSetState(
                              () => _selectedCondition = 'above',
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.space8),
                        Expanded(
                          child: _ConditionPill(
                            label: 'Below',
                            icon: Icons.arrow_downward_rounded,
                            selected: _selectedCondition == 'below',
                            selectedColor: AppColors.danger,
                            onTap: () => sheetSetState(
                              () => _selectedCondition = 'below',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space12),
                    AppTextField(
                      controller: _priceController,
                      label: 'Price (₹ per quintal)',
                      hint: 'e.g. 2500',
                      prefixIcon: Icons.currency_rupee_rounded,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space24),
                    AppButton(
                      label: 'Create alert',
                      size: AppButtonSize.lg,
                      isFullWidth: true,
                      leadingIcon: Icons.notifications_active_rounded,
                      onPressed: () => _createAlert(sheetSetState),
                    ),
                    const SizedBox(height: AppSpacing.space16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.space6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: AppRadii.brMd,
            border: Border.all(color: AppColors.outlineVariant),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(hint, style: AppTextStyles.bodyMedium),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.onSurfaceVariant,
              ),
              items: items
                  .map(
                    (s) => DropdownMenuItem<String>(value: s, child: Text(s)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _ConditionPill extends StatelessWidget {
  const _ConditionPill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.selectedColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color selectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brMd,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space12,
            vertical: AppSpacing.space12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? selectedColor.withValues(alpha: 0.12)
                : AppColors.surfaceContainerLow,
            borderRadius: AppRadii.brMd,
            border: Border.all(
              color: selected ? selectedColor : AppColors.outlineVariant,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? selectedColor : AppColors.onSurfaceVariant,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.space8),
              Text(
                label,
                style: AppTextStyles.titleSmall.copyWith(
                  color: selected ? selectedColor : AppColors.onSurface,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.alert,
    required this.onToggle,
    required this.onDelete,
  });

  final PriceAlert alert;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isAbove = alert.condition == 'above';
    final condColor = isAbove ? AppColors.success : AppColors.danger;
    final location = [
      alert.state,
      if (alert.district != null && alert.district!.isNotEmpty) alert.district!,
      if (alert.market != null && alert.market!.isNotEmpty) alert.market!,
    ].join(' · ');

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: condColor.withValues(alpha: 0.12),
                  borderRadius: AppRadii.brMd,
                ),
                child: Icon(
                  isAbove
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  color: condColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.space12),
              Expanded(
                child: Text(
                  alert.commodity,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Switch.adaptive(
                value: alert.isActive,
                activeColor: AppColors.primary,
                onChanged: (_) => onToggle(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space12,
              vertical: AppSpacing.space8,
            ),
            decoration: BoxDecoration(
              color: condColor.withValues(alpha: 0.08),
              borderRadius: AppRadii.brMd,
            ),
            child: Row(
              children: [
                Icon(
                  isAbove ? Icons.arrow_upward : Icons.arrow_downward,
                  color: condColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isAbove ? 'Above' : 'Below'} ₹${alert.targetPrice.toStringAsFixed(0)}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: condColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: AppColors.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Created ${DateFormat('d MMM, yyyy').format(alert.createdAt)}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              AppButton(
                label: 'Delete',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                leadingIcon: Icons.delete_outline_rounded,
                onPressed: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
