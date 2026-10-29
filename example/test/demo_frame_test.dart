import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas_example/demos/demo_catalog.dart';
import 'package:scroll_atlas_example/main.dart';

void main() {
  Future<void> openDemo(WidgetTester tester, DemoScreenSpec spec) async {
    final title = find.text('${spec.id} ${spec.title}');
    await tester.scrollUntilVisible(title, 300,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(title);
    await tester.pumpAndSettle();
  }

  testWidgets('every screen has What to try and Debug', (tester) async {
    tester.view.physicalSize = const Size(1000, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const ScrollAtlasDemoApp());
    for (final spec in demoCatalog) {
      await openDemo(tester, spec);
      await tester.tap(find.byKey(const Key('what_to_try_toggle')));
      await tester.tap(find.byKey(const Key('debug_toggle')));
      await tester.pumpAndSettle();
      expect(find.text(spec.whatToTry), findsWidgets, reason: spec.id);
      final built = tester
          .widget<Text>(find.textContaining('Built items: '))
          .data!
          .replaceFirst('Built items: ', '');
      expect(int.parse(built), greaterThan(0), reason: spec.id);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('D1 reports its jump error to the overlay', (tester) async {
    await tester.pumpWidget(const ScrollAtlasDemoApp());
    await openDemo(tester, demoCatalog.first);
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
