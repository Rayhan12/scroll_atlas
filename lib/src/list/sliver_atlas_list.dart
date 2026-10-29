import 'package:flutter/widgets.dart';

import '../core/extent_cache.dart';
import '../core/extent_estimator.dart';
import '../core/scroll_target.dart';
import 'atlas_list_layout.dart';
import 'atlas_options.dart';
import 'render_sliver_atlas_list.dart';

/// A sliver list that can jump to any index in one frame, estimates the
/// extent of items it has not built, and keeps the item you are reading
/// still when items above it change.
///
/// Use it in a [CustomScrollView] whose controller is
/// [AtlasController.scrollController], or use `AtlasListView`, which does
/// the wiring. One [SliverAtlasList] per controller.
class SliverAtlasList extends StatefulWidget {
  /// Creates the sliver.
  const SliverAtlasList({
    required this.delegate,
    this.controller,
    this.anchor = AtlasAnchor.firstVisible,
    this.initialIndex = 0,
    this.initialAlignment = 0,
    this.estimator,
    super.key,
  });

  /// Builds the items. Give it a `findChildIndexCallback` and keyed items
  /// so inserted items keep their identity (needed for anchoring on
  /// inserts).
  final SliverChildDelegate delegate;

  /// Controller that jumps and animates this list.
  final AtlasLayoutRegistry? controller;

  /// What stays still when items above the viewport change.
  final AtlasAnchor anchor;

  /// Item shown at [initialAlignment] in the first frame.
  final int initialIndex;

  /// Alignment of [initialIndex]: 0 is the leading edge, 0.5 the middle.
  final double initialAlignment;

  /// Estimates unmeasured items. Defaults to a running average.
  final ExtentEstimator? estimator;

  @override
  State<SliverAtlasList> createState() => _SliverAtlasListState();
}

class _SliverAtlasListState extends State<SliverAtlasList> {
  late final ExtentCache _cache = ExtentCache(estimator: widget.estimator);

  @override
  Widget build(BuildContext context) => _SliverAtlasListAdaptor(
        delegate: widget.delegate,
        cache: _cache,
        registry: widget.controller,
        anchor: widget.anchor,
        initialTarget: widget.initialIndex == 0 && widget.initialAlignment == 0
            ? null
            : ScrollTarget(widget.initialIndex,
                alignment: widget.initialAlignment),
      );
}

class _SliverAtlasListAdaptor extends SliverMultiBoxAdaptorWidget {
  const _SliverAtlasListAdaptor({
    required super.delegate,
    required this.cache,
    required this.registry,
    required this.anchor,
    required this.initialTarget,
  });

  final ExtentCache cache;
  final AtlasLayoutRegistry? registry;
  final AtlasAnchor anchor;
  final ScrollTarget? initialTarget;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  RenderSliverAtlasList createRenderObject(BuildContext context) =>
      RenderSliverAtlasList(
        childManager: context as SliverMultiBoxAdaptorElement,
        cache: cache,
        registry: registry,
        anchor: anchor,
        initialTarget: initialTarget,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverAtlasList renderObject,
  ) {
    renderObject
      ..cache = cache
      ..registry = registry
      ..anchor = anchor;
  }
}
