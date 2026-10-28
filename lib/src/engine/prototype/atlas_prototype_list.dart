import 'package:flutter/widgets.dart';

import '../../core/extent_cache.dart';
import 'anchor_requests.dart';
import 'item_locator.dart';
import 'render_atlas_sliver_list.dart';

/// Sliver widget for the prototype. Wires a [RenderAtlasSliverList] to
/// the collaborators it depends on; it holds no logic of its own.
class SliverAtlasPrototypeList extends SliverMultiBoxAdaptorWidget {
  /// Creates the sliver.
  const SliverAtlasPrototypeList({
    required super.delegate,
    required this.cache,
    required this.anchors,
    required this.locatorSlot,
    super.key,
  });

  /// Shared extent cache.
  final ExtentCache cache;

  /// Pending jump requests.
  final AnchorRequests anchors;

  /// Where the render object publishes itself.
  final ItemLocatorSlot locatorSlot;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  RenderAtlasSliverList createRenderObject(BuildContext context) =>
      RenderAtlasSliverList(
        childManager: context as SliverMultiBoxAdaptorElement,
        cache: cache,
        anchors: anchors,
        locatorSlot: locatorSlot,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderAtlasSliverList renderObject,
  ) {
    renderObject
      ..cache = cache
      ..anchors = anchors
      ..locatorSlot = locatorSlot;
  }
}
