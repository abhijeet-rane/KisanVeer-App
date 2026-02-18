import 'package:flutter/material.dart';

class FinancialTransaction {
  final String id;
  final String userId;
  final String title;
  final String category;
  final double amount;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  FinancialTransaction({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.amount,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FinancialTransaction.fromJson(Map<String, dynamic> json) {
    return FinancialTransaction(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      category: json['category'],
      amount: json['amount'].toDouble(),
      transactionDate: DateTime.parse(json['transaction_date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'category': category,
        'amount': amount,
        'transaction_date': transactionDate.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

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
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      totalAmount: (json['total_amount'] as num).toDouble(),
      remainingAmount: (json['remaining_amount'] as num).toDouble(),
      interestRate: json['interest_rate'] != null ? (json['interest_rate'] as num).toDouble() : null,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      status: json['status'] as String,
      purpose: json['purpose'] as String,
      lenderName: json['lender_name'] as String,
      accountNumber: json['account_number'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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

class LoanPayment {
  final String id;
  final String loanId;
  final double amount;
  final DateTime paymentDate;
  final String paymentMethod;
  final DateTime createdAt;

  LoanPayment({
    required this.id,
    required this.loanId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory LoanPayment.fromJson(Map<String, dynamic> json) {
    return LoanPayment(
      id: json['id'],
      loanId: json['loan_id'],
      amount: json['amount'].toDouble(),
      paymentDate: DateTime.parse(json['payment_date']),
      paymentMethod: json['payment_method'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'loan_id': loanId,
        'amount': amount,
        'payment_date': paymentDate.toIso8601String(),
        'payment_method': paymentMethod,
        'created_at': createdAt.toIso8601String(),
      };
}
