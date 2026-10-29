import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/compat.dart';

const double _item = 50;

Widget _host(Widget list) => Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(data: const MediaQueryData(), child: list),
    );

Widget _tile(BuildContext context, int index) =>
    SizedBox(height: _item, width: _item, child: Text('item $index'));

double _top(WidgetTester tester, int index) =>
    tester.getTopLeft(find.text('item $index')).dy;

void main() {
  group('ScrollablePositionedList.builder', () {
    testWidgets('initial index and alignment', (tester) async {
      await tester.pumpWidget(_host(const ScrollablePositionedList.builder(
        itemCount: 1000,
        itemBuilder: _tile,
        initialScrollIndex: 20,
        initialAlignment: 0.5,
      )));
      expect(_top(tester, 20), 300);
    });

    testWidgets('jumpTo lands exactly, isAttached follows the list',
        (tester) async {
      final controller = ItemScrollController();
      expect(controller.isAttached, isFalse);
      await tester.pumpWidget(_host(ScrollablePositionedList.builder(
        itemCount: 1000,
        itemBuilder: _tile,
        itemScrollController: controller,
      )));
      expect(controller.isAttached, isTrue);
      controller.jumpTo(index: 500, alignment: 0.25);
      await tester.pump();
      expect(_top(tester, 500), 150);
      await tester.pumpWidget(_host(const SizedBox()));
      expect(controller.isAttached, isFalse);
    });

    testWidgets('scrollTo lands exactly and completes', (tester) async {
      final controller = ItemScrollController();
      await tester.pumpWidget(_host(ScrollablePositionedList.builder(
        itemCount: 1000,
        itemBuilder: _tile,
        itemScrollController: controller,
      )));
      var done = false;
      unawaited(controller.scrollTo(
        index: 300,
        alignment: 0.5,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        // ignore: deprecated_member_use_from_same_package
        opacityAnimationWeights: const [20, 60, 20],
      ).then((_) => done = true));
      await tester.pumpAndSettle();
      expect(done, isTrue);
      expect(_top(tester, 300), 300);
    });

    testWidgets('item positions report items as fractions', (tester) async {
      final controller = ItemScrollController();
      final listener = ItemPositionsListener.create();
      await tester.pumpWidget(_host(ScrollablePositionedList.builder(
        itemCount: 1000,
        itemBuilder: _tile,
        itemScrollController: controller,
        itemPositionsListener: listener,
      )));
      controller.jumpTo(index: 100);
      await tester.pump();
      final positions = listener.itemPositions.value.toList()
        ..sort((a, b) => a.index.compareTo(b.index));
      expect(
        positions.first,
        const ItemPosition(
          index: 100,
          itemLeadingEdge: 0,
          itemTrailingEdge: _item / 600,
        ),
      );
      expect(positions.map((p) => p.index), containsAll([100, 111]));
    });

    testWidgets('animateScroll moves by pixels', (tester) async {
      final offsets = ScrollOffsetController();
      await tester.pumpWidget(_host(ScrollablePositionedList.builder(
        itemCount: 1000,
        itemBuilder: _tile,
        scrollOffsetController: offsets,
      )));
      expect(offsets.isAttached, isTrue);
      unawaited(offsets.animateScroll(
        offset: 200,
        duration: const Duration(milliseconds: 300),
      ));
      await tester.pumpAndSettle();
      expect(_top(tester, 4), 0);
    });

    testWidgets('scroll offset listener reports deltas', (tester) async {
      final controller = ItemScrollController();
      final all = ScrollOffsetListener.create();
      final userOnly =
          ScrollOffsetListener.create(recordProgrammaticScrolls: false);
      final allDeltas = <double>[];
      final userDeltas = <double>[];
      all.changes.listen(allDeltas.add);
      userOnly.changes.listen(userDeltas.add);

      Widget list(ScrollOffsetListener listener) =>
          _host(ScrollablePositionedList.builder(
            key: const ValueKey('list'),
            itemCount: 1000,
            itemBuilder: _tile,
            itemScrollController: controller,
            scrollOffsetListener: listener,
          ));

      await tester.pumpWidget(list(all));
      controller.jumpTo(index: 2);
      await tester.pump();
      expect(allDeltas.fold<double>(0, (a, b) => a + b), 100);

      await tester.pumpWidget(list(userOnly));
      controller.jumpTo(index: 0);
      await tester.pump();
      expect(userDeltas, isEmpty);
      final before = _top(tester, 5);
      await tester.drag(find.text('item 5'), const Offset(0, -150));
      await tester.pump();
      final moved = before - _top(tester, 5);
      expect(moved, greaterThan(0));
      expect(userDeltas.fold<double>(0, (a, b) => a + b), closeTo(moved, 1e-9));
    });

    testWidgets('a new controller takes over on rebuild', (tester) async {
      final first = ItemScrollController();
      final second = ItemScrollController();
      final listener = ItemPositionsListener.create();
      Widget list(ItemScrollController controller) =>
          _host(ScrollablePositionedList.builder(
            itemCount: 100,
            itemBuilder: _tile,
            itemScrollController: controller,
            itemPositionsListener: listener,
          ));
      await tester.pumpWidget(list(first));
      await tester.pumpWidget(list(second));
      expect(first.isAttached, isFalse);
      expect(second.isAttached, isTrue);
      second.jumpTo(index: 50);
      await tester.pump();
      expect(listener.itemPositions.value.map((p) => p.index), contains(50));
    });

    testWidgets('one controller on two lists asserts', (tester) async {
      final controller = ItemScrollController();
      await tester.pumpWidget(_host(Row(
        children: [
          for (var i = 0; i < 2; i++)
            Expanded(
              child: ScrollablePositionedList.builder(
                itemCount: 10,
                itemBuilder: _tile,
                itemScrollController: controller,
              ),
            ),
        ],
      )));
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('shrinkWrap is not silently ignored', (tester) async {
      await tester.pumpWidget(_host(const ScrollablePositionedList.builder(
        itemCount: 10,
        itemBuilder: _tile,
        // ignore: deprecated_member_use_from_same_package
        shrinkWrap: true,
      )));
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('passes every other parameter through', (tester) async {
      await tester.pumpWidget(_host(const ScrollablePositionedList.builder(
        itemCount: 100,
        itemBuilder: _tile,
        scrollDirection: Axis.horizontal,
        physics: ClampingScrollPhysics(),
        semanticChildCount: 100,
        padding: EdgeInsets.only(left: 10),
        addSemanticIndexes: false,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        minCacheExtent: 100,
      )));
      expect(tester.getTopLeft(find.text('item 0')).dx, 10);
      expect(tester.getTopLeft(find.text('item 1')).dx, 60);
    });
  });

  group('ScrollablePositionedList.separated', () {
    Widget separated({
      ItemScrollController? controller,
      ItemPositionsListener? listener,
      bool reverse = false,
    }) =>
        _host(ScrollablePositionedList.separated(
          itemCount: 50,
          itemBuilder: _tile,
          separatorBuilder: (context, index) =>
              SizedBox(height: 10, child: Text('sep $index')),
          itemScrollController: controller,
          itemPositionsListener: listener,
          reverse: reverse,
        ));

    testWidgets('indexes stay item indexes', (tester) async {
      final controller = ItemScrollController();
      final listener = ItemPositionsListener.create();
      await tester.pumpWidget(
        separated(controller: controller, listener: listener),
      );
      expect(tester.getTopLeft(find.text('sep 0')).dy, _item);
      expect(_top(tester, 1), _item + 10);
      controller.jumpTo(index: 10);
      await tester.pump();
      expect(_top(tester, 10), 0);
      expect(
          listener.itemPositions.value.map((p) => p.index).reduce(
                (a, b) => a < b ? a : b,
              ),
          10);
      controller.jumpTo(index: 49);
      await tester.pump();
      expect(find.text('item 49'), findsOneWidget);
      expect(find.text('sep 49'), findsNothing);
      expect(find.text('sep 48'), findsOneWidget);
    });

    testWidgets('reversed lists put separators between items', (tester) async {
      await tester.pumpWidget(separated(reverse: true));
      expect(tester.getBottomLeft(find.text('item 0')).dy, 600);
      final separator = tester.getRect(find.text('sep 0'));
      expect(separator.bottom, 600 - _item);
      expect(tester.getBottomLeft(find.text('item 1')).dy, separator.top);
    });
  });
}
