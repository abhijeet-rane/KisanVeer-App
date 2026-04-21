import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kisan_veer/widgets/custom_button.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('CustomButton', () {
    testWidgets('renders the provided text', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomButton(text: 'Login', onPressed: () {}),
      ));
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('fires onPressed when tapped', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(
        CustomButton(text: 'Tap me', onPressed: () => taps++),
      ));
      await tester.tap(find.byType(CustomButton));
      expect(taps, 1);
    });

    testWidgets('is disabled and swallows taps while loading',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(_wrap(
        CustomButton(
          text: 'Saving',
          isLoading: true,
          onPressed: () => taps++,
        ),
      ));
      await tester.tap(find.byType(CustomButton), warnIfMissed: false);
      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('is disabled when onPressed is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const CustomButton(text: 'Disabled', onPressed: null),
      ));
      final ElevatedButton btn = tester.widget(find.byType(ElevatedButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('renders an OutlinedButton for ButtonType.outlined',
        (tester) async {
      await tester.pumpWidget(_wrap(
        CustomButton(
          text: 'Outlined',
          onPressed: () {},
          buttonType: ButtonType.outlined,
        ),
      ));
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders a TextButton for ButtonType.text', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomButton(
          text: 'Textual',
          onPressed: () {},
          buttonType: ButtonType.text,
        ),
      ));
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('renders a leading icon when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomButton(
          text: 'Save',
          onPressed: () {},
          leadingIcon: Icons.save,
        ),
      ));
      expect(find.byIcon(Icons.save), findsOneWidget);
    });

    testWidgets('hides leading icon while loading', (tester) async {
      await tester.pumpWidget(_wrap(
        CustomButton(
          text: 'Save',
          onPressed: () {},
          leadingIcon: Icons.save,
          isLoading: true,
        ),
      ));
      expect(find.byIcon(Icons.save), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
