import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../list/list_harness.dart';

void main() {
  testWidgets('hidden tabs defer positions and scroll spy until shown',
      (tester) async {
    usePhone(tester);
    final first = AtlasController();
    final second = AtlasController();
    final spy = AtlasScrollSpy(controller: first, sectionIds: const ['a']);
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    addTearDown(spy.dispose);

    var tab = 0;
    var positionFrames = 0;
    first.positions.addListener(() => positionFrames++);
    var spyFrames = 0;
    spy.addListener(() => spyFrames++);

    Widget tabs() => MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => IndexedStack(
              index: tab,
              children: [
                TickerMode(
                  enabled: tab == 0,
                  child: AtlasScrollView(
                    controller: first,
                    slivers: [
                      SliverAtlasSection(
                        id: 'a',
                        header: (_, __) => const SizedBox(height: 40),
                        sliver: SliverAtlasList.builder(
                          id: 'a-list',
                          itemCount: 40,
                          itemBuilder: (context, i) => item(i),
                        ),
                      ),
                    ],
                  ),
                ),
                TickerMode(
                  enabled: tab == 1,
                  child: AtlasScrollView(
                    controller: second,
                    slivers: [
                      SliverAtlasSection(
                        id: 'b',
                        header: (_, __) => const SizedBox(height: 40),
                        sliver: SliverAtlasList.builder(
                          id: 'b-list',
                          itemCount: 40,
                          itemBuilder: (context, i) => item(i + 1000),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    await tester.pumpWidget(tabs());
    await tester.pumpAndSettle();
    first.jumpTo(target: const AtlasTarget.item('a-list', 10));
    await tester.pumpAndSettle();
    positionFrames = 0;
    spyFrames = 0;
    final spyBeforeHide = spy.value;

    first.jumpTo(target: const AtlasTarget.item('a-list', 30));
    tab = 1;
    await tester.pumpWidget(tabs());
    await tester.pump();
    await tester.pump();

    expect(positionFrames, 0);
    expect(spyFrames, 0);
    expect(spy.value, spyBeforeHide);

    tab = 0;
    await tester.pumpWidget(tabs());
    await tester.pumpAndSettle();

    expect(positionFrames, greaterThan(0));
    expect(rectOf(tester, 30)!.top, closeTo(40, 0.5));
    expect(spy.value, 0);
  });

  testWidgets('jump while hidden applies when the tab is shown again',
      (tester) async {
    usePhone(tester);
    final first = AtlasController();
    final second = AtlasController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    var tab = 0;
    Widget tabs() => MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) => IndexedStack(
              index: tab,
              children: [
                TickerMode(
                  enabled: tab == 0,
                  child: AtlasScrollView(
                    controller: first,
                    slivers: [
                      SliverAtlasSection(
                        id: 'a',
                        header: (_, __) => const SizedBox(height: 40),
                        sliver: SliverAtlasList.builder(
                          id: 'a-list',
                          itemCount: 40,
                          itemBuilder: (context, i) => item(i),
                        ),
                      ),
                    ],
                  ),
                ),
                TickerMode(
                  enabled: tab == 1,
                  child: AtlasScrollView(
                    controller: second,
                    slivers: [
                      SliverAtlasSection(
                        id: 'b',
                        header: (_, __) => const SizedBox(height: 40),
                        sliver: SliverAtlasList.builder(
                          id: 'b-list',
                          itemCount: 40,
                          itemBuilder: (context, i) => item(i + 1000),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
    await tester.pumpWidget(tabs());
    await tester.pumpAndSettle();
    tab = 1;
    await tester.pumpWidget(tabs());
    await tester.pumpAndSettle();
    first.jumpTo(target: const AtlasTarget.item('a-list', 35));
    await tester.pump();
    tab = 0;
    await tester.pumpWidget(tabs());
    await tester.pumpAndSettle();
    expect(rectOf(tester, 35)!.top, closeTo(40, 0.5));
  });
}
