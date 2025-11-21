// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:paddyai/main.dart';

void main() {
  testWidgets('PaddyAI app launches', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PaddyAIApp());

    // Verify that the app loads
    await tester.pumpAndSettle();
    
    // Basic smoke test - app should build without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
