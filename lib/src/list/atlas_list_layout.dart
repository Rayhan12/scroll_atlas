import '../core/index_fraction.dart';
import '../core/scroll_target.dart';

/// What a controller can ask of an attached Atlas sliver. The render object
/// implements it; controllers depend on this interface only (dependency
/// inversion), so they never touch render objects or the extent cache.
abstract interface class AtlasListLayout {
  /// Number of items in the list.
  int get itemCount;

  /// Main axis extent of the viewport, or null before the first layout.
  double? get viewportExtent;

  /// Whether item [index] is built and laid out.
  bool isBuilt(int index);

  /// Scroll offset of item [index]'s leading edge in the scroll view's
  /// coordinates: exact when the item is built, estimated otherwise.
  double leadingOffsetOf(int index);

  /// Measured or estimated main axis extent of item [index].
  double extentOf(int index);

  /// While [frozen], newly measured extents are not recorded, so estimated
  /// offsets of unbuilt items stay put. An animation freezes estimates so
  /// that its target does not wander while it crosses unbuilt items.
  void freezeEstimates({required bool frozen});

  /// Places [target] exactly at its alignment in the next layout.
  void anchorNextLayout(ScrollTarget target);

  /// Visible items in fractional indexes, or null before layout.
  IndexSpan? get visibleSpan;
}

/// Where an Atlas sliver registers its layout so that a controller can
/// reach it. Implemented by `AtlasController`.
abstract interface class AtlasLayoutRegistry {
  /// Called when the sliver attaches.
  void attachLayout(AtlasListLayout layout);

  /// Called when the sliver detaches.
  void detachLayout(AtlasListLayout layout);
}
