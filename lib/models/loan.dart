class Loan {
  final String id;
  final String userId;
  final String title;
  final double totalAmount;
  final double remainingAmount;
  final double? interestRate;
  final DateTime startDate;
  final DateTime? endDate;
  final String status;
  final String purpose;
  final String lenderName;
  final String? accountNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  Loan({
    required this.id,
    required this.userId,
    required this.title,
    required this.totalAmount,
    required this.remainingAmount,
    this.interestRate,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.purpose,
    required this.lenderName,
    this.accountNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      totalAmount: json['total_amount'].toDouble(),
      remainingAmount: json['remaining_amount'].toDouble(),
      interestRate: json['interest_rate']?.toDouble(),
      startDate: DateTime.parse(json['start_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      status: json['status'],
      purpose: json['purpose'],
      lenderName: json['lender_name'],
      accountNumber: json['account_number'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'total_amount': totalAmount,
      'remaining_amount': remainingAmount,
      'interest_rate': interestRate,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'status': status,
      'purpose': purpose,
      'lender_name': lenderName,
      'account_number': accountNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
