import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas_example/demos/demo_catalog.dart';
import 'package:scroll_atlas_example/main.dart';

void main() {
  testWidgets('home lists demo tiles D1 through D6',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ScrollAtlasDemoApp());
    expect(demoCatalog.length, 6);
    final scrollable = find.byType(Scrollable).first;
    for (final DemoScreenSpec spec in demoCatalog) {
      final tileTitle = '${spec.id} ${spec.title}';
      await tester.scrollUntilVisible(
        find.text(tileTitle),
        500,
        scrollable: scrollable,
      );
      expect(find.text(tileTitle), findsOneWidget);
    }
  });

  testWidgets('D1 jump to index 50000 shows Item 50000',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ScrollAtlasDemoApp());
    await tester.tap(find.textContaining('D1 Jump lab'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('jump_index_field')), '50000');
    await tester.tap(find.byKey(const Key('jump_button')));
    await tester.pumpAndSettle();

    expect(find.text('Item 50000'), findsOneWidget);
    // A far jump builds about one screen of items, never the skipped range.
    final readout =
        tester.widget<Text>(find.textContaining('Builds on last jump')).data!;
    final builds = int.parse(readout.split(': ').last);
    expect(builds, inInclusiveRange(1, 40));
  });
}
