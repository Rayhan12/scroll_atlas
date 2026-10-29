import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'list_harness.dart';

void main() {
  late AtlasController controller;
  late Builds builds;

  setUp(() {
    controller = AtlasController();
    builds = Builds();
  });
  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester, {int count = 100000}) async {
    usePhone(tester);
    await tester.pumpWidget(host(AtlasListView.builder(
      controller: controller,
      itemCount: count,
      itemBuilder: (context, index) {
        builds.count++;
        return item(index);
      },
    )));
  }

  testWidgets('far jump lands in one frame and builds < 40 items',
      (tester) async {
    await pump(tester);
    builds.count = 0;
    controller.jumpTo(index: 50000);
    await tester.pump();
    expect(rectOf(tester, 50000)!.top, closeTo(0, 0.5));
    expect(builds.count, lessThan(40));
  });

  testWidgets('1000 random jumps land within 0.5 px', (tester) async {
    await pump(tester);
    final random = math.Random(42);
    const alignments = [0.0, 0.3, 0.5, 1.0];
    var worst = 0.0;
    for (var i = 0; i < 1000; i++) {
      // Keep away from the very end, where the list end clamps (covered by
      // its own test).
      final index = random.nextInt(99900);
      final alignment = alignments[random.nextInt(alignments.length)];
      controller.jumpTo(index: index, alignment: alignment);
      await tester.pump();
      final top = rectOf(tester, index)!.top;
      worst = math.max(worst, (top - alignedTop(alignment)).abs());
    }
    expect(worst, lessThan(0.5));
  });

  testWidgets('alignment 0.3 puts the leading edge at 30%', (tester) async {
    await pump(tester);
    controller.jumpTo(index: 777, alignment: 0.3);
    await tester.pump();
    expect(rectOf(tester, 777)!.top, closeTo(0.3 * phoneSize.height, 0.5));
  });

  testWidgets('jump to a built item is exact', (tester) async {
    await pump(tester);
    controller.jumpTo(index: 4, alignment: 0.1);
    await tester.pump();
    expect(rectOf(tester, 4)!.top, closeTo(alignedTop(0.1), 0.5));
  });

  testWidgets('a target too close to the start stays at its natural place',
      (tester) async {
    await pump(tester);
    controller.jumpTo(index: 50000);
    await tester.pump();
    controller.jumpTo(index: 2, alignment: 0.9);
    await tester.pump();
    await tester.pump();
    expect(rectOf(tester, 0)!.top, closeTo(0, 0.5));
    expect(rectOf(tester, 2)!.top, closeTo(extentFor(0) + extentFor(1), 0.5));
  });

  testWidgets('jump to the last item ends the list at the bottom',
      (tester) async {
    await pump(tester);
    controller.jumpTo(index: 99999);
    await tester.pump();
    expect(rectOf(tester, 99999)!.bottom, closeTo(phoneSize.height, 0.5));
    await tester.pumpAndSettle();
    expect(rectOf(tester, 99999)!.bottom, closeTo(phoneSize.height, 0.5));
  });

  testWidgets('jump back to the top after far jumps puts item 0 at 0',
      (tester) async {
    await pump(tester);
    controller.jumpTo(index: 60000);
    await tester.pump();
    controller.jumpTo(index: 3);
    await tester.pump();
    controller.jumpTo(index: 0);
    await tester.pump();
    await tester.pump();
    expect(rectOf(tester, 0)!.top, closeTo(0, 0.5));
    expect(controller.scrollController.offset, closeTo(0, 0.5));
  });

  testWidgets('scrolling up from a far jump reaches item 0 at offset 0',
      (tester) async {
    await pump(tester, count: 400);
    controller.jumpTo(index: 300);
    await tester.pump();
    for (var i = 0; i < 400 && rectOf(tester, 0) == null; i++) {
      controller.scrollController
          .jumpTo(controller.scrollController.offset - 400);
      await tester.pump();
    }
    controller.scrollController.jumpTo(0);
    await tester.pump();
    await tester.pump();
    expect(rectOf(tester, 0)!.top, closeTo(0, 0.5));
  });

  testWidgets('index -1 fails an assertion in debug', (tester) async {
    await pump(tester);
    expect(() => controller.jumpTo(index: -1), throwsAssertionError);
    expect(() => controller.jumpTo(index: 100000), throwsAssertionError);
  });

  testWidgets('jump before attach is applied on the first layout',
      (tester) async {
    controller.jumpTo(index: 4000, alignment: 0.5);
    await pump(tester);
    expect(rectOf(tester, 4000)!.top, closeTo(alignedTop(0.5), 0.5));
    expect(() => AtlasController().jumpTo(index: -1), throwsAssertionError);
  });

  testWidgets('IndexJumper methods delegate', (tester) async {
    await pump(tester);
    controller.jumpToIndex(1234, alignment: 0.5);
    await tester.pump();
    expect(rectOf(tester, 1234)!.top, closeTo(alignedTop(0.5), 0.5));
    final done = controller.animateToIndex(1240,
        duration: const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await done;
    expect(rectOf(tester, 1240)!.top, closeTo(0, 0.5));
  });
}
