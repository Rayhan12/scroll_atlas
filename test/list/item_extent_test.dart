import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'list_harness.dart';

void main() {
  testWidgets('itemExtent makes jumps exact without measuring gaps',
      (tester) async {
    const extent = 72.0;
    final controller = AtlasController();
    addTearDown(controller.dispose);
    usePhone(tester);
    await tester.pumpWidget(host(AtlasListView.builder(
      controller: controller,
      itemCount: 5000,
      itemExtent: extent,
      itemBuilder: (context, index) => Text('$index'),
    )));
    controller.jumpTo(index: 2500);
    await tester.pump();
    expect(
      controller.scrollController.offset,
      closeTo(2500 * extent, 0.5),
    );
    expect(FixedExtentEstimator(extent).estimate, extent);
  });
}
