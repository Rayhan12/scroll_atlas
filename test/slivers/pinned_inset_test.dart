import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../list/list_harness.dart';

void main() {
  testWidgets('pinnedInset shifts jump alignment below an overlay',
      (tester) async {
    usePhone(tester);
    final controller = AtlasController();
    addTearDown(controller.dispose);
    const overlay = 48.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              AtlasScope(
                controller: controller,
                pinnedInset: overlay,
                child: AtlasListView.builder(
                  controller: controller,
                  itemCount: 1000,
                  itemBuilder: (context, index) => item(index),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: overlay,
                child: ColoredBox(color: Color(0xFF000000)),
              ),
            ],
          ),
        ),
      ),
    );
    controller.jumpTo(index: 50);
    await tester.pump();
    expect(rectOf(tester, 50)!.top, closeTo(overlay, 0.5));
  });
}
