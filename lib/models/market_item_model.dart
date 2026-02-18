class MarketItemModel {
  final String id;
  final String sellerId;
  final String buyerId;
  final String productId;
  final String title;
  final String description;
  final double price;
  final double quantity;
  final String unit;
  final String status; // 'pending', 'accepted', 'rejected', 'completed'
  final DateTime createdAt;
  final DateTime updatedAt;

  MarketItemModel({
    required this.id,
    required this.sellerId,
    required this.buyerId,
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create an empty market item
  factory MarketItemModel.empty() {
    return MarketItemModel(
      id: '',
      sellerId: '',
      buyerId: '',
      productId: '',
      title: '',
      description: '',
      price: 0.0,
      quantity: 0.0,
      unit: 'kg',
      status: 'pending',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  // Convert from JSON for local storage
  factory MarketItemModel.fromJson(Map<String, dynamic> json) {
    return MarketItemModel(
      id: json['id'] ?? '',
      sellerId: json['sellerId'] ?? '',
      buyerId: json['buyerId'] ?? '',
      productId: json['productId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      quantity: (json['quantity'] ?? 0.0).toDouble(),
      unit: json['unit'] ?? 'kg',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  // Convert to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'productId': productId,
      'title': title,
      'description': description,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  MarketItemModel copyWith({
    String? id,
    String? sellerId,
    String? buyerId,
    String? productId,
    String? title,
    String? description,
    double? price,
    double? quantity,
    String? unit,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MarketItemModel(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      buyerId: buyerId ?? this.buyerId,
      productId: productId ?? this.productId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
