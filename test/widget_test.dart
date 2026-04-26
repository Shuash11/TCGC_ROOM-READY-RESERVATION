// test/widget_test.dart
// ─────────────────────────────────────────────
// Basic smoke test for RoomReady.
// Verifies the login screen loads correctly.
// ─────────────────────────────────────────────


import 'package:flutter_test/flutter_test.dart';
import 'package:kaye/main.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const RoomReadyApp());

    // App title is visible
    expect(find.text('RoomReady'), findsOneWidget);

    // Role toggle buttons are present
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Admin'),   findsOneWidget);

    // Login button is present
    expect(find.text('Log In'), findsOneWidget);
  });

  testWidgets('Admin login tab shows correct hint', (WidgetTester tester) async {
    await tester.pumpWidget(const RoomReadyApp());

    // Tap the Admin tab
    await tester.tap(find.text('Admin'));
    await tester.pump();

    // Admin hint text should now be visible
    expect(
      find.textContaining('admin123'),
      findsOneWidget,
    );
  });

  testWidgets('Empty login shows validation errors', (WidgetTester tester) async {
    await tester.pumpWidget(const RoomReadyApp());

    // Tap Log In without entering anything
    await tester.tap(find.text('Log In'));
    await tester.pump();

    // Validation messages should appear
    expect(find.text('Please enter your ID'),       findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
  });
}