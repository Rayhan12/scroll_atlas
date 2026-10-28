import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:scroll_atlas/experimental.dart';
import 'package:scroll_atlas/fixtures.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

/// State and scroll actions for the D1 Jump lab demo.
final class JumpLabController {
  JumpLabController({Random? random})
      : _random = random ?? Random(),
        engine = PrototypeScrollEngine(),
        extents = SeededExtents(seed: 42, length: itemCount),
        buildCounter = BuildCounter();

  static const int itemCount = 100000;

  final Random _random;
  final IndexedScrollEngine engine;
  final SeededExtents extents;
  final BuildCounter buildCounter;

  double alignment = 0.5;
  int targetIndex = 0;
  int lastJumpBuilds = 0;

  final TextEditingController indexController =
      TextEditingController(text: '0');

  void dispose() {
    indexController.dispose();
    engine.dispose();
  }

  int parseIndex() {
    final parsed = int.tryParse(indexController.text.trim());
    if (parsed == null) {
      return targetIndex.clamp(0, itemCount - 1);
    }
    return parsed.clamp(0, itemCount - 1);
  }

  void syncIndexFromField() {
    targetIndex = parseIndex();
    indexController.text = '$targetIndex';
  }

  void pickRandomIndex() {
    targetIndex = _random.nextInt(itemCount);
    indexController.text = '$targetIndex';
  }

  /// Jumps, then records how many items the next frame built. Items build
  /// during layout, so the count is only known once that frame ends.
  Future<void> jump() async {
    syncIndexFromField();
    buildCounter.reset();
    engine.jumpToIndex(targetIndex, alignment: alignment);
    await WidgetsBinding.instance.endOfFrame;
    lastJumpBuilds = buildCounter.builds;
  }

  Future<void> animate(
      {Duration duration = const Duration(milliseconds: 600)}) {
    syncIndexFromField();
    buildCounter.reset();
    final future = engine.animateToIndex(
      targetIndex,
      duration: duration,
      alignment: alignment,
    );
    return future.whenComplete(() {
      lastJumpBuilds = buildCounter.builds;
    });
  }

  Widget buildList() {
    return engine.buildList(
      itemCount: itemCount,
      itemBuilder: buildCounter.wrap(
        (BuildContext context, int index) =>
            FixtureItem(index: index, extent: extents[index]),
      ),
    );
  }
}
