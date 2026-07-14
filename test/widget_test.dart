// Minimal smoke test for wonder_isles. Full integration tests come later.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MaterialApp scaffolds', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    expect(find.byType(Scaffold), findsOneWidget);
  });
}