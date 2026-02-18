import 'package:kisan_veer/models/user_models.dart';

class Product {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final double price;
  final int availableQuantity;
  final String category;
  final String? subcategory;
  final List<String> imageUrls;
  final String? location;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final double avgRating;
  final int reviewCount;
  final UserProfile? seller;
  final String? status;
  final String? contactPhone;
  final String? contactEmail;

  Product({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.price,
    required this.availableQuantity,
    required this.category,
    this.subcategory,
    required this.imageUrls,
    this.location,
    required this.unit,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.avgRating,
    required this.reviewCount,
    this.seller,
    this.status,
    this.contactPhone,
    this.contactEmail,
  });

  factory Product.fromJson(Map<String, dynamic> json, {UserProfile? seller}) {
    List<String> imageList = [];
    if (json['image_urls'] != null) {
      if (json['image_urls'] is List) {
        imageList = List<String>.from(json['image_urls']);
      } else if (json['image_urls'] is String) {
        // Handle case where it might be a stringified JSON array
        try {
          final String imageString = json['image_urls'];
          if (imageString.startsWith('[') && imageString.endsWith(']')) {
            final trimmedString =
                imageString.substring(1, imageString.length - 1);
            imageList = trimmedString
                .split(',')
                .map((e) => e.trim().replaceAll('"', ''))
                .toList();
          } else {
            imageList = [imageString];
          }
        } catch (e) {
          imageList = [];
        }
      }
    }

    String parseString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    String parseStringNonNull(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    int parseInt(dynamic value) => value == null
        ? 0
        : (value is int ? value : int.tryParse(value.toString()) ?? 0);
    double parseDouble(dynamic value) => value == null
        ? 0.0
        : (value is double ? value : double.tryParse(value.toString()) ?? 0.0);

    return Product(
      id: parseStringNonNull(json['id']),
      sellerId: parseStringNonNull(json['seller_id']),
      name: parseStringNonNull(json['name']),
      description: parseStringNonNull(json['description']),
      price: parseDouble(json['price']),
      availableQuantity: parseInt(json['available_quantity']),
      category: parseStringNonNull(
          json['category'].toString().isEmpty ? 'Other' : json['category']),
      subcategory: parseString(json['subcategory']),
      imageUrls: imageList,
      location: parseString(json['location']),
      unit: parseStringNonNull(json['unit']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      isActive: json['is_active'] is bool
          ? json['is_active']
          : (json['is_active'] == null
              ? true
              : json['is_active'].toString() == 'true' ||
                  json['is_active'] == 1),
      avgRating: parseDouble(json['avg_rating']),
      reviewCount: parseInt(json['review_count']),
      seller: seller ??
          (json['user_profiles'] != null
              ? UserProfile.fromJson(json['user_profiles'])
              : null),
      status: parseString(json['status']),
      contactPhone: parseString(json['contact_phone']),
      contactEmail: parseString(json['contact_email']),
    );
  }

  Product copyWith({
    String? id,
    String? sellerId,
    String? name,
    String? description,
    double? price,
    int? availableQuantity,
    String? category,
    String? subcategory,
    List<String>? imageUrls,
    String? location,
    String? unit,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    double? avgRating,
    int? reviewCount,
    UserProfile? seller,
    String? status,
    String? contactPhone,
    String? contactEmail,
  }) {
    return Product(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      imageUrls: imageUrls ?? this.imageUrls,
      location: location ?? this.location,
      unit: unit ?? this.unit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      seller: seller ?? this.seller,
      status: status ?? this.status,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seller_id': sellerId,
      'name': name,
      'description': description,
      'price': price,
      'available_quantity': availableQuantity,
      'category': category,
      'subcategory': subcategory,
      'image_urls': imageUrls,
      'location': location,
      'unit': unit,
      'is_active': isActive,
      'status': status,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
    };
  }
}

class CartItem {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Product? product;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json, {Product? product}) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is double) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    String parseString(dynamic value) {
      if (value == null) return '';
      return value.toString(); // Ensure all ids are always String
    }

    return CartItem(
      id: parseString(json['id']),
      userId: parseString(json['user_id']),
      productId: parseString(json['product_id']),
      quantity: parseInt(json['quantity']),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
      product: product ??
          (json['products'] != null
              ? Product.fromJson(json['products'])
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
    };
  }

  CartItem copyWith({
    String? id,
    String? userId,
    String? productId,
    int? quantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    Product? product,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      product: product ?? this.product,
    );
  }
}

