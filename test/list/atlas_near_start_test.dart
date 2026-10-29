import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

/// Regression: a target near the start, where the items above it are much
/// taller or shorter than estimated, must still land at its alignment (or
/// as close as the start allows) on the first frame.
void main() {
  const itemCount = 2000;
  const viewport = 600.0;
  final patterns = <String, double Function(int)>{
    'mixed': (i) => 60.0 + (i % 5) * 30,
    'wild': (i) => 20.0 + (i * 37 % 300),
    'tall top': (i) => i < 10 ? 400.0 : 40.0,
    'tiny': (i) => 12.0,
  };
  final indexes = [for (var i = 0; i < 25; i++) i, 40, 300, 1990, 1999];

  for (final pattern in patterns.entries) {
    final extentOf = pattern.value;
    final offsets = <double>[0];
    for (var i = 0; i < itemCount; i++) {
      offsets.add(offsets.last + extentOf(i));
    }
    final maxScroll = math.max(0.0, offsets.last - viewport);

    double expected(int index, double alignment) {
      final scroll =
          (offsets[index] - alignment * viewport).clamp(0.0, maxScroll);
      return offsets[index] - scroll;
    }

    Future<double?> leadingEdgeOf(
      WidgetTester tester,
      int index, {
      required bool reverse,
    }) async {
      final finder = find.byKey(ValueKey(index));
      if (finder.evaluate().isEmpty) return null;
      return reverse
          ? viewport - tester.getBottomLeft(finder).dy
          : tester.getTopLeft(finder).dy;
    }

    Widget list({
      required AtlasController controller,
      required bool reverse,
      int initialIndex = 0,
      double initialAlignment = 0,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: viewport,
            child: AtlasListView.builder(
              controller: controller,
              reverse: reverse,
              itemCount: itemCount,
              initialIndex: initialIndex,
              initialAlignment: initialAlignment,
              itemBuilder: (context, i) =>
                  SizedBox(key: ValueKey(i), height: extentOf(i)),
            ),
          ),
        ),
      );
    }

    for (final reverse in [false, true]) {
      testWidgets(
          'initialIndex near the start lands in the first frame '
          '(${pattern.key}, reverse: $reverse)', (tester) async {
        for (final alignment in [0.0, 0.5, 0.7]) {
          for (final index in indexes) {
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(
              list(
                controller: AtlasController(),
                reverse: reverse,
                initialIndex: index,
                initialAlignment: alignment,
              ),
            );
            final edge = await leadingEdgeOf(tester, index, reverse: reverse);
            expect(edge, isNotNull, reason: 'index $index at $alignment');
            expect(
              edge,
              closeTo(expected(index, alignment), 0.5),
              reason: 'index $index at $alignment',
            );
          }
        }
      });

      testWidgets(
          'jumpTo near the start lands at its alignment '
          '(${pattern.key}, reverse: $reverse)', (tester) async {
        for (final alignment in [0.0, 0.5, 0.7]) {
          for (final index in indexes) {
            final controller = AtlasController();
            await tester.pumpWidget(const SizedBox());
            await tester.pumpWidget(
              list(controller: controller, reverse: reverse),
            );
            controller.jumpTo(index: index, alignment: alignment);
            await tester.pump();
            final edge = await leadingEdgeOf(tester, index, reverse: reverse);
            expect(edge, isNotNull, reason: 'index $index at $alignment');
            expect(
              edge,
              closeTo(expected(index, alignment), 0.5),
              reason: 'index $index at $alignment',
            );
          }
        }
      });
    }
  }
}
