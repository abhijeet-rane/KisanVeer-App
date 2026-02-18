import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';

class AlertBanner extends StatelessWidget {
  final List<String> alerts;
  final VoidCallback onViewAll;

  const AlertBanner({
    Key? key, 
    required this.alerts,
    required this.onViewAll,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onTap: onViewAll,
      child: Container(
        margin: const EdgeInsets.all(16.0),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.orange.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Weather Alerts',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  'View All',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              alerts.first, // Show first alert in the banner
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            if (alerts.length > 1)
              Text(
                '+${alerts.length - 1} more alerts',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
