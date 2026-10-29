import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas_example/demos/demo_catalog.dart';
import 'package:scroll_atlas_example/main.dart';

import 'open_demo.dart';

void main() {
  testWidgets('the gallery has a card per demo with its before and after',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ScrollAtlasDemoApp());
    expect(demoCatalog.length, 5);
    final scrollable = find.byType(Scrollable).first;
    for (final DemoSpec spec in demoCatalog) {
      final card = find.byKey(ValueKey<String>('demo-card-${spec.slug}'));
      await tester.scrollUntilVisible(card, 300, scrollable: scrollable);
      for (final String line in <String>[spec.title, spec.problem]) {
        expect(
          find.descendant(of: card, matching: find.text(line)),
          findsOneWidget,
        );
      }
      expect(
        find.descendant(
          of: card,
          matching: find.textContaining(spec.withAtlas, findRichText: true),
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('the app builds in dark mode', (WidgetTester tester) async {
    await tester
        .pumpWidget(const ScrollAtlasDemoApp(themeMode: ThemeMode.dark));
    final context = tester.element(find.text('scroll_atlas').first);
    expect(Theme.of(context).brightness, Brightness.dark);
  });

  testWidgets('jump to index 50000 shows Item 50000',
      (WidgetTester tester) async {
    await openDemo(tester, 'jump');

    await tester.enterText(find.byKey(const Key('jump_index_field')), '50000');
    await tester.tap(find.byKey(const Key('jump_button')));
    await tester.pumpAndSettle();

    expect(find.text('Item 50000'), findsOneWidget);
    // A far jump builds about one screen of items, never the skipped range.
    final readout =
        tester.widget<Text>(find.textContaining('Builds on last jump')).data!;
    final match = RegExp(r'Builds on last jump: (\d+)').firstMatch(readout)!;
    final builds = int.parse(match.group(1)!);
    expect(builds, inInclusiveRange(1, 40));
  });

  Future<double> openAt500(WidgetTester tester) async {
    await openDemo(tester, 'jump');
    await tester.enterText(find.byKey(const Key('jump_index_field')), '500');
    await tester.tap(find.byKey(const Key('jump_button')));
    await tester.pumpAndSettle();
    return tester.getTopLeft(find.text('Item 500')).dy;
  }

  testWidgets('insert 20 at top keeps the reading position',
      (WidgetTester tester) async {
    final before = await openAt500(tester);
    await tester.ensureVisible(find.byKey(const Key('insert_button')));
    await tester.tap(find.byKey(const Key('insert_button')));
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.text('Item 500')).dy;
    expect(after, moreOrLessEquals(before, epsilon: 0.5));
  });

  testWidgets('growing images above does not move the view',
      (WidgetTester tester) async {
    final before = await openAt500(tester);
    await tester.ensureVisible(find.byKey(const Key('grow_button')));
    await tester.tap(find.byKey(const Key('grow_button')));
    await tester.pumpAndSettle();
    final after = tester.getTopLeft(find.text('Item 500')).dy;
    expect(after, moreOrLessEquals(before, epsilon: 0.5));
  });

  testWidgets('opens the chat at the first unread message',
      (WidgetTester tester) async {
    await openDemo(tester, 'chat');
    expect(find.text('First unread'), findsOneWidget);
  });

  testWidgets('visible readout covers the item it jumped to',
      (WidgetTester tester) async {
    await openDemo(tester, 'jump');

    await tester.enterText(find.byKey(const Key('jump_index_field')), '1204');
    await tester.tap(find.byKey(const Key('jump_button')));
    await tester.pumpAndSettle();

    final text =
        tester.widget<Text>(find.byKey(const Key('visible_readout'))).data!;
    final match = RegExp(r'Visible: (\d+) to (\d+)').firstMatch(text)!;
    final first = int.parse(match.group(1)!);
    final last = int.parse(match.group(2)!);
    expect(first, lessThanOrEqualTo(1204));
    expect(last, greaterThanOrEqualTo(1204));
    expect(find.text('Item $first'), findsOneWidget);
    expect(find.text('Item $last'), findsOneWidget);
  });
}
