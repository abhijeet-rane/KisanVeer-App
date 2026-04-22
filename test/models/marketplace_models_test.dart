import 'package:flutter_test/flutter_test.dart';
import 'package:kisan_veer/models/marketplace_models.dart';

Map<String, dynamic> _productJson({
  dynamic price = 250,
  dynamic quantity = 10,
  dynamic isActive = true,
  dynamic imageUrls,
  String? category,
}) {
  return {
    'id': 'p1',
    'seller_id': 's1',
    'name': 'Cotton',
    'description': 'Long-staple',
    'price': price,
    'available_quantity': quantity,
    'category': category ?? 'Grains',
    'image_urls': imageUrls ?? ['https://cdn/a.png', 'https://cdn/b.png'],
    'unit': 'kg',
    'is_active': isActive,
    'avg_rating': 4.5,
    'review_count': 12,
    'created_at': '2026-04-21T10:00:00.000Z',
    'updated_at': '2026-04-21T11:00:00.000Z',
  };
}

void main() {
  group('Product.fromJson — image_urls parsing', () {
    test('accepts a list of strings', () {
      final p = Product.fromJson(_productJson());
      expect(p.imageUrls, ['https://cdn/a.png', 'https://cdn/b.png']);
    });

    test('accepts a single string as a 1-element list', () {
      final p = Product.fromJson(_productJson(imageUrls: 'https://cdn/a.png'));
      expect(p.imageUrls, ['https://cdn/a.png']);
    });

    test('parses a Postgres-style stringified array', () {
      final p = Product.fromJson(
        _productJson(imageUrls: '["https://cdn/a.png","https://cdn/b.png"]'),
      );
      expect(
        p.imageUrls,
        containsAllInOrder(['https://cdn/a.png', 'https://cdn/b.png']),
      );
    });

    test('returns empty list when image_urls is null', () {
      final json = _productJson()..remove('image_urls');
      final p = Product.fromJson(json);
      expect(p.imageUrls, isEmpty);
    });
  });

  group('Product.fromJson — numeric coercion', () {
    test('coerces integer price to double', () {
      final p = Product.fromJson(_productJson(price: 250));
      expect(p.price, 250.0);
      expect(p.price, isA<double>());
    });

    test('coerces string price to double', () {
      final p = Product.fromJson(_productJson(price: '1999.99'));
      expect(p.price, 1999.99);
    });

    test('coerces string quantity to int', () {
      final p = Product.fromJson(_productJson(quantity: '42'));
      expect(p.availableQuantity, 42);
    });

    test('defaults invalid numeric values to 0', () {
      final p = Product.fromJson(_productJson(price: 'abc', quantity: 'xyz'));
      expect(p.price, 0.0);
      expect(p.availableQuantity, 0);
    });
  });

  group('Product.fromJson — is_active coercion', () {
    test('accepts bool', () {
      expect(Product.fromJson(_productJson(isActive: false)).isActive, isFalse);
    });

    test('accepts integer 1 as true', () {
      expect(Product.fromJson(_productJson(isActive: 1)).isActive, isTrue);
    });

    test('accepts string "true"/"false"', () {
      expect(Product.fromJson(_productJson(isActive: 'true')).isActive, isTrue);
      expect(
        Product.fromJson(_productJson(isActive: 'false')).isActive,
        isFalse,
      );
    });

    test('defaults to true when field is null', () {
      final json = _productJson()..remove('is_active');
      expect(Product.fromJson(json).isActive, isTrue);
    });
  });

  test('Product.copyWith overrides only specified fields', () {
    final p = Product.fromJson(_productJson());
    final p2 = p.copyWith(price: 500.0, category: 'Fruits');
    expect(p2.price, 500.0);
    expect(p2.category, 'Fruits');
    expect(p2.name, p.name);
    expect(p2.id, p.id);
  });

  group('CartItem.fromJson', () {
    Map<String, dynamic> cartJson(dynamic qty) => {
      'id': 'c1',
      'user_id': 'u1',
      'product_id': 'p1',
      'quantity': qty,
      'created_at': '2026-04-21T10:00:00.000Z',
      'updated_at': '2026-04-21T10:00:00.000Z',
    };

    test('coerces quantity from int/double/string', () {
      expect(CartItem.fromJson(cartJson(3)).quantity, 3);
      expect(CartItem.fromJson(cartJson(3.0)).quantity, 3);
      expect(CartItem.fromJson(cartJson('3')).quantity, 3);
    });

    test('defaults quantity to 0 when null/invalid', () {
      expect(CartItem.fromJson(cartJson(null)).quantity, 0);
      expect(CartItem.fromJson(cartJson('abc')).quantity, 0);
    });

    test('toJson serialises only the persisted fields', () {
      final item = CartItem.fromJson(cartJson(2));
      expect(item.toJson(), {
        'id': 'c1',
        'user_id': 'u1',
        'product_id': 'p1',
        'quantity': 2,
      });
    });
  });

  group('Order.fromJson', () {
    Map<String, dynamic> orderJson({dynamic total = 1500.0}) => {
      'id': 'o1',
      'user_id': 'u1',
      'status': 'confirmed',
      'total_amount': total,
      'address_id': 'a1',
      'created_at': '2026-04-21T10:00:00.000Z',
      'updated_at': '2026-04-21T11:00:00.000Z',
      'payment_id': 'pay_123',
      'payment_method': 'razorpay',
    };

    test('parses double total_amount', () {
      final o = Order.fromJson(orderJson(total: 1500.0));
      expect(o.totalAmount, 1500.0);
    });

    test('parses integer total_amount as double', () {
      final o = Order.fromJson(orderJson(total: 1500));
      expect(o.totalAmount, 1500.0);
    });

    test('parses string total_amount via tryParse', () {
      final o = Order.fromJson(orderJson(total: '1500.75'));
      expect(o.totalAmount, 1500.75);
    });

    test('builds a placeholder Address when none is provided', () {
      final o = Order.fromJson(orderJson());
      expect(o.address, isNotNull);
      expect(o.address.id, isNotEmpty);
    });

    test('defaults status to "pending" when missing', () {
      final j = orderJson();
      j.remove('status');
      final o = Order.fromJson(j);
      expect(o.status, 'pending');
    });

    test('toJson emits payment fields only when present', () {
      final o = Order.fromJson(orderJson());
      final emitted = o.toJson();
      expect(emitted['payment_id'], 'pay_123');
      expect(emitted['payment_method'], 'razorpay');
    });
  });
}
