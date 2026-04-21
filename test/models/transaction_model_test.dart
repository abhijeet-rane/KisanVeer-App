import 'package:flutter_test/flutter_test.dart';
import 'package:kisan_veer/models/transaction_model.dart';

void main() {
  group('TransactionModel.empty', () {
    test('produces an expense with zero amount and default category', () {
      final t = TransactionModel.empty();
      expect(t.id, '');
      expect(t.amount, 0.0);
      expect(t.type, 'expense');
      expect(t.category, 'other');
      expect(t.attachmentUrl, '');
    });
  });

  group('TransactionModel.fromJson', () {
    test('fills defaults when fields are missing', () {
      final t = TransactionModel.fromJson(<String, dynamic>{});
      expect(t.id, '');
      expect(t.title, '');
      expect(t.amount, 0.0);
      expect(t.type, 'expense');
      expect(t.category, 'other');
    });

    test('coerces integer amount to double', () {
      final t = TransactionModel.fromJson({'amount': 500});
      expect(t.amount, 500.0);
      expect(t.amount, isA<double>());
    });

    test('parses ISO dates', () {
      final t = TransactionModel.fromJson({
        'date': '2026-04-21T09:00:00.000Z',
        'createdAt': '2026-04-21T10:00:00.000Z',
        'updatedAt': '2026-04-21T11:00:00.000Z',
      });
      expect(t.date.toUtc().hour, 9);
      expect(t.createdAt.toUtc().hour, 10);
      expect(t.updatedAt.toUtc().hour, 11);
    });
  });

  group('TransactionModel.toJson', () {
    test('roundtrips preserving type, amount, and category', () {
      final original = TransactionModel(
        id: 't1',
        title: 'Seeds',
        description: 'Cotton seeds',
        amount: 1250.75,
        type: 'expense',
        category: 'seeds',
        date: DateTime.utc(2026, 4, 21),
        userId: 'u1',
        attachmentUrl: 'https://cdn/a.png',
        createdAt: DateTime.utc(2026, 4, 21, 10),
        updatedAt: DateTime.utc(2026, 4, 21, 11),
      );
      final copy = TransactionModel.fromJson(original.toJson());
      expect(copy.id, 't1');
      expect(copy.amount, 1250.75);
      expect(copy.type, 'expense');
      expect(copy.category, 'seeds');
      expect(copy.attachmentUrl, 'https://cdn/a.png');
    });
  });

  group('TransactionModel.copyWith', () {
    test('overrides only specified fields', () {
      final t = TransactionModel.empty().copyWith(amount: 99.0, type: 'income');
      expect(t.amount, 99.0);
      expect(t.type, 'income');
      expect(t.category, 'other'); // unchanged
    });
  });

  test('toString includes id, title, amount, and type', () {
    final t = TransactionModel.empty().copyWith(
      id: 'x',
      title: 'Sales',
      amount: 500.0,
      type: 'income',
    );
    final s = t.toString();
    expect(s, contains('x'));
    expect(s, contains('Sales'));
    expect(s, contains('500'));
    expect(s, contains('income'));
  });
}
