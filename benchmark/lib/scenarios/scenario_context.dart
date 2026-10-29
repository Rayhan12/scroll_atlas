import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/fixtures.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../measure/alignment_convention.dart';
import '../measure/item_probe.dart';

/// Everything a scenario needs, built once per engine run.
final class ScenarioContext {
  ScenarioContext({
    required this.tester,
    required this.engine,
    required this.extents,
  }) : probe = ItemProbe(
         GlobalKey(debugLabel: 'bench-host'),
         convention: AlignmentConvention.of(engine),
       );

  final WidgetTester tester;
  final ListEngine engine;
  final List<double> extents;
  final BuildCounter counter = BuildCounter();
  final ItemProbe probe;
  final PageStorageBucket _bucket = PageStorageBucket();

  /// Length of one frame when pumping.
  static const Duration frame = Duration(milliseconds: 16);

  /// Pumps the engine's list of [extents] fixture items.
  ///
  /// With [insertedAtTop] above 0, that many extra items with ids -1, -2, and
  /// so on sit before item 0, newest first. Item ids stay stable, and the
  /// list gets a `findChildIndexCallback`, so engines that support it keep
  /// built items when items are inserted (B6).
  Future<void> mount({int insertedAtTop = 0}) => tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: PageStorage(
        bucket: _bucket,
        child: KeyedSubtree(
          key: probe.hostKey,
          child: engine.buildList(
            itemCount: extents.length + insertedAtTop,
            itemBuilder: counter.wrap((context, index) {
              final id = index - insertedAtTop;
              return FixtureItem(index: id, extent: extentOf(id));
            }),
            findChildIndexCallback: (key) {
              final id = FixtureKeys.idOf(key);
              final index = id == null ? null : id + insertedAtTop;
              return index == null || index < 0 ? null : index;
            },
          ),
        ),
      ),
    ),
  );

  /// Extent of the item with [id]; inserted items (negative ids) reuse the
  /// seeded extents from the start of the list.
  double extentOf(int id) => extents[id < 0 ? (-id) % extents.length : id];

  Future<void> nextFrame() => tester.pump(frame);

  /// Pumps frames until [index] sits at [alignment] within [tolerance] for
  /// two frames in a row, or until [maxFrames].
  Future<SettleResult> pumpUntilSettled(
    int index,
    double alignment, {
    double tolerance = 0.5,
    int maxFrames = 60,
  }) async {
    double? firstFrameError;
    int? settledAt;
    for (var frame = 1; frame <= maxFrames; frame++) {
      await nextFrame();
      final error = probe.alignmentError(index, alignment);
      firstFrameError ??= error;
      final ok = error <= tolerance;
      if (ok && settledAt != null) break;
      settledAt = ok ? frame : null;
    }
    return SettleResult(
      firstFrameError: firstFrameError!,
      settledAtFrame: settledAt,
    );
  }
}

/// Outcome of [ScenarioContext.pumpUntilSettled].
final class SettleResult {
  const SettleResult({
    required this.firstFrameError,
    required this.settledAtFrame,
  });

  /// Alignment error after the first frame; infinity if the item was not
  /// built yet. This is what the user sees right after the jump.
  final double firstFrameError;

  /// First frame (1 based) of a stable aligned run, or null if never.
  final int? settledAtFrame;
}
