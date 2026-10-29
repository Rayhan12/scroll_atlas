import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'list_harness.dart';

void main() {
  late AtlasController controller;

  setUp(() => controller = AtlasController());
  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester,
      {int count = 100000, bool reverse = false}) async {
    usePhone(tester);
    await tester.pumpWidget(host(AtlasScrollbar(
      controller: controller,
      reverse: reverse,
      child: AtlasListView.builder(
        controller: controller,
        reverse: reverse,
        itemCount: count,
        itemBuilder: (context, index) => item(index),
      ),
    )));
  }

  AtlasThumbPainter painter(WidgetTester tester) => tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((paint) => paint.painter)
      .whereType<AtlasThumbPainter>()
      .single;

  testWidgets(
      'the fraction only grows during a fling, while items '
      'get measured', (tester) async {
    await pump(tester);
    controller.jumpTo(index: 30000);
    await tester.pump();
    final values = <double>[controller.scrollFraction!];
    controller.scrollController.addListener(
      () => values.add(controller.scrollFraction!),
    );
    await tester.fling(find.byType(Scrollable), const Offset(0, -600), 8000);
    await tester.pumpAndSettle();
    expect(values.length, greaterThan(10));
    for (var i = 1; i < values.length; i++) {
      expect(values[i], greaterThanOrEqualTo(values[i - 1]));
    }
    expect(values.last, greaterThan(values.first));
  });

  testWidgets('the thumb follows the fraction', (tester) async {
    await pump(tester);
    expect(controller.scrollFraction, 0);
    controller.jumpTo(index: 50000);
    await tester.pump();
    expect(controller.scrollFraction, closeTo(0.5, 0.001));
    final rect = painter(tester).thumbRect(const Size(24, 844))!;
    expect(
        rect.height,
        AtlasScrollbar(controller: controller, child: const SizedBox())
            .minThumbExtent);
    expect(rect.center.dy, closeTo(844 / 2, 1));
  });

  testWidgets('dragging the thumb area jumps by fraction', (tester) async {
    await pump(tester);
    await tester.dragFrom(const Offset(380, 10), const Offset(0, 412));
    await tester.pump();
    expect(controller.scrollFraction, closeTo(0.5, 0.02));
    await tester.dragFrom(const Offset(380, 400), const Offset(0, 1000));
    await tester.pump();
    expect(controller.scrollFraction, closeTo(1, 1e-4));
    expect(rectOf(tester, 99999)!.bottom, closeTo(844, 0.5));
  });

  testWidgets('a reversed bar starts at the bottom', (tester) async {
    await pump(tester, reverse: true);
    final rect = painter(tester).thumbRect(const Size(24, 844))!;
    expect(rect.bottom, closeTo(844, 0.01));
    await tester.dragFrom(const Offset(380, 830), const Offset(0, -10));
    await tester.pump();
    expect(controller.scrollFraction, closeTo(0, 0.01));
  });

  testWidgets('no thumb when every item fits', (tester) async {
    await pump(tester, count: 2);
    expect(painter(tester).thumbRect(const Size(24, 844)), isNull);
  });

  test('AtlasThumbPainter repaints only on change', () {
    final other = AtlasController();
    addTearDown(other.dispose);
    AtlasThumbPainter make({
      AtlasController? using,
      Color color = const Color(0xFF000000),
    }) =>
        AtlasThumbPainter(
          controller: using ?? controller,
          reverse: false,
          thickness: 6,
          minThumbExtent: 32,
          color: color,
        );
    expect(make().shouldRepaint(make()), isFalse);
    expect(make().shouldRepaint(make(using: other)), isTrue);
    expect(make().shouldRepaint(make(color: const Color(0xFFFFFFFF))), isTrue);
    // Not attached: nothing to paint.
    expect(make().thumbRect(const Size(24, 800)), isNull);
  });
}
