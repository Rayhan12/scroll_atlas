import 'package:flutter/foundation.dart';

/// Where a jump should land: an item [index] whose leading edge is placed
/// at [alignment] of the viewport (0 is the leading edge, 0.5 the middle).
/// Same meaning as scrollable_positioned_list, which keeps the migration
/// path simple.
///
/// With [respectPinned] the alignment is measured inside the area
/// below everything pinned at the final position (pinned app bars and the
/// stuck header of the target's section). [padding] adds a gap below that.
@immutable
final class ScrollTarget {
  /// Creates a target. [index] must not be negative.
  ScrollTarget(
    this.index, {
    this.alignment = 0,
    this.respectPinned = true,
    this.padding = 0,
  })  : assert(alignment.isFinite, 'alignment must be finite'),
        assert(padding.isFinite, 'padding must be finite') {
    RangeError.checkNotNegative(index, 'index');
  }

  /// Item index inside the list (0 for the leading edge of a sliver).
  final int index;

  /// Fraction of the viewport where the item's leading edge lands.
  final double alignment;

  /// Whether pinned headers are subtracted before aligning.
  final bool respectPinned;

  /// Extra gap in pixels between the obstruction and the alignment area.
  final double padding;

  /// A copy with another [index].
  ScrollTarget withIndex(int index) => ScrollTarget(
        index,
        alignment: alignment,
        respectPinned: respectPinned,
        padding: padding,
      );

  @override
  bool operator ==(Object other) =>
      other is ScrollTarget &&
      other.index == index &&
      other.alignment == alignment &&
      other.respectPinned == respectPinned &&
      other.padding == padding;

  @override
  int get hashCode => Object.hash(index, alignment, respectPinned, padding);

  @override
  String toString() => 'ScrollTarget($index, alignment: $alignment, '
      'respectPinned: $respectPinned, padding: $padding)';
}
