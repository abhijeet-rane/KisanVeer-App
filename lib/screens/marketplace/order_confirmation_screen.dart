// lib/screens/marketplace/order_confirmation_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/models/marketplace_models.dart';
import 'package:kisan_veer/screens/marketplace/marketplace_screen_fixed.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:lottie/lottie.dart';

import 'order_details_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final Order order;

  const OrderConfirmationScreen({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Order Confirmed',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            _buildSuccessAnimation(),
            const SizedBox(height: 24),
            Text(
              'Thank You!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your order has been confirmed.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _buildOrderDetails(),
            const SizedBox(height: 24),
            _buildDeliveryDetails(),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Continue Shopping',
              onPressed: () => _navigateToMarketplace(context),
              color: AppColors.primary,
              textColor: Colors.white,
              icon: Icons.shopping_bag_outlined,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _viewOrderDetails(context),
              child: Text(
                'View Order Details',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessAnimation() {
    return SizedBox(
      height: 200,
      child: Lottie.asset(
        'assets/animations/order_success.json',
        repeat: false,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.check_circle,
          color: Colors.green,
          size: 100,
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Order ID', order.id.substring(0, 8)),
            _buildInfoRow('Date', dateFormat.format(order.createdAt)),
            _buildInfoRow('Payment Method', order.paymentMethod ?? 'Online'),
            _buildInfoRow('Order Items', '${order.items?.length ?? 0} items'),
            _buildInfoRow('Total Amount', '₹${order.totalAmount.toStringAsFixed(2)}'),
            _buildInfoRow('Status', _getStatusText(order.status)),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryDetails() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Address', order.address.fullAddress),
            _buildInfoRow('City', order.address.city),
            _buildInfoRow('State', order.address.state),
            _buildInfoRow('Pincode', order.address.pincode),
            _buildInfoRow('Phone', order.address.phone),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.delivery_dining,
                    color: Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Expected Delivery',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getExpectedDeliveryDate(),
                          style: TextStyle(color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  String _getExpectedDeliveryDate() {
    // Calculate expected delivery date (5 days from order date)
    final deliveryDate = order.createdAt.add(const Duration(days: 2));
    return DateFormat('EEEE, dd MMMM yyyy').format(deliveryDate);
  }

  void _navigateToMarketplace(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MarketplaceScreen(initialTabIndex: 0), // 0 for Buy tab
      ),
      (route) => false,
    );
  }

  void _viewOrderDetails(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => OrderDetailsScreen(orderId: order.id),
      ),
      (route) => false,
    );
  }
}
