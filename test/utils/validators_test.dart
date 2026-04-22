import 'package:flutter_test/flutter_test.dart';
import 'package:kisan_veer/utils/validators.dart';

void main() {
  group('Validators.validateEmail', () {
    test('returns error when null', () {
      expect(Validators.validateEmail(null), 'Email is required');
    });

    test('returns error when empty', () {
      expect(Validators.validateEmail(''), 'Email is required');
    });

    test('returns error for missing @', () {
      expect(
        Validators.validateEmail('fooexample.com'),
        'Please enter a valid email address',
      );
    });

    test('returns error for missing TLD', () {
      expect(
        Validators.validateEmail('foo@example'),
        'Please enter a valid email address',
      );
    });

    test('returns null for well-formed email', () {
      expect(Validators.validateEmail('abhi@kisan-veer.in'), isNull);
      expect(Validators.validateEmail('user.name@domain.co'), isNull);
    });
  });

  group('Validators.validatePassword', () {
    test('returns error when empty', () {
      expect(Validators.validatePassword(''), 'Password is required');
      expect(Validators.validatePassword(null), 'Password is required');
    });

    test('returns error when shorter than 8 chars', () {
      expect(
        Validators.validatePassword('Abc1'),
        'Password must be at least 8 characters long',
      );
    });

    test('returns error when no uppercase letter', () {
      expect(
        Validators.validatePassword('abcdefg1'),
        'Password must contain at least one uppercase letter',
      );
    });

    test('returns error when no digit', () {
      expect(
        Validators.validatePassword('Abcdefgh'),
        'Password must contain at least one number',
      );
    });

    test('returns null for valid password', () {
      expect(Validators.validatePassword('Password1'), isNull);
      expect(Validators.validatePassword('Kisan123'), isNull);
    });
  });

  group('Validators.validatePhone', () {
    test('returns error when empty', () {
      expect(Validators.validatePhone(''), 'Phone number is required');
      expect(Validators.validatePhone(null), 'Phone number is required');
    });

    test('rejects fewer than 10 digits', () {
      expect(
        Validators.validatePhone('98765432'),
        'Please enter a valid 10-digit phone number',
      );
    });

    test('rejects more than 10 digits', () {
      expect(
        Validators.validatePhone('98765432100'),
        'Please enter a valid 10-digit phone number',
      );
    });

    test('rejects non-digit characters', () {
      expect(
        Validators.validatePhone('+919876543210'),
        'Please enter a valid 10-digit phone number',
      );
      expect(
        Validators.validatePhone('98765 43210'),
        'Please enter a valid 10-digit phone number',
      );
    });

    test('accepts 10-digit phone', () {
      expect(Validators.validatePhone('9876543210'), isNull);
    });
  });

  group('Validators.validateRequired', () {
    test('returns error when null, empty, or whitespace-only', () {
      expect(
        Validators.validateRequired(null, 'Address'),
        'Address is required',
      );
      expect(Validators.validateRequired('', 'Address'), 'Address is required');
      expect(
        Validators.validateRequired('   ', 'Address'),
        'Address is required',
      );
    });

    test('returns null when value has content', () {
      expect(Validators.validateRequired('Pune', 'City'), isNull);
    });
  });

  group('Validators.validateName', () {
    test('rejects empty or too-short names', () {
      expect(Validators.validateName(null), 'Name is required');
      expect(Validators.validateName(''), 'Name is required');
      expect(
        Validators.validateName('A'),
        'Name must be at least 2 characters long',
      );
    });

    test('accepts 2+ char names', () {
      expect(Validators.validateName('Al'), isNull);
      expect(Validators.validateName('Abhijeet Rane'), isNull);
    });
  });

  group('Validators.validateNumeric', () {
    test('rejects null / empty / non-numeric', () {
      expect(Validators.validateNumeric(null, 'Price'), 'Price is required');
      expect(Validators.validateNumeric('', 'Price'), 'Price is required');
      expect(
        Validators.validateNumeric('abc', 'Price'),
        'Please enter a valid number',
      );
      expect(
        Validators.validateNumeric('12.345', 'Price'),
        'Please enter a valid number',
      );
    });

    test('accepts integers and up to 2-decimal floats', () {
      expect(Validators.validateNumeric('100', 'Price'), isNull);
      expect(Validators.validateNumeric('100.5', 'Price'), isNull);
      expect(Validators.validateNumeric('100.99', 'Price'), isNull);
    });
  });
}
