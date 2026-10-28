/// The single place that turns an alignment into pixels. The engine, the
/// test helpers and the benchmark all call these functions, so the meaning
/// of "alignment" cannot drift between them.
abstract final class AlignmentMath {
  /// Distance from the viewport's leading edge to where an item's leading
  /// edge should sit. [leadingObstruction] is the extent covered by pinned
  /// headers; the item is aligned inside the unobstructed area.
  static double leadingEdgeInViewport({
    required double alignment,
    required double viewportExtent,
    double leadingObstruction = 0,
  }) =>
      leadingObstruction + alignment * (viewportExtent - leadingObstruction);

  /// Scroll offset that puts an item whose leading edge is at
  /// [itemLeadingOffset] at [alignment] of the viewport.
  static double scrollOffsetFor({
    required double itemLeadingOffset,
    required double alignment,
    required double viewportExtent,
    double leadingObstruction = 0,
  }) =>
      itemLeadingOffset -
      leadingEdgeInViewport(
        alignment: alignment,
        viewportExtent: viewportExtent,
        leadingObstruction: leadingObstruction,
      );
}
