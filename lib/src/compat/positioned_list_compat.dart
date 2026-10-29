import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/item_position.dart';
import '../list/atlas_controller.dart';
import '../list/atlas_list_view.dart';

/// scrollable_positioned_list's `ItemPosition`. Same fields, same equality.
typedef ItemPosition = AtlasItemPosition;

const String _noShrinkWrap =
    'scroll_atlas lists do not shrink-wrap. Give the list a bounded size, '
    'for example with SizedBox or Expanded, and use AtlasListView.';

/// Drop-in for scrollable_positioned_list 0.3.8's
/// `ScrollablePositionedList`, built on [AtlasListView].
///
/// New code should use [AtlasListView] and [AtlasController] directly.
class ScrollablePositionedList extends StatefulWidget {
  /// Same as `ScrollablePositionedList.builder`.
  const ScrollablePositionedList.builder({
    required this.itemCount,
    required this.itemBuilder,
    super.key,
    this.itemScrollController,
    @Deprecated(_noShrinkWrap) this.shrinkWrap = false,
    this.itemPositionsListener,
    this.scrollOffsetController,
    this.scrollOffsetListener,
    this.initialScrollIndex = 0,
    this.initialAlignment = 0,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
    this.semanticChildCount,
    this.padding,
    this.addSemanticIndexes = true,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.minCacheExtent,
  }) : separatorBuilder = null;

  /// Same as `ScrollablePositionedList.separated`. Indexes are item
  /// indexes; separators never get one.
  const ScrollablePositionedList.separated({
    required this.itemCount,
    required this.itemBuilder,
    required IndexedWidgetBuilder this.separatorBuilder,
    super.key,
    this.itemScrollController,
    @Deprecated(_noShrinkWrap) this.shrinkWrap = false,
    this.itemPositionsListener,
    this.scrollOffsetController,
    this.scrollOffsetListener,
    this.initialScrollIndex = 0,
    this.initialAlignment = 0,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
    this.semanticChildCount,
    this.padding,
    this.addSemanticIndexes = true,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.minCacheExtent,
  });

  /// Number of items.
  final int itemCount;

  /// Builds item `index`.
  final IndexedWidgetBuilder itemBuilder;

  /// Builds the separator after item `index`, or null for `builder`.
  final IndexedWidgetBuilder? separatorBuilder;

  /// Jumps and scrolls to items. Maps to [AtlasController].
  final ItemScrollController? itemScrollController;

  /// Not supported. Asserts when true.
  @Deprecated(_noShrinkWrap)
  final bool shrinkWrap;

  /// Reports visible item positions. Maps to [AtlasController.positions].
  final ItemPositionsListener? itemPositionsListener;

  /// Scrolls by pixels. Maps to [AtlasController.animateBy].
  final ScrollOffsetController? scrollOffsetController;

  /// Reports scroll deltas.
  final ScrollOffsetListener? scrollOffsetListener;

  /// Item shown first. Maps to [AtlasListView.initialIndex].
  final int initialScrollIndex;

  /// Where [initialScrollIndex] sits. Maps to
  /// [AtlasListView.initialAlignment].
  final double initialAlignment;

  /// Scroll axis.
  final Axis scrollDirection;

  /// Whether the list scrolls from the far end.
  final bool reverse;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Number of semantic children; defaults to [itemCount].
  final int? semanticChildCount;

  /// Padding around the items.
  final EdgeInsets? padding;

  /// Whether items get semantic indexes.
  final bool addSemanticIndexes;

  /// Whether items are kept alive.
  final bool addAutomaticKeepAlives;

  /// Whether items get repaint boundaries.
  final bool addRepaintBoundaries;

  /// Pixels laid out beyond each edge. Maps to [AtlasListView.cacheExtent].
  final double? minCacheExtent;

  @override
  State<ScrollablePositionedList> createState() =>
      _ScrollablePositionedListState();
}

class _ScrollablePositionedListState extends State<ScrollablePositionedList> {
  final AtlasController _atlas = AtlasController();

  @override
  void initState() {
    super.initState();
    _bind(widget);
  }

  @override
  void didUpdateWidget(ScrollablePositionedList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unbind(oldWidget);
    _bind(widget);
  }

  @override
  void dispose() {
    _unbind(widget);
    _atlas.dispose();
    super.dispose();
  }

  void _bind(ScrollablePositionedList list) {
    // ignore: deprecated_member_use_from_same_package
    assert(!list.shrinkWrap, _noShrinkWrap);
    list.itemScrollController?._attach(_atlas);
    list.scrollOffsetController?._attach(_atlas);
    _positionsOf(list)?._attach(_atlas);
  }

  void _unbind(ScrollablePositionedList list) {
    list.itemScrollController?._detach(_atlas);
    list.scrollOffsetController?._detach(_atlas);
    _positionsOf(list)?._detach(_atlas);
  }

  static _ItemPositionsNotifier? _positionsOf(ScrollablePositionedList list) =>
      list.itemPositionsListener as _ItemPositionsNotifier?;

