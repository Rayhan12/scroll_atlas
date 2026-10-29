import 'package:flutter/widgets.dart';

/// Builds a scrollable list of [itemCount] items.
///
/// Implemented by every engine, including plain `ListView` in the
/// benchmark, which cannot jump to an index.
abstract interface class ListEngine {
  /// Stable identifier used in benchmark results, for example `plain_listview`.
  String get id;

  /// Builds the scrollable list.
  ///
  /// [findChildIndexCallback] maps an item key to its current index, so an
  /// engine can keep the state and position of keyed items when items are
  /// inserted or removed. Engines whose package has no such hook ignore it.
  Widget buildList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
  });

  /// Releases controllers.
  void dispose();
}

/// Moves a list so that an item lands at an alignment of the viewport.
///
/// App code depends on this small interface only (interface segregation),
/// not on how a particular engine lays items out.
abstract interface class IndexJumper {
  /// Moves immediately so that item [index] has its leading edge at
  /// [alignment] of the viewport.
  void jumpToIndex(int index, {double alignment = 0});

  /// Animates to item [index] over [duration].
  Future<void> animateToIndex(
    int index, {
    required Duration duration,
    Curve curve = Curves.easeInOut,
    double alignment = 0,
  });
}

/// A list engine that can also jump to an index.
///
/// Benchmarks decide which implementation backs the public widgets.
/// Everything above this interface (widgets, scope registry, benchmark)
/// stays the same whichever option Rayhanul Islam picks.
abstract interface class IndexedScrollEngine
    implements ListEngine, IndexJumper {}
