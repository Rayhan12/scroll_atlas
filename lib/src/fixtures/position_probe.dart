import 'package:flutter/rendering.dart';

import '../core/alignment_math.dart';

/// Measures where an item sits in a viewport. Shared by the test helpers
/// and the benchmark, so both report the same numbers.
abstract final class PositionProbe {
  /// Distance from the viewport's top edge to the item's top edge.
  static double leadingEdgeInViewport(RenderBox item, RenderBox viewport) =>
      item.localToGlobal(Offset.zero, ancestor: viewport).dy;

  /// Absolute distance between where the item is and where [alignment]
  /// says it should be.
  static double alignmentError({
    required RenderBox item,
    required RenderBox viewport,
    required double alignment,
    double leadingObstruction = 0,
  }) =>
      (leadingEdgeInViewport(item, viewport) -
              AlignmentMath.leadingEdgeInViewport(
                alignment: alignment,
                viewportExtent: viewport.size.height,
                leadingObstruction: leadingObstruction,
              ))
          .abs();
}
