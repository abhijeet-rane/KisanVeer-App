import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/marketplace_models.dart';
import 'package:kisan_veer/models/user_model.dart';
import 'package:kisan_veer/screens/marketplace/add_product_screen.dart';
import 'package:kisan_veer/screens/marketplace/admin_panel_screen.dart';
import 'package:kisan_veer/screens/marketplace/cart_screen.dart';
import 'package:kisan_veer/screens/marketplace/my_products_screen.dart';
import 'package:kisan_veer/screens/marketplace/order_history_screen.dart';
import 'package:kisan_veer/screens/marketplace/product_details_screen.dart';
import 'package:kisan_veer/screens/marketplace/seller_pending_orders_screen.dart';
import 'package:kisan_veer/services/auth_service.dart';
import 'package:kisan_veer/services/marketplace_service.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:kisan_veer/widgets/marketplace/product_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarketplaceScreen extends StatefulWidget {
  final int initialTabIndex;
  const MarketplaceScreen({Key? key, this.initialTabIndex = 0})
      : super(key: key);

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();
  final MarketplaceService _marketplaceService = MarketplaceService();
  UserModel? _currentUser;
  bool _isLoading = true;
  List<Product> _products = [];
  List<Product> _userProducts = [];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _cartCount = 0;
  bool _cartLoading = false;
  int _pendingOrdersCount = 0;
  double _totalSales = 0.0;
  StreamSubscription? _ordersSubscription;
  StreamSubscription? _orderItemsSubscription;

  final List<String> _categories = [
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

  StreamSubscription? _productSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTabIndex);
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
        .stream(primaryKey: ['id']).listen((List<Map<String, dynamic>> data) {
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
          .stream(primaryKey: ['id']).listen((_) {
        _fetchSellTabStats();
      });
      _orderItemsSubscription = Supabase.instance.client
          .from('order_items')
          .stream(primaryKey: ['id']).listen((_) {
        _fetchSellTabStats();
      });
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

      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load products from the marketplace service
      await _marketplaceService.getProducts();

      if (_currentUser != null) {
        // Load user products if logged in
        final userProducts =
            await _marketplaceService.getProducts(showUserProducts: true);

        setState(() {
          _userProducts = userProducts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCartCount() async {
    setState(() => _cartLoading = true);
    try {
      final items = await _marketplaceService.getCartItems();
      setState(() {
        _cartCount = items.fold(0, (sum, item) => sum + (item.quantity));
        _cartLoading = false;
      });
    } catch (e) {
      setState(() => _cartLoading = false);
    }
  }

  Future<void> _fetchSellTabStats() async {
    if (_currentUser == null) return;
    final userId = _currentUser!.uid;
    // Pending Orders: orders where order_items.seller_id = userId and orders.status NOT IN ('completed', 'cancelled')
    final pendingOrdersResp = await Supabase.instance.client
        .from('order_items')
        .select('order_id')
        .eq('seller_id', userId);
    final pendingOrderIds = <String>{};
    if (pendingOrdersResp != null && pendingOrdersResp is List) {
      for (final item in pendingOrdersResp) {
        final orderId = item['order_id']?.toString();
        if (orderId != null) pendingOrderIds.add(orderId);
      }
    }
    int pendingOrders = 0;
    if (pendingOrderIds.isNotEmpty) {
      final ordersResp = await Supabase.instance.client
          .from('orders')
          .select('id, status')
          .inFilter('id', pendingOrderIds.toList())
          .not('status', 'in', ['completed', 'cancelled']);
      if (ordersResp != null && ordersResp is List) {
        pendingOrders = ordersResp.length;
      }
    }
    // Total Sales: sum order_items.total_price where seller_id=userId and parent order is delivered
    final completedOrderItemsResp = await Supabase.instance.client
        .from('order_items')
        .select('total_price, order_id')
        .eq('seller_id', userId);
    double totalSales = 0.0;
    if (completedOrderItemsResp != null && completedOrderItemsResp is List) {
      final deliveredOrderIdsResp = await Supabase.instance.client
          .from('orders')
          .select('id')
          .eq('status', 'delivered');
      final deliveredOrderIds = <String>{};
      if (deliveredOrderIdsResp != null && deliveredOrderIdsResp is List) {
        for (final row in deliveredOrderIdsResp) {
          deliveredOrderIds.add(row['id'].toString());
        }
      }
      for (final item in completedOrderItemsResp) {
        if (deliveredOrderIds.contains(item['order_id'].toString())) {
          totalSales += (item['total_price'] as num?)?.toDouble() ?? 0.0;
        }
      }
    }
    setState(() {
      _pendingOrdersCount = pendingOrders;
      _totalSales = totalSales;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Marketplace',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Search Products'),
                  content: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                        hintText: 'Enter product name...'),
                    autofocus: true,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        Navigator.of(context).pop();
                      },
                      child: const Text('Clear'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings, color: Colors.white),
            tooltip: 'Admin Panel',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const AdminPanelScreen()),
              );
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                tooltip: 'Go to Cart',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(),
                    ),
                  );
                  _loadCartCount();
                },
              ),
              if (_cartCount > 0 && !_cartLoading)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints:
                        const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$_cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withAlpha((0.7 * 255).round()),
          tabs: const [
            Tab(text: 'Buy'),
            Tab(text: 'Sell'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBuyTab(),
                _buildSellTab(),
                _buildOrdersTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 2
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddProductScreen(),
                  ),
                ).then((_) => _loadProducts());
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildBuyTab() {
    final filteredProducts = _products.where((product) {
      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ).animate().fadeIn(
              duration: const Duration(milliseconds: 500),
            ),
        Expanded(
          child: filteredProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_basket,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No products available',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Refresh',
                        onPressed: _loadProducts,
                        width: 150,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];

                      return ProductCard(
                        product: product,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                ProductDetailsScreen(productId: product.id),
                          ),
                        ).then((_) => _loadProducts()),
                      ).animate().fadeIn(
                            duration: const Duration(milliseconds: 500),
                            delay: Duration(milliseconds: 100 * index),
                          );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSellTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Selling Dashboard',
                    style: AppTextStyles.h3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        'Active Listings',
                        '${_userProducts.length}',
                        Icons.shopping_cart_outlined,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Pending Orders',
                        '$_pendingOrdersCount',
                        Icons.receipt_long_outlined,
                        Colors.orange,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Total Sales',
                        '₹${_totalSales.toStringAsFixed(2)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  CustomButton(
                    text: 'Add New Product',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddProductScreen(),
                        ),
                      ).then((_) => _loadProducts());
                    },
                    width: double.infinity,
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(
                duration: const Duration(milliseconds: 500),
              ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Text(
                'My Products',
                style: AppTextStyles.h3,
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          MyProductsScreen(products: _userProducts),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ).animate().fadeIn(
              duration: const Duration(milliseconds: 500),
              delay: const Duration(milliseconds: 200),
            ),
        Expanded(
          child: _userProducts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No products listed',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first product to start selling',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _userProducts.length,
                  itemBuilder: (context, index) {
                    return _buildMyProductCard(index).animate().fadeIn(
                          duration: const Duration(milliseconds: 500),
                          delay: Duration(milliseconds: 300 + (100 * index)),
                        );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: title == 'Pending Orders' && _currentUser != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SellerPendingOrdersScreen(sellerId: _currentUser!.uid),
                  ),
                );
              }
            : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha((0.1 * 255).round()),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: AppTextStyles.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyProductCard(int index) {
    // Build a card for my products tab
    if (_userProducts.isEmpty || index >= _userProducts.length) {
      return const SizedBox.shrink();
    }

    final product = _userProducts[index];

    return ProductCard(
      product: product,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailsScreen(productId: product.id),
        ),
      ).then((_) => _loadProducts()),
    );
  }

  Widget _buildStatItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    if (_currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Login Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please login to view your orders',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 160,
              child: CustomButton(
                text: 'Login',
                onPressed: () {
                  // Navigate to login screen
                },
              ),
            ),
          ],
        ),
      );
    }

    // Directly embed the OrderHistoryScreen
    return const OrderHistoryScreen();
  }
}
