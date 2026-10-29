import 'package:flutter/rendering.dart';

import '../core/alignment_math.dart';
import '../core/placement_math.dart';
import '../core/scroll_target.dart';

/// A render sliver that pins part of itself above one of its child slivers,
/// such as a section with a sticky header. Lets descendants estimate what
/// will cover them before they have been scrolled under it.
abstract interface class AtlasStickyParent {
  /// Extent that this sliver pins above [child] while [child] is scrolled.
  double stickyExtentAbove(RenderObject child);
}

/// Placement helpers shared by every Atlas target sliver:
/// virtual scroll offset, pinned obstruction, and the correction that
/// puts a leading edge at its alignment line.
mixin AtlasPlacement on RenderSliver {
  double? _learnedObstruction;
  double? _placementViewportExtent;
  double _placementPrecedingExtent = 0;

  /// Call first in `performLayout`: records the viewport, the preceding
  /// extent and, while this sliver is scrolled, what covers it.
  void beginPlacementLayout() {
    _placementViewportExtent = constraints.viewportMainAxisExtent;
    _placementPrecedingExtent = constraints.precedingScrollExtent;
    if (constraints.scrollOffset > PlacementMath.tolerance) {
      _learnedObstruction = _nonNegative(constraints.overlap);
    }
  }

  /// Viewport extent of the last layout.
  double? get placementViewportExtent => _placementViewportExtent;

  /// Scroll extent of the slivers before this one in the last layout.
  double get placementPrecedingExtent => _placementPrecedingExtent;

  /// What covers this sliver's leading edge while it is scrolled: measured
  /// once it has been scrolled, estimated from pinned ancestors and
  /// preceding pinned headers before that.
  double get pinnedObstruction =>
      _learnedObstruction ?? AtlasObstruction.hint(this);

  /// Obstruction to use while placing a target in the current layout.
  double get placementObstruction =>
      constraints.scrollOffset > PlacementMath.tolerance
          ? _nonNegative(constraints.overlap)
          : pinnedObstruction;

  /// Distance from the viewport's leading edge to [target]'s alignment
  /// line in the current layout.
  double alignedOffset(ScrollTarget target) =>
      AlignmentMath.leadingEdgeInViewport(
        alignment: target.alignment,
        viewportExtent: constraints.viewportMainAxisExtent,
        leadingObstruction:
            (target.respectPinned ? placementObstruction : 0) + target.padding,
      );

  /// The scroll offset at this sliver's leading edge: like
  /// `constraints.scrollOffset`, but negative while the sliver starts below
  /// the viewport's leading edge.
  ///
  /// Uses the constraints where they are exact: wrappers such as
  /// flutter_sticky_header lay their sliver out after a header without
  /// adding it to `precedingScrollExtent`.
  double get virtualScrollOffset {
    if (constraints.scrollOffset > PlacementMath.tolerance) {
      return constraints.scrollOffset;
    }
    final below =
        constraints.viewportMainAxisExtent - constraints.remainingPaintExtent;
    if (constraints.growthDirection == GrowthDirection.forward &&
        constraints.remainingPaintExtent > PlacementMath.tolerance) {
      return -below;
    }
    final viewport = RenderAbstractViewport.maybeOf(this);
    if (viewport is RenderViewportBase &&
        viewport.offset.hasPixels &&
        constraints.growthDirection == GrowthDirection.forward) {
      return viewport.offset.pixels - constraints.precedingScrollExtent;
    }
    return constraints.scrollOffset;
  }

  /// Lowest [virtualScrollOffset]: the scroll view's start.
  double get minVirtualScrollOffset => -constraints.precedingScrollExtent;

  /// Scroll offset correction that puts [leading] (in this sliver's scroll
  /// coordinates) at [target]'s alignment line, or null when it is there.
  double? placementCorrection(double leading, ScrollTarget target) =>
      PlacementMath.correction(
        leading: leading,
        aligned: alignedOffset(target),
        virtualOffset: virtualScrollOffset,
        minVirtualOffset: minVirtualScrollOffset,
      );

  static double _nonNegative(double value) => value < 0 ? 0 : value;
}

/// Sliver tree queries used for placement.
abstract final class AtlasObstruction {
  /// Estimates what will cover [sliver]'s leading edge once it is scrolled:
  /// the sticky extents of enclosing [AtlasStickyParent]s plus the minimum
  /// extent of every pinned header before it in the viewport.
  static double hint(RenderSliver sliver) {
    var hint = 0.0;
    RenderObject child = sliver;
    var parent = sliver.parent;
    while (parent != null && parent is! RenderAbstractViewport) {
      if (parent is AtlasStickyParent) {
        hint += (parent as AtlasStickyParent).stickyExtentAbove(child);
      }
      child = parent;
      parent = parent.parent;
    }
    if (parent is RenderViewportBase && child is RenderSliver) {
      for (var before = parent.childBefore(child);
          before != null;
          before = parent.childBefore(before)) {
        if (before is RenderSliverPinnedPersistentHeader ||
            before is RenderSliverFloatingPinnedPersistentHeader) {
          hint += (before as RenderSliverPersistentHeader).minExtent;
        }
      }
    }
    return hint;
  }

  /// Whether nothing follows [sliver] in its scroll view, so it may pull
  /// the scroll offset back to close a gap after its end.
  static bool isLast(RenderObject sliver) {
    RenderObject? current = sliver;
    while (current != null) {
      final data = current.parentData;
      if (data is ContainerParentDataMixin<RenderSliver> &&
          data.nextSibling != null) {
        return false;
      }
      final parent = current.parent;
      if (parent == null || parent is RenderAbstractViewport) return true;
      current = parent;
    }
    return true;
  }
}
