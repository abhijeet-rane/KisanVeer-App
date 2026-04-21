import 'package:flutter_test/flutter_test.dart';
import 'package:kisan_veer/models/user_model.dart';

void main() {
  group('UserModel.empty', () {
    test('has empty strings and farmer default', () {
      final u = UserModel.empty();
      expect(u.uid, '');
      expect(u.email, '');
      expect(u.name, '');
      expect(u.userType, 'farmer');
      expect(u.state, 'Maharashtra');
      expect(u.crops, isEmpty);
    });
  });

  group('UserModel.fromJson', () {
    test('applies defaults when required fields are missing', () {
      final u = UserModel.fromJson(<String, dynamic>{});
      expect(u.uid, '');
      expect(u.email, '');
      expect(u.userType, 'farmer');
      expect(u.state, 'Maharashtra');
      expect(u.crops, isEmpty);
    });

    test('parses crops from a list', () {
      final u = UserModel.fromJson({
        'crops': ['wheat', 'rice', 'cotton'],
      });
      expect(u.crops, ['wheat', 'rice', 'cotton']);
    });

    test('parses crops from a comma-separated string', () {
      final u = UserModel.fromJson({
        'crops': 'wheat, rice , , cotton',
      });
      expect(u.crops, ['wheat', 'rice', 'cotton']);
    });

    test('prefers profile_image_url over photoUrl', () {
      final u = UserModel.fromJson({
        'profile_image_url': 'https://cdn/new.png',
        'photoUrl': 'https://cdn/old.png',
      });
      expect(u.photoUrl, 'https://cdn/new.png');
      expect(u.profileImageUrl, 'https://cdn/new.png');
    });

    test('falls back to photoUrl when profile_image_url is missing', () {
      final u = UserModel.fromJson({
        'photoUrl': 'https://cdn/fallback.png',
      });
      expect(u.photoUrl, 'https://cdn/fallback.png');
    });

    test('parses createdAt/lastActive as ISO strings', () {
      final u = UserModel.fromJson({
        'createdAt': '2026-04-21T10:00:00.000Z',
        'lastActive': '2026-04-21T12:00:00.000Z',
      });
      expect(u.createdAt.toUtc().hour, 10);
      expect(u.lastActive.toUtc().hour, 12);
    });
  });

  group('UserModel.toJson', () {
    test('roundtrips to and from JSON preserving values', () {
      final original = UserModel(
        uid: 'u1',
        email: 'test@example.com',
        name: 'Test',
        phoneNumber: '9876543210',
        userType: 'buyer',
        photoUrl: 'https://cdn/p.png',
        createdAt: DateTime.utc(2026, 4, 21, 10),
        lastActive: DateTime.utc(2026, 4, 21, 12),
        address: 'Line 1',
        city: 'Pune',
        state: 'Maharashtra',
        pincode: '411001',
        crops: const ['rice', 'cotton'],
      );

      final roundtrip = UserModel.fromJson(original.toJson());
      expect(roundtrip.uid, original.uid);
      expect(roundtrip.email, original.email);
      expect(roundtrip.name, original.name);
      expect(roundtrip.phoneNumber, original.phoneNumber);
      expect(roundtrip.userType, original.userType);
      expect(roundtrip.photoUrl, original.photoUrl);
      expect(roundtrip.address, original.address);
      expect(roundtrip.city, original.city);
      expect(roundtrip.state, original.state);
      expect(roundtrip.pincode, original.pincode);
      expect(roundtrip.crops, original.crops);
      expect(roundtrip.createdAt.toUtc(), original.createdAt.toUtc());
    });
  });

  group('UserModel.copyWith', () {
    test('overrides only given fields', () {
      final u = UserModel.empty().copyWith(
        name: 'Abhijeet',
        crops: const ['jowar'],
      );
      expect(u.name, 'Abhijeet');
      expect(u.crops, ['jowar']);
      expect(u.state, 'Maharashtra');
      expect(u.email, '');
    });
  });
}
