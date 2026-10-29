import 'package:flutter/foundation.dart';

/// The visible part of a list in fractional item indexes: [first] is the
/// index at the viewport's leading edge plus how far into that item the edge
/// is, and [end] the same for the trailing edge.
@immutable
final class IndexSpan {
  /// Creates a span. [end] must not be smaller than [first].
  const IndexSpan(this.first, this.end)
      : assert(first >= 0, 'first must not be negative'),
        assert(end >= first, 'end must not be before first');

  /// Fractional index at the leading edge.
  final double first;

  /// Fractional index at the trailing edge.
  final double end;

  /// Number of items that fit in the viewport, fractionally.
  double get length => end - first;

  @override
  bool operator ==(Object other) =>
      other is IndexSpan && other.first == first && other.end == end;

  @override
  int get hashCode => Object.hash(first, end);

  @override
  String toString() => 'IndexSpan($first, $end)';
}

/// Scroll position as a fraction of items rather than pixels.
///
/// Pixel offsets of unmeasured items are estimates and move when items get
/// measured, so a pixel-based scrollbar thumb jumps. Item counts never
/// change while scrolling, so this fraction moves forward whenever the
/// list moves forward.
abstract final class IndexFraction {
  /// 0 at the start, 1 at the end: items before the viewport divided by
  /// items outside it. Grows strictly while scrolling forward.
  static double of(IndexSpan span, int itemCount) {
    final before = span.first;
    final after = (itemCount - span.end).clamp(0.0, double.infinity);
    final outside = before + after;
    if (outside <= 0) return 0;
    return (before / outside).clamp(0.0, 1.0);
  }

  /// Fractional index to put at the leading edge so that [of] returns
  /// [fraction], assuming the viewport keeps showing [visibleItems] items.
  static double leadingIndexFor(
    double fraction, {
    required int itemCount,
    required double visibleItems,
  }) {
    final room = (itemCount - visibleItems).clamp(0.0, double.infinity);
    return fraction.clamp(0.0, 1.0) * room;
  }
}
