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

  testWidgets('a diagonal drag on the body scrolls both axes in line',
      (tester) async {
    final h = LinkedScrollGroup();
    final v = LinkedScrollGroup();
    addTearDown(h.dispose);
    addTearDown(v.dispose);
    await tester.pumpWidget(table(h: h, v: v));
    final gesture =
        await tester.startGesture(tester.getCenter(find.text('3:3')));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(-20, -30));
      await tester.pump();
      for (final p in <ScrollPosition>[...h.positions, ...v.positions]) {
        expect(p.pixels, p.axis == Axis.horizontal ? h.offset : v.offset);
      }
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(h.offset, greaterThan(100));
    expect(v.offset, greaterThan(150));
    final cell = find.text('9:6');
    expect(tester.getRect(cell).left, tester.getRect(find.text('C6')).left);
    expect(tester.getRect(cell).top, tester.getRect(find.text('R9')).top);
  });

  testWidgets('a diagonal fling keeps headers in line on every frame',
      (tester) async {
    final h = LinkedScrollGroup();
    final v = LinkedScrollGroup();
    addTearDown(h.dispose);
    addTearDown(v.dispose);
    await tester.pumpWidget(table(h: h, v: v));
    await tester.fling(find.text('4:2'), const Offset(-300, -400), 2000);
    var frames = 0;
    while (tester.binding.hasScheduledFrame && frames < 300) {
      await tester.pump(const Duration(milliseconds: 16));
      frames++;
      for (final p in <ScrollPosition>[...h.positions, ...v.positions]) {
        expect(p.pixels, p.axis == Axis.horizontal ? h.offset : v.offset);
      }
    }
    expect(h.offset, greaterThan(300));
    expect(v.offset, greaterThan(400));
  });

  testWidgets('new extents and a locked drag behavior apply on rebuild',
      (tester) async {
    Widget sized(double extent) => Directionality(
          textDirection: TextDirection.ltr,
          child: LinkedTable(
            rowCount: 100,
            columnCount: 20,
            rowExtent: extent,
            columnExtent: extent * 2,
            diagonalDragBehavior: DiagonalDragBehavior.none,
            cellBuilder: (_, int row, int column) => Text('$row:$column'),
            columnHeaderBuilder: (_, int column) => Text('C$column'),
            rowHeaderBuilder: (_, int row) => Text('R$row'),
          ),
        );
    await tester.pumpWidget(sized(48));
    expect(
        tester.getSize(find.text('1:1').first).height, lessThanOrEqualTo(48));
    await tester.pumpWidget(sized(60));
    expect(
      tester.getRect(find.text('2:0')).top,
      tester.getRect(find.text('R2')).top,
    );
  });
}
