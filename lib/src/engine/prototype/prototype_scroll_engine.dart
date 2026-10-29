import 'package:flutter/widgets.dart';

import '../../core/alignment_math.dart';
import '../../core/extent_cache.dart';
import '../../core/extent_estimator.dart';
import '../../core/scroll_target.dart';
import '../list_engine.dart';
import 'anchor_requests.dart';
import 'atlas_prototype_list.dart';
import 'item_locator.dart';

/// Option (a): our own extent-estimating sliver.
///
/// Experimental prototype code. It exists to be measured against
/// super_sliver_list and scrollview_observer, not to be shipped as is.
final class PrototypeScrollEngine implements IndexedScrollEngine {
  /// Creates the engine. [estimator] defaults to a running average.
  PrototypeScrollEngine(
      {ExtentEstimator? estimator, ScrollController? controller})
      : _cache = ExtentCache(estimator: estimator),
        _ownsController = controller == null,
        controller = controller ?? ScrollController();

  /// Scroll controller of the built list.
  final ScrollController controller;
  final bool _ownsController;
  final ExtentCache _cache;
  final AnchorRequests _anchors = AnchorRequests();
  final ItemLocatorSlot _locatorSlot = ItemLocatorSlot();

  @override
  String get id => 'scroll_atlas_prototype';

  @override
  Widget buildList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
  }) =>
      CustomScrollView(
        controller: controller,
        slivers: [
          SliverAtlasPrototypeList(
            delegate: SliverChildBuilderDelegate(
              itemBuilder,
              childCount: itemCount,
              findChildIndexCallback: findChildIndexCallback,
            ),
            cache: _cache,
            anchors: _anchors,
            locatorSlot: _locatorSlot,
          ),
        ],
      );

  @override
  void jumpToIndex(int index, {double alignment = 0}) {
    final target = ScrollTarget(index, alignment: alignment);
    final exact = _exactPixelsOf(target);
    if (exact != null) {
      controller.jumpTo(_clamp(exact));
      return;
    }
    _anchors.request(target);
    controller.jumpTo(_clamp(_estimatedPixelsOf(target)));
  }

  @override
  Future<void> animateToIndex(
    int index, {
    required Duration duration,
    Curve curve = Curves.easeInOut,
    double alignment = 0,
  }) async {
    final target = ScrollTarget(index, alignment: alignment);
    final pixels = _exactPixelsOf(target) ?? _estimatedPixelsOf(target);
    await controller.animateTo(_clamp(pixels),
        duration: duration, curve: curve);
    // Prototype landing: correct the remaining estimate error in one jump.
    // Retargeting in flight would remove this snap.
    jumpToIndex(index, alignment: alignment);
  }

  double? _exactPixelsOf(ScrollTarget target) {
    final locator = _locatorSlot.locator;
    final viewport = locator?.viewportExtent;
    final itemOffset = locator?.scrollOffsetOfBuiltItem(target.index);
    if (viewport == null || itemOffset == null) return null;
    return _pixelsFor(target, itemOffset, viewport);
  }

  double _estimatedPixelsOf(ScrollTarget target) {
    final locator = _locatorSlot.locator;
    final viewport =
        locator?.viewportExtent ?? controller.position.viewportDimension;
    final leading = (locator?.precedingScrollExtent ?? 0) +
        _cache.offsetOf(target.index.clamp(0, _cache.itemCount));
    return _pixelsFor(target, leading, viewport);
  }

  double _pixelsFor(ScrollTarget target, double itemOffset, double viewport) =>
      AlignmentMath.scrollOffsetFor(
        itemLeadingOffset: itemOffset,
        alignment: target.alignment,
        viewportExtent: viewport,
      );

  double _clamp(double pixels) {
    final position = controller.position;
    return pixels.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  @override
  void dispose() {
    _anchors.dispose();
    if (_ownsController) controller.dispose();
  }
}
