import 'package:flutter/material.dart';
import 'package:kisan_veer/services/marketplace_service.dart';
import 'package:kisan_veer/models/marketplace_models.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'dart:async';
import 'package:kisan_veer/screens/marketplace/edit_product_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final MarketplaceService _marketplaceService = MarketplaceService();
  List<Product> _products = [];
  bool _isLoading = true;
  String? _error;

  String _searchQuery = '';
  List<Product> get _filteredProducts {
    if (_searchQuery.isEmpty) return _products;
    return _products.where((p) =>
      p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      (p.seller?.displayName?.toLowerCase() ?? '').contains(_searchQuery.toLowerCase())
    ).toList();
  }

  String _selectedStatus = 'All';
  final List<String> _statusOptions = ['All', 'available', 'sold', 'inactive'];

  @override
  void initState() {
    super.initState();
    _loadUserProducts();
  }

  Future<void> _loadUserProducts() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final products = await _marketplaceService.getSellerProducts();
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load products: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _marketplaceService.deleteProduct(productId);
      _loadUserProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete product: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by product or seller',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: _statusOptions.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status[0].toUpperCase() + status.substring(1)),
                  )).toList(),
                  onChanged: (val) => setState(() => _selectedStatus = val!),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : ListView.builder(
                        itemCount: _filteredProducts.where((p) => _selectedStatus == 'All' || (p.status ?? 'available') == _selectedStatus).length,
                        itemBuilder: (context, index) {
                          final productsToShow = _filteredProducts.where((p) => _selectedStatus == 'All' || (p.status ?? 'available') == _selectedStatus).toList();
                          final product = productsToShow[index];
                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: ListTile(
                              leading: product.imageUrls.isNotEmpty
                                  ? Image.network(product.imageUrls.first, width: 48, height: 48, fit: BoxFit.cover)
                                  : const Icon(Icons.image, size: 48),
                              title: Text(product.name),
                              subtitle: Text('Status: ${product.status ?? 'available'}\nPrice: ${product.price}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      final updated = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => EditProductScreen(product: product),
                                        ),
                                      );
                                      if (updated == true) _loadUserProducts();
                                    },
                                    tooltip: 'Edit',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteProduct(product.id),
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                              onTap: () {
                                // Optionally view/edit product details
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
