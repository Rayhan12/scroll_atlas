import 'dart:math' as math;

/// Turns "put this leading edge at the alignment line" into a scroll
/// offset correction. Offsets are in a sliver's own scroll
/// coordinates; [virtualOffset] is the scroll offset at the sliver's
/// leading edge, negative while the sliver starts below the viewport's
/// leading edge.
abstract final class PlacementMath {
  /// Corrections at or below this many pixels are ignored.
  static const double tolerance = 0.01;

  /// The scroll offset correction that moves [leading] to [aligned] pixels
  /// from the viewport's leading edge, without scrolling before the start
  /// of the scroll view ([minVirtualOffset]). Null when no move is needed.
  static double? correction({
    required double leading,
    required double aligned,
    required double virtualOffset,
    required double minVirtualOffset,
  }) {
    final desired = math.max(minVirtualOffset, leading - aligned);
    final correction = desired - virtualOffset;
    return correction.abs() <= tolerance ? null : correction;
  }
}
