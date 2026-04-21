import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kisan_veer/utils/app_logger.dart';

void main() {
  // Capture debugPrint output so we can assert without polluting test logs.
  final capturedLines = <String>[];
  late DebugPrintCallback originalDebugPrint;

  setUp(() {
    capturedLines.clear();
    originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      if (message != null) capturedLines.add(message);
    };
    AppLogger.setLogLevel(LogLevel.debug);
  });

  tearDown(() {
    debugPrint = originalDebugPrint;
  });

  group('AppLogger level filtering', () {
    test('all levels emit when min level is debug', () {
      AppLogger.d('dbg');
      AppLogger.i('inf');
      AppLogger.w('warn');
      AppLogger.e('err');
      expect(capturedLines.length, greaterThanOrEqualTo(4));
    });

    test('debug is suppressed when min level is info', () {
      AppLogger.setLogLevel(LogLevel.info);
      capturedLines.clear();
      AppLogger.d('hidden');
      AppLogger.i('shown');
      expect(capturedLines.any((l) => l.contains('hidden')), isFalse);
      expect(capturedLines.any((l) => l.contains('shown')), isTrue);
    });

    test('only errors emit when min level is error', () {
      AppLogger.setLogLevel(LogLevel.error);
      capturedLines.clear();
      AppLogger.d('d');
      AppLogger.i('i');
      AppLogger.w('w');
      AppLogger.e('e');
      expect(capturedLines.any((l) => l.contains(' d')), isFalse);
      expect(capturedLines.any((l) => l.contains(' i')), isFalse);
      expect(capturedLines.any((l) => l.contains(' w')), isFalse);
      expect(capturedLines.any((l) => l.contains(' e')), isTrue);
    });
  });

  group('AppLogger formatting', () {
    test('tag appears in the log line', () {
      AppLogger.i('message', tag: 'Auth');
      expect(capturedLines.any((l) => l.contains('[Auth]')), isTrue);
    });

    test('falls back to app tag when no tag given', () {
      AppLogger.i('message');
      expect(capturedLines.any((l) => l.contains('[KisanVeer]')), isTrue);
    });

    test('error log emits a trailing "Error:" line when error is provided', () {
      AppLogger.e('failed', error: StateError('boom'));
      expect(capturedLines.any((l) => l.contains('Error:')), isTrue);
    });

    test('stack trace only appears for error-level logs', () {
      final stack = StackTrace.current;
      AppLogger.w('warn', stackTrace: stack);
      expect(capturedLines.any((l) => l.contains('StackTrace:')), isFalse);
      AppLogger.e('err', stackTrace: stack);
      expect(capturedLines.any((l) => l.contains('StackTrace:')), isTrue);
    });
  });
}
