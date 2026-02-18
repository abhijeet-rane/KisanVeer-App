// lib/screens/marketplace/order_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/models/marketplace_models.dart';
import 'package:kisan_veer/services/marketplace_service.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:timeline_tile/timeline_tile.dart';

class OrderDetailsScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailsScreen({
    Key? key,
    required this.orderId,
  }) : super(key: key);

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  bool _isLoading = true;
  bool _isCancelling = false;
  Order? _order;
  List<OrderStatusHistory> _statusHistory = [];
  DateTime? _estimatedDeliveryDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load order with full item details
      final order = await _marketplaceService.getOrderWithItems(widget.orderId);
      final statusHistory =
          await _marketplaceService.getOrderStatusHistory(widget.orderId);
      final estimatedDelivery =
          await _marketplaceService.getEstimatedDeliveryDate(widget.orderId);

      if (mounted) {
        setState(() {
          _order = order;
          _statusHistory = statusHistory;
          _estimatedDeliveryDate = estimatedDelivery;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading order details: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load order details: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _cancelOrder() async {
    if (_order == null) return;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text(
          'Are you sure you want to cancel this order? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('YES, CANCEL'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      await _marketplaceService.cancelOrder(widget.orderId);
      // Reload order details after cancellation
      await _loadOrderDetails();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error cancelling order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCancelling = false);
      }
    }
  }

  // Helper method to check if order can be cancelled
  bool _canCancelOrder() {
    if (_order == null) return false;

    final cancellableStatuses = [
      'pending',
      'confirmed',
      'processing',
      'payment_pending',
    ];

    // Only allow cancel if not shipped, delivered, or cancelled
    return cancellableStatuses.contains(_order!.status.toLowerCase());
  }

  // Helper method to get appropriate color for order status
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
      case 'payment_pending':
        return Colors.blue;
      case 'confirmed':
      case 'processing':
        return Colors.orange;
      case 'shipped':
        return Colors.purple;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Helper method to format the status text
  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Order Details',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : _order == null
                  ? _buildOrderNotFoundWidget()
                  : RefreshIndicator(
                      onRefresh: _loadOrderDetails,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOrderHeader(),
                            const SizedBox(height: 24),
                            _buildOrderStatus(),
                            const SizedBox(height: 24),
                            _buildOrderItems(),
                            const SizedBox(height: 24),
                            _buildShippingDetails(),
                            const SizedBox(height: 24),
                            _buildPaymentSummary(),
                            const SizedBox(height: 32),
                            if (_canCancelOrder()) _buildCancelButton(),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 60,
          ),
          const SizedBox(height: 16),
          Text(
            _error ?? 'Something went wrong',
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Try Again',
            onPressed: _loadOrderDetails,
            color: AppColors.primary,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderNotFoundWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            color: Colors.grey[400],
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Order Not Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The order you requested could not be found',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Go Back',
            onPressed: () => Navigator.pop(context),
            color: AppColors.primary,
            textColor: Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader() {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final formattedDate = dateFormat.format(_order!.createdAt);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Order Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_order!.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: _getStatusColor(_order!.status),
                    ),
                  ),
                  child: Text(
                    _formatStatus(_order!.status),
                    style: TextStyle(
                      color: _getStatusColor(_order!.status),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Order ID', '#${_order!.id.substring(0, 8)}'),
            _buildInfoRow('Order Date', formattedDate),
            _buildInfoRow('Payment Method', _order!.paymentMethod ?? 'Online'),
            _buildInfoRow(
              'Items',
              '${_order!.items?.length ?? 0} items',
            ),
            _buildInfoRow(
              'Total Amount',
              '₹${_order!.totalAmount.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus() {
    // Combine status history with estimated delivery if available
    final allStatuses = [..._statusHistory];

    // Add estimated delivery date if order is not yet delivered or cancelled
    if (_estimatedDeliveryDate != null &&
        !['delivered', 'cancelled'].contains(_order!.status.toLowerCase())) {
      final dateFormat = DateFormat('dd MMM yyyy');
      allStatuses.add(OrderStatusHistory(
        id: 'estimated',
        orderId: _order!.id,
        status: 'estimated_delivery',
        notes:
            'Estimated delivery by ${dateFormat.format(_estimatedDeliveryDate!)}',
        createdAt: _estimatedDeliveryDate!,
      ));
    }

    // Filter out duplicate statuses (keep only the latest for each status)
    final Map<String, OrderStatusHistory> statusMap = {};
    for (final s in allStatuses) {
      statusMap[s.status] = s;
    }
    final filteredStatuses = statusMap.values.toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Timeline',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...filteredStatuses.map((status) => ListTile(
                  leading: Icon(
                    status.status == 'delivered'
                        ? Icons.check_circle
                        : status.status == 'shipped'
                            ? Icons.local_shipping
                            : status.status == 'packed'
                                ? Icons.inventory
                                : status.status == 'confirmed' ||
                                        status.status == 'processing'
                                    ? Icons.sync
                                    : status.status == 'cancelled'
                                        ? Icons.cancel
                                        : Icons.radio_button_unchecked,
                    color: status.status == 'delivered'
                        ? Colors.green
                        : status.status == 'shipped'
                            ? Colors.purple
                            : status.status == 'packed'
                                ? Colors.orange
                                : status.status == 'cancelled'
                                    ? Colors.red
                                    : Colors.grey,
                  ),
                  title: Text(
                    _formatStatus(status.status),
                    style: TextStyle(
                      color: status.status == 'delivered'
                          ? Colors.green
                          : status.status == 'cancelled'
                              ? Colors.red
                              : null,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (status.status == 'estimated_delivery' &&
                          status.notes != null &&
                          status.notes!.isNotEmpty)
                        Text(
                          status.notes!,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black54),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMM yyyy, hh:mm a')
                            .format(status.createdAt),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems() {
    final items = _order!.items ?? [];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              const Center(
                child: Text('No items available'),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = items[index];

                  if (item.product == null) {
                    return const ListTile(
                      title: Text('Unknown Product'),
                      subtitle: Text('Product details not available'),
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (item.product!.imageUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item.product!.imageUrls.first,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${item.product!.price.toStringAsFixed(2)} / ${item.product!.unit}',
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Quantity: ${item.quantity}',
                              style: TextStyle(
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total: ₹${(item.product!.price * item.quantity).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingDetails() {
    if (_order == null || _order!.address == null) {
      return const SizedBox();
    }
    // Removed unused local variable 'address' as all references use _order!.address directly.
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shipping Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _order!.address.name.isNotEmpty
                ? _buildInfoRow('Name', _order!.address.name)
                : const SizedBox(),
            _order!.address.fullAddress.isNotEmpty
                ? _buildInfoRow('Address', _order!.address.fullAddress)
                : const SizedBox(),
            _order!.address.city.isNotEmpty
                ? _buildInfoRow('City', _order!.address.city)
                : const SizedBox(),
            _order!.address.state.isNotEmpty
                ? _buildInfoRow('State', _order!.address.state)
                : const SizedBox(),
            _order!.address.pincode.isNotEmpty
                ? _buildInfoRow('Pincode', _order!.address.pincode)
                : const SizedBox(),
            _order!.address.phone.isNotEmpty
                ? _buildInfoRow('Phone', _order!.address.phone)
                : const SizedBox(),
            const SizedBox(height: 8),
            if (_estimatedDeliveryDate != null &&
                !['delivered', 'cancelled']
                    .contains(_order!.status.toLowerCase()))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        color: Colors.green[700],
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated Delivery',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('dd MMM yyyy')
                                  .format(_estimatedDeliveryDate!),
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildPaymentSummary() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items Total'),
                Text('₹${_order!.totalAmount.toStringAsFixed(2)}'),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery Fee'),
                  Text('₹0.00'),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Tax'),
                  Text('Included'),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '₹${_order!.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            if (_order!.paymentId != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment ID',
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _order!.paymentId!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
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

  Widget _buildCancelButton() {
    return SizedBox(
      width: double.infinity,
      child: CustomButton(
        text: 'Cancel Order',
        onPressed: _isCancelling ? null : _cancelOrder,
        isLoading: _isCancelling,
        buttonType: ButtonType.outlined,
        color: Colors.red,
        textColor: Colors.red,
        icon: Icons.cancel_outlined,
      ),
    );
  }
}
