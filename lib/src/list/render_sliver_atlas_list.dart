import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../core/alignment_math.dart';
import '../core/extent_cache.dart';
import '../core/index_fraction.dart';
import '../core/scroll_target.dart';
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
///   ([AtlasAnchor.firstVisible]).
///
/// Everything else (filling the cache area, garbage collection, keep
/// alive) is the framework's list layout.
class RenderSliverAtlasList extends RenderSliverList
    implements AtlasListLayout {
  /// Creates the render object.
  RenderSliverAtlasList({
    required super.childManager,
    required ExtentCache cache,
    AtlasLayoutRegistry? registry,
    AtlasAnchor anchor = AtlasAnchor.firstVisible,
    ScrollTarget? initialTarget,
  })  : _cache = cache,
        _registry = registry,
        _anchor = anchor,
        _pendingTarget = initialTarget;

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

  AtlasAnchor _anchor;

  /// What stays still when items above the viewport change.
  AtlasAnchor get anchor => _anchor;
  set anchor(AtlasAnchor value) {
    if (value == _anchor) return;
    _anchor = value;
    _readingAnchor = null;
  }

  ScrollTarget? _pendingTarget;

  /// True while a placed target is being placed again because the items
  /// above it needed more room than estimated.
  bool _replacingTarget = false;
  _ReadingAnchor? _readingAnchor;
  double? _viewportExtent;
  double _precedingScrollExtent = 0;
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
  double? get viewportExtent => _viewportExtent;

  @override
  bool isBuilt(int index) => _builtChild(index) != null;

  @override
  double leadingOffsetOf(int index) {
    final child = _builtChild(index);
    final local = child == null
        ? _estimatedLayoutOffsetOf(index)
        : childScrollOffset(child)!;
    return _precedingScrollExtent + local;
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
    final reach = _followViewports * (_viewportExtent ?? 0);
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
    markNeedsLayout();
  }

  @override
  IndexSpan? get visibleSpan {
    final viewport = _viewportExtent;
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
    _viewportExtent = constraints.viewportMainAxisExtent;
    _precedingScrollExtent = constraints.precedingScrollExtent;
    _scrollOffset = constraints.scrollOffset;
    _cache.itemCount = itemCount;

    if (_reconcileLeadingEdge()) return;

    final placing = _pendingTarget;
    final target = _takeTarget();
    if (target == _TargetStep.corrected) return;
    final anchored = target == _TargetStep.placed;
    final readingAnchor = anchored ? null : _liveReadingAnchor();
    if (readingAnchor != null) _reseatMovedAnchor(readingAnchor);
    if (!anchored && (firstChild == null || _isFarFromBuiltChildren())) {
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
    if (anchored && _correctTrailingGap()) return;
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
    final aligned = _alignedOffset(target);
    if (firstChild == null || _replacingTarget) {
      // First layout (initial index, or a list that just attached), or a
      // target placed again after the items above it grew: move the scroll
      // offset to the estimate first, so the items above the target have
      // room.
      final desired = math.max(0.0, _estimatedOffsetOf(index) - aligned);
      final correction = desired - constraints.scrollOffset;
      if (correction.abs() > ExtentCache.tolerance) {
        geometry = SliverGeometry(scrollOffsetCorrection: correction);
        return _TargetStep.corrected;
      }
    }
    _pendingTarget = null;
    _replacingTarget = false;
    _readingAnchor = null;
    // Near the start the scroll offset was clamped at 0, so there is not
    // enough room above the target to align it: put it at its own offset.
    final atStart = constraints.scrollOffset <= ExtentCache.tolerance;
    final layoutOffset = atStart
        ? math.min(aligned, _estimatedOffsetOf(index))
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

  double _alignedOffset(ScrollTarget target) =>
      AlignmentMath.leadingEdgeInViewport(
        alignment: target.alignment,
        viewportExtent: constraints.viewportMainAxisExtent,
      );

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
    final desired =
        math.max(0.0, childScrollOffset(child)! - _alignedOffset(target));
    final correction = desired - constraints.scrollOffset;
    if (correction.abs() <= ExtentCache.tolerance) return false;
    _readingAnchor = null;
    geometry = SliverGeometry(scrollOffsetCorrection: correction);
    return true;
  }

  /// After a jump near the end, pulls the scroll offset back so the last
  /// item ends at the viewport's trailing edge instead of leaving a gap.
  bool _correctTrailingGap() {
    final last = lastChild;
    if (last == null || indexOf(last) != itemCount - 1) return false;
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
    if (anchor == null || _anchor == AtlasAnchor.none) return null;
    if (!identical(anchor.box.parent, this)) return null;
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
    if (_anchor == AtlasAnchor.none) return;
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

enum _TargetStep { none, corrected, placed }

/// The first visible child and where it was after the previous layout.
final class _ReadingAnchor {
  const _ReadingAnchor(this.box, this.index, this.layoutOffset);

  final RenderBox box;
  final int index;
  final double layoutOffset;
}
