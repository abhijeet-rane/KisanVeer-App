import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_elevation.dart';
import 'package:kisan_veer/constants/app_radii.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/models/marketplace_models.dart';
import 'package:kisan_veer/screens/marketplace/checkout_screen.dart';
import 'package:kisan_veer/services/marketplace_service.dart';
import 'package:kisan_veer/utils/app_logger.dart';
import 'package:kisan_veer/widgets/marketplace/cart_item_tile.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';
import 'package:shimmer/shimmer.dart';

/// V2 shopping cart screen.
///
/// Shimmer-loading state, AppEmptyState for empty cart, dismiss-to-
/// delete tiles, and a pinned checkout bar with subtotal + primary CTA.
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();

  List<CartItem> _cartItems = [];
  bool _isLoading = true;
  bool _isProcessing = false;
  double _totalPrice = 0;

  @override
  void initState() {
    super.initState();
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    setState(() => _isLoading = true);
    try {
      final cartItems = await _marketplaceService.getCartItems();
      if (!mounted) return;
      setState(() {
        _cartItems = cartItems;
        _totalPrice = _calculateTotal(cartItems);
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.e('Cart load failed', tag: 'Cart', error: e);
      if (!mounted) return;
      _toast('Could not load your cart', color: AppColors.danger);
      setState(() => _isLoading = false);
    }
  }

  double _calculateTotal(List<CartItem> items) {
    double total = 0;
    for (final item in items) {
      if (item.product != null) {
        total += item.product!.price * item.quantity;
      }
    }
    return total;
  }

  Future<void> _updateQuantity(CartItem item, int newQuantity) async {
    if (newQuantity <= 0) {
      _removeItem(item);
      return;
    }
    try {
      await _marketplaceService.updateCartItemQuantity(item.id, newQuantity);
      await _loadCartItems();
    } catch (e) {
      AppLogger.e('Update quantity failed', tag: 'Cart', error: e);
      if (!mounted) return;
      _toast('Could not update quantity', color: AppColors.danger);
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      await _marketplaceService.removeFromCart(item.id);
      await _loadCartItems();
      if (!mounted) return;
      _toast('Item removed from cart', color: AppColors.primary);
    } catch (e) {
      AppLogger.e('Remove item failed', tag: 'Cart', error: e);
      if (!mounted) return;
      _toast('Could not remove item', color: AppColors.danger);
    }
  }

  void _confirmClearCart() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear cart?'),
        content: const Text(
          'This removes every item from your cart. You can always add '
          'them again later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await _marketplaceService.clearCart();
                await _loadCartItems();
                if (!mounted) return;
                _toast('Cart cleared', color: AppColors.primary);
              } catch (e) {
                AppLogger.e('Clear cart failed', tag: 'Cart', error: e);
                if (!mounted) return;
                _toast('Could not clear cart', color: AppColors.danger);
              }
            },
            child: const Text('Clear cart'),
          ),
        ],
      ),
    );
  }

  Future<void> _proceedToCheckout() async {
    setState(() => _isProcessing = true);
    await Navigator.of(context).push(
      AppPageRoute.of(
        CheckoutScreen(cartItems: _cartItems, totalAmount: _totalPrice),
      ),
    );
    if (!mounted) return;
    setState(() => _isProcessing = false);
    _loadCartItems();
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
      appBar: AppAppBar(
        title: 'Shopping cart',
        showBack: true,
        actions: [
          if (_cartItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _confirmClearCart,
              tooltip: 'Clear cart',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingShimmer()
          : _cartItems.isEmpty
          ? AppEmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              message:
                  'Browse the marketplace and add items to start a '
                  'new order.',
              actionLabel: 'Continue shopping',
              onAction: () => Navigator.pop(context),
            )
          : _buildCartItems(),
      bottomNavigationBar: _cartItems.isEmpty ? null : _buildCheckoutBar(),
    );
  }

  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surfaceContainerLow,
      highlightColor: AppColors.surfaceContainer,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.space16),
        itemCount: 4,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.space12),
          child: Container(
            height: 104,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadii.brLg,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartItems() {
    return RefreshIndicator(
      onRefresh: _loadCartItems,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.space16),
        itemCount: _cartItems.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.space12),
        itemBuilder: (context, index) {
          final item = _cartItems[index];
          return CartItemTile(
            cartItem: item,
            onUpdateQuantity: (q) => _updateQuantity(item, q),
            onRemove: () => _removeItem(item),
          );
        },
      ),
    );
  }

  Widget _buildCheckoutBar() {
    final itemCount = _cartItems.fold<int>(0, (sum, i) => sum + i.quantity);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.space16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppElevation.shadowHigh,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$itemCount item${itemCount == 1 ? '' : 's'}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${_totalPrice.toStringAsFixed(0)}',
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.space16),
                AppButton(
                  label: 'Checkout',
                  size: AppButtonSize.lg,
                  isLoading: _isProcessing,
                  trailingIcon: Icons.arrow_forward_rounded,
                  onPressed: _proceedToCheckout,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
