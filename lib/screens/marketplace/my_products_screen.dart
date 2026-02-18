import 'package:flutter/material.dart';
import 'package:kisan_veer/models/marketplace_models.dart';
import 'package:kisan_veer/screens/marketplace/product_details_screen.dart';
import 'package:kisan_veer/widgets/marketplace/product_card.dart';

class MyProductsScreen extends StatelessWidget {
  final List<Product> products;
  const MyProductsScreen({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Products'),
      ),
      body: products.isEmpty
          ? const Center(child: Text('No products added yet.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return ProductCard(
                  product: product,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsScreen(productId: product.id),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
