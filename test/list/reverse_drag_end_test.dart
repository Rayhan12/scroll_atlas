import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'list_harness.dart';

void main() {
  testWidgets('slow drag toward the newest message reaches the true end',
      (tester) async {
    final controller = AtlasController();
    addTearDown(controller.dispose);
    usePhone(tester);
    await tester.pumpWidget(host(AtlasListView.builder(
      controller: controller,
      reverse: true,
      itemCount: 500,
      itemBuilder: (context, index) => item(index),
    )));
    final scrollable = find.byType(Scrollable);
    await tester.drag(scrollable, Offset(0, phoneSize.height * 4));
    await tester.pumpAndSettle();
    expect(controller.scrollController.offset, greaterThan(phoneSize.height));
    final gesture = await tester.startGesture(tester.getCenter(scrollable));
    for (var step = 0; step < 80; step++) {
      await gesture.moveBy(const Offset(0, -60));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pumpAndSettle();
    expect(controller.scrollController.offset, closeTo(0, 1));
    expect(rectOf(tester, 0), isNotNull);
    expect(rectOf(tester, 0)!.bottom, closeTo(phoneSize.height, 0.5));
  });
}
