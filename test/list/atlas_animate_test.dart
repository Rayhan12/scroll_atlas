import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'list_harness.dart';

void main() {
  late AtlasController controller;

  setUp(() => controller = AtlasController());
  tearDown(() => controller.dispose());

  Future<void> pump(WidgetTester tester, {int count = 100000}) async {
    usePhone(tester);
    await tester.pumpWidget(host(AtlasListView.builder(
      controller: controller,
      itemCount: count,
      itemBuilder: (context, index) => item(index),
    )));
  }

  /// Pumps 16 ms frames until [done] completes; returns the scroll offset
  /// after every frame.
  Future<List<double>> frames(WidgetTester tester, Future<void> done) async {
    var finished = false;
    unawaited(done.whenComplete(() => finished = true));
    final offsets = <double>[];
    for (var i = 0; i < 400 && !finished; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      offsets.add(controller.scrollController.offset);
    }
    await tester.pump();
    return offsets;
  }

  double lastMove(List<double> offsets) {
    for (var i = offsets.length - 1; i > 0; i--) {
      final move = (offsets[i] - offsets[i - 1]).abs();
      if (move > 0) return move;
    }
    return 0;
  }

  for (final mode in AtlasLongDistance.values) {
    testWidgets('${mode.name}: 80k items in 600 ms, no final snap',
        (tester) async {
      await pump(tester);
      controller.jumpTo(index: 1000);
      await tester.pump();
      final offsets = await frames(
        tester,
        controller.animateTo(
          index: 81000,
          alignment: 0.5,
          duration: const Duration(milliseconds: 600),
          longDistance: mode,
        ),
      );
      expect(rectOf(tester, 81000)!.top, closeTo(alignedTop(0.5), 0.5));
      expect(lastMove(offsets), lessThan(2));
      expect(offsets.length, lessThan(45));
      for (var i = 1; i < offsets.length; i++) {
        expect(offsets[i], greaterThanOrEqualTo(offsets[i - 1] - 0.01));
      }
    });
  }

  testWidgets('short animation backwards lands exactly', (tester) async {
    await pump(tester);
    controller.jumpTo(index: 500);
    await tester.pump();
    final offsets = await frames(
      tester,
      controller.animateTo(
          index: 497, duration: const Duration(milliseconds: 300)),
    );
    expect(rectOf(tester, 497)!.top, closeTo(0, 0.5));
    expect(lastMove(offsets), lessThan(2));
    // Monotonic: never overshoots.
    for (var i = 1; i < offsets.length; i++) {
      expect(offsets[i], lessThanOrEqualTo(offsets[i - 1] + 0.01));
    }
  });

  testWidgets('animating to where the list already is is a no-op',
      (tester) async {
    await pump(tester);
    controller.jumpTo(index: 300);
    await tester.pump();
    final before = controller.scrollController.offset;
    await frames(tester,
        controller.animateTo(index: 300, duration: const Duration(seconds: 1)));
    expect(controller.scrollController.offset, closeTo(before, 0.01));
  });

  testWidgets('a drag cancels the animation', (tester) async {
    await pump(tester);
    var completed = false;
    unawaited(controller
        .animateTo(index: 90000, duration: const Duration(seconds: 2))
        .whenComplete(() => completed = true));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(completed, isFalse);
    final gesture = await tester.startGesture(const Offset(200, 400));
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump(const Duration(milliseconds: 16));
    expect(completed, isTrue);
    final heldAt = controller.scrollController.offset;
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump(const Duration(milliseconds: 16));
    expect(controller.scrollController.offset, closeTo(heldAt + 40, 1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(rectOf(tester, 90000), isNull);
  });

  testWidgets('a jump during an animation wins', (tester) async {
    await pump(tester);
    final done = controller.animateTo(
        index: 90000, duration: const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 100));
    controller.jumpTo(index: 42);
    await tester.pump();
    await done;
    await tester.pumpAndSettle();
    expect(rectOf(tester, 42)!.top, closeTo(0, 0.5));
  });

  testWidgets('animateTo before attach jumps on first layout', (tester) async {
    final done =
        controller.animateTo(index: 700, duration: const Duration(seconds: 1));
    await done;
    await pump(tester);
    expect(rectOf(tester, 700)!.top, closeTo(0, 0.5));
  });

  testWidgets('works with a ScrollPosition that is not an activity delegate',
      (tester) async {
    final custom = AtlasController(scrollController: _PlainController());
    usePhone(tester);
    await tester.pumpWidget(host(AtlasListView.builder(
      controller: custom,
      itemCount: 1000,
      itemBuilder: (context, index) => item(index),
    )));
    final done = custom.animateTo(
        index: 20, duration: const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await done;
    expect(custom.scrollController.offset, greaterThan(0));
    custom.dispose();
    custom.scrollController.dispose();
  });
}

class _PlainController extends ScrollController {
  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) =>
      _PlainPosition(
          physics: physics, context: context, oldPosition: oldPosition);
}

/// A position that does not implement ScrollActivityDelegate itself.
class _PlainPosition extends ScrollPosition {
  _PlainPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
  }) {
    if (!hasPixels) correctPixels(0);
    beginActivity(IdleScrollActivity(_IdleDelegate(this)));
  }

  @override
  AxisDirection get axisDirection => context.axisDirection;

  @override
  ScrollDirection get userScrollDirection => ScrollDirection.idle;

  @override
  Future<void> animateTo(
    double to, {
    required Duration duration,
    required Curve curve,
  }) async =>
      jumpTo(to);

  @override
  void jumpTo(double value) => forcePixels(value);

  @override
  void jumpToWithoutSettling(double value) => jumpTo(value);

  @override
  void pointerScroll(double delta) => jumpTo(pixels + delta);

  @override
  ScrollHoldController hold(VoidCallback holdCancelCallback) =>
      throw UnimplementedError();

  @override
  Drag drag(DragStartDetails details, VoidCallback dragCancelCallback) =>
      throw UnimplementedError();
}

class _IdleDelegate implements ScrollActivityDelegate {
  _IdleDelegate(this.position);

  final _PlainPosition position;

  @override
  AxisDirection get axisDirection => position.axisDirection;

  @override
  double setPixels(double pixels) => 0;

  @override
  void applyUserOffset(double delta) {}

  @override
  void goIdle() {}

  @override
  void goBallistic(double velocity) {}
}
