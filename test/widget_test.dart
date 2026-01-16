import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:sudoku_cookie/main.dart';
import 'package:sudoku_cookie/screens/splash_screen.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SudokuCookieApp());

    // Verify that SplashScreen is present initially
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
