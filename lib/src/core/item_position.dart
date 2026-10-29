import 'package:flutter/foundation.dart';

/// Where a visible item of an Atlas list is.
///
/// Same meaning as scrollable_positioned_list's `ItemPosition`:
/// [itemLeadingEdge] and [itemTrailingEdge] are fractions of the
/// unobstructed viewport, the part below whatever is pinned above the
/// list. 0 is its leading edge and 1 its trailing edge, so an item that is
/// partly covered has a negative leading edge.
///
/// ```dart
/// ValueListenableBuilder<List<AtlasItemPosition>>(
///   valueListenable: atlas.positions,
///   builder: (context, visible, _) => Text(
///     visible.isEmpty ? '' : 'Showing ${visible.first.index} to ${visible.last.index}',
///   ),
/// );
/// ```
@immutable
final class AtlasItemPosition {
  /// Creates a position.
  const AtlasItemPosition({
    required this.index,
    required this.itemLeadingEdge,
    required this.itemTrailingEdge,
    this.sliverId,
  });

  /// Id of the list that holds the item, or null for an unnamed list.
  final String? sliverId;

  /// Index of the item in its list.
  final int index;

  /// Leading edge as a fraction of the unobstructed viewport.
  final double itemLeadingEdge;

  /// Trailing edge as a fraction of the unobstructed viewport.
  final double itemTrailingEdge;

  /// Whether the whole item is in the unobstructed viewport.
  bool get isFullyVisible => itemLeadingEdge >= 0 && itemTrailingEdge <= 1;

  /// Fraction of the unobstructed viewport the item covers.
  double get visibleFraction =>
      (itemTrailingEdge.clamp(0.0, 1.0) - itemLeadingEdge.clamp(0.0, 1.0))
          .toDouble();

  @override
  bool operator ==(Object other) =>
      other is AtlasItemPosition &&
      other.sliverId == sliverId &&
      other.index == index &&
      other.itemLeadingEdge == itemLeadingEdge &&
      other.itemTrailingEdge == itemTrailingEdge;

  @override
  int get hashCode =>
      Object.hash(sliverId, index, itemLeadingEdge, itemTrailingEdge);

  @override
  String toString() => 'AtlasItemPosition(${sliverId ?? ''}#$index, '
      '$itemLeadingEdge, $itemTrailingEdge)';
}

/// Builds [AtlasItemPosition]s from pixel offsets.
abstract final class PositionMath {
  /// The position of an item from [leading] to [trailing] pixels from the
  /// viewport's leading edge, when [obstruction] pixels at the top are
  /// covered, or null when no pixel of it is in the unobstructed viewport.
  static AtlasItemPosition? visible({
    required int index,
    required double leading,
    required double trailing,
    required double obstruction,
    required double viewportExtent,
    String? sliverId,
  }) {
    final top = obstruction.clamp(0.0, viewportExtent).toDouble();
    if (trailing <= top || leading >= viewportExtent) return null;
    final room = viewportExtent - top;
    if (room <= 0) return null;
    return AtlasItemPosition(
      sliverId: sliverId,
      index: index,
      itemLeadingEdge: (leading - top) / room,
      itemTrailingEdge: (trailing - top) / room,
    );
  }
}

/// Helpers for common questions about visible items.
extension AtlasItemPositions on Iterable<AtlasItemPosition> {
  /// Positions of the list with [sliverId] (null: the unnamed list).
  Iterable<AtlasItemPosition> inSliver(String? sliverId) =>
      where((p) => p.sliverId == sliverId);

  /// The fully visible item nearest the leading edge, or null.
  AtlasItemPosition? get firstFullyVisible {
    AtlasItemPosition? best;
    for (final p in this) {
      if (!p.isFullyVisible) continue;
      if (best == null || p.itemLeadingEdge < best.itemLeadingEdge) best = p;
    }
    return best;
  }

  /// The item covering the most of the unobstructed viewport; on a tie,
  /// the one nearer the leading edge. Null when nothing is visible.
  AtlasItemPosition? get mostVisible {
    AtlasItemPosition? best;
    for (final p in this) {
      if (best == null ||
          p.visibleFraction > best.visibleFraction ||
          (p.visibleFraction == best.visibleFraction &&
              p.itemLeadingEdge < best.itemLeadingEdge)) {
        best = p;
      }
    }
    return best;
  }
}

/// Picks the active section for a scroll spy.
abstract final class ScrollSpyMath {
  /// Distance within which a header counts as having reached the pinned
  /// area.
  static const double tolerance = 0.5;

  /// Index of the active section: the last one whose leading edge
  /// ([sectionTops], pixels from the viewport's leading edge, null when
  /// unknown) has reached the bottom of what is pinned above it
  /// ([pinnedBottoms]). At the end of the scroll ([atEnd]) the last known
  /// section is active, even if it is short. 0 when none has reached it.
  static int activeIndex({
    required List<double?> sectionTops,
    required List<double> pinnedBottoms,
    required bool atEnd,
  }) {
    assert(
      sectionTops.length == pinnedBottoms.length,
      'one pinned bottom per section',
    );
    var active = 0;
    for (var i = 0; i < sectionTops.length; i++) {
      final top = sectionTops[i];
      if (top == null) continue;
      if (atEnd || top <= pinnedBottoms[i] + tolerance) active = i;
    }
    return active;
  }
}