  @override
  Widget build(BuildContext context) {
    final separator = widget.separatorBuilder;
    final Widget list = AtlasListView.builder(
      itemCount: widget.itemCount,
      itemBuilder: separator == null
          ? widget.itemBuilder
          : separatedItemBuilder(
              itemBuilder: widget.itemBuilder,
              separatorBuilder: separator,
              itemCount: widget.itemCount,
              scrollDirection: widget.scrollDirection,
              reverse: widget.reverse,
            ),
      controller: _atlas,
      initialIndex: widget.initialScrollIndex,
      initialAlignment: widget.initialAlignment,
      scrollDirection: widget.scrollDirection,
      reverse: widget.reverse,
      physics: widget.physics,
      padding: widget.padding,
      cacheExtent: widget.minCacheExtent,
      addAutomaticKeepAlives: widget.addAutomaticKeepAlives,
      addRepaintBoundaries: widget.addRepaintBoundaries,
      addSemanticIndexes: widget.addSemanticIndexes,
      semanticChildCount: widget.semanticChildCount,
    );
    final offsets = widget.scrollOffsetListener as _ScrollOffsetNotifier?;
    if (offsets == null) return list;
    return NotificationListener<ScrollUpdateNotification>(
      onNotification: (notification) {
        if (notification.depth == 0) offsets._report(notification);
        return false;
      },
      child: list,
    );
  }
}

/// Mixin for the controllers a [ScrollablePositionedList] attaches to its
/// [AtlasController].
mixin _Attachable {
  AtlasController? _atlas;

  /// Whether a list is using this controller.
  bool get isAttached => _atlas != null;

  AtlasController get _attached {
    assert(isAttached, '$runtimeType is not attached to a list.');
    return _atlas!;
  }

  void _attach(AtlasController atlas) {
    assert(
      _atlas == null || identical(_atlas, atlas),
      '$runtimeType is already attached to another list.',
    );
    _atlas = atlas;
  }

  void _detach(AtlasController atlas) {
    if (identical(_atlas, atlas)) _atlas = null;
  }
}

/// Same as scrollable_positioned_list's `ItemScrollController`.
class ItemScrollController with _Attachable {
  /// Shows item [index] at [alignment] (0 is the leading edge, 1 the
  /// trailing edge) without animation.
  void jumpTo({required int index, double alignment = 0}) =>
      _attached.jumpTo(index: index, alignment: alignment);

  /// Animates to item [index] at [alignment] over [duration].
  ///
  /// Long distances glide instead of cross fading, so
  /// [opacityAnimationWeights] has no effect.
  Future<void> scrollTo({
    required int index,
    required Duration duration,
    double alignment = 0,
    Curve curve = Curves.linear,
    @Deprecated('scroll_atlas glides instead of cross fading; remove it.')
    List<double> opacityAnimationWeights = const [40, 20, 40],
  }) =>
      _attached.animateTo(
        index: index,
        alignment: alignment,
        duration: duration,
        curve: curve,
      );
}

/// Same as scrollable_positioned_list's `ScrollOffsetController`.
class ScrollOffsetController with _Attachable {
  /// Animates the scroll offset by [offset] pixels. Maps to
  /// [AtlasController.animateBy].
  Future<void> animateScroll({
    required double offset,
    required Duration duration,
    Curve curve = Curves.linear,
  }) =>
      _attached.animateBy(offset: offset, duration: duration, curve: curve);
}

/// Same as scrollable_positioned_list's `ItemPositionsListener`.
abstract class ItemPositionsListener {
  /// Creates a listener to pass to a [ScrollablePositionedList].
  factory ItemPositionsListener.create() = _ItemPositionsNotifier;

  /// Visible items, updated after every layout.
  ValueListenable<Iterable<ItemPosition>> get itemPositions;
}

class _ItemPositionsNotifier with _Attachable implements ItemPositionsListener {
  @override
  final ValueNotifier<Iterable<ItemPosition>> itemPositions =
      ValueNotifier<Iterable<ItemPosition>>(const []);

  void _sync() => itemPositions.value = _attached.positions.value;

  @override
  void _attach(AtlasController atlas) {
    super._attach(atlas);
    atlas.positions.addListener(_sync);
  }

  @override
  void _detach(AtlasController atlas) {
    atlas.positions.removeListener(_sync);
    super._detach(atlas);
  }
}

/// Same as scrollable_positioned_list's `ScrollOffsetListener`.
abstract class ScrollOffsetListener {
  /// Creates a listener to pass to a [ScrollablePositionedList]. With
  /// [recordProgrammaticScrolls] false only deltas from a finger on the
  /// list are reported; jumps, animations and the fling after a drag are
  /// not.
  factory ScrollOffsetListener.create({bool recordProgrammaticScrolls}) =
      _ScrollOffsetNotifier;

  /// Scroll deltas in pixels, positive towards the end. A broadcast
  /// stream.
  Stream<double> get changes;
}

class _ScrollOffsetNotifier implements ScrollOffsetListener {
  _ScrollOffsetNotifier({this.recordProgrammaticScrolls = true});

  final bool recordProgrammaticScrolls;
  final StreamController<double> _changes =
      StreamController<double>.broadcast();

  @override
  Stream<double> get changes => _changes.stream;

  void _report(ScrollUpdateNotification notification) {
    final delta = notification.scrollDelta;
    if (delta == null) return;
    if (!recordProgrammaticScrolls && notification.dragDetails == null) return;
    _changes.add(delta);
  }
}
