import 'package:flutter/material.dart';
import 'package:kisan_veer/models/marketplace_models.dart';
import 'package:kisan_veer/services/marketplace_service.dart';
import 'package:kisan_veer/constants/app_colors.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;
  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  late TextEditingController _descriptionController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _contactEmailController;
  late TextEditingController _locationController;
  String _selectedCategory = 'Grains';
  String _selectedStatus = 'available';
  bool _isLoading = false;

  final List<String> _categories = [
    'Grains', 'Fruits', 'Vegetables', 'Dairy', 'Poultry', 'Seeds', 'Fertilizers', 'Equipment'
  ];
  final List<String> _statusOptions = ['available', 'sold', 'inactive'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.name);
    _priceController = TextEditingController(text: p.price.toString());
    _quantityController = TextEditingController(text: p.availableQuantity.toString());
    _descriptionController = TextEditingController(text: p.description);
    _contactPhoneController = TextEditingController(text: p.contactPhone ?? '');
    _contactEmailController = TextEditingController(text: p.contactEmail ?? '');
    _locationController = TextEditingController(text: p.location ?? '');
    _selectedCategory = p.category;
    _selectedStatus = p.status ?? 'available';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final updatedProduct = widget.product.copyWith(
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        availableQuantity: int.tryParse(_quantityController.text) ?? 0,
        description: _descriptionController.text,
        category: _selectedCategory,
        status: _selectedStatus,
        contactPhone: _contactPhoneController.text,
        contactEmail: _contactEmailController.text,
        location: _locationController.text,
      );
      await MarketplaceService().updateProduct(
        productId: updatedProduct.id,
        name: updatedProduct.name,
        description: updatedProduct.description,
        price: updatedProduct.price,
        availableQuantity: updatedProduct.availableQuantity,
        category: updatedProduct.category,
        imageUrls: updatedProduct.imageUrls,
        location: updatedProduct.location,
        unit: updatedProduct.unit,
        status: updatedProduct.status,
        contactPhone: updatedProduct.contactPhone,
        contactEmail: updatedProduct.contactEmail,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update product: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product'),
        backgroundColor: AppColors.primary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location (e.g. City, State or Market)'),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val!),
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(labelText: 'Quantity'),
                      keyboardType: TextInputType.number,
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      items: _statusOptions.map((status) => DropdownMenuItem(value: status, child: Text(status))).toList(),
                      onChanged: (val) => setState(() => _selectedStatus = val!),
                      decoration: const InputDecoration(labelText: 'Status'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactPhoneController,
                      decoration: const InputDecoration(labelText: 'Contact Phone'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactEmailController,
                      decoration: const InputDecoration(labelText: 'Contact Email'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveProduct,
                        child: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
