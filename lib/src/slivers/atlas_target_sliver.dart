import 'package:flutter/rendering.dart';

import '../core/scroll_target.dart';
import '../list/atlas_list_layout.dart';
import 'atlas_placement.dart';

/// Registration and leading edge placement for a sliver that is one
/// target as a whole (`SliverAtlasSection`, `AtlasAnchor`).
mixin AtlasTargetSliver
    on RenderSliver, AtlasPlacement
    implements AtlasTargetLayout {
  String? _id;
  AtlasLayoutRegistry? _registry;
  ScrollTarget? _pendingTarget;
  int _placementPasses = 0;
  bool _laidOut = false;

  @override
  String? get id => _id;
  set id(String? value) {
    if (value == _id) return;
    if (attached) _registry?.detachLayout(this);
    _id = value;
    if (attached) _registry?.attachLayout(this);
  }

  /// Controller that this sliver registers with while attached.
  AtlasLayoutRegistry? get registry => _registry;
  set registry(AtlasLayoutRegistry? value) {
    if (identical(value, _registry)) return;
    if (attached) _registry?.detachLayout(this);
    _registry = value;
    if (attached) _registry?.attachLayout(this);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _registry?.attachLayout(this);
  }

  @override
  void detach() {
    _registry?.detachLayout(this);
    _laidOut = false;
    super.detach();
  }

  @override
  int get itemCount => 1;

  @override
  double? get viewportExtent => placementViewportExtent;

  @override
  bool isBuilt(int index) => _laidOut;

  @override
  double leadingOffsetOf(int index) => placementPrecedingExtent;

  @override
  void anchorNextLayout(ScrollTarget target) {
    _pendingTarget = target;
    _placementPasses = _maxPlacementPasses;
    markNeedsLayout();
  }

  /// Call at the end of `performLayout`, once [geometry] is set and has no
  /// correction. Returns true when it replaced [geometry] with a scroll
  /// offset correction that puts the leading edge at the pending target's
  /// alignment line.
  bool placePendingTarget() {
    _laidOut = true;
    final target = _pendingTarget;
    if (target == null) return false;
    final correction = placementCorrection(0, target);
    if (correction == null || _placementPasses <= 0) {
      _pendingTarget = null;
      return false;
    }
    _placementPasses--;
    geometry = SliverGeometry(scrollOffsetCorrection: correction);
    return true;
  }
}

const int _maxPlacementPasses = 3;
