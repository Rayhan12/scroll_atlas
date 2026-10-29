import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../list/list_harness.dart';
import 'navigation_harness.dart';

Widget _view(AtlasController controller, {Widget? bar}) => host(
      AtlasScrollView(
        controller: controller,
        slivers: <Widget>[
          SliverPersistentHeader(pinned: true, delegate: PinnedBar(child: bar)),
          ...sections(),
        ],
      ),
    );

void main() {
  group('AtlasScrollSpy', () {
    late AtlasController controller;
    late AtlasScrollSpy spy;
    late List<int> changes;

    Future<void> setUpView(WidgetTester tester) async {
      usePhone(tester);
      controller = AtlasController();
      spy = AtlasScrollSpy(
        controller: controller,
        sectionIds: [
          for (var s = 0; s < sectionSizes.length; s++) sectionId(s)
        ],
      );
      changes = <int>[];
      spy.addListener(() => changes.add(spy.value));
      addTearDown(() {
        spy.dispose();
        controller.dispose();
      });
      await tester.pumpWidget(_view(controller));
      await tester.pump();
    }

    testWidgets('starts on the first section', (tester) async {
      await setUpView(tester);
      expect(spy.value, 0);
      expect(spy.sectionIds, hasLength(sectionSizes.length));
    });

    testWidgets('a section becomes active when its header reaches the bar',
        (tester) async {
      await setUpView(tester);
      // Section 1 starts at 40 + 10 * 50 = 540 in list coordinates.
      final scroll = controller.scrollController;
      scroll.jumpTo(540 - 1);
      await tester.pump();
      expect(spy.value, 0);
      scroll.jumpTo(540);
      await tester.pump();
      expect(spy.value, 1);
      expect(changes, [1]);

      // Scrolling back by hand: the spy follows both ways.
      await tester.drag(find.byType(Scrollable), const Offset(0, 300));
      await tester.pumpAndSettle();
      expect(spy.value, 0);
    });

    testWidgets('a jump to a section activates exactly that section',
        (tester) async {
      await setUpView(tester);
      controller.jumpTo(target: AtlasTarget.section(sectionId(2)));
      await tester.pump();
      await tester.pump();
      expect(spy.value, 2);
    });

    testWidgets('the short last section is active at the end', (tester) async {
      await setUpView(tester);
      final scroll = controller.scrollController;
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      await tester.pump();
      expect(spy.value, sectionSizes.length - 1);
      // Its header never reached the bar.
      final header = tester.getRect(find.byKey(const ValueKey('header-4')));
      expect(header.top, greaterThan(barExtent + 1));
    });

    testWidgets('lock holds the value and unlock catches up', (tester) async {
      await setUpView(tester);
      spy.lock();
      expect(spy.locked, isTrue);
      controller.jumpTo(target: AtlasTarget.section(sectionId(2)));
      await tester.pump();
      await tester.pump();
      expect(spy.value, 0);
      spy.unlock();
      expect(spy.locked, isFalse);
      expect(spy.value, 2);
      spy.unlock(); // Extra unlocks are ignored.
      expect(spy.locked, isFalse);
    });

    testWidgets('hold keeps a section until the view scrolls', (tester) async {
      await setUpView(tester);
      final scroll = controller.scrollController;
      scroll.jumpTo(scroll.position.maxScrollExtent);
      await tester.pump();
      await tester.pump();
      expect(spy.value, 4);
      spy.hold(3);
      spy.update();
      expect(spy.value, 3);
      spy.hold(3);
      expect(spy.value, 3);
      // One pixel before the end, section 3 has not reached the bar yet.
      scroll.jumpTo(scroll.position.maxScrollExtent - 1);
      await tester.pump();
      await tester.pump();
      expect(spy.value, 2);
    });

    testWidgets('does nothing without a scroll view', (tester) async {
      final lonely = AtlasController();
      final idle = AtlasScrollSpy(controller: lonely, sectionIds: ['a']);
      idle.update();
      idle.hold(0);
      expect(idle.value, 0);
      idle.dispose();
      idle.update();
      lonely.dispose();
    });
  });
}
