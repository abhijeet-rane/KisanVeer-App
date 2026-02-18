// lib/widgets/marketplace/order_status_timeline.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kisan_veer/models/marketplace_models.dart';
import 'package:timeline_tile/timeline_tile.dart';

class OrderStatusTimeline extends StatelessWidget {
  final List<OrderStatusHistory> statusHistory;
  final bool isActive;
  
  const OrderStatusTimeline({
    Key? key,
    required this.statusHistory,
    this.isActive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort status history by date
    final sortedHistory = List<OrderStatusHistory>.from(statusHistory)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 8.0, bottom: 16.0),
            child: Text(
              'Order Status History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (sortedHistory.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No status updates available.'),
            )
          else
            ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: sortedHistory.length,
              itemBuilder: (context, index) {
                final status = sortedHistory[index];
                final isFirst = index == 0;
                final isLast = index == sortedHistory.length - 1;
                
                return TimelineTile(
                  alignment: TimelineAlign.start,
                  isFirst: isFirst,
                  isLast: isLast,
                  indicatorStyle: IndicatorStyle(
                    width: 20,
                    height: 20,
                    indicator: _buildIndicator(status.status, isActive),
                    color: _getStatusColor(status.status),
                  ),
                  endChild: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 0, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _getStatusText(status.status),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(status.status),
                                ),
                              ),
                            ),
                            Text(
                              DateFormat('MMM d, h:mm a').format(status.createdAt),
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        if (status.notes != null && status.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              status.notes!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  beforeLineStyle: LineStyle(
                    color: Colors.grey[300]!,
                  ),
                  afterLineStyle: LineStyle(
                    color: Colors.grey[300]!,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildIndicator(String status, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          _getStatusIcon(status),
          size: 12,
          color: Colors.white,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'processing':
        return Colors.indigo;
      case 'shipped':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.hourglass_bottom;
      case 'confirmed':
        return Icons.check_circle_outline;
      case 'processing':
        return Icons.inventory;
      case 'shipped':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.circle;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Pending';
      case 'confirmed':
        return 'Order Confirmed';
      case 'processing':
        return 'Order Processing';
      case 'shipped':
        return 'Order Shipped';
      case 'delivered':
        return 'Order Delivered';
      case 'cancelled':
        return 'Order Cancelled';
      default:
        return status;
    }
  }
}