import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../core/extent_cache.dart';
import '../core/index_fraction.dart';
import '../core/item_position.dart';
import '../core/scroll_target.dart';
import '../slivers/atlas_placement.dart';
import 'atlas_list_layout.dart';
import 'atlas_options.dart';

/// The list engine.
///
/// A [RenderSliverList] that
///
/// * records every measured child extent in an [ExtentCache], so unbuilt
///   items have an estimated offset and the scroll extent is estimated
///   without building every item,
/// * starts layout at the estimated item when the scroll offset lands far
///   from the built children, so a jump builds one screen of items,
/// * places a requested [ScrollTarget] exactly at its alignment in the
///   first frame after a jump,
/// * keeps the first visible item still when items above it change
///   ([AtlasAnchorMode.firstVisible]).
///
/// Targets are aligned below whatever is pinned above the list at their
/// final position, and the list can sit anywhere in a
/// `CustomScrollView` next to other slivers.
///
/// Everything else (filling the cache area, garbage collection, keep
/// alive) is the framework's list layout.
class RenderSliverAtlasList extends RenderSliverList
    with AtlasPlacement
    implements AtlasListLayout {
  /// Creates the render object.
  RenderSliverAtlasList({
    required super.childManager,
    required ExtentCache cache,
    String? id,
    AtlasLayoutRegistry? registry,
    AtlasAnchorMode anchorMode = AtlasAnchorMode.firstVisible,
    ScrollTarget? initialTarget,
  })  : _cache = cache,
        _id = id,
        _registry = registry,
        _anchorMode = anchorMode,
        _pendingTarget = initialTarget;

  String? _id;

  @override
  String? get id => _id;
  set id(String? value) {
    if (value == _id) return;
    if (attached) _registry?.detachLayout(this);
    _id = value;
    if (attached) _registry?.attachLayout(this);
  }

  ExtentCache _cache;

  /// Measured and estimated extents.
  ExtentCache get cache => _cache;
  set cache(ExtentCache value) {
    if (identical(value, _cache)) return;
    _cache = value;
    markNeedsLayout();
  }

  AtlasLayoutRegistry? _registry;

  /// Controller that this sliver registers with while attached.
  AtlasLayoutRegistry? get registry => _registry;
  set registry(AtlasLayoutRegistry? value) {
    if (identical(value, _registry)) return;
    if (attached) _registry?.detachLayout(this);
    _registry = value;
    if (attached) _registry?.attachLayout(this);
  }

  AtlasAnchorMode _anchorMode;

  /// What stays still when items above the viewport change.
  AtlasAnchorMode get anchorMode => _anchorMode;
  set anchorMode(AtlasAnchorMode value) {
    if (value == _anchorMode) return;
    _anchorMode = value;
    _readingAnchor = null;
  }

  ScrollTarget? _pendingTarget;

  /// True while a placed target is being placed again because the items
  /// above it needed more room than estimated.
  bool _replacingTarget = false;

  /// Placement passes left for the pending target: after a correction the
  /// next layout checks the target again, a bounded number of times.
  int _placementPasses = _maxPlacementPasses;
  _ReadingAnchor? _readingAnchor;
  double _scrollOffset = 0;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _registry?.attachLayout(this);
  }

  @override
  void detach() {
    _registry?.detachLayout(this);
    super.detach();
  }

  // AtlasListLayout ---------------------------------------------------------

  @override
  int get itemCount => childManager.childCount;

  @override
  double? get viewportExtent => placementViewportExtent;

  @override
  bool isBuilt(int index) => _builtChild(index) != null;

  @override
  double leadingOffsetOf(int index) {
    final child = _builtChild(index);
    final local = child == null
        ? _estimatedLayoutOffsetOf(index)
        : childScrollOffset(child)!;
    return placementPrecedingExtent + local;
  }

  /// Estimates where [index] would be laid out.
  ///
  /// Within [_followViewports] viewports of the built children the estimate
  /// is measured from them, because scrolling there continues their layout,
  /// even when they drifted away from the cache's offsets. Further away it
  /// is the cache's offset, which is where a far layout restarts.
  double _estimatedLayoutOffsetOf(int index) {
    final estimate = _estimatedOffsetOf(index);
    final first = firstChild;
    final last = lastChild;
    if (first == null || last == null || !last.hasSize) return estimate;
    final reach = _followViewports * (placementViewportExtent ?? 0);
    final firstIndex = indexOf(first);
    if (index < firstIndex) {
      final gap = _estimatedOffsetOf(firstIndex) - estimate;
      return gap > reach ? estimate : childScrollOffset(first)! - gap;
    }
    final gap = estimate - _estimatedOffsetOf(indexOf(last) + 1);
    return gap > reach
        ? estimate
        : childScrollOffset(last)! + paintExtentOf(last) + gap;
  }

  /// How far from the built children, in viewports, an estimate follows
  /// them rather than the cache.
  static const double _followViewports = 4;

  @override
  double extentOf(int index) {
    final child = _builtChild(index);
    if (child != null) return paintExtentOf(child);
    _cache.itemCount = itemCount;
    return _cache.extentOf(index);
  }

  bool _estimatesFrozen = false;

  @override
  void freezeEstimates({required bool frozen}) {
    if (frozen == _estimatesFrozen) return;
    _estimatesFrozen = frozen;
    if (!frozen) markNeedsLayout();
  }

  @override
  void anchorNextLayout(ScrollTarget target) {
    _pendingTarget = target;
    _placementPasses = _maxPlacementPasses;
    _replacingTarget = false;
    markNeedsLayout();
  }

  @override
  IndexSpan? get visibleSpan {
    final viewport = placementViewportExtent;
    if (viewport == null || firstChild == null || itemCount == 0) return null;
    final start = math.max(0.0, _scrollOffset);
    final first = _fractionalIndexAt(start);
    final end = _fractionalIndexAt(start + viewport);
    return IndexSpan(first, math.max(first, end));
  }

  double _fractionalIndexAt(double offset) {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final childOffset = childScrollOffset(child);
      if (childOffset == null || !child.hasSize) continue;
      final extent = paintExtentOf(child);
      if (offset < childOffset + extent || childAfter(child) == null) {
        final within = extent <= 0
            ? 0.0
            : ((offset - childOffset) / extent).clamp(0.0, 1.0);
        return indexOf(child) + within;
      }
    }
    return 0;
  }

  RenderBox? _builtChild(int index) {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (indexOf(child) == index) {
        final laidOut = child.hasSize && childScrollOffset(child) != null;
        return laidOut ? child : null;
      }
    }
    return null;
  }

  double _estimatedOffsetOf(int index) {
    _cache.itemCount = itemCount;
    return _cache.offsetOf(index.clamp(0, _cache.itemCount));
  }

  // Layout ------------------------------------------------------------------

  @override
  void performLayout() {
    _layout();
    _registry?.layoutChanged(this);
  }

  @override
  List<AtlasItemPosition> get visiblePositions {
    final viewport = placementViewportExtent;
    if (viewport == null || firstChild == null) return const [];
    final origin = virtualScrollOffset;
    final paintStart = math.max(0.0, -origin);
    final obstruction = math.max(0.0, paintStart + constraints.overlap);
    final positions = <AtlasItemPosition>[];
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final offset = childScrollOffset(child);
      if (offset == null || !child.hasSize) continue;
      final leading = offset - origin;
      final position = PositionMath.visible(
        sliverId: id,
        index: indexOf(child),
        leading: leading,
        trailing: leading + paintExtentOf(child),
        obstruction: obstruction,
        viewportExtent: viewport,
      );
      if (position != null) positions.add(position);
    }
    return positions;
  }

  void _layout() {
    beginPlacementLayout();
    _scrollOffset = constraints.scrollOffset;
    _cache.itemCount = itemCount;

    if (_reconcileLeadingEdge()) return;

    final placing = _pendingTarget;
    final target = _takeTarget();
    if (target == _TargetStep.corrected) return;
    final anchored = target == _TargetStep.placed;
    final readingAnchor = anchored ? null : _liveReadingAnchor();
    if (readingAnchor != null) _reseatMovedAnchor(readingAnchor);
    if (!anchored &&
        (firstChild == null ||
            _isFarFromBuiltChildren() ||
            _startsBelowWithoutLeadingItem())) {
      _restartAt(_cache.indexAt(_cacheRegionStart));
    }

    super.performLayout();
    final correction = geometry!.scrollOffsetCorrection;
    if (correction != null) {
      _readingAnchor = null;
      // Near the start the items above a placed target can need more room
      // than estimated: the framework then moves the scroll offset forward.
      // Keep what was measured and place the target again in the next pass,
      // so it keeps its alignment instead of being pushed down.
      if (anchored) {
        if (!_estimatesFrozen) _recordBuiltExtents();
        _pendingTarget = placing;
        _replacingTarget = true;
      }
      return;
    }
    if (!_estimatesFrozen) _recordBuiltExtents();
    if (anchored && _correctTrailingGap()) {
      _pendingTarget = null;
      return;
    }
    if (anchored && _correctPlacedTarget(placing!)) return;
    if (readingAnchor != null && _correctForReadingAnchor(readingAnchor)) {
      return;
    }
    _useCacheForScrollExtent();
    _recordReadingAnchor();
  }

  /// When item 0 is built away from offset 0 (estimates above it were
  /// wrong), moves every child so item 0 starts at 0 and moves the scroll
  /// offset by the same amount. Nothing moves on screen.
  bool _reconcileLeadingEdge() {
    final first = firstChild;
    if (first == null || indexOf(first) != 0) return false;
    final offset = childScrollOffset(first);
    if (offset == null || offset.abs() < ExtentCache.tolerance) return false;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final data = child.parentData! as SliverMultiBoxAdaptorParentData;
      if (data.layoutOffset != null) {
        data.layoutOffset = data.layoutOffset! - offset;
      }
    }
    _readingAnchor = null;
    // A list that starts below the viewport's leading edge shows nothing
    // above its first item: moving its children is enough.
    if (virtualScrollOffset < -ExtentCache.tolerance) return false;
    geometry = SliverGeometry(scrollOffsetCorrection: -offset);
    return true;
  }

  _TargetStep _takeTarget() {
    final target = _pendingTarget;
    if (target == null || itemCount == 0) {
      _pendingTarget = null;
      _replacingTarget = false;
      return _TargetStep.none;
    }
    final index = target.index.clamp(0, itemCount - 1);
    final aligned = alignedOffset(target);
    final estimate = _estimatedOffsetOf(index);
    final virtualOffset = virtualScrollOffset;
    if (firstChild == null || _replacingTarget) {
      // First layout (initial index, or a list that just attached), or a
      // target placed again after the items above it grew: move the scroll
      // offset to the estimate first, so the items above the target have
      // room.
      final desired = math.max(minVirtualScrollOffset, estimate - aligned);
      final correction = desired - virtualOffset;
      if (correction.abs() > ExtentCache.tolerance) {
        geometry = SliverGeometry(scrollOffsetCorrection: correction);
        return _TargetStep.corrected;
      }
    }
    _pendingTarget = null;
    _replacingTarget = false;
    _readingAnchor = null;
    // A built target keeps its children: the normal layout runs and the
    // placement check moves the scroll offset if needed.
    final built = _builtChild(index);
    if (built != null && _isInCacheRegion(built)) {
      return _TargetStep.placed;
    }
    // Near the start of the list the scroll offset is clamped at 0, so the
    // target goes to its alignment line, but never below its own estimate
    // or above the list's start.
    final atStart = constraints.scrollOffset <= ExtentCache.tolerance;
    final layoutOffset = atStart
        ? math.max(0.0, math.min(virtualOffset + aligned, estimate))
        : constraints.scrollOffset + aligned;
    _restartAt(index, layoutOffset: layoutOffset);
    return _TargetStep.placed;
  }

  double get _cacheRegionStart =>
      math.max(0, constraints.scrollOffset + constraints.cacheOrigin);

  double get _cacheRegionEnd =>
      constraints.scrollOffset +
      constraints.cacheOrigin +
      constraints.remainingCacheExtent;

  /// A list that starts below the viewport's leading edge, but kept a
  /// child from when it was above it (the framework keeps one). Laying it
  /// out from that child would move the scroll offset to make room for the
  /// items before it, under the content on screen.
  bool _startsBelowWithoutLeadingItem() =>
      indexOf(firstChild!) != 0 && virtualScrollOffset < -ExtentCache.tolerance;

  /// Whether [child] would be kept by a layout at the current scroll
  /// offset. The items before this list can change size between passes,
  /// which moves a built target out of the region the layout keeps.
  bool _isInCacheRegion(RenderBox child) {
    final start = childScrollOffset(child);
    if (start == null || !child.hasSize) return false;
    return start + paintExtentOf(child) >= _cacheRegionStart &&
        start <= _cacheRegionEnd;
  }

  bool _isFarFromBuiltChildren() {
    final first = firstChild!;
    final last = lastChild!;
    final builtStart = childScrollOffset(first);
    final lastOffset = childScrollOffset(last);
    if (builtStart == null || lastOffset == null || !last.hasSize) return true;
    final builtEnd = lastOffset + paintExtentOf(last);
    final margin = constraints.viewportMainAxisExtent;
    return _cacheRegionStart > builtEnd + margin ||
        _cacheRegionEnd < builtStart - margin;
  }

  /// Drops every built child and starts layout from item [index]. The
  /// framework's list layout then fills before and after it.
  void _restartAt(int index, {double? layoutOffset}) {
    final offset = layoutOffset ?? _cache.offsetOf(index);
    if (firstChild != null) collectGarbage(childCount, 0);
    _readingAnchor = null;
    addInitialChild(index: index, layoutOffset: offset);
  }

  void _recordBuiltExtents() {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (child.hasSize) _cache.record(indexOf(child), paintExtentOf(child));
    }
  }

  /// After a jump near the start, the framework can move the items above
  /// the target once they are measured. Moves the scroll offset so the
  /// target sits at its alignment again, or as close as the start allows.
  bool _correctPlacedTarget(ScrollTarget target) {
    final index = target.index.clamp(0, itemCount - 1);
    RenderBox? child = firstChild;
    while (child != null && indexOf(child) != index) {
      child = childAfter(child);
    }
    if (child == null) return false;
    final correction = placementCorrection(childScrollOffset(child)!, target);
    if (correction == null || _placementPasses <= 0) return false;
    _placementPasses--;
    // Check again in the next pass: what is pinned above the target can
    // change with the scroll offset (a section header becomes stuck).
    _pendingTarget = target;
    _readingAnchor = null;
    geometry = SliverGeometry(scrollOffsetCorrection: correction);
    return true;
  }

  /// After a jump near the end, pulls the scroll offset back so the last
  /// item ends at the viewport's trailing edge instead of leaving a gap.
  bool _correctTrailingGap() {
    final last = lastChild;
    if (last == null || indexOf(last) != itemCount - 1) return false;
    if (!AtlasObstruction.isLast(this)) return false;
    final lastEnd = childScrollOffset(last)! + paintExtentOf(last);
    final gap =
        constraints.scrollOffset + constraints.remainingPaintExtent - lastEnd;
    final correction = -math.min(gap, constraints.scrollOffset);
    if (gap <= ExtentCache.tolerance || correction >= -ExtentCache.tolerance) {
      return false;
    }
    geometry = SliverGeometry(scrollOffsetCorrection: correction);
    return true;
  }

  _ReadingAnchor? _liveReadingAnchor() {
    final anchor = _readingAnchor;
    if (anchor == null || _anchorMode == AtlasAnchorMode.none) return null;
    if (!identical(anchor.box.parent, this)) return null;
    // A jump elsewhere in the scroll view moved this list away from its
    // anchor: there is nothing on screen to keep in place.
    if (anchor.layoutOffset > _cacheRegionEnd ||
        anchor.layoutOffset <
            _cacheRegionStart - constraints.viewportMainAxisExtent) {
      _readingAnchor = null;
      return null;
    }
    return anchor;
  }

  /// When keyed items were inserted or removed before the reading anchor,
  /// the framework moved its box to a new index, and the layout offsets of
  /// the moved children are stale. Keeps only the anchor's box, at its old
  /// offset, so layout continues from it and nothing on screen moves.
  void _reseatMovedAnchor(_ReadingAnchor anchor) {
    if (indexOf(anchor.box) == anchor.index) return;
    final data = anchor.box.parentData! as SliverMultiBoxAdaptorParentData;
    var leading = 0;
    for (var child = firstChild;
        child != null && !identical(child, anchor.box);
        child = childAfter(child)) {
      leading++;
    }
    var trailing = 0;
    for (var child = lastChild;
        child != null && !identical(child, anchor.box);
        child = childBefore(child)) {
      trailing++;
    }
    collectGarbage(leading, trailing);
    data.layoutOffset = anchor.layoutOffset;
  }

  /// Moves the scroll offset by however far the reading anchor moved in
  /// this layout, so it stays at the same place on screen.
  bool _correctForReadingAnchor(_ReadingAnchor anchor) {
    if (!identical(anchor.box.parent, this) || !anchor.box.hasSize) {
      return false;
    }
    final now = childScrollOffset(anchor.box);
    if (now == null) return false;
    final moved = now - anchor.layoutOffset;
    if (moved.abs() < ExtentCache.tolerance) return false;
    _readingAnchor = _ReadingAnchor(anchor.box, indexOf(anchor.box), now);
    geometry = SliverGeometry(scrollOffsetCorrection: moved);
    return true;
  }

  void _recordReadingAnchor() {
    _readingAnchor = null;
    if (_anchorMode == AtlasAnchorMode.none) return;
    // Pinned to the start: new items at the start should push content
    // (a chat list stays at the newest message).
    if (constraints.scrollOffset <= 0.5) return;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      final offset = childScrollOffset(child);
      if (offset == null || !child.hasSize) continue;
      if (offset + paintExtentOf(child) > constraints.scrollOffset) {
        _readingAnchor = _ReadingAnchor(child, indexOf(child), offset);
        return;
      }
    }
  }

  void _useCacheForScrollExtent() {
    final last = lastChild;
    final lastOffset = last == null ? null : childScrollOffset(last);
    if (last == null || lastOffset == null) return;
    final trailingIndex = indexOf(last) + 1;
    final estimatedEnd = lastOffset +
        paintExtentOf(last) +
        _cache.totalExtent -
        _cache.offsetOf(trailingIndex);
    final current = geometry!;
    if ((estimatedEnd - current.scrollExtent).abs() < ExtentCache.tolerance) {
      return;
    }
    geometry = current.copyWith(
      scrollExtent: estimatedEnd,
      maxPaintExtent: math.max(estimatedEnd, current.paintExtent),
    );
  }
}

/// Placement checks after a jump, so an oscillating obstruction cannot
/// exhaust the viewport's layout cycles.
const int _maxPlacementPasses = 3;

enum _TargetStep { none, corrected, placed }

/// The first visible child and where it was after the previous layout.
final class _ReadingAnchor {
  const _ReadingAnchor(this.box, this.index, this.layoutOffset);

  final RenderBox box;
  final int index;
  final double layoutOffset;
}
