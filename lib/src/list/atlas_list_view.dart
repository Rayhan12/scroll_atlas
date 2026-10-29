import 'package:flutter/widgets.dart';

import '../core/extent_estimator.dart';
import 'atlas_controller.dart';
import 'atlas_options.dart';
import 'sliver_atlas_list.dart';

/// A scrollable list that jumps or animates to any index exactly, even in
/// lists of millions of variable-height items. A drop-in for
/// `ListView.builder` plus an [AtlasController].
///
/// ```dart
/// final controller = AtlasController();
/// AtlasListView.builder(
///   controller: controller,
///   itemCount: messages.length,
///   itemBuilder: (context, index) => MessageTile(messages[index]),
/// );
/// controller.jumpTo(index: 50000, alignment: 0.5);
/// ```
class AtlasListView extends StatefulWidget {
  /// Creates a list that builds items on demand.
  const AtlasListView.builder({
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.findChildIndexCallback,
    this.initialIndex = 0,
    this.initialAlignment = 0,
    this.anchorMode = AtlasAnchorMode.firstVisible,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
    this.padding,
    this.cacheExtent,
    this.estimator,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    super.key,
  });

  /// Number of items.
  final int itemCount;

  /// Builds item `index`.
  final NullableIndexedWidgetBuilder itemBuilder;

  /// Jumps and animates the list. When null, the list owns a controller.
  final AtlasController? controller;

  /// Finds the new index of a keyed item after the data changed. Needed
  /// for inserts above the viewport to keep the reading position.
  final ChildIndexGetter? findChildIndexCallback;

  /// Item shown at [initialAlignment] in the first frame.
  final int initialIndex;

  /// Alignment of [initialIndex].
  final double initialAlignment;

  /// What stays still when items above the viewport change.
  final AtlasAnchorMode anchorMode;

  /// Scroll axis.
  final Axis scrollDirection;

  /// Whether index 0 is at the bottom (or right). Use for chats: new
  /// messages at index 0 stay in view while the list is at the newest one.
  final bool reverse;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Padding around the items.
  final EdgeInsetsGeometry? padding;

  /// Extent built before and after the viewport.
  final double? cacheExtent;

  /// Estimates unmeasured items. Defaults to a running average.
  final ExtentEstimator? estimator;

  /// Same as in `SliverChildBuilderDelegate`.
  final bool addAutomaticKeepAlives;

  /// Same as in `SliverChildBuilderDelegate`.
  final bool addRepaintBoundaries;

  @override
  State<AtlasListView> createState() => _AtlasListViewState();
}

class _AtlasListViewState extends State<AtlasListView> {
  AtlasController? _ownController;

  AtlasController get _controller =>
      widget.controller ?? (_ownController ??= AtlasController());

  @override
  void didUpdateWidget(AtlasListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null && _ownController != null) {
      _ownController!.dispose();
      _ownController = null;
    }
  }

  @override
  void dispose() {
    _ownController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    Widget sliver = SliverAtlasList(
      controller: controller,
      anchorMode: widget.anchorMode,
      initialIndex: widget.initialIndex,
      initialAlignment: widget.initialAlignment,
      estimator: widget.estimator,
      delegate: SliverChildBuilderDelegate(
        widget.itemBuilder,
        childCount: widget.itemCount,
        findChildIndexCallback: widget.findChildIndexCallback,
        addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.addRepaintBoundaries,
      ),
    );
    final padding = widget.padding;
    if (padding != null) {
      sliver = SliverPadding(padding: padding, sliver: sliver);
    }
    return CustomScrollView(
      controller: controller.scrollController,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      physics: widget.physics,
      cacheExtent: widget.cacheExtent,
      slivers: [sliver],
    );
  }
}
