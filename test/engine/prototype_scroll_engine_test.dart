import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/experimental.dart';
import 'package:scroll_atlas/fixtures.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../support/position_matchers.dart';
import '../support/test_app.dart';

const int _itemCount = 100000;

void main() {
  late SeededExtents extents;
  late BuildCounter counter;
  late IndexedScrollEngine engine;

  setUp(() {
    extents = SeededExtents(seed: 42, length: _itemCount);
    counter = BuildCounter();
    engine = PrototypeScrollEngine();
  });
  tearDown(() => engine.dispose());

  Future<void> pumpList(WidgetTester tester) async {
    usePhoneView(tester);
    await tester.pumpWidget(host(engine.buildList(
      itemCount: _itemCount,
      itemBuilder: counter.wrap(
        (context, index) => FixtureItem(index: index, extent: extents[index]),
      ),
    )));
  }

  testWidgets('jumps to unbuilt items in one frame with a bounded build',
      (tester) async {
    await pumpList(tester);
    final targets =
        seededTargets(seed: 7, count: 60, itemCount: _itemCount - 50);
    const alignments = [0.0, 0.25, 0.5];
    for (var i = 0; i < targets.length; i++) {
      counter.reset();
      final alignment = alignments[i % alignments.length];
      engine.jumpToIndex(targets[i], alignment: alignment);
      await tester.pump();
      expectItemAt(tester, targets[i], alignment: alignment);
      // Viewport (844) plus two default cache extents (2 x 250) of items no
      // shorter than 48 px, plus the items that straddle the edges.
      expect(counter.builtIndexes.length, lessThanOrEqualTo(1344 ~/ 48 + 2));
    }
  });

  testWidgets('a near jump reuses built children', (tester) async {
    await pumpList(tester);
    engine.jumpToIndex(3, alignment: 0.5);
    await tester.pump();
    expectItemAt(tester, 3, alignment: 0.5);
  });

  testWidgets('animateToIndex lands exactly far away', (tester) async {
    await pumpList(tester);
    engine.jumpToIndex(1000);
    await tester.pump();
    final done = engine.animateToIndex(81000,
        duration: const Duration(milliseconds: 600), alignment: 0.5);
    await tester.pumpAndSettle();
    await done;
    await tester.pump();
    expectItemAt(tester, 81000, alignment: 0.5);
  });

  testWidgets('scrolling back to the top after a far jump ends at item 0',
      (tester) async {
    await pumpList(tester);
    engine.jumpToIndex(50000);
    await tester.pump();
    engine.jumpToIndex(0);
    await tester.pump();
    expectItemAt(tester, 0);
    expectNoBuildOf(const [50000]);
  });

  testWidgets('dragging after a jump keeps items in order', (tester) async {
    await pumpList(tester);
    engine.jumpToIndex(20000, alignment: 0.5);
    await tester.pump();
    final before = itemLeadingEdge(tester, 20000);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pump();
    expect(itemLeadingEdge(tester, 20000), closeTo(before - 200, 0.5));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pump();
    expect(itemLeadingEdge(tester, 20000), closeTo(before + 200, 0.5));
  });

  testWidgets('works with a caller-owned controller and an empty list',
      (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    final ownEngine = PrototypeScrollEngine(controller: controller);
    addTearDown(ownEngine.dispose);
    usePhoneView(tester);
    await tester.pumpWidget(host(ownEngine.buildList(
      itemCount: 0,
      itemBuilder: (context, index) => const SizedBox(),
    )));
    expect(controller.position.maxScrollExtent, 0);
    expect(ownEngine.id, 'scroll_atlas_prototype');
  });
}
