import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'section_harness.dart';

void main() {
  testWidgets('unnamed list in a section uses the section id', (tester) async {
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
                id: 'K',
                header: (context, stuck) => header('K', stuck),
                sliver: SliverAtlasList.builder(
                  itemCount: peopleIn('K'),
                  itemBuilder: (context, i) => person('K', i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    controller.jumpTo(target: const AtlasTarget.sectionItem('K', 2));
    await tester.pump();
    expect(topOf(tester, personKey('K', 2)), isNotNull);
    expect(controller.hasTarget('K'), isTrue);
  });
}
