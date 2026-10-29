import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'section_harness.dart';

void main() {
  testWidgets('jump to an empty section lands on its header', (tester) async {
    usePhone(tester);
    final controller = AtlasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AtlasScrollView(
            controller: controller,
            slivers: [
              SliverAtlasSection(
                id: 'A',
                header: (context, stuck) => header('A', stuck),
                sliver: SliverAtlasList.builder(
                  id: 'people-A',
                  itemCount: peopleIn('A'),
                  itemBuilder: (context, i) => person('A', i),
                ),
              ),
              SliverAtlasSection(
                id: 'EMPTY',
                header: (context, stuck) => header('EMPTY', stuck),
                sliver: SliverAtlasList.builder(
                  id: 'people-EMPTY',
                  itemCount: 0,
                  itemBuilder: (context, i) => person('EMPTY', i),
                ),
              ),
              SliverAtlasSection(
                id: 'B',
                header: (context, stuck) => header('B', stuck),
                sliver: SliverAtlasList.builder(
                  id: 'people-B',
                  itemCount: peopleIn('B'),
                  itemBuilder: (context, i) => person('B', i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    controller.jumpTo(target: const AtlasTarget.section('EMPTY'));
    await tester.pump();
    expect(topOf(tester, headerKey('EMPTY')), isNotNull);
    expect(controller.hasTarget('EMPTY'), isTrue);
  });

  testWidgets('fallbackToNearest jumps to the previous section',
      (tester) async {
    usePhone(tester);
    final controller = AtlasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(contacts(controller));
    expect(controller.hasTarget('missing'), isFalse);
    expect(controller.nearestRegisteredId('M2'), 'M');
    controller.jumpTo(
      target: const AtlasTarget.section('M2'),
      fallbackToNearest: true,
    );
    await tester.pump();
    expect(
      topOf(tester, headerKey('M'))! - viewportTop(tester),
      closeTo(appBarExtent, 1),
    );
  });
}
