import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_motion.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/marketplace_models.dart';
import 'package:kisan_veer/models/user_model.dart';
import 'package:kisan_veer/screens/auth/login_screen.dart';
import 'package:kisan_veer/screens/marketplace/add_product_screen.dart';
import 'package:kisan_veer/screens/marketplace/admin_panel_screen.dart';
import 'package:kisan_veer/screens/marketplace/cart_screen.dart';
import 'package:kisan_veer/screens/marketplace/my_products_screen.dart';
import 'package:kisan_veer/screens/marketplace/order_history_screen.dart';
import 'package:kisan_veer/screens/marketplace/product_details_screen.dart';
import 'package:kisan_veer/screens/marketplace/seller_pending_orders_screen.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/services/marketplace_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/widgets/marketplace/product_card.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// V2 marketplace hub.
///
/// Three-tab surface (Buy / Sell / Orders) with a polished hero
/// that carries search, a cart badge, and the admin shortcut.
/// Category chips filter products in the Buy tab; the Sell tab shows
/// seller stats and their listed products.
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final MarketplaceService _marketplaceService = MarketplaceService();
  final TextEditingController _searchController = TextEditingController();

  UserModel? _currentUser;
  bool _isLoading = true;
  List<Product> _products = [];
  List<Product> _userProducts = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  int _cartCount = 0;
  bool _cartLoading = false;
  int _pendingOrdersCount = 0;
  double _totalSales = 0.0;

  StreamSubscription? _productSubscription;
  StreamSubscription? _ordersSubscription;
  StreamSubscription? _orderItemsSubscription;

  static const List<String> _categories = [
    'All',
    'Grains',
    'Fruits',
    'Vegetables',
    'Dairy',
    'Poultry',
    'Seeds',
    'Fertilizers',
    'Equipment',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _subscribeToProductStream();
    _subscribeToOrdersStream();
    _loadUserData();
    _loadProducts();
    _loadCartCount();
    _fetchSellTabStats();
  }

  void _subscribeToProductStream() {
    _productSubscription?.cancel();
    _productSubscription = Supabase.instance.client
        .from('products')
        .stream(primaryKey: ['id'])
        .listen((data) {
          if (!mounted) return;
          setState(() {
            _products = data.map((e) => Product.fromJson(e)).toList();
          });
        });
  }

  void _subscribeToOrdersStream() {
    final userId = _currentUser?.uid;
    _ordersSubscription?.cancel();
    if (userId != null) {
      _ordersSubscription = Supabase.instance.client
          .from('orders')
          .stream(primaryKey: ['id'])
          .listen((_) => _fetchSellTabStats());
      _orderItemsSubscription = Supabase.instance.client
          .from('order_items')
          .stream(primaryKey: ['id'])
          .listen((_) => _fetchSellTabStats());
    }
  }

  @override
  void dispose() {
    _productSubscription?.cancel();
    _ordersSubscription?.cancel();
    _orderItemsSubscription?.cancel();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _authService.getCurrentUserModel();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Error loading user data', tag: 'Marketplace', error: e);
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      await _marketplaceService.getProducts();
      if (_currentUser != null) {
        final userProducts = await _marketplaceService.getProducts(
          showUserProducts: true,
        );
        if (!mounted) return;
        setState(() {
          _userProducts = userProducts;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() => _isLoading = false);
      }
    } catch (e) {
      AppLogger.e('Error loading products', tag: 'Marketplace', error: e);
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadCartCount() async {
    setState(() => _cartLoading = true);
    try {
      final items = await _marketplaceService.getCartItems();
      if (!mounted) return;
      setState(() {
        _cartCount = items.fold(0, (sum, item) => sum + item.quantity);
        _cartLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _cartLoading = false);
    }
  }

  Future<void> _fetchSellTabStats() async {
    if (_currentUser == null) return;
    final userId = _currentUser!.uid;
    try {
      final pendingOrdersResp = await Supabase.instance.client
          .from('order_items')
          .select('order_id')
          .eq('seller_id', userId);
      final pendingOrderIds = <String>{
        for (final item in pendingOrdersResp)
          if (item['order_id'] != null) item['order_id'].toString(),
      };
      int pendingOrders = 0;
      if (pendingOrderIds.isNotEmpty) {
        final ordersResp = await Supabase.instance.client
            .from('orders')
            .select('id, status')
            .inFilter('id', pendingOrderIds.toList())
            .not('status', 'in', ['completed', 'cancelled']);
        pendingOrders = ordersResp.length;
      }

      final completedItemsResp = await Supabase.instance.client
          .from('order_items')
          .select('total_price, order_id')
          .eq('seller_id', userId);
      final deliveredOrdersResp = await Supabase.instance.client
          .from('orders')
          .select('id')
          .eq('status', 'delivered');
      final deliveredOrderIds = <String>{
        for (final row in deliveredOrdersResp) row['id'].toString(),
      };
      double totalSales = 0;
      for (final item in completedItemsResp) {
        if (deliveredOrderIds.contains(item['order_id'].toString())) {
          totalSales += (item['total_price'] as num?)?.toDouble() ?? 0.0;
        }
      }

      if (!mounted) return;
      setState(() {
        _pendingOrdersCount = pendingOrders;
        _totalSales = totalSales;
      });
    } catch (e) {
      AppLogger.e('Fetch seller stats failed', tag: 'Marketplace', error: e);
    }
  }

  void _open(Widget screen) {
    Navigator.of(context).push(AppPageRoute.of(screen));
  }

  void _openSearchSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.xxl)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: AppSpacing.space20,
          right: AppSpacing.space20,
          top: AppSpacing.space16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.outlineVariant,
                borderRadius: AppRadii.brFull,
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            AppTextField(
              controller: _searchController,
              label: 'Search products',
              hint: 'e.g. wheat, tomatoes',
              prefixIcon: Icons.search_rounded,
              autofocus: true,
              onChanged: (val) => setState(() => _searchQuery = val),
              suffix: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: AppSpacing.space16),
            AppButton(
              label: 'Apply',
              size: AppButtonSize.lg,
              isFullWidth: true,
              leadingIcon: Icons.check_rounded,
              onPressed: () => Navigator.pop(ctx),
            ),
            const SizedBox(height: AppSpacing.space16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const AppLoadingState(message: 'Loading marketplace…')
          : TabBarView(
              controller: _tabController,
              children: [_buildBuyTab(), _buildSellTab(), _buildOrdersTab()],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(
                  context,
                ).push(AppPageRoute.of(const AddProductScreen()));
                _loadProducts();
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('List product'),
            )
          : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppAppBar(
      title: 'Marketplace',
      showBack: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Search',
          onPressed: _openSearchSheet,
        ),
        IconButton(
          icon: const Icon(Icons.admin_panel_settings_outlined),
          tooltip: 'Admin panel',
          onPressed: () => _open(const AdminPanelScreen()),
        ),
        _CartAction(
          count: _cartCount,
          loading: _cartLoading,
          onTap: () async {
            await Navigator.of(
              context,
            ).push(AppPageRoute.of(const CartScreen()));
            _loadCartCount();
          },
        ),
        const SizedBox(width: AppSpacing.space4),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.onSurfaceVariant,
        labelStyle: AppTextStyles.titleSmall.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTextStyles.titleSmall,
        tabs: const [
          Tab(text: 'Buy'),
          Tab(text: 'Sell'),
          Tab(text: 'Orders'),
        ],
      ),
    );
  }

  // ─── Buy tab ────────────────────────────────────────────────────────────
  Widget _buildBuyTab() {
    final filtered = _products.where((p) {
      final matchesCategory =
          _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.space16,
              vertical: AppSpacing.space8,
            ),
            itemCount: _categories.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: AppSpacing.space8),
            itemBuilder: (context, index) {
              final c = _categories[index];
              final selected = c == _selectedCategory;
              return _CategoryChip(
                label: c,
                selected: selected,
                onTap: () => setState(() => _selectedCategory = c),
              );
            },
          ),
        ).animate().fadeIn(duration: AppMotion.base),
        Expanded(
          child: filtered.isEmpty
              ? AppEmptyState(
                  icon: Icons.shopping_basket_outlined,
                  title: _searchQuery.isEmpty
                      ? 'No products in this category'
                      : 'No matches for "$_searchQuery"',
                  message: 'Try a different category or search term.',
                  actionLabel: 'Refresh',
                  onAction: _loadProducts,
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.space16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final product = filtered[index];
                      return ProductCard(
                        product: product,
                        onTap: () async {
                          await Navigator.of(context).push(
                            AppPageRoute.of(
                              ProductDetailsScreen(productId: product.id),
                            ),
                          );
                          _loadProducts();
                        },
                      ).animate().fadeIn(
                        duration: AppMotion.base,
                        delay: Duration(milliseconds: 50 * index.clamp(0, 6)),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ─── Sell tab ───────────────────────────────────────────────────────────
  Widget _buildSellTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.space16),
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.space16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seller dashboard',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.space16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Listings',
                      value: '${_userProducts.length}',
                      tint: const Color(0xFF1565C0),
                      bg: const Color(0xFFE3F2FD),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'Pending',
                      value: '$_pendingOrdersCount',
                      tint: const Color(0xFFE65100),
                      bg: const Color(0xFFFFF3E0),
                      onTap: _currentUser == null
                          ? null
                          : () => _open(
                              SellerPendingOrdersScreen(
                                sellerId: _currentUser!.uid,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.trending_up_rounded,
                      title: 'Sales',
                      value: '₹${_totalSales.toStringAsFixed(0)}',
                      tint: const Color(0xFF2E7D32),
                      bg: const Color(0xFFE8F5E9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space16),
              AppButton(
                label: 'List a new product',
                size: AppButtonSize.lg,
                isFullWidth: true,
                leadingIcon: Icons.add_circle_outline_rounded,
                onPressed: () async {
                  await Navigator.of(
                    context,
                  ).push(AppPageRoute.of(const AddProductScreen()));
                  _loadProducts();
                },
              ),
            ],
          ),
        ).animate().fadeIn(duration: AppMotion.slow),
        const SizedBox(height: AppSpacing.space16),
        Row(
          children: [
            Expanded(
              child: Text(
                'My products',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_userProducts.isNotEmpty)
              AppButton(
                label: 'View all',
                variant: AppButtonVariant.ghost,
                size: AppButtonSize.sm,
                trailingIcon: Icons.chevron_right_rounded,
                onPressed: () =>
                    _open(MyProductsScreen(products: _userProducts)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.space8),
        if (_userProducts.isEmpty)
          const AppEmptyState(
            icon: Icons.inventory_2_outlined,
            title: 'No products listed yet',
            message: 'Tap "List a new product" above to start selling.',
          )
        else
          ..._userProducts
              .take(5)
              .map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.space8),
                  child: ProductCard(
                    product: p,
                    onTap: () async {
                      await Navigator.of(context).push(
                        AppPageRoute.of(ProductDetailsScreen(productId: p.id)),
                      );
                      _loadProducts();
                    },
                  ),
                ),
              ),
      ],
    );
  }

  // ─── Orders tab ─────────────────────────────────────────────────────────
  Widget _buildOrdersTab() {
    if (_currentUser == null) {
      return AppEmptyState(
        icon: Icons.receipt_long_outlined,
        title: 'Sign in to view orders',
        message: 'Your marketplace orders will show up here once signed in.',
        actionLabel: 'Sign in',
        onAction: () => _open(const LoginScreen()),
      );
    }
    return const OrderHistoryScreen();
  }
}

class _CartAction extends StatelessWidget {
  const _CartAction({
    required this.count,
    required this.loading,
    required this.onTap,
  });

  final int count;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart_outlined),
          tooltip: 'Cart',
          onPressed: onTap,
        ),
        if (count > 0 && !loading)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: AppRadii.brFull,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '$count',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brFull,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space16,
            vertical: AppSpacing.space8,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: AppRadii.brFull,
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.outlineVariant,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: selected ? AppColors.onPrimary : AppColors.onSurface,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.tint,
    required this.bg,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color tint;
  final Color bg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadii.brMd,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brMd,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.space12),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadii.brMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: tint, size: 20),
              const SizedBox(height: AppSpacing.space8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleSmall.copyWith(
                  color: tint,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.onSurfaceVariant,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
