import 'package:flutter/widgets.dart';

import '../core/extent_cache.dart';
import '../core/extent_estimator.dart';
import '../core/scroll_target.dart';
import '../slivers/atlas_scope.dart';
import 'atlas_list_layout.dart';
import 'atlas_options.dart';
import 'render_sliver_atlas_list.dart';

/// A sliver list that can jump to any index in one frame, estimates the
/// extent of items it has not built, and keeps the item you are reading
/// still when items above it change.
///
/// Use it in an `AtlasScrollView` (give it an [id] when there are several
/// lists), in a [CustomScrollView] whose controller is
/// `AtlasController.scrollController` (pass [controller]), or use
/// `AtlasListView`, which does the wiring.
///
/// ```dart
/// AtlasScrollView(
///   controller: atlas,
///   slivers: [
///     const SliverAppBar(pinned: true, title: Text('Inbox')),
///     SliverAtlasList.builder(
///       id: 'mail',
///       itemCount: mails.length,
///       itemBuilder: (context, index) => MailTile(mails[index]),
///     ),
///   ],
/// );
/// atlas.jumpTo(target: const AtlasTarget.item('mail', 420));
/// ```
class SliverAtlasList extends StatefulWidget {
  /// Creates the sliver from a [delegate].
  const SliverAtlasList({
    required this.delegate,
    this.id,
    this.controller,
    this.anchorMode = AtlasAnchorMode.firstVisible,
    this.initialIndex = 0,
    this.initialAlignment = 0,
    this.estimator,
    super.key,
  });

  /// Creates the sliver with a builder, like `SliverList.builder`.
  SliverAtlasList.builder({
    required int itemCount,
    required NullableIndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    this.id,
    this.controller,
    this.anchorMode = AtlasAnchorMode.firstVisible,
    this.initialIndex = 0,
    this.initialAlignment = 0,
    this.estimator,
    super.key,
  }) : delegate = SliverChildBuilderDelegate(
          itemBuilder,
          childCount: itemCount,
          findChildIndexCallback: findChildIndexCallback,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
        );

  /// Builds the items. Give it a `findChildIndexCallback` and keyed items
  /// so inserted items keep their identity.
  final SliverChildDelegate delegate;

  /// Id for `AtlasTarget.item(id, index)`. Unique within one
  /// scroll view; null for the only list of a controller.
  final String? id;

  /// Controller that jumps and animates this list. Defaults to the
  /// controller of the enclosing `AtlasScrollView` or `AtlasScope`.
  final AtlasLayoutRegistry? controller;

  /// What stays still when items above the viewport change.
  final AtlasAnchorMode anchorMode;

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
        id: widget.id,
        registry: widget.controller ?? AtlasScope.maybeOf(context),
        anchorMode: widget.anchorMode,
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
    required this.id,
    required this.registry,
    required this.anchorMode,
    required this.initialTarget,
  });

  final ExtentCache cache;
  final String? id;
  final AtlasLayoutRegistry? registry;
  final AtlasAnchorMode anchorMode;
  final ScrollTarget? initialTarget;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  RenderSliverAtlasList createRenderObject(BuildContext context) =>
      RenderSliverAtlasList(
        childManager: context as SliverMultiBoxAdaptorElement,
        cache: cache,
        id: id,
        registry: registry,
        anchorMode: anchorMode,
        initialTarget: initialTarget,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverAtlasList renderObject,
  ) {
    renderObject
      ..cache = cache
      ..id = id
      ..registry = registry
      ..anchorMode = anchorMode;
  }
}
