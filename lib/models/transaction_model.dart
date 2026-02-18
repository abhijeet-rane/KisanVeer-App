class TransactionModel {
  final String id;
  final String title;
  final String description;
  final double amount;
  final String type; // income, expense
  final String category; // seeds, fertilizer, equipment, sales, etc.
  final DateTime date;
  final String userId;
  final String attachmentUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.userId,
    this.attachmentUrl = '',
    required this.createdAt,
    required this.updatedAt,
  });

  // Create an empty transaction
  factory TransactionModel.empty() {
    return TransactionModel(
      id: '',
      title: '',
      description: '',
      amount: 0.0,
      type: 'expense',
      category: 'other',
      date: DateTime.now(),
      userId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  // Convert from JSON for local storage
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      type: json['type'] ?? 'expense',
      category: json['category'] ?? 'other',
      date: json['date'] != null 
          ? DateTime.parse(json['date']) 
          : DateTime.now(),
      userId: json['userId'] ?? '',
      attachmentUrl: json['attachmentUrl'] ?? '',
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
      'title': title,
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
      'userId': userId,
      'attachmentUrl': attachmentUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  TransactionModel copyWith({
    String? id,
    String? title,
    String? description,
    double? amount,
    String? type,
    String? category,
    DateTime? date,
    String? userId,
    String? attachmentUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      userId: userId ?? this.userId,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TransactionModel{id: $id, title: $title, amount: $amount, type: $type}';
  }
}
