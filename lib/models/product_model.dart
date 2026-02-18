class ProductModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category;
  final double quantity;
  final String unit; // kg, gram, litre, etc.
  final List<String> imageUrls;
  final String sellerId;
  final String location;
  final Map<String, double>? coordinates;
  final bool isAvailable;
  final bool isFeatured;
  final int viewCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.imageUrls,
    required this.sellerId,
    required this.location,
    this.coordinates,
    required this.isAvailable,
    required this.isFeatured,
    required this.viewCount,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create an empty product
  factory ProductModel.empty() {
    return ProductModel(
      id: '',
      name: '',
      description: '',
      price: 0.0,
      category: '',
      quantity: 0.0,
      unit: 'kg',
      imageUrls: [],
      sellerId: '',
      location: '',
      isAvailable: true,
      isFeatured: false,
      viewCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Create from JSON for local storage
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: parseDouble(json['price']),
      category: json['category']?.toString() ?? '',
      quantity: parseDouble(json['quantity']),
      unit: json['unit']?.toString() ?? 'kg',
      imageUrls: (() {
        final val = json['imageUrls'];
        if (val == null) return <String>[];
        if (val is List) {
          // Defensive: convert all elements to String and cast to List<String>
          return List<String>.from(
              val.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty));
        }
        if (val is String) {
          // Try to parse as JSON array string
          if (val.startsWith('[') && val.endsWith(']')) {
            final trimmed = val.substring(1, val.length - 1);
            return List<String>.from(trimmed
                .split(',')
                .map((e) => e.trim().replaceAll('"', ''))
                .where((e) => e.isNotEmpty));
          }
          return <String>[val];
        }
        // Defensive: if int, double, or any other type, cast to String
        return <String>[val.toString()];
      })(),
      sellerId: json['sellerId']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      coordinates: json['coordinates'] != null
          ? Map<String, double>.from(json['coordinates'])
          : null,
      isAvailable: json['isAvailable'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      viewCount: json['viewCount'] ?? 0,
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
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'imageUrls': imageUrls,
      'sellerId': sellerId,
      'location': location,
      'coordinates': coordinates,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'viewCount': viewCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy with modified fields
  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    double? quantity,
    String? unit,
    List<String>? imageUrls,
    String? sellerId,
    String? location,
    Map<String, double>? coordinates,
    bool? isAvailable,
    bool? isFeatured,
    int? viewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerId: sellerId ?? this.sellerId,
      location: location ?? this.location,
      coordinates: coordinates ?? this.coordinates,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      viewCount: viewCount ?? this.viewCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ProductModel{id: $id, name: $name, price: $price, category: $category}';
  }
}
