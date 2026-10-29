import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas_example/main.dart';

/// Pumps the app, scrolls the gallery to the card of [slug] and opens it.
Future<void> openDemo(WidgetTester tester, String slug,
    {bool pumpApp = true}) async {
  if (pumpApp) await tester.pumpWidget(const ScrollAtlasDemoApp());
  final card = find.byKey(ValueKey<String>('demo-card-$slug'));
  await tester.scrollUntilVisible(card, 300,
      scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}
