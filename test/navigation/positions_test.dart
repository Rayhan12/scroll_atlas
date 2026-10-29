import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../list/list_harness.dart';
import 'navigation_harness.dart';

void main() {
  group('AtlasController.positions', () {
    testWidgets('matches ItemPosition semantics in a plain list',
        (tester) async {
      usePhone(tester);
      final controller = AtlasController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(AtlasListView.builder(
        controller: controller,
        itemCount: 1000,
        itemBuilder: (context, i) => item(i, extent: 100),
      )));
      await tester.pump();
      var visible = controller.positions.value;
      expect(visible.first.index, 0);
      expect(visible.first.itemLeadingEdge, 0);
      expect(visible.first.itemTrailingEdge, closeTo(100 / 844, 1e-9));
      expect(visible.last.index, 8);
      expect(visible.last.itemTrailingEdge, greaterThan(1));
      expect(visible.map((p) => p.index), List.generate(9, (i) => i));

      controller.jumpTo(index: 500, alignment: 0.5);
      await tester.pump();
      await tester.pump();
      visible = controller.positions.value;
      final target = visible.firstWhere((p) => p.index == 500);
      expect(target.itemLeadingEdge, closeTo(0.5, 1e-9));
      expect(
          visible.firstFullyVisible!.itemLeadingEdge, greaterThanOrEqualTo(0));
      expect(visible.mostVisible, isNotNull);
    });

    testWidgets('fractions are relative to the unobstructed viewport',
        (tester) async {
      usePhone(tester);
      final controller = AtlasController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(AtlasScrollView(
        controller: controller,
        slivers: <Widget>[
          const SliverPersistentHeader(pinned: true, delegate: PinnedBar()),
          SliverAtlasList.builder(
            id: 'list',
            itemCount: 200,
            itemBuilder: (context, i) => item(i, extent: 100),
          ),
        ],
      )));
      await tester.pump();
      // Before scrolling, the list starts right below the bar.
      var visible = controller.positions.value.inSliver('list').toList();
      expect(visible.first.index, 0);
      expect(visible.first.itemLeadingEdge, closeTo(0, 1e-9));

      controller.jumpTo(target: const AtlasTarget.item('list', 20));
      await tester.pump();
      await tester.pump();
      visible = controller.positions.value.inSliver('list').toList();
      final target = visible.firstWhere((p) => p.index == 20);
      expect(target.itemLeadingEdge, closeTo(0, 1e-9));
      expect(target.itemTrailingEdge, closeTo(100 / 744, 1e-9));
      // Item 19 is under the bar, so it is not visible.
      expect(visible.any((p) => p.index == 19), isFalse);

      final scroll = controller.scrollController;
      scroll.jumpTo(scroll.offset - 50);
      await tester.pump();
      visible = controller.positions.value.inSliver('list').toList();
      expect(visible.first.index, 19);
      expect(visible.first.itemLeadingEdge, closeTo(-50 / 744, 1e-9));
    });

    testWidgets('tells listeners at most once per frame', (tester) async {
      usePhone(tester);
      final controller = AtlasController();
      addTearDown(controller.dispose);
      var calls = 0;
      controller.positions.addListener(() => calls++);
      await tester.pumpWidget(host(AtlasScrollView(
        controller: controller,
        slivers: <Widget>[
          const SliverPersistentHeader(pinned: true, delegate: PinnedBar()),
          ...sections(),
        ],
      )));
      await tester.pump();
      expect(calls, 1);
      for (var frame = 0; frame < 10; frame++) {
        controller.scrollController.position.jumpTo(
          controller.scrollController.offset + 13,
        );
        await tester.pump();
        expect(calls, 2 + frame);
      }
      // A frame where nothing moves does not notify.
      await tester.pump();
      expect(calls, 11);
      // Several lists and positions in one frame: one notification.
      final before = calls;
      controller.jumpTo(target: AtlasTarget.section(sectionId(3)));
      await tester.pump();
      expect(calls, before + 1);
    });

    testWidgets('a removed list stops reporting positions', (tester) async {
      usePhone(tester);
      final controller = AtlasController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(host(AtlasListView.builder(
        controller: controller,
        itemCount: 10,
        itemBuilder: (context, i) => item(i, extent: 100),
      )));
      await tester.pump();
      expect(controller.positions.value, isNotEmpty);
      await tester.pumpWidget(host(const SizedBox()));
      await tester.pump();
      expect(controller.positions.value, isEmpty);
    });
  });
}
