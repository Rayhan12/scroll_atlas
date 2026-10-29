import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas_example/demos/timetable/timetable_screen.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: TimetableScreen()));
  }

  testWidgets('times stay above their cells after a fling',
      (WidgetTester tester) async {
    await open(tester);
    await tester.fling(find.byKey(const ValueKey<String>('cell-1-1')),
        const Offset(-300, 0), 2000);
    await tester.pumpAndSettle();
    // Every time on screen sits right above its column of cells.
    var checked = 0;
    for (var slot = 0; slot < TimetableScreen.slots; slot++) {
      final label = find.text(TimetableScreen.slotLabel(slot));
      final cell = find.byKey(ValueKey<String>('cell-2-$slot'));
      if (label.evaluate().isEmpty || cell.evaluate().isEmpty) continue;
      final header = tester.getRect(
          find.ancestor(of: label, matching: find.byType(Center)).first);
      expect(tester.getRect(cell).left - 2,
          moreOrLessEquals(header.left, epsilon: 0.5));
      checked++;
    }
    expect(checked, greaterThan(2));
    expect(find.text('00:00'), findsNothing, reason: 'the fling moved');
  });

  testWidgets('a diagonal fling moves both axes, headers in line',
      (WidgetTester tester) async {
    await open(tester);
    await tester.fling(find.byKey(const ValueKey<String>('cell-2-2')),
        const Offset(-300, -400), 2500);
    await tester.pumpAndSettle();
    expect(find.text('00:00'), findsNothing);
    expect(find.text('Table 0'), findsNothing);
    final cells = find.byWidgetPredicate((Widget w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('cell-'));
    final first = cells.evaluate().first.widget.key! as ValueKey<String>;
    final parts = first.value.split('-');
    final room = find.text('Table ${parts[1]}');
    if (room.evaluate().isNotEmpty) {
      expect(
        tester.getCenter(find.byKey(first)).dy,
        moreOrLessEquals(tester.getCenter(room).dy, epsilon: 0.5),
      );
    }
  });

  testWidgets('rows built after scrolling down are in line',
      (WidgetTester tester) async {
    await open(tester);
    await tester.tap(find.byTooltip('Go to 12:00'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('Table 2'), const Offset(0, -3000));
    await tester.pumpAndSettle();
    final header = tester.getRect(find
        .ancestor(of: find.text('12:00'), matching: find.byType(Center))
        .first);
    final rows = find.byWidgetPredicate((Widget w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.endsWith('-24') &&
        (w.key! as ValueKey<String>).value.startsWith('cell-'));
    expect(rows, findsWidgets);
    for (final e in rows.evaluate()) {
      final left = tester.getRect(find.byWidget(e.widget)).left - 2;
      expect(left, moreOrLessEquals(header.left, epsilon: 0.5));
    }
  });
}
