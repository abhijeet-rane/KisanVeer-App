import 'package:flutter_test/flutter_test.dart';
import 'package:kisan_veer/models/financial_models.dart';

Map<String, dynamic> _financialTransactionJson({
  String id = 'ft1',
  String userId = 'u1',
  String title = 'Crop sale',
  String category = 'sales',
  num amount = 5000,
}) {
  return {
    'id': id,
    'user_id': userId,
    'title': title,
    'category': category,
    'amount': amount,
    'transaction_date': '2026-04-21T00:00:00.000Z',
    'created_at': '2026-04-21T10:00:00.000Z',
    'updated_at': '2026-04-21T11:00:00.000Z',
  };
}

Map<String, dynamic> _loanJson({
  num total = 50000,
  num remaining = 30000,
  num? rate = 9.5,
  String? endDate = '2027-04-21T00:00:00.000Z',
  String? accountNumber = 'ACC-1',
}) {
  return {
    'id': 'l1',
    'user_id': 'u1',
    'title': 'Tractor loan',
    'total_amount': total,
    'remaining_amount': remaining,
    'interest_rate': rate,
    'start_date': '2026-04-21T00:00:00.000Z',
    'end_date': endDate,
    'status': 'active',
    'purpose': 'equipment',
    'lender_name': 'KisanBank',
    'account_number': accountNumber,
    'created_at': '2026-04-21T10:00:00.000Z',
    'updated_at': '2026-04-21T11:00:00.000Z',
  };
}

void main() {
  group('FinancialTransaction.fromJson', () {
    test('coerces integer amount to double', () {
      final t = FinancialTransaction.fromJson(_financialTransactionJson());
      expect(t.amount, 5000.0);
      expect(t.amount, isA<double>());
    });

    test('roundtrips via toJson preserving values', () {
      final t = FinancialTransaction.fromJson(
          _financialTransactionJson(amount: 1234.56));
      final t2 = FinancialTransaction.fromJson(t.toJson());
      expect(t2.id, t.id);
      expect(t2.amount, t.amount);
      expect(t2.category, t.category);
    });
  });

  group('Loan.fromJson', () {
    test('parses integer and double inputs into doubles', () {
      final loan = Loan.fromJson(_loanJson(total: 75000, remaining: 25000));
      expect(loan.totalAmount, 75000.0);
      expect(loan.remainingAmount, 25000.0);
      expect(loan.interestRate, 9.5);
    });

    test('handles null optional fields', () {
      final loan = Loan.fromJson(
          _loanJson(rate: null, endDate: null, accountNumber: null));
      expect(loan.interestRate, isNull);
      expect(loan.endDate, isNull);
      expect(loan.accountNumber, isNull);
    });

    test('toJson emits null for missing end date / account / rate', () {
      final loan = Loan.fromJson(
          _loanJson(rate: null, endDate: null, accountNumber: null));
      final map = loan.toJson();
      expect(map['interest_rate'], isNull);
      expect(map['end_date'], isNull);
      expect(map['account_number'], isNull);
    });

    test('roundtrips through JSON', () {
      final original = Loan.fromJson(_loanJson());
      final copy = Loan.fromJson(original.toJson());
      expect(copy.id, original.id);
      expect(copy.totalAmount, original.totalAmount);
      expect(copy.remainingAmount, original.remainingAmount);
      expect(copy.interestRate, original.interestRate);
      expect(copy.status, original.status);
      expect(copy.lenderName, original.lenderName);
    });

    test('remaining amount correctly reflects paid-off state', () {
      final loan = Loan.fromJson(_loanJson(remaining: 0));
      expect(loan.remainingAmount, 0.0);
      expect(loan.totalAmount - loan.remainingAmount, loan.totalAmount);
    });
  });

  group('LoanPayment.fromJson', () {
    test('parses amount and dates', () {
      final p = LoanPayment.fromJson({
        'id': 'p1',
        'loan_id': 'l1',
        'amount': 2500,
        'payment_date': '2026-04-21T00:00:00.000Z',
        'payment_method': 'razorpay',
        'created_at': '2026-04-21T10:00:00.000Z',
      });
      expect(p.amount, 2500.0);
      expect(p.paymentMethod, 'razorpay');
      expect(p.paymentDate.toUtc().year, 2026);
    });

    test('roundtrips via toJson', () {
      final p = LoanPayment.fromJson({
        'id': 'p1',
        'loan_id': 'l1',
        'amount': 2500.50,
        'payment_date': '2026-04-21T00:00:00.000Z',
        'payment_method': 'razorpay',
        'created_at': '2026-04-21T10:00:00.000Z',
      });
      final p2 = LoanPayment.fromJson(p.toJson());
      expect(p2.id, p.id);
      expect(p2.amount, p.amount);
      expect(p2.paymentMethod, p.paymentMethod);
    });
  });
}
