import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../list/list_harness.dart';
import 'navigation_harness.dart';

const _ids = <String>[
  'section-0',
  'section-1',
  'section-2',
  'section-3',
  'section-4'
];

class _Menu extends StatefulWidget {
  const _Menu({required this.controller, this.onChanged, this.ids = _ids});

  final AtlasController controller;
  final ValueChanged<int>? onChanged;
  final List<String> ids;

  @override
  State<_Menu> createState() => _MenuState();
}

class _MenuState extends State<_Menu> {
  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: AtlasScrollView(
            controller: widget.controller,
            slivers: <Widget>[
              SliverPersistentHeader(
                pinned: true,
                delegate: PinnedBar(
                  child: Material(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: AtlasTabBar(
                        controller: widget.controller,
                        sectionIds: widget.ids,
                        tabs: [
                          for (final id in widget.ids)
                            Tab(text: 'T${id.substring(8)}')
                        ],
                        onSectionChanged: widget.onChanged,
                      ),
                    ),
                  ),
                ),
              ),
              ...sections(),
            ],
          ),
        ),
      );
}

TabController _tabs(WidgetTester tester) =>
    tester.widget<TabBar>(find.byType(TabBar)).controller!;

double _headerTop(WidgetTester tester, int section) =>
    tester.getRect(find.byKey(ValueKey('header-$section'))).top;

void main() {
  group('AtlasTabBar', () {
    testWidgets('tapping a tab lands its section and moves the indicator once',
        (tester) async {
      usePhone(tester);
      final controller = AtlasController();
      addTearDown(controller.dispose);
      final reported = <int>[];
      await tester.pumpWidget(
        _Menu(controller: controller, onChanged: reported.add),
      );
      await tester.pump();
      final tabs = _tabs(tester);
      final indexes = <int>[];
      tabs.addListener(() {
        if (indexes.isEmpty || indexes.last != tabs.index) {
          indexes.add(tabs.index);
        }
      });

      await tester.tap(find.text('T2'));
      await tester.pumpAndSettle();
      expect(indexes, [2], reason: 'one indicator change for one tap');
      expect(reported, [2]);
      expect(_headerTop(tester, 2), closeTo(barExtent, 0.5));

      // Section 3 is too close to the end to reach the bar: its tab stays.
      indexes.clear();
      await tester.tap(find.text('T3'));
      await tester.pumpAndSettle();
      expect(indexes, [3]);
      final position = controller.scrollController.position;
      expect(position.pixels, position.maxScrollExtent);
      await tester.pump(const Duration(seconds: 1));
      expect(tabs.index, 3);

      // Back to the first tab, passing sections 2 and 1.
      indexes.clear();
      await tester.tap(find.text('T0'));
      await tester.pumpAndSettle();
      expect(indexes, [0]);
      expect(controller.scrollController.offset, 0);
    });

    testWidgets('the short last tab lands at the end and stays active',
        (tester) async {
      usePhone(tester);
      final controller = AtlasController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_Menu(controller: controller));
      await tester.pump();
      await tester.tap(find.text('T4'));
      await tester.pumpAndSettle();
      final position = controller.scrollController.position;
      expect(position.pixels, position.maxScrollExtent);
      expect(_tabs(tester).index, 4);
    });

    testWidgets('scrolling by hand moves the indicator', (tester) async {
      usePhone(tester);
      final controller = AtlasController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_Menu(controller: controller));
      await tester.pump();
      controller.jumpTo(target: AtlasTarget.section(_ids[2]));
      await tester.pumpAndSettle();
      expect(_tabs(tester).index, 2);
    });

    testWidgets('a drag during the animation hands control to the spy',
        (tester) async {
      usePhone(tester);
      final controller = AtlasController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_Menu(controller: controller));
      await tester.pump();
      await tester.tap(find.text('T4'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // The animation is under way; the user grabs the list.
      final gesture = await tester.startGesture(const Offset(200, 600));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 40));
      await gesture.up();
      await tester.pumpAndSettle();
      final position = controller.scrollController.position;
      expect(position.pixels, lessThan(position.maxScrollExtent));
      // The indicator shows the section under the bar, not the tapped one.
      final spy = AtlasScrollSpy(controller: controller, sectionIds: _ids)
        ..update();
      expect(_tabs(tester).index, spy.value);
      expect(spy.value, isNot(4));
      spy.dispose();
    });

    testWidgets('new section ids rebuild the spy', (tester) async {
      usePhone(tester);
      final controller = AtlasController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_Menu(controller: controller));
      await tester.pump();
      await tester.pumpWidget(
        _Menu(controller: controller, ids: _ids.reversed.toList()),
      );
      await tester.pump();
      await tester.pumpWidget(
        _Menu(controller: controller, ids: _ids.reversed.toList()),
      );
      await tester.pump();
      expect(find.byType(AtlasTabBar), findsOneWidget);
      expect(
        AtlasTabBar(
          controller: controller,
          sectionIds: const ['a'],
          tabs: const [Tab(text: 'a')],
        ).preferredSize.height,
        greaterThan(0),
      );
    });
  });
}
