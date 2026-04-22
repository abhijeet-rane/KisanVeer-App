import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/screens/marketplace/order_details_screen.dart';
import 'package:kisan_veer/services/marketplace_service.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SellerPendingOrdersScreen extends StatefulWidget {
  final String sellerId;
  const SellerPendingOrdersScreen({Key? key, required this.sellerId})
    : super(key: key);

  @override
  State<SellerPendingOrdersScreen> createState() =>
      _SellerPendingOrdersScreenState();
}

class _SellerPendingOrdersScreenState extends State<SellerPendingOrdersScreen> {
  List<Map<String, dynamic>> _orders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPendingOrders();
  }

  Future<void> _fetchPendingOrders() async {
    setState(() {
      _isLoading = true;
    });
    final resp = await Supabase.instance.client
        .from('order_items')
        .select('*, orders(*)')
        .eq('seller_id', widget.sellerId)
        .not('orders.status', 'in', ['completed', 'cancelled']);
    // Deduplicate orders by orderId
    final orderMap = <String, Map<String, dynamic>>{};
    for (final item in resp) {
      final order = item['orders'];
      if (order != null && order['status'] != 'cancelled') {
        final orderId = order['id'].toString();
        if (!orderMap.containsKey(orderId)) {
          orderMap[orderId] = item;
        }
      }
    }
    setState(() {
      _orders = orderMap.values.toList();
      _isLoading = false;
    });
  }

  void _onOrderStageChanged(String orderId, String newStage) async {
    await MarketplaceService().updateOrderStatus(orderId, newStage);
    // Wait for update before refreshing
    await Future.delayed(const Duration(milliseconds: 300));
    _fetchPendingOrders();
  }

  Widget _buildOrderCard(Map<String, dynamic> orderItem) {
    final order = orderItem['orders'];
    final orderId = order['id'].toString();
    final status = order['status'] ?? 'pending';
    final stages = ['pending', 'confirmed', 'packed', 'shipped', 'delivered'];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        title: Text('Order #$orderId'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: $status'),
            DropdownButton<String>(
              value: stages.contains(status) ? status : stages.first,
              items: stages
                  .map(
                    (stage) => DropdownMenuItem(
                      value: stage,
                      child: Text(stage[0].toUpperCase() + stage.substring(1)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null && value != status) {
                  _onOrderStageChanged(orderId, value);
                }
              },
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(AppPageRoute.of(OrderDetailsScreen(orderId: orderId)));
              },
              child: const Text('View Details'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'Pending orders', showBack: true),
      body: _isLoading
          ? const AppLoadingState(message: 'Loading pending orders…')
          : _orders.isEmpty
          ? const AppEmptyState(
              icon: Icons.inbox_outlined,
              title: 'No pending orders',
              message: 'All caught up — no orders waiting to be fulfilled.',
            )
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
            ),
    );
  }
}
