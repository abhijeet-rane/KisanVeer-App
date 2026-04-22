import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_spacing.dart';
import 'package:kisan_veer/models/marketplace_models.dart';
import 'package:kisan_veer/screens/marketplace/product_details_screen.dart';
import 'package:kisan_veer/widgets/marketplace/product_card.dart';
import 'package:kisan_veer/widgets/ui/ui.dart';

/// V2 my products screen — list of the seller's own listings.
class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key, required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AppAppBar(title: 'My products', showBack: true),
      body: products.isEmpty
          ? const AppEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No products listed yet',
              message:
                  'List products from the Sell tab in the marketplace to '
                  'see them here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.space16),
              itemCount: products.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.space12),
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () => Navigator.of(context).push(
                    AppPageRoute.of(
                      ProductDetailsScreen(productId: product.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
