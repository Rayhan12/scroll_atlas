import 'dart:math' as math;

/// Geometry of a sticky section header, in the section's paint
/// coordinates: 0 is where the section starts painting.
abstract final class StickyHeaderMath {
  /// Where the header paints: at its natural place, or stuck below what is
  /// pinned above the section ([overlap]), and pushed up by the end of the
  /// section so it never overlaps the next header.
  static double headerPaintOffset({
    required double scrollOffset,
    required double overlap,
    required double headerExtent,
    required double sectionExtent,
  }) =>
      math.min(
        math.max(-scrollOffset, overlap),
        sectionExtent - scrollOffset - headerExtent,
      );

  /// How far the header has left its natural place, from 0 (scrolls with
  /// the content) to 1 (stuck by at least its own extent).
  static double stuckAmount({
    required double headerPaintOffset,
    required double scrollOffset,
    required double headerExtent,
  }) {
    if (headerExtent <= 0) return 0;
    final moved = headerPaintOffset + scrollOffset;
    return (moved / headerExtent).clamp(0.0, 1.0);
  }

  /// How much of the section body's leading edge is covered by the stuck
  /// header or by what is pinned above the section. [bodyPaintOffset] is
  /// where the body starts painting inside the section.
  static double bodyOverlap({
    required double scrollOffset,
    required double overlap,
    required double headerExtent,
    required double bodyPaintOffset,
  }) {
    final stuck = math.max(-scrollOffset, overlap);
    return math.max(
      0,
      math.max(overlap, stuck + headerExtent) - bodyPaintOffset,
    );
  }
}
