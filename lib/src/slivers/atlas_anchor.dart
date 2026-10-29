import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../list/atlas_list_layout.dart';
import 'atlas_placement.dart';
import 'atlas_scope.dart';
import 'atlas_target_sliver.dart';

/// Makes any [sliver] (a `SliverToBoxAdapter`, a `SliverGrid`, ...) a
/// target for `AtlasTarget.sliver(id)`. Its leading edge lands at
/// the alignment line.
///
/// ```dart
/// AtlasAnchor(
///   id: 'photos',
///   sliver: SliverGrid.count(crossAxisCount: 3, children: photos),
/// );
/// atlas.jumpTo(target: const AtlasTarget.sliver('photos'));
/// ```
class AtlasAnchor extends SingleChildRenderObjectWidget {
  /// Creates the anchor.
  const AtlasAnchor({
    required this.id,
    required Widget sliver,
    this.controller,
    super.key,
  }) : super(child: sliver);

  /// Id for `AtlasTarget.sliver(id)`, unique within one scroll view.
  final String id;

  /// Controller to register with. Defaults to the enclosing `AtlasScope`.
  final AtlasLayoutRegistry? controller;

  @override
  RenderAtlasAnchor createRenderObject(BuildContext context) =>
      RenderAtlasAnchor(
        id: id,
        registry: controller ?? AtlasScope.maybeOf(context),
      );

  @override
  void updateRenderObject(
      BuildContext context, RenderAtlasAnchor renderObject) {
    renderObject
      ..id = id
      ..registry = controller ?? AtlasScope.maybeOf(context);
  }
}

/// Render object of [AtlasAnchor]: lays its child out unchanged and
/// corrects the scroll offset when a jump targets it.
class RenderAtlasAnchor extends RenderProxySliver
    with AtlasPlacement, AtlasTargetSliver {
  /// Creates the render object.
  RenderAtlasAnchor({required String id, AtlasLayoutRegistry? registry}) {
    this.id = id;
    this.registry = registry;
  }

  @override
  void performLayout() {
    beginPlacementLayout();
    final child = this.child;
    if (child == null) {
      geometry = SliverGeometry.zero;
    } else {
      child.layout(constraints, parentUsesSize: true);
      geometry = child.geometry;
      if (geometry!.scrollOffsetCorrection != null) return;
    }
    placePendingTarget();
  }
}
