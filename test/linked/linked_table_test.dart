import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

Widget table({LinkedScrollGroup? h, LinkedScrollGroup? v, bool corner = true}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: LinkedTable(
      rowCount: 1000,
      columnCount: 50,
      horizontalGroup: h,
      verticalGroup: v,
      physics: const ClampingScrollPhysics(),
      cornerBuilder: corner ? (_) => const Text('corner') : null,
      cellBuilder: (_, int row, int column) => Text('$row:$column'),
      columnHeaderBuilder: (_, int column) => Text('C$column'),
      rowHeaderBuilder: (_, int row) => Text('R$row'),
    ),
  );
}

void main() {
  testWidgets('header row and first column stay frozen and in line',
      (tester) async {
    final h = LinkedScrollGroup();
    final v = LinkedScrollGroup();
    addTearDown(h.dispose);
    addTearDown(v.dispose);
    await tester.pumpWidget(table(h: h, v: v));
    expect(find.text('corner'), findsOneWidget);

    await tester.drag(find.text('2:2'), const Offset(-300, 0));
    await tester.pump();
    await tester.drag(find.text('2:5'), const Offset(0, -480));
    await tester.pump();
    // The finger loses the touch slop to the gesture arena.
    expect(h.offset, greaterThan(250));
    expect(v.offset, greaterThan(400));
    for (final p in <ScrollPosition>[...h.positions, ...v.positions]) {
      expect(p.pixels, p.axis == Axis.horizontal ? h.offset : v.offset);
    }

    // Columns line up: a header is directly above its cells.
    final header = tester.getRect(find.text('C7'));
    final cell = tester.getRect(find.text('14:7'));
    expect(cell.left, header.left);
    // Rows line up: a row header is level with its cells.
    expect(tester.getRect(find.text('R14')).top, cell.top);
  });

  testWidgets('rows built after a horizontal scroll start in line',
      (tester) async {
    final h = LinkedScrollGroup();
    addTearDown(h.dispose);
    await tester.pumpWidget(table(h: h, corner: false));
    await tester.drag(find.text('1:1'), const Offset(-500, 0));
    await tester.pump();
    // Scroll far enough that every visible row is newly built.
    await tester.drag(find.text('R1'), const Offset(0, -2000));
    await tester.pump();
    final header = tester.getRect(find.text('C9'));
    expect(tester.getRect(find.text('45:9')).left, header.left);
    expect(h.offset, greaterThan(400));
    for (final p in h.positions) {
      expect(p.pixels, h.offset);
    }
  });

  testWidgets('owned groups are made and disposed by the table',
      (tester) async {
    await tester.pumpWidget(table());
    await tester.drag(find.text('1:1'), const Offset(-200, 0));
    await tester.pump();
    expect(
      tester.getRect(find.text('3:4')).left,
      tester.getRect(find.text('C4')).left,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
