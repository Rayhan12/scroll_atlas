import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import '../../core/alignment_math.dart';
import '../../core/extent_cache.dart';
import '../../core/scroll_target.dart';
import 'anchor_requests.dart';
import 'item_locator.dart';

/// Prototype: a [RenderSliverList] that
///
/// * records every measured child extent in an [ExtentCache],
/// * starts layout at the cached offset when the scroll offset lands far from
///   the built children (no walk through every item in between),
/// * places a requested [ScrollTarget] child directly at its aligned
///   position, so an index jump lands in the first frame.
///
/// It reuses the framework's list layout for everything else. Experimental:
/// not the main engine.
class RenderAtlasSliverList extends RenderSliverList implements ItemLocator {
  /// Creates the render object.
  RenderAtlasSliverList({
    required super.childManager,
    required ExtentCache cache,
    required AnchorRequests anchors,
    required ItemLocatorSlot locatorSlot,
  })  : _cache = cache,
        _anchors = anchors,
        _locatorSlot = locatorSlot;

  ExtentCache _cache;

  /// Measured and estimated extents.
  ExtentCache get cache => _cache;
  set cache(ExtentCache value) {
    if (identical(value, _cache)) return;
    _cache = value;
    markNeedsLayout();
  }

  AnchorRequests _anchors;

  /// Source of pending index jumps.
  AnchorRequests get anchors => _anchors;
  set anchors(AnchorRequests value) {
    if (identical(value, _anchors)) return;
    if (attached) _anchors.removeListener(markNeedsLayout);
    _anchors = value;
    if (attached) _anchors.addListener(markNeedsLayout);
    markNeedsLayout();
  }

  ItemLocatorSlot _locatorSlot;

  /// Where this object publishes itself as an [ItemLocator].
  ItemLocatorSlot get locatorSlot => _locatorSlot;
  set locatorSlot(ItemLocatorSlot value) {
    if (identical(value, _locatorSlot)) return;
    if (identical(_locatorSlot.locator, this)) _locatorSlot.locator = null;
    _locatorSlot = value;
    if (attached) _locatorSlot.locator = this;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _anchors.addListener(markNeedsLayout);
    _locatorSlot.locator = this;
  }

  @override
  void detach() {
    _anchors.removeListener(markNeedsLayout);
    if (identical(_locatorSlot.locator, this)) _locatorSlot.locator = null;
    super.detach();
  }

  double? _viewportExtent;
  double _precedingScrollExtent = 0;

  @override
  void performLayout() {
    _viewportExtent = constraints.viewportMainAxisExtent;
    _precedingScrollExtent = constraints.precedingScrollExtent;
    _cache.itemCount = childManager.childCount;
    final target = _anchors.take();
    if (target != null && target.index < _cache.itemCount) {
      _restartAt(target.index, _anchoredOffset(target));
    } else if (firstChild == null || _isFarFromBuiltChildren()) {
      final index = _cache.indexAt(_cacheRegionStart);
      _restartAt(index, _cache.offsetOf(index));
    }
    super.performLayout();
    if (geometry!.scrollOffsetCorrection != null) return;
    _recordBuiltExtents();
    _useCacheForScrollExtent();
  }

  double get _cacheRegionStart =>
      math.max(0, constraints.scrollOffset + constraints.cacheOrigin);

  double get _cacheRegionEnd =>
      constraints.scrollOffset +
      constraints.cacheOrigin +
      constraints.remainingCacheExtent;

  double _anchoredOffset(ScrollTarget target) =>
      constraints.scrollOffset +
      AlignmentMath.leadingEdgeInViewport(
        alignment: target.alignment,
        viewportExtent: constraints.viewportMainAxisExtent,
      );

  bool _isFarFromBuiltChildren() {
    final builtStart = childScrollOffset(firstChild!);
    final last = lastChild!;
    final lastOffset = childScrollOffset(last);
    if (builtStart == null || lastOffset == null || !last.hasSize) return true;
    final builtEnd = lastOffset + paintExtentOf(last);
    final margin = constraints.viewportMainAxisExtent;
    return _cacheRegionStart > builtEnd + margin ||
        _cacheRegionEnd < builtStart - margin;
  }

  /// Drops every built child and starts layout from item [index] at
  /// [layoutOffset]. The framework's list layout then fills before and after.
  void _restartAt(int index, double layoutOffset) {
    if (firstChild != null) collectGarbage(childCount, 0);
    addInitialChild(index: index, layoutOffset: layoutOffset);
  }

  void _recordBuiltExtents() {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (child.hasSize) _cache.record(indexOf(child), paintExtentOf(child));
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
      maxPaintExtent: estimatedEnd,
    );
  }

  @override
  double? scrollOffsetOfBuiltItem(int index) {
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (indexOf(child) == index) {
        final offset = childScrollOffset(child);
        return offset == null ? null : _precedingScrollExtent + offset;
      }
    }
    return null;
  }

  @override
  double? get viewportExtent => _viewportExtent;

  @override
  double get precedingScrollExtent => _precedingScrollExtent;
}