class Address {
  final String id;
  final String userId;
  final String name;
  final String fullAddress;
  final String city;
  final String state;
  final String pincode;
  final String phone;
  final bool isDefault;

  Address({
    required this.id,
    required this.userId,
    required this.name,
    required this.fullAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
    this.isDefault = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'] ?? '',
      fullAddress: json['full_address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      phone: json['phone'] ?? '',
      isDefault: json['is_default'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'full_address': fullAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
      'is_default': isDefault,
    };
  }
}

class ShippingAddress {
  final String fullName;
  final String streetAddress;
  final String city;
  final String state;
  final String pincode;
  final String phone;

  ShippingAddress({
    required this.fullName,
    required this.streetAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      fullName: json['full_name'] ?? '',
      streetAddress: json['street_address'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      pincode: json['pincode'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'street_address': streetAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
    };
  }
}

class Order {
  final String id;
  final String userId;
  final String status;
  final double totalAmount;
  Address address;
  final String? addressId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? paymentId;
  final String? paymentMethod;
  final List<CartItem>? items;

  Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalAmount,
    required this.address,
    this.addressId,
    required this.createdAt,
    required this.updatedAt,
    this.paymentId,
    this.paymentMethod,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json, {List<CartItem>? items}) {
    return Order(
      id: json['id'],
      userId: json['user_id'],
      status: json['status'] ?? 'pending',
      totalAmount: (json['total_amount'] is String)
          ? double.tryParse(json['total_amount']) ?? 0.0
          : (json['total_amount'] ?? 0.0).toDouble(),
      address: json['address'] != null
          ? Address.fromJson(json['address'])
          : Address(
              id: json['address_id'] ?? 'temp-address',
              userId: json['user_id'],
              name: '',
              fullAddress: '',
              city: '',
              state: '',
              pincode: '',
              phone: '',
            ),
      addressId: json['address_id'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      paymentId: json['payment_id'],
      paymentMethod: json['payment_method'],
      items: items,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'user_id': userId,
      'status': status,
      'total_amount': totalAmount,
      'address_id': addressId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    if (paymentId != null) data['payment_id'] = paymentId;
    if (paymentMethod != null) data['payment_method'] = paymentMethod;

    return data;
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final String sellerId;
  final int quantity;
  final double pricePerUnit;
  final double totalPrice;
  final DateTime createdAt;
  final Product? product;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.sellerId,
    required this.quantity,
    required this.pricePerUnit,
    required this.totalPrice,
    required this.createdAt,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json, {Product? product}) {
    return OrderItem(
      id: json['id'],
      orderId: json['order_id'],
      productId: json['product_id'],
      sellerId: json['seller_id'],
      quantity: json['quantity'] ?? 1,
      pricePerUnit: (json['price_per_unit'] is String)
          ? double.tryParse(json['price_per_unit']) ?? 0.0
          : (json['price_per_unit'] ?? 0.0).toDouble(),
      totalPrice: (json['total_price'] is String)
          ? double.tryParse(json['total_price']) ?? 0.0
          : (json['total_price'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      product: product ??
          (json['products'] != null
              ? Product.fromJson(json['products'])
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'seller_id': sellerId,
      'quantity': quantity,
      'price_per_unit': pricePerUnit,
      'total_price': totalPrice,
    };
  }
}

class ProductReview {
  final String id;
  final String productId;
  final String userId;
  final int rating;
  final String? reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserProfile? user;

  ProductReview({
    required this.id,
    required this.productId,
    required this.userId,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json,
      {UserProfile? user}) {
    return ProductReview(
      id: json['id'],
      productId: json['product_id'],
      userId: json['user_id'],
      rating: json['rating'] ?? 0,
      reviewText: json['review_text'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      user: user ??
          (json['user_profiles'] != null
              ? UserProfile.fromJson(json['user_profiles'])
              : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'user_id': userId,
      'rating': rating,
      'review_text': reviewText,
    };
  }
}

class OrderStatusHistory {
  final String id;
  final String orderId;
  final String status;
  final String? notes;
  final DateTime createdAt;
  final String? updatedBy;

  OrderStatusHistory({
    required this.id,
    required this.orderId,
    required this.status,
    this.notes,
    required this.createdAt,
    this.updatedBy,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistory(
      id: json['id'],
      orderId: json['order_id'],
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedBy: json['updated_by'],
    );
  }
}
