import 'package:flutter/foundation.dart';

/// Where an index jump should land: an item [index] whose leading edge is
/// placed at [alignment] of the viewport (0 is the leading edge, 0.5 the
/// middle). Same meaning as scrollable_positioned_list, which keeps the
/// migration path (SA-6xx) simple.
@immutable
final class ScrollTarget {
  /// Creates a target. [index] must not be negative.
  ScrollTarget(this.index, {this.alignment = 0})
      : assert(alignment.isFinite, 'alignment must be finite') {
    RangeError.checkNotNegative(index, 'index');
  }

  /// Item index inside the list.
  final int index;

  /// Fraction of the viewport where the item's leading edge lands.
  final double alignment;

  @override
  bool operator ==(Object other) =>
      other is ScrollTarget &&
      other.index == index &&
      other.alignment == alignment;

  @override
  int get hashCode => Object.hash(index, alignment);

  @override
  String toString() => 'ScrollTarget($index, alignment: $alignment)';
}
