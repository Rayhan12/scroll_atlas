import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

void main() {
  testWidgets('AtlasListView.separated keeps item indexes horizontally',
      (tester) async {
    final controller = AtlasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: AtlasListView.separated(
        itemCount: 100,
        controller: controller,
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) =>
            SizedBox(width: 80, child: Text('item $index')),
        separatorBuilder: (context, index) =>
            SizedBox(width: 20, child: Text('sep $index')),
      ),
    ));
    expect(tester.getTopLeft(find.text('sep 0')).dx, 80);
    expect(tester.getTopLeft(find.text('item 1')).dx, 100);
    controller.jumpTo(index: 30);
    await tester.pump();
    expect(tester.getTopLeft(find.text('item 30')).dx, 0);
    unawaited(controller.animateBy(
      offset: 100,
      duration: const Duration(milliseconds: 200),
    ));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('item 31')).dx, 0);
  });
}
