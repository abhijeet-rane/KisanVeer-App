// lib/screens/marketplace/product_details_screen.dart

import 'package:flutter/material.dart';
import 'package:kisan_veer/constants/app_colors.dart';
import 'package:kisan_veer/models/marketplace_models.dart';
import 'package:kisan_veer/models/user_models.dart';
import 'package:kisan_veer/screens/marketplace/cart_screen.dart';
import 'package:kisan_veer/services/marketplace_service.dart';
import 'package:kisan_veer/widgets/custom_button.dart';
import 'package:kisan_veer/widgets/marketplace/product_image_gallery.dart';
import 'package:kisan_veer/widgets/marketplace/product_reviews_list.dart';
import 'package:kisan_veer/widgets/marketplace/quantity_selector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool _canReviewProduct = false;
  bool _hasReviewedProduct = false;
  final _reviewFormKey = GlobalKey<FormState>();
  int _reviewRating = 5;
  String _reviewText = '';
  final MarketplaceService _marketplaceService = MarketplaceService();
  late Future<Product> _productFuture;
  late Future<List<ProductReview>> _reviewsFuture;
  int _quantity = 1;
  bool _addingToCart = false;
  int _cartItemCount = 0;
  bool _isInterested = false;
  List<UserProfile> _interestedBuyers = [];
  String? _contactPhone;
  String? _contactEmail;
  String? _currentUserId;
  bool _isSeller = false;
  String? _selectedState;
  String? _selectedDistrict;
  List<String> _states = ['State 1', 'State 2', 'State 3']; // Replace with actual states
  List<String> _districts = [];

  @override
  void initState() {
    super.initState();
    _productFuture = _marketplaceService.getProductById(widget.productId);
    _reviewsFuture = _marketplaceService.getProductReviews(widget.productId);
    _loadCartCount();
    _initProductExtras();
    _states = [
      'Maharashtra', 'Gujarat', 'Madhya Pradesh', 'Rajasthan', 'Karnataka', 'Uttar Pradesh', 'Punjab', 'Haryana', 'Bihar', 'West Bengal', 'Tamil Nadu', 'Andhra Pradesh', 'Telangana', 'Kerala', 'Odisha', 'Chhattisgarh', 'Jharkhand', 'Assam', 'Goa', 'Delhi', 'Others'
    ];
    if (_selectedState == null) {
      _selectedState = '';
    }
    if (_selectedDistrict == null) {
      _selectedDistrict = '';
    }
    _districts = [];
  }

  Future<void> _loadCartCount() async {
    try {
      final cartItems = await _marketplaceService.getCartItems();
      if (mounted) {
        setState(() {
          _cartItemCount = cartItems.length;
        });
      }
    } catch (e) {
      // Silent fail - user might not be logged in
    }
  }

  Future<void> _initProductExtras() async {
    final userId = await _marketplaceService.getCurrentUserId();
    // Check if user can review this product
    final canReview = await _marketplaceService.canUserReviewProduct(widget.productId);
    // Check if user has already reviewed
    final reviews = await _marketplaceService.getProductReviews(widget.productId);
    final hasReviewed = reviews.any((r) => r.userId == userId);
    setState(() {
      _canReviewProduct = canReview;
      _hasReviewedProduct = hasReviewed;
      _currentUserId = userId;
    });
    final product = await _marketplaceService.getProductById(widget.productId);
    _isSeller = product.sellerId == _currentUserId;
    // Fetch interest state
    if (!_isSeller) {
      final buyers =
          await _marketplaceService.getInterestedBuyers(widget.productId);
      _isInterested = buyers.any((u) => u.id == _currentUserId);
    } else {
      _interestedBuyers =
          await _marketplaceService.getInterestedBuyers(widget.productId);
    }
    // Fetch contact info
    final contact =
        await _marketplaceService.getSellerContact(widget.productId);
    _contactPhone = contact['phone'];
    _contactEmail = contact['email'];
    if (mounted) setState(() {});
  }

  Future<void> _toggleInterest() async {
    if (_isInterested) {
      await _marketplaceService.unmarkInterested(widget.productId);
      _isInterested = false;
    } else {
      await _marketplaceService.markInterested(productId: widget.productId);
      _isInterested = true;
    }
    if (mounted) setState(() {});
  }

  Future<void> _addToCart(Product product) async {
    if (_quantity <= 0) return;

    setState(() => _addingToCart = true);

    try {
      await _marketplaceService.addToCart(product.id, _quantity);

      await _loadCartCount();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${product.name} to cart'),
            action: SnackBarAction(
              label: 'VIEW CART',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartScreen()),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding to cart: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _addingToCart = false);
      }
    }
  }

  List<String> _getDistrictsForState(String state) {
    // Replace with actual logic to get districts for a state
    return ['District 1', 'District 2', 'District 3'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          if (!snapshot.hasData) {
            return _buildErrorState('Product not found');
          }

          final product = snapshot.data!;
          // Reset dropdowns so they are not set by default from product/location
          _selectedState = null;
          _selectedDistrict = null;
          return _buildProductDetails(product);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 300,
                color: Colors.white,
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 24,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 150,
                      height: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: 100,
                      height: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 100,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Product Details',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Product',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _productFuture =
                      _marketplaceService.getProductById(widget.productId);
                  _reviewsFuture =
                      _marketplaceService.getProductReviews(widget.productId);
                });
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductDetails(Product product) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          floating: false,
          pinned: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          flexibleSpace: FlexibleSpaceBar(
            background: ProductImageGallery(imageUrls: product.imageUrls),
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart, color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const CartScreen()),
                    ).then((_) => _loadCartCount());
                  },
                ),
                if (_cartItemCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _cartItemCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.category,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    Text(
                      ' ${product.avgRating.toStringAsFixed(1)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      ' (${product.reviewCount})',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${product.price.toStringAsFixed(2)} / ${product.unit}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Status: ',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.grey[700]),
                    ),
                    Text(
                      product.status ?? 'available',
                      style: TextStyle(
                        color: product.status == 'sold'
                            ? Colors.red
                            : product.status == 'inactive'
                                ? Colors.grey
                                : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      product.location != null && product.location!.isNotEmpty
                          ? product.location!
                          : 'Location not specified',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${product.availableQuantity} ${product.unit} available',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Listed on ${DateFormat('MMM dd, yyyy').format(product.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                const Divider(height: 32),
                if (product.seller != null) _buildSellerInfo(product),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Quantity:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 16),
                    QuantitySelector(
                      initialValue: _quantity,
                      minValue: 1,
                      maxValue: product.availableQuantity,
                      onChanged: (value) {
                        setState(() {
                          _quantity = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text:
                            'Add to Cart : ₹${(product.price * _quantity).toStringAsFixed(2)}',
                        onPressed: _addingToCart ? null : () => _addToCart(product),
                        color: AppColors.primary,
                        textColor: Colors.white,
                        isLoading: _addingToCart,
                        icon: Icons.shopping_cart,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 32),
                _buildReviews(product),
                if (!_isSeller)
                  Row(
                    children: [
                      Flexible(
                        child: ElevatedButton.icon(
                          icon: Icon(_isInterested
                              ? Icons.favorite
                              : Icons.favorite_border),
                          label: Text(_isInterested
                              ? 'Unmark Interest'
                              : 'Mark Interest'),
                          onPressed: _toggleInterest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isInterested ? Colors.red : AppColors.primary,
                          ),
                        ),
                      ),
                      if (_contactPhone != null || _contactEmail != null)
                        const SizedBox(width: 12),
                      if (_contactPhone != null || _contactEmail != null)
                        Flexible(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.contact_phone),
                            label: const Text('Contact Seller'),
                            onPressed: () {
                              if (_contactPhone != null &&
                                  _contactPhone!.isNotEmpty) {
                                launchUrl(Uri.parse('tel:$_contactPhone'));
                              } else if (_contactEmail != null &&
                                  _contactEmail!.isNotEmpty) {
                                launchUrl(Uri.parse('mailto:$_contactEmail'));
                              }
                            },
                          ),
                        ),
                    ],
                  ),
                if (_isSeller && _interestedBuyers.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      const Text('Interested Buyers:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._interestedBuyers.map((buyer) => ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(buyer.displayName ?? 'User'),
                            subtitle: Text(buyer.email ?? ''),
                          )),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSellerInfo(Product product) {
    final seller = product.seller;
    // Prefer product.seller.phone/email if available, else fallback to _contactPhone/_contactEmail
    final phone = seller?.phone ?? _contactPhone;
    final email = seller?.email ?? _contactEmail;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Seller Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[200],
              backgroundImage: seller != null && seller.avatarUrl != null
                  ? CachedNetworkImageProvider(seller.avatarUrl!)
                  : null,
              child: (seller == null || seller.avatarUrl == null)
                  ? Text(
                      seller?.displayName?.isNotEmpty == true
                          ? seller!.displayName![0].toUpperCase()
                          : 'S',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    seller?.displayName != null &&
                            seller!.displayName!.isNotEmpty
                        ? seller!.displayName!
                        : 'Seller',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    seller?.location != null && seller!.location!.isNotEmpty
                        ? seller!.location!
                        : 'Location not available',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 16),
        if (phone != null && phone.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(child: Text('Phone: $phone')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => launchUrl(Uri.parse('tel:$phone')),
                  child: const Text('Call'),
                  style: ElevatedButton.styleFrom(minimumSize: Size(64, 36)),
                ),
              ],
            ),
          ),
        if (email != null && email.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.email, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Flexible(child: Text('Email: $email')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => launchUrl(Uri.parse('mailto:$email')),
                  child: const Text('Email'),
                  style: ElevatedButton.styleFrom(minimumSize: Size(64, 36)),
                ),
              ],
            ),
          ),
        const Divider(height: 16),
      ],
    );
  }

  Widget _buildReviews(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Reviews (${product.reviewCount})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (product.reviewCount > 0)
              TextButton(
                onPressed: () {
                  // Show all reviews
                },
                child: const Text('See All'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ProductReviewsList(reviewsFuture: _reviewsFuture),
        if (_canReviewProduct && !_hasReviewedProduct)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _reviewFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Write a Review', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Rating: '),
                          DropdownButton<int>(
                            value: _reviewRating,
                            items: List.generate(5, (i) => i + 1).map((v) => DropdownMenuItem(value: v, child: Text(v.toString()))).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _reviewRating = val);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Your review',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (val) => _reviewText = val,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your review';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (_reviewFormKey.currentState!.validate()) {
                              try {
                                await _marketplaceService.addProductReview(
                                  productId: widget.productId,
                                  rating: _reviewRating,
                                  reviewText: _reviewText,
                                );
                                setState(() {
                                  _hasReviewedProduct = true;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Review submitted!')),
                                );
                                // Optionally refresh reviews
                                setState(() {
                                  _reviewsFuture = _marketplaceService.getProductReviews(widget.productId);
                                });
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to submit review: \$e')),
                                );
                              }
                            }
                          },
                          child: const Text('Submit Review'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
