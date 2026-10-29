import '../core/index_fraction.dart';
import '../core/item_position.dart';
import '../core/scroll_target.dart';

/// What a controller can ask of any attached Atlas target sliver (an Atlas
/// list, a `SliverAtlasSection` or an `AtlasAnchor`). Render objects
/// implement it; controllers depend on this interface only (dependency
/// inversion), so they never touch render objects or the extent cache.
abstract interface class AtlasTargetLayout {
  /// Id the sliver registered with, or null for an unnamed list.
  String? get id;

  /// Number of addressable positions: items for a list, 1 for a sliver.
  int get itemCount;

  /// Main axis extent of the viewport, or null before the first layout.
  double? get viewportExtent;

  /// Whether position [index] is laid out, so its offset is exact.
  bool isBuilt(int index);

  /// Scroll offset of position [index]'s leading edge in the scroll view's
  /// coordinates: exact when it is built, estimated otherwise.
  double leadingOffsetOf(int index);

  /// Extent pinned above this sliver's leading edge (pinned app bars and
  /// enclosing stuck headers), as last measured or estimated.
  double get pinnedObstruction;

  /// Places [target] exactly at its alignment in the next layout.
  void anchorNextLayout(ScrollTarget target);
}

/// What a controller can additionally ask of an Atlas list.
abstract interface class AtlasListLayout implements AtlasTargetLayout {
  /// Measured or estimated main axis extent of item [index].
  double extentOf(int index);

  /// While [frozen], newly measured extents are not recorded, so estimated
  /// offsets of unbuilt items stay put. An animation freezes estimates so
  /// that its target does not wander while it crosses unbuilt items.
  void freezeEstimates({required bool frozen});

  /// Visible items in fractional indexes, or null before layout.
  IndexSpan? get visibleSpan;

  /// Built items with at least one pixel in the unobstructed viewport, in
  /// index order, as of the last layout.
  List<AtlasItemPosition> get visiblePositions;

  /// When false, [AtlasLayoutRegistry.layoutChanged] and visible-item
  /// collection skip this list (see [AtlasVisibility]).
  bool get layoutUpdatesEnabled;
}

/// Where an Atlas sliver registers its layout so that a controller can
/// reach it. Implemented by `AtlasController`.
abstract interface class AtlasLayoutRegistry {
  /// Called when the sliver attaches.
  void attachLayout(AtlasTargetLayout layout);

  /// Called when the sliver detaches.
  void detachLayout(AtlasTargetLayout layout);

  /// Called after each layout of the sliver, so that listeners of what is
  /// visible can be told once the frame is done.
  void layoutChanged(AtlasTargetLayout layout);

  /// Re-runs placement for the last [jumpTo] on [layout] when it becomes
  /// active again.
  void refreshLayout(AtlasTargetLayout layout);

  /// Extra obstruction from [AtlasController.pinnedInset] or
  /// [AtlasScope.pinnedInset], applied during placement.
  double get pinnedInset;
}
