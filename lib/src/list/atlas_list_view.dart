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
    this.itemExtent,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.semanticChildCount,
    super.key,
  }) : separatorBuilder = null;

  /// Creates a list with [separatorBuilder] between items.
  ///
  /// Indexes stay item indexes: `jumpTo(index: 7)` lands on item 7, and
  /// positions report items only. Each separator is laid out with the
  /// item before it, so that item's trailing edge includes it.
  const AtlasListView.separated({
    required this.itemCount,
    required this.itemBuilder,
    required IndexedWidgetBuilder this.separatorBuilder,
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
    this.itemExtent,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.semanticChildCount,
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

  /// When set, every item uses this main axis extent with an exact
  /// estimator. Do not combine with [estimator].
  final double? itemExtent;

  /// Same as in `SliverChildBuilderDelegate`.
  final bool addAutomaticKeepAlives;

  /// Same as in `SliverChildBuilderDelegate`.
  final bool addRepaintBoundaries;

  /// Whether items get semantic indexes, as in [ListView].
  final bool addSemanticIndexes;

  /// Number of semantic children; defaults to [itemCount].
  final int? semanticChildCount;

  /// Builds the separator after item `index`, for every item but the last.
  /// Null for [AtlasListView.builder].
  final IndexedWidgetBuilder? separatorBuilder;

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
      itemExtent: widget.itemExtent,
      delegate: SliverChildBuilderDelegate(
        _itemBuilder(),
        childCount: widget.itemCount,
        findChildIndexCallback: widget.findChildIndexCallback,
        addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
        addRepaintBoundaries: widget.addRepaintBoundaries,
        addSemanticIndexes: widget.addSemanticIndexes,
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
      semanticChildCount: widget.semanticChildCount ?? widget.itemCount,
      slivers: [sliver],
    );
  }

  NullableIndexedWidgetBuilder _itemBuilder() {
    final separator = widget.separatorBuilder;
    if (separator == null) return widget.itemBuilder;
    return separatedItemBuilder(
      itemBuilder: widget.itemBuilder,
      separatorBuilder: separator,
      itemCount: widget.itemCount,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
    );
  }
}

/// Wraps [itemBuilder] so every item but the last is followed by the
/// widget from [separatorBuilder], laid out with that item.
///
/// Used by [AtlasListView.separated] and the compat layer, so item
/// indexes never change meaning.
NullableIndexedWidgetBuilder separatedItemBuilder({
  required NullableIndexedWidgetBuilder itemBuilder,
  required IndexedWidgetBuilder separatorBuilder,
  required int itemCount,
  required Axis scrollDirection,
  required bool reverse,
}) {
  final last = itemCount - 1;
  return (BuildContext context, int index) {
    final child = itemBuilder(context, index);
    if (child == null || index >= last) return child;
    // The separator follows the item in scroll order, which is screen
    // order reversed when the list is.
    final pair = <Widget>[child, separatorBuilder(context, index)];
    return Flex(
      direction: scrollDirection,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: reverse ? pair.reversed.toList() : pair,
    );
  };
}
