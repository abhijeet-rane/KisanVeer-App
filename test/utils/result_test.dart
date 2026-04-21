import 'package:flutter_test/flutter_test.dart';
import 'package:kisan_veer/utils/result.dart';

void main() {
  group('Result<T>', () {
    test('Success exposes data and flags', () {
      final Result<int> r = Result.success(42);
      expect(r.isSuccess, isTrue);
      expect(r.isFailure, isFalse);
      expect(r.dataOrNull, 42);
      expect(r.errorOrNull, isNull);
      expect(r.getOrThrow(), 42);
      expect(r.getOrDefault(0), 42);
    });

    test('Failure exposes error and flags', () {
      final err = AppError(message: 'boom', code: 'E1');
      final Result<int> r = Result.failure(err);
      expect(r.isSuccess, isFalse);
      expect(r.isFailure, isTrue);
      expect(r.dataOrNull, isNull);
      expect(r.errorOrNull, same(err));
      expect(() => r.getOrThrow(), throwsA(same(err)));
      expect(r.getOrDefault(-1), -1);
    });

    test('map transforms success value without touching failure', () {
      final doubled = Result<int>.success(3).map((v) => v * 2);
      expect(doubled.dataOrNull, 6);

      final err = AppError(message: 'x');
      final Result<int> failed = Result.failure(err);
      final mapped = failed.map((v) => v * 2);
      expect(mapped.isFailure, isTrue);
      expect(mapped.errorOrNull, same(err));
    });

    test('when dispatches to the correct branch', () {
      final String s = Result<int>.success(5).when(
        success: (d) => 'ok:$d',
        failure: (e) => 'err:${e.message}',
      );
      expect(s, 'ok:5');

      final String f = Result<int>.failure(AppError(message: 'nope')).when(
        success: (d) => 'ok:$d',
        failure: (e) => 'err:${e.message}',
      );
      expect(f, 'err:nope');
    });
  });

  group('AppError factories', () {
    test('NetworkError factories carry codes', () {
      expect(NetworkError.noConnection().code, 'NO_CONNECTION');
      expect(NetworkError.timeout().code, 'TIMEOUT');
      expect(NetworkError.unauthorized().statusCode, 401);
      expect(NetworkError.notFound(resource: 'Order').message,
          contains('Order'));
    });

    test('AuthError factories carry codes', () {
      expect(AuthError.invalidCredentials().code, 'INVALID_CREDENTIALS');
      expect(AuthError.userNotFound().code, 'USER_NOT_FOUND');
      expect(AuthError.emailInUse().code, 'EMAIL_IN_USE');
      expect(AuthError.weakPassword().code, 'WEAK_PASSWORD');
      expect(AuthError.emailNotVerified().code, 'EMAIL_NOT_VERIFIED');
    });

    test('ValidationError includes field', () {
      const err = ValidationError(field: 'email', message: 'bad');
      expect(err.field, 'email');
      expect(err.code, 'VALIDATION_ERROR');
    });

    test('AppError.toString includes code when present', () {
      const err = AppError(message: 'bad', code: 'X');
      expect(err.toString(), contains('bad'));
      expect(err.toString(), contains('X'));
    });
  });

  group('FutureResultExtension.toResult', () {
    test('wraps resolved value in Success', () async {
      final Result<int> r = await Future.value(7).toResult();
      expect(r.isSuccess, isTrue);
      expect(r.dataOrNull, 7);
    });

    test('wraps thrown AppError as Failure carrying the same error', () async {
      final err = AuthError.invalidCredentials();
      final Result<int> r = await Future<int>.error(err).toResult();
      expect(r.isFailure, isTrue);
      expect(r.errorOrNull, same(err));
    });

    test('wraps non-AppError throw in a generic AppError', () async {
      final Result<int> r =
          await Future<int>.error(StateError('whoops')).toResult();
      expect(r.isFailure, isTrue);
      expect(r.errorOrNull, isA<AppError>());
      expect(r.errorOrNull!.message, contains('whoops'));
    });
  });
}
