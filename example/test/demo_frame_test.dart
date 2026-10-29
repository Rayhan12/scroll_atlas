import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas_example/demos/demo_catalog.dart';
import 'package:scroll_atlas_example/main.dart';

import 'open_demo.dart';

void main() {
  testWidgets('every screen has How it helps and Debug', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ScrollAtlasDemoApp());
    for (final spec in demoCatalog) {
      await openDemo(tester, spec.slug, pumpApp: false);
      await tester.tap(find.byKey(const Key('what_to_try_toggle')));
      await tester.tap(find.byKey(const Key('debug_toggle')));
      await tester.pumpAndSettle();
      expect(
          find.textContaining(spec.whatToTry, findRichText: true), findsWidgets,
          reason: spec.slug);
      final built = tester
          .widget<Text>(find.textContaining('Built items: '))
          .data!
          .replaceFirst('Built items: ', '');
      expect(int.parse(built), greaterThan(0), reason: spec.slug);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('reports its jump error to the overlay', (tester) async {
    await openDemo(tester, 'jump');
    await tester.tap(find.byKey(const Key('debug_toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Last jump error: -'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('jump_index_field')), '50000');
    await tester.tap(find.byKey(const Key('jump_button')));
    await tester.pumpAndSettle();
    final text =
        tester.widget<Text>(find.textContaining('Last jump error: ')).data!;
    final px = double.parse(RegExp(r'([\d.]+) px').firstMatch(text)!.group(1)!);
    expect(px, lessThan(0.5));
  });
}
