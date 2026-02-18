import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/constants/app_text_styles.dart';
import 'package:kisan_veer/services/marketplace_service.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:kisan_veer/widgets/custom_text_field.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String _selectedCategory = 'Grains';
  String _selectedUnit = 'quintal';
  bool _isOrganic = false;
  bool _isLoading = false;
  String _selectedStatus = 'available';

  final _marketplaceService = MarketplaceService();
  final _imagePicker = ImagePicker();
  List<File> _selectedImages = [];

  final List<String> _categories = [
    'Grains',
    'Fruits',
    'Vegetables',
    'Dairy',
    'Poultry',
    'Seeds',
    'Fertilizers',
    'Equipment',
  ];

  final List<String> _units = [
    'quintal',
    'kg',
    'dozen',
    'piece',
    'liter',
  ];

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

  Future<void> _submitProduct() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        setState(() {
          _isLoading = true;
        });

        // Create the product data
        final double price = double.parse(_priceController.text);
        final int quantity = int.parse(_quantityController.text);

        // Build product description with organic tag if applicable
        String description = _descriptionController.text;
        if (_isOrganic) {
          description = "[ORGANIC] $description";
        }

        // Try to upload images - if this fails, we'll still create the product with empty image URLs
        List<String> imageUrls = [];
        try {
          if (_selectedImages.isNotEmpty) {
            imageUrls =
                await _marketplaceService.uploadProductImages(_selectedImages);
          }
        } catch (imageError) {
          print('Warning: Image upload failed: $imageError');
          // Continue with product creation anyway
        }

        // Add the product to database
        await _marketplaceService.createProduct(
          name: _nameController.text,
          description: description,
          price: price,
          availableQuantity: quantity,
          category: _selectedCategory,
          imageUrls: imageUrls,
          location: _locationController.text.isNotEmpty ? _locationController.text : null,
          unit: _selectedUnit,
          status: _selectedStatus,
          contactPhone: _contactPhoneController.text.isNotEmpty ? _contactPhoneController.text : null,
          contactEmail: _contactEmailController.text.isNotEmpty ? _contactEmailController.text : null,
        );

        // Reset form after success
        setState(() {
          _isLoading = false;
        });

        // Show success and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to add product: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        print('Error adding product: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: const Text(
          'Add New Product',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product images
                _buildImageUploadSection().animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                    ),

                const SizedBox(height: 24),

                // Product name
                CustomTextField(
                  label: 'Product Name',
                  hint: 'Enter product name',
                  controller: _nameController,
                  prefixIcon: Icons.inventory_2_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ).animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 100),
                    ),

                const SizedBox(height: 16),

                // Location field
                CustomTextField(
                  label: 'Location (e.g. City, State or Market)',
                  hint: 'Enter location',
                  controller: _locationController,
                  prefixIcon: Icons.location_pin,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter location';
                    }
                    return null;
                  },
                ).animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 150),
                    ),

                // Contact phone
                CustomTextField(
                  label: 'Contact Phone (optional)',
                  hint: 'Enter phone number',
                  controller: _contactPhoneController,
                  prefixIcon: Icons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 10) {
                      return 'Enter a valid phone number';
                    }
                    return null;
                  },
                ).animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 200),
                    ),

                // Contact email
                CustomTextField(
                  label: 'Contact Email (optional)',
                  hint: 'Enter email address',
                  controller: _contactEmailController,
                  prefixIcon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && !value.contains('@')) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ).animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 250),
                    ),

                // Status dropdown
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Listing Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'available', child: Text('Available')),
                      DropdownMenuItem(value: 'sold', child: Text('Sold')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedStatus = val);
                    },
                  ),
                ).animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 300),
                    ),

                const SizedBox(height: 16),

                // Category selection
                Text(
                  'Category',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ).animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 350),
                    ),

                const SizedBox(height: 8),

                _buildCategorySelector().animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 350),
                    ),

                const SizedBox(height: 16),

                // Price and unit
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: CustomTextField(
                        label: 'Price',
                        hint: 'Enter price',
                        controller: _priceController,
                        prefixIcon: Icons.currency_rupee,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter price';
                          }
                          if (int.tryParse(value) == null ||
                              int.parse(value) <= 0) {
                            return 'Invalid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: _buildUnitDropdown(),
                    ),
                  ],
                ).animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 400),
                    ),

                const SizedBox(height: 16),

                // Quantity
                CustomTextField(
                  label: 'Quantity',
                  hint: 'Enter available quantity',
                  controller: _quantityController,
                  prefixIcon: Icons.production_quantity_limits,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter quantity';
                    }
                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                      return 'Invalid quantity';
                    }
                    return null;
                  },
                ).animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 450),
                    ),

                const SizedBox(height: 16),

                // Organic toggle
                Row(
                  children: [
                    Text(
                      'Is this product organic?',
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isOrganic,
                      onChanged: (value) {
                        setState(() {
                          _isOrganic = value;
                        });
                      },
                      activeColor: AppColors.primary,
                    ),
                  ],
                ).animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 500),
                    ),

                const SizedBox(height: 16),

                // Description
                CustomTextField(
                  label: 'Description',
                  hint: 'Describe your product',
                  controller: _descriptionController,
                  prefixIcon: Icons.description_outlined,
                  minLines: 3,
                  maxLines: 5,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product description';
                    }
                    if (value.length < 10) {
                      return 'Description is too short';
                    }
                    return null;
                  },
                ).animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 550),
                    ),

                const SizedBox(height: 32),

                // Submit button
                CustomButton(
                  text: 'Add Product',
                  onPressed: _submitProduct,
                  isLoading: _isLoading,
                  width: double.infinity,
                ).animate().fadeIn(
                      duration: const Duration(milliseconds: 500),
                      delay: const Duration(milliseconds: 600),
                    ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _imagePicker.pickMultiImage();
      if (pickedFiles.isNotEmpty) {
        setState(() {
          for (var file in pickedFiles) {
            if (_selectedImages.length < 5) {
              // Limit to 5 images
              _selectedImages.add(File(file.path));
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Product Images',
          style: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add up to 5 images of your product',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + 1, // +1 for add button
            itemBuilder: (context, index) {
              // First item is always add button
              if (index == 0) {
                return GestureDetector(
                  onTap: _selectedImages.length < 5 ? _pickImages : null,
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _selectedImages.length < 5
                          ? Colors.grey.shade200
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          color: _selectedImages.length < 5
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedImages.length < 5 ? 'Add Image' : 'Max (5)',
                          style: AppTextStyles.caption.copyWith(
                            color: _selectedImages.length < 5
                                ? Colors.grey.shade600
                                : Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Display selected image thumbnails
              final imageIndex = index - 1;
              return Stack(
                children: [
                  Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[imageIndex]),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _removeImage(imageIndex),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = category == _selectedCategory;

          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = category;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnitDropdown() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedUnit,
          hint: const Text('Unit'),
          icon: const Icon(Icons.arrow_drop_down),
          isExpanded: true,
          style: AppTextStyles.bodyMedium,
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedUnit = newValue;
              });
            }
          },
          items: _units.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
        ),
      ),
    );
  }
}
