import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:kisan_veer/models/marketplace_models.dart';
import 'package:kisan_veer/models/user_models.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class MarketplaceService {
  final _supabase = Supabase.instance.client;
  final _uuid = Uuid();

  // Product Methods
  Future<List<Product>> getProducts({
    String? searchQuery,
    String? category,
    String? sortBy,
    bool showUserProducts = false,
  }) async {
    dynamic query = _supabase
        .from('products')
        .select('*, user_profiles!inner(*)')
        .eq('is_active', true);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query
          .or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
    }

    if (category != null && category.isNotEmpty && category != 'All') {
      query = query.eq('category', category);
    }

    // Filter for user's products if requested
    final userId = _supabase.auth.currentUser?.id;
    if (showUserProducts && userId != null) {
      query = query.eq('seller_id', userId);
    }

    // Apply sorting
    if (sortBy != null) {
      switch (sortBy) {
        case 'price_low':
          query = query.order('price', ascending: true);
          break;
        case 'price_high':
          query = query.order('price', ascending: false);
          break;
        case 'rating':
          query = query.order('avg_rating', ascending: false);
          break;
        case 'newest':
          query = query.order('created_at', ascending: false);
          break;
        default:
          query = query.order('created_at', ascending: false);
      }
    } else {
      query = query.order('created_at', ascending: false);
    }

    final response = await query;

    return (response as List)
        .map((row) => Product.fromJson(
              row,
              seller: UserProfile.fromJson(row['user_profiles']),
            ))
        .toList();
  }

  Future<Product> getProductById(String productId) async {
    final response = await _supabase
        .from('products')
        .select(
            '*, user_profiles:seller_id(id, display_name, location, phone, email)')
        .eq('id', productId)
        .single();

    return Product.fromJson(
      response,
      seller: response['user_profiles'] != null
          ? UserProfile.fromJson(response['user_profiles'])
          : null,
    );
  }

  Future<List<String>> uploadProductImages(List<File> images) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final imageUrls = <String>[];

    try {
      // Get list of available buckets to find the correct one
      final buckets = await _supabase.storage.listBuckets();
      String bucketName = '';

      // Use the first available bucket, or default to 'storage'
      if (buckets.isNotEmpty) {
        bucketName = buckets.first.name;
      } else {
        bucketName = 'storage'; // Default Supabase bucket
      }

      print('Using bucket: $bucketName');

      for (var image in images) {
        final fileExt = path.extension(image.path);
        final fileName = '${_uuid.v4()}$fileExt';
        final filePath = 'products/$userId/$fileName';

        await _supabase.storage.from(bucketName).upload(
              filePath,
              image,
              fileOptions:
                  const FileOptions(cacheControl: '3600', upsert: false),
            );

        final imageUrl =
            _supabase.storage.from(bucketName).getPublicUrl(filePath);
        imageUrls.add(imageUrl);
      }

      return imageUrls;
    } catch (e) {
      print('Error uploading images: $e');

      // If we can't upload images, create placeholder URLs for now
      if (imageUrls.isEmpty && images.isNotEmpty) {
        // Create placeholder image URLs so we can still create the product
        for (int i = 0; i < images.length; i++) {
          imageUrls.add('placeholder_image_${i + 1}');
        }
      }

      return imageUrls;
    }
  }

  Future<Product> createProduct({
    required String name,
    required String description,
    required double price,
    required int availableQuantity,
    required String category,
    String? subcategory,
    required List<String> imageUrls,
    String? location,
    required String unit,
    String status = 'available',
    String? contactPhone,
    String? contactEmail,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final data = {
      'seller_id': userId.toString(),
      'name': name,
      'description': description,
      'price': price,
      'available_quantity': availableQuantity,
      'category': category,
      'subcategory': subcategory,
      'image_urls': imageUrls,
      'location': location,
      'unit': unit,
      'status': status,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
    };

    // Remove nulls and ensure all values are correct type for Supabase
    data.removeWhere((k, v) => v == null);

    try {
      final response =
          await _supabase.from('products').insert(data).select('*').single();

      final userProfile = await _supabase
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();

      return Product.fromJson(
        response,
        seller: UserProfile.fromJson(userProfile),
      );
    } catch (e, stack) {
      print('Error adding product: $e\n$stack');
      rethrow;
    }
  }

  Future<void> updateProduct({
    required String productId,
    String? name,
    String? description,
    double? price,
    int? availableQuantity,
    String? category,
    String? subcategory,
    List<String>? imageUrls,
    String? location,
    String? unit,
    bool? isActive,
    String? status,
    String? contactPhone,
    String? contactEmail,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name;
    if (description != null) updateData['description'] = description;
    if (price != null) updateData['price'] = price;
    if (availableQuantity != null)
      updateData['available_quantity'] = availableQuantity;
    if (category != null) updateData['category'] = category;
    if (subcategory != null) updateData['subcategory'] = subcategory;
    if (imageUrls != null) updateData['image_urls'] = imageUrls;
    if (location != null) updateData['location'] = location;
    if (unit != null) updateData['unit'] = unit;
    if (isActive != null) updateData['is_active'] = isActive;
    if (status != null) updateData['status'] = status;
    if (contactPhone != null) updateData['contact_phone'] = contactPhone;
    if (contactEmail != null) updateData['contact_email'] = contactEmail;
    updateData['updated_at'] = DateTime.now().toIso8601String();

    await _supabase
        .from('products')
        .update(updateData)
        .eq('id', productId)
        .eq('seller_id', userId);
  }

  Future<void> deleteProduct(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase
        .from('products')
        .delete()
        .eq('id', productId)
        .eq('seller_id', userId);
  }

  // Cart Methods
  Future<List<CartItem>> getCartItems() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _supabase
        .from('cart_items')
        .select('*, products!inner(*, user_profiles(*))')
        .eq('user_id', userId);

    return response.map((row) {
      final product = Product.fromJson(
        row['products'],
        seller: UserProfile.fromJson(row['products']['user_profiles']),
      );

      return CartItem.fromJson(row, product: product);
    }).toList();
  }

  Future<CartItem> addToCart(String productId, int quantity) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Check if item already exists in cart
    final existing = await _supabase
        .from('cart_items')
        .select()
        .eq('user_id', userId)
        .eq('product_id', productId);

    Map<String, dynamic> data;

    if (existing.isNotEmpty) {
      // Update existing item
      final currentQuantity = existing[0]['quantity'] as int;
      data = await _supabase
          .from('cart_items')
          .update({
            'quantity': currentQuantity + quantity,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('product_id', productId)
          .select('*, products!inner(*, user_profiles(*))')
          .single();
    } else {
      // Add new item
      data = await _supabase
          .from('cart_items')
          .insert({
            'user_id': userId,
            'product_id': productId,
            'quantity': quantity,
          })
          .select('*, products!inner(*, user_profiles(*))')
          .single();
    }

    final product = Product.fromJson(
      data['products'],
      seller: UserProfile.fromJson(data['products']['user_profiles']),
    );

    return CartItem.fromJson(data, product: product);
  }

  Future<CartItem> updateCartItemQuantity(
      String cartItemId, int quantity) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final data = await _supabase
        .from('cart_items')
        .update({
          'quantity': quantity,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', cartItemId)
        .eq('user_id', userId)
        .select('*, products!inner(*, user_profiles(*))')
        .single();

    final product = Product.fromJson(
      data['products'],
      seller: UserProfile.fromJson(data['products']['user_profiles']),
    );

    return CartItem.fromJson(data, product: product);
  }

  Future<void> removeFromCart(String cartItemId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase
        .from('cart_items')
        .delete()
        .eq('id', cartItemId)
        .eq('user_id', userId);
  }

  Future<void> clearCart() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase.from('cart_items').delete().eq('user_id', userId);
  }

  // Address Methods
  Future<String> getCurrentUserId() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    return userId;
  }

  Future<List<Address>> getSavedAddresses() async {
    final userId = await getCurrentUserId();

    final response = await _supabase
        .from('addresses')
        .select()
        .eq('user_id', userId)
        .order('is_default', ascending: false);

    return response.map((row) => Address.fromJson(row)).toList();
  }

  Future<Address> saveAddress(Address address) async {
    final userId = await getCurrentUserId();

    // If this is the first address or marked as default, reset other defaults
    if (address.isDefault) {
      await _supabase
          .from('addresses')
          .update({'is_default': false}).eq('user_id', userId);
    }

    final data = await _supabase
        .from('addresses')
        .insert(address.toJson())
        .select()
        .single();

    return Address.fromJson(data);
  }

  // Order Methods
  Future<Order> createOrder(Order order) async {
    // Verify user authentication
    await getCurrentUserId();

    if (order.items == null || order.items!.isEmpty) {
      throw Exception('Order items cannot be empty');
    }

    // Create order in the database
    await _supabase.from('orders').insert(order.toJson());

    // Create order items
    if (order.items != null && order.items!.isNotEmpty) {
      for (var item in order.items!) {
        if (item.product == null) continue;

        await _supabase.from('order_items').insert({
          'id': const Uuid().v4(),
          'order_id': order.id,
          'product_id': item.productId,
          'seller_id': item.product!.sellerId,
          'quantity': item.quantity,
          'price_per_unit': item.product!.price,
          'total_price': item.product!.price * item.quantity,
        });
      }
    }

    // Add status history
    await _supabase.from('order_status_history').insert({
      'id': const Uuid().v4(),
      'order_id': order.id,
      'status': order.status,
      'notes': 'Order created and payment confirmed via ${order.paymentMethod}',
      'created_at': DateTime.now().toIso8601String(),
    });

    return order;
  }

  Future<List<Order>> getOrders() async {
    final userId = await getCurrentUserId();

    final response = await _supabase
        .from('orders')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final orders = response.map((row) => Order.fromJson(row)).toList();

    // Fetch items for each order
    for (var i = 0; i < orders.length; i++) {
      final order = orders[i];
      final itemsResponse = await _supabase
          .from('order_items')
          .select('*, products(*)')
          .eq('order_id', order.id);

      final items = <CartItem>[];
      for (var item in itemsResponse) {
        // Convert OrderItem to CartItem for UI consistency
        final product = Product.fromJson(item['products']);
        items.add(CartItem(
          id: item['id'],
          userId: userId,
          productId: item['product_id'],
          quantity: item['quantity'],
          createdAt: item['created_at'],
          updatedAt: DateTime.now(),
          product: product,
        ));
      }

      // Update the order with its items
      orders[i] = Order(
        id: order.id,
        userId: order.userId,
        status: order.status,
        totalAmount: order.totalAmount,
        address: order.address,
        addressId: order.addressId,
        createdAt: order.createdAt,
        updatedAt: order.updatedAt,
        paymentId: order.paymentId,
        paymentMethod: order.paymentMethod,
        items: items,
      );
    }

    return orders;
  }

  Future<Order> getOrderById(String orderId) async {
    final userId = await getCurrentUserId();

    final response = await _supabase
        .from('orders')
        .select('*, addresses(*)')
        .eq('id', orderId)
        .eq('user_id', userId)
        .single();

    final orderData = Order.fromJson(response);

    // If address is nested, parse it correctly
    if (response['addresses'] != null) {
      orderData.address = Address.fromJson(response['addresses']);
    }

    // Fetch order items
    final itemsResponse = await _supabase
        .from('order_items')
        .select('*, products(*)')
        .eq('order_id', orderId);

    final items = <CartItem>[];
    for (var item in itemsResponse) {
      final product = Product.fromJson(item['products']);
      items.add(CartItem(
        id: item['id'],
        userId: userId,
        productId: item['product_id'],
        quantity: item['quantity'],
        createdAt: DateTime.parse(item['created_at']),
        updatedAt: DateTime.parse(item['created_at']),
        product: product,
      ));
    }

    return Order(
      id: orderData.id,
      userId: orderData.userId,
      status: orderData.status,
      totalAmount: orderData.totalAmount,
      address: orderData.address,
      addressId: orderData.addressId,
      createdAt: orderData.createdAt,
      updatedAt: orderData.updatedAt,
      paymentId: orderData.paymentId,
      paymentMethod: orderData.paymentMethod,
      items: items,
    );
  }

  // Modified Order Method that supports our new Order model
  Future<Order> createOrderFromCart({
    required double totalAmount,
    required Address address,
    required String paymentMethod,
    String? paymentId,
  }) async {
    final userId = await getCurrentUserId();

    // Get cart items
    final cartItems = await getCartItems();
    if (cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    final orderId = _uuid.v4();

    // Create the order object
    final order = Order(
      id: orderId,
      userId: userId,
      status: 'confirmed',
      totalAmount: totalAmount,
      address: address,
      addressId: address.id,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      paymentMethod: paymentMethod,
      paymentId: paymentId,
      items: cartItems,
    );

    // Create order in the database
    await _supabase.from('orders').insert(order.toJson());

    // Create order items
    for (final cartItem in cartItems) {
      if (cartItem.product == null) continue;
      await _supabase.from('order_items').insert({
        'id': _uuid.v4(),
        'order_id': order.id,
        'product_id': cartItem.productId,
        'seller_id': cartItem.product!.sellerId,
        'quantity': cartItem.quantity,
        'price_per_unit': cartItem.product!.price,
        'total_price': cartItem.product!.price * cartItem.quantity,
      });
    }

    // Insert estimated delivery date for the order (default: 5 days from now)
    final estimatedDelivery = DateTime.now().add(const Duration(days: 5));
    await _supabase.from('order_delivery').insert({
      'order_id': order.id,
      'estimated_delivery_date': estimatedDelivery.toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Add status history
    await _supabase.from('order_status_history').insert({
      'id': const Uuid().v4(),
      'order_id': order.id,
      'status': order.status,
      'notes': 'Order created and payment confirmed via ${order.paymentMethod}',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Clear cart after order creation
    await clearCart();

    return order;
  }

  Future<void> updateOrderPayment(
      String orderId, String paymentId, String status) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _supabase
        .from('orders')
        .update({
          'payment_id': paymentId,
          'payment_status': status,
          'status': status == 'completed' ? 'confirmed' : 'pending',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId)
        .eq('user_id', userId);
  }

  // Fetches user's orders with optional filtering by status
  Future<List<Order>> getUserOrders({String? status}) async {
    final userId = await getCurrentUserId();

    var query = _supabase.from('orders').select().eq('user_id', userId);

    // Apply status filter if provided
    if (status != null && status.isNotEmpty) {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);
    final List<Order> orders = [];
    for (final row in response) {
      final orderId = row['id'] as String;
      // Use getOrderWithItems to fetch items and address
      final order = await getOrderWithItems(orderId);
      orders.add(order);
    }
    return orders;
  }

  Future<Order> getOrderWithItems(String orderId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Fetch order (no join)
    final orderData = await _supabase
        .from('orders')
        .select()
        .eq('id', orderId)
        .eq('user_id', userId)
        .single();

    // Fetch address if address_id exists
    Address? address;
    if (orderData['address_id'] != null && (orderData['address_id'] as String).isNotEmpty) {
      final addressData = await _supabase
          .from('addresses')
          .select()
          .eq('id', orderData['address_id'])
          .single();
      address = Address.fromJson(addressData);
    } else if (orderData['address'] != null && orderData['address'] is Map<String, dynamic>) {
      address = Address.fromJson(orderData['address']);
    }

    // Fetch order items
    final orderItemsData = await _supabase
        .from('order_items')
        .select('*, products!inner(*, user_profiles(*))')
        .eq('order_id', orderId);

    final orderItems = orderItemsData.map((row) {
      final product = Product.fromJson(
        row['products'],
        seller: UserProfile.fromJson(row['products']['user_profiles']),
      );
      return OrderItem.fromJson(row, product: product);
    }).toList();

    // Convert OrderItem list to CartItem list for Order constructor
    final cartItems = orderItems
        .map((item) => CartItem(
              id: item.id,
              userId: orderData['user_id'],
              productId: item.productId,
              quantity: item.quantity,
              createdAt: item.createdAt,
              updatedAt: DateTime.now(),
              product: item.product,
            ))
        .toList();

    return Order(
      id: orderData['id'],
      userId: orderData['user_id'],
      status: orderData['status'] ?? 'pending',
      totalAmount: (orderData['total_amount'] is String)
          ? double.tryParse(orderData['total_amount']) ?? 0.0
          : (orderData['total_amount'] ?? 0.0),
      address: address ?? Address(
        id: '',
        userId: '',
        name: '',
        fullAddress: '',
        city: '',
        state: '',
        pincode: '',
        phone: '',
      ),
      addressId: orderData['address_id'],
      createdAt: DateTime.parse(orderData['created_at']),
      updatedAt: DateTime.parse(orderData['updated_at']),
      paymentId: orderData['payment_id'],
      paymentMethod: orderData['payment_method'],
      items: cartItems,
    );
  }

  // Get order status history with timestamps
  Future<List<OrderStatusHistory>> getOrderStatusHistory(String orderId) async {
    final response = await _supabase
        .from('order_status_history')
        .select()
        .eq('order_id', orderId)
        .order('created_at', ascending: true);

    return response.map((row) => OrderStatusHistory.fromJson(row)).toList();
  }

  // Cancels an order if it's in a cancellable state
  Future<bool> cancelOrder(String orderId) async {
    final userId = await getCurrentUserId();

    // First check if the order exists and belongs to the user
    final orderQuery = await _supabase
        .from('orders')
        .select()
        .eq('id', orderId)
        .eq('user_id', userId)
        .single();

    final order = Order.fromJson(orderQuery);

    // Determine if order can be cancelled based on status
    if (!_isOrderCancellable(order.status)) {
      throw Exception(
          'Order cannot be cancelled in its current state: ${order.status}');
    }

    // Update order status to cancelled
    await _supabase
        .from('orders')
        .update({
          'status': 'cancelled',
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', orderId)
        .eq('user_id', userId);

    // Add entry to status history
    await _supabase.from('order_status_history').insert({
      'id': _uuid.v4(),
      'order_id': orderId,
      'status': 'cancelled',
      'notes': 'Order cancelled by customer',
      'created_at': DateTime.now().toIso8601String(),
    });

    return true;
  }

  // Determines if an order can be cancelled based on its status
  bool _isOrderCancellable(String status) {
    // Only allow cancellation for orders that haven't been shipped
    final cancellableStatuses = [
      'pending',
      'confirmed',
      'processing',
      'payment_pending',
    ];

    return cancellableStatuses.contains(status.toLowerCase());
  }

  // Fetches the estimated delivery date for an order
  Future<DateTime?> getEstimatedDeliveryDate(String orderId) async {
    try {
      final response = await _supabase
          .from('order_delivery')
          .select('estimated_delivery_date')
          .eq('order_id', orderId)
          .single();

      if (response['estimated_delivery_date'] != null) {
        return DateTime.parse(response['estimated_delivery_date']);
      }

      // If no specific delivery date found, calculate based on order date
      final orderResponse = await _supabase
          .from('orders')
          .select('created_at')
          .eq('id', orderId)
          .single();

      if (orderResponse['created_at'] != null) {
        // Default to 5 days after order creation
        final orderDate = DateTime.parse(orderResponse['created_at']);
        return orderDate.add(const Duration(days: 5));
      }

      return null;
    } catch (e) {
      print('Error getting delivery date: $e');
      return null;
    }
  }

  // Future<void> updateOrderStatus(String orderId, String status, {String? notes}) async {
  //   final userId = _supabase.auth.currentUser?.id;
  //   if (userId == null) {
  //     throw Exception('User not authenticated');
  //   }

  //   // Verify the user is the seller of at least one item in this order
  //   final sellerCheck = await _supabase
  //       .from('order_items')
  //       .select('id')
  //       .eq('order_id', orderId)
  //       .eq('seller_id', userId);

  //   if (sellerCheck.isEmpty) {
  //     throw Exception('You are not authorized to update this order');
  //   }

  //   // Update order status
  //   await _supabase
  //       .from('orders')
  //       .update({
  //         'status': status,
  //         'updated_at': DateTime.now().toIso8601String(),
  //       })
  //       .eq('id', orderId);

  //   // Add status update to history
  //   await _supabase.from('order_status_history').insert({
  //     'id': _uuid.v4(),
  //     'order_id': orderId,
  //     'status': status,
  //     'notes': notes ?? 'Status updated to $status by seller',
  //     'created_at': DateTime.now().toIso8601String(),
  //     'created_by': userId,
  //   });

  //   // Update delivery date if order is marked as shipped
  //   if (status.toLowerCase() == 'shipped') {
  //     // Calculate estimated delivery date (5 days from now)
  //     final estimatedDelivery = DateTime.now().add(const Duration(days: 5));

  //     try {
  //       await _supabase.from('order_delivery').upsert({
  //         'order_id': orderId,
  //         'estimated_delivery_date': estimatedDelivery.toIso8601String(),
  //         'updated_at': DateTime.now().toIso8601String(),
  //       });
  //     } catch (e) {
  //       print('Error updating delivery date: $e');
  //       // Continue even if delivery date update fails
  //     }
  //   }
  // }

  // Create a stream for order updates
  Stream<Order> getOrderUpdatesStream(String orderId) async* {
    // Initial fetch
    final order = await getOrderWithItems(orderId);
    yield order;

    // Poll for updates every 10 seconds
    while (true) {
      await Future.delayed(const Duration(seconds: 10));
      try {
        final updatedOrder = await getOrderWithItems(orderId);
        yield updatedOrder;
      } catch (e) {
        print('Error polling order updates: $e');
      }
    }
  }

  // Create a stream for order status history updates
  Stream<List<OrderStatusHistory>> getOrderStatusHistoryStream(
      String orderId) async* {
    // Initial fetch
    final statusHistory = await getOrderStatusHistory(orderId);
    yield statusHistory;

    // Poll for updates every 10 seconds
    while (true) {
      await Future.delayed(const Duration(seconds: 10));
      try {
        final updatedStatusHistory = await getOrderStatusHistory(orderId);
        yield updatedStatusHistory;
      } catch (e) {
        print('Error polling status history updates: $e');
      }
    }
  }

  // Product Reviews
  Future<List<ProductReview>> getProductReviews(String productId) async {
    final response = await _supabase
        .from('product_reviews')
        .select('*, user_profiles(*)')
        .eq('product_id', productId)
        .order('created_at', ascending: false);

    return response
        .map((row) => ProductReview.fromJson(
              row,
              user: UserProfile.fromJson(row['user_profiles']),
            ))
        .toList();
  }

  // Future<ProductReview> addProductReview({
  //   required String productId,
  //   required int rating,
  //   String? reviewText,
  // }) async {
  //   final userId = _supabase.auth.currentUser?.id;
  //   if (userId == null) {
  //     throw Exception('User not authenticated');
  //   }

  //   // Check if user has purchased this product
  //   final purchases = await _supabase
  //       .from('order_items')
  //       .select('orders!inner(*)')
  //       .eq('product_id', productId)
  //       .eq('orders.user_id', userId)
  //       .eq('orders.status', 'delivered');

  //   if (purchases.isEmpty) {
  //     throw Exception('You can only review products you have purchased');
  //   }

  //   // Check if user has already reviewed this product
  //   final existingReview = await _supabase
  //       .from('product_reviews')
  //       .select()
  //       .eq('product_id', productId)
  //       .eq('user_id', userId);

  //   Map<String, dynamic> data;

  //   if (existingReview.isNotEmpty) {
  //     // Update existing review
  //     data = await _supabase
  //         .from('product_reviews')
  //         .update({
  //           'rating': rating,
  //           'review_text': reviewText,
  //           'updated_at': DateTime.now().toIso8601String(),
  //         })
  //         .eq('product_id', productId)
  //         .eq('user_id', userId)
  //         .select('*, user_profiles(*)')
  //         .single();
  //   } else {
  //     // Add new review
  //     data = await _supabase
  //         .from('product_reviews')
  //         .insert({
  //           'product_id': productId,
  //           'user_id': userId,
  //           'rating': rating,
  //           'review_text': reviewText,
  //         })
  //         .select('*, user_profiles(*)')
  //         .single();
  //   }

  //   return ProductReview.fromJson(
  //     data,
  //     user: UserProfile.fromJson(data['user_profiles']),
  //   );
  // }

  // Polling-based subscription for order updates
  Stream<Map<String, dynamic>> subscribeToOrderUpdates(String orderId) async* {
    Map<String, dynamic>? lastData;

    while (true) {
      try {
        final data =
            await _supabase.from('orders').select().eq('id', orderId).single();

        // Only yield if data has changed
        if (lastData == null || !_mapsEqual(lastData, data)) {
          lastData = data;
          yield data;
        }
      } catch (e) {
        print('Error polling order updates: $e');
      }

      // Wait before polling again
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // Polling-based subscription for notifications
  Stream<List<Map<String, dynamic>>> subscribeToNewNotifications(
      String userId) async* {
    List<String> processedIds = [];

    while (true) {
      try {
        final data = await _supabase
            .from('notifications')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(10);

        // Filter out notifications we've already processed
        final newNotifications = data.where((notification) {
          return !processedIds.contains(notification['id']);
        }).toList();

        // Add new notification IDs to processed list
        for (var notification in newNotifications) {
          processedIds.add(notification['id']);
        }

        // Only yield if there are new notifications
        if (newNotifications.isNotEmpty) {
          yield newNotifications.cast<Map<String, dynamic>>();
        }

        // Limit the size of processedIds to prevent memory growth
        if (processedIds.length > 100) {
          processedIds = processedIds.sublist(processedIds.length - 100);
        }
      } catch (e) {
        print('Error polling notifications: $e');
      }

      // Wait before polling again
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  // Helper method to compare maps
  bool _mapsEqual(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    if (map1.length != map2.length) return false;

    for (final key in map1.keys) {
      if (!map2.containsKey(key) || map1[key] != map2[key]) {
        return false;
      }
    }

    return true;
  }

  Future<bool> updateOrderStatus(String orderId, String newStatus,
      {String? notes}) async {
    final userId = await getCurrentUserId();

    try {
      // Update the order status
      await _supabase.from('orders').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', orderId);

      // Add entry to status history
      await _supabase.from('order_status_history').insert({
        'id': _uuid.v4(),
        'order_id': orderId,
        'status': newStatus,
        'notes': (newStatus == 'pending' || newStatus == 'confirmed' || newStatus == 'packed' || newStatus == 'shipped' || newStatus == 'delivered' || newStatus == 'cancelled') ? null : (notes ?? 'Status updated to $newStatus'),
        'created_at': DateTime.now().toIso8601String(),
        'updated_by': userId,
      });

      return true;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  Future<void> addProductReview({
    required String productId,
    required int rating,
    String? reviewText,
  }) async {
    final userId = await getCurrentUserId();

    try {
      await _supabase.from('product_reviews').insert({
        'id': _uuid.v4(),
        'product_id': productId,
        'user_id': userId,
        'rating': rating,
        'review_text': reviewText ?? '',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding review: $e');
      throw Exception('Failed to add review: $e');
    }
  }

  // --- MARKETPLACE ENHANCEMENTS (2025-04-21) --- //

  // Mark a product as sold
  Future<void> markProductAsSold(String productId) async {
    await _supabase.from('products').update({
      'status': 'sold',
      'is_active': false,
      'updated_at': DateTime.now().toIso8601String()
    }).eq('id', productId);
  }

  // Interested Buyers CRUD
  Future<void> markInterested(
      {required String productId, String? contactMessage}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _supabase.from('interested_buyers').upsert({
      'product_id': productId,
      'user_id': userId,
      'contact_message': contactMessage,
      'created_at': DateTime.now().toIso8601String(),
    }, onConflict: 'product_id,user_id');
  }

  Future<void> unmarkInterested(String productId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');
    await _supabase
        .from('interested_buyers')
        .delete()
        .eq('product_id', productId)
        .eq('user_id', userId);
  }

  Future<List<UserProfile>> getInterestedBuyers(String productId) async {
    final response = await _supabase
        .from('interested_buyers')
        .select('user_id, user_profiles:user_id(*)')
        .eq('product_id', productId);
    return response
        .map<UserProfile>((row) => UserProfile.fromJson(row['user_profiles']))
        .toList();
  }

  Future<List<Product>> getProductsByStatus(String status) async {
    final response = await _supabase
        .from('products')
        .select('*, user_profiles!inner(*)')
        .eq('status', status)
        .order('created_at', ascending: false);
    return response
        .map((row) => Product.fromJson(row,
            seller: UserProfile.fromJson(row['user_profiles'])))
        .toList();
  }

  // Admin: get all products (any status)
  Future<List<Product>> getAllProductsAdmin() async {
    final response = await _supabase
        .from('products')
        .select('*, user_profiles!inner(*)')
        .order('created_at', ascending: false);
    return response
        .map((row) => Product.fromJson(row,
            seller: UserProfile.fromJson(row['user_profiles'])))
        .toList();
  }

  // Real-time stream for products table
  Stream<List<Product>> getProductsStream() {
    return _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .map((data) =>
            data.map<Product>((row) => Product.fromJson(row)).toList());
  }

  /// Checks if the current user can review the given product (i.e., has a delivered order for it)
  Future<bool> canUserReviewProduct(String productId) async {
    final userId = await getCurrentUserId();
    if (userId == null) return false;
    final response = await _supabase
        .from('order_items')
        .select('orders!inner(status, user_id)')
        .eq('product_id', productId)
        .eq('orders.user_id', userId)
        .eq('orders.status', 'delivered');
    return response.isNotEmpty;
  }

  // Fetch seller contact info for a product
  Future<Map<String, String?>> getSellerContact(String productId) async {
    final response = await _supabase
        .from('products')
        .select('contact_phone, contact_email')
        .eq('id', productId)
        .single();
    return {
      'phone': response['contact_phone'] as String?,
      'email': response['contact_email'] as String?,
    };
  }

  // --- END MARKETPLACE ENHANCEMENTS --- //

  Future<Map<String, dynamic>> getMarketplaceStats() async {
    try {
      // Top categories by sales
      final topCategoriesResponse = await _supabase
          .from('order_items')
          .select('products!inner(category)')
          .order('created_at', ascending: false);

      // Count by category
      Map<String, int> categoryCounts = {};
      for (var item in topCategoriesResponse) {
        final category = item['products']['category'] as String;
        categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
      }

      // Sort by count
      final sortedCategories = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Get total products, orders
      final productsCount = await _supabase.from('products').select();

      final ordersCount = await _supabase.from('orders').select();

      return {
        'top_categories': sortedCategories.take(5).toList(),
        'products_count': productsCount.length,
        'orders_count': ordersCount.length,
      };
    } catch (e) {
      print('Error fetching marketplace stats: $e');
      return {
        'top_categories': [],
        'products_count': 0,
        'orders_count': 0,
      };
    }
  }

  Future<List<Product>> getSellerProducts() async {
    final userId = await getCurrentUserId();

    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('seller_id', userId)
          .order('created_at', ascending: false);

      return response.map((row) => Product.fromJson(row)).toList();
    } catch (e) {
      print('Error fetching seller products: $e');
      return [];
    }
  }

  Future<List<Product>> searchProducts({
    String? query,
    String? category,
    double? minPrice,
    double? maxPrice,
    bool? isOrganic,
  }) async {
    var dbQuery = _supabase
        .from('products')
        .select('*, user_profiles!inner(*)')
        .eq('is_active', true);

    // Search by text in name or description
    if (query != null && query.isNotEmpty) {
      dbQuery = dbQuery.or('name.ilike.%$query%,description.ilike.%$query%');
    }

    // Filter by category
    if (category != null && category.isNotEmpty && category != 'All') {
      dbQuery = dbQuery.eq('category', category);
    }

    // Filter by price range
    if (minPrice != null) {
      dbQuery = dbQuery.gte('price', minPrice);
    }

    if (maxPrice != null) {
      dbQuery = dbQuery.lte('price', maxPrice);
    }

    // Filter organic products
    if (isOrganic == true) {
      dbQuery = dbQuery.ilike('description', '%ORGANIC%');
    }

    final response = await dbQuery.order('created_at', ascending: false);

    return (response as List)
        .map((row) => Product.fromJson(
              row,
              seller: UserProfile.fromJson(row['user_profiles']),
            ))
        .toList();
  }
}
