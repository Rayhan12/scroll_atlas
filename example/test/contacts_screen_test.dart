import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas_example/demos/contacts/contacts_screen.dart';

void main() {
  const appBarBottom = 56.0 + 96.0;
  const headerExtent = 40.0;

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: ContactsScreen()));
  }

  double topOf(WidgetTester tester, String key) => tester
      .getTopLeft(find.byKey(ValueKey<String>(key), skipOffstage: false))
      .dy;

  testWidgets('Jump to Z, item 3 lands on the first try',
      (WidgetTester tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Jump to Z, item 3'));
    await tester.pumpAndSettle();
    expect(topOf(tester, 'contact-Z-3'),
        moreOrLessEquals(appBarBottom + headerExtent, epsilon: 0.5));
    expect(topOf(tester, 'header-Z'),
        moreOrLessEquals(appBarBottom, epsilon: 0.5));
  });

  testWidgets('the toggle decides whether the header covers K 3',
      (WidgetTester tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Jump to K, item 3'));
    await tester.pumpAndSettle();
    expect(topOf(tester, 'contact-K-3'),
        moreOrLessEquals(appBarBottom + headerExtent, epsilon: 0.5));

    await tester.tap(find.byKey(const Key('respect_pinned_switch')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Jump to K, item 3'));
    await tester.pumpAndSettle();
    expect(topOf(tester, 'contact-K-3'), moreOrLessEquals(0, epsilon: 0.5));
  });

  testWidgets('the Footer chip lands on the footer block',
      (WidgetTester tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Jump to Footer'));
    await tester.pumpAndSettle();
    final footer = find.byKey(const Key('footer_block'));
    // The footer is the last sliver: it ends at the viewport's bottom and
    // is fully visible below the app bar.
    expect(
        tester.getBottomLeft(footer).dy, moreOrLessEquals(844, epsilon: 0.5));
    expect(
        tester.getTopLeft(footer).dy, greaterThanOrEqualTo(appBarBottom - 0.5));
  });

  testWidgets('the index rail jumps to a letter', (WidgetTester tester) async {
    await open(tester);
    final rail = tester.getRect(find.byKey(const Key('index_rail')));
    // Tap the middle of the slot for M (index 12 of 26).
    await tester
        .tapAt(Offset(rail.center.dx, rail.top + rail.height * (12.5 / 26)));
    await tester.pumpAndSettle();
    expect(topOf(tester, 'header-M'),
        moreOrLessEquals(appBarBottom, epsilon: 0.5));
    await tester.drag(find.byKey(const Key('index_rail')), const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(find.byType(LetterHeader), findsWidgets);
  });
}
