import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'list_harness.dart';

void main() {
  testWidgets('animateTo survives itemCount change mid flight', (tester) async {
    usePhone(tester);
    final controller = AtlasController();
    addTearDown(controller.dispose);
    var count = 500;
    late StateSetter setState;
    await tester.pumpWidget(host(StatefulBuilder(
      builder: (context, set) {
        setState = set;
        return AtlasListView.builder(
          controller: controller,
          itemCount: count,
          itemBuilder: (context, index) => item(index),
        );
      },
    )));
    final animation = controller.animateTo(
      index: 400,
      duration: const Duration(milliseconds: 400),
    );
    await tester.pump();
    setState(() => count = 800);
    await tester.pump();
    await tester.pumpAndSettle();
    await animation;
    await tester.pump();
    expect(rectOf(tester, 400)!.top, closeTo(0, 0.5));
  });

  testWidgets('animateTo completes when another jump interrupts the wait',
      (tester) async {
    usePhone(tester);
    final controller = AtlasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(host(AtlasListView.builder(
      controller: controller,
      itemCount: 10,
      itemBuilder: (context, index) => item(index),
    )));
    final animation = controller.animateTo(
      index: 5,
      duration: const Duration(milliseconds: 200),
    );
    await tester.pump();
    controller.jumpTo(index: 0);
    await animation;
  });

  testWidgets('animateTo item 150 lands right after the list reloads',
      (tester) async {
    usePhone(tester);
    final controller = AtlasController();
    addTearDown(controller.dispose);
    const alignment = 0.25;
    var count = 20;
    late StateSetter setState;
    late Future<void> animation;
    await tester.pumpWidget(host(StatefulBuilder(
      builder: (context, set) {
        setState = set;
        return AtlasScrollView(
          controller: controller,
          slivers: [
            SliverAtlasList.builder(
              id: 'list',
              itemCount: count,
              itemBuilder: (context, index) => item(index, extent: 100),
            ),
          ],
        );
      },
    )));
    await tester.pumpAndSettle();
    setState(() => count = 200);
    await tester.pump();
    animation = controller.animateTo(
      target: const AtlasTarget.item('list', 150),
      alignment: alignment,
      duration: const Duration(milliseconds: 500),
    );
    await tester.pump();
    await tester.pumpAndSettle();
    await animation;
    await tester.pump();
    expect(rectOf(tester, 150)!.top, closeTo(alignedTop(alignment), 0.5));
  });

  testWidgets('animateTo retargets when itemCount grows during the glide',
      (tester) async {
    usePhone(tester);
    final controller = AtlasController();
    addTearDown(controller.dispose);
    var count = 200;
    late StateSetter setState;
    await tester.pumpWidget(host(StatefulBuilder(
      builder: (context, set) {
        setState = set;
        return AtlasScrollView(
          controller: controller,
          slivers: [
            SliverAtlasList.builder(
              id: 'list',
              itemCount: count,
              itemBuilder: (context, index) => item(index, extent: 100),
            ),
          ],
        );
      },
    )));
    await tester.pumpAndSettle();
    final animation = controller.animateTo(
      target: const AtlasTarget.item('list', 400),
      duration: const Duration(milliseconds: 800),
    );
    await tester.pump();
    setState(() => count = 500);
    await tester.pump();
    await tester.pumpAndSettle();
    await animation;
    await tester.pump();
    expect(rectOf(tester, 400)!.top, closeTo(0, 0.5));
  });
}
