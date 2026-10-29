import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas_example/demos/demo_catalog.dart';
import 'package:scroll_atlas_example/main.dart';

void main() {
  test('every demo has a deep link route', () {
    for (final DemoSpec spec in demoCatalog) {
      final RouteSettings settings = RouteSettings(name: spec.route);
      expect(demoRoute(settings), isNotNull, reason: spec.slug);
    }
    expect(demoRoute(const RouteSettings(name: '/nope')), isNull);
  });

  testWidgets('tapping a tile opens its demo by name',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ScrollAtlasDemoApp());
    await tester.tap(find.text('Food menu'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('debug_toggle')), findsOneWidget);
  });
}
