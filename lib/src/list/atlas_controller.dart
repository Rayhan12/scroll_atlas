import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../core/alignment_math.dart';
import '../core/glide_path.dart';
import '../core/index_fraction.dart';
import '../core/scroll_target.dart';
import '../engine/list_engine.dart';
import 'atlas_list_layout.dart';
import 'atlas_options.dart';
import 'glide_scroll_activity.dart';

/// Jumps and animates an Atlas list to an item index.
///
/// Give the same controller to an `AtlasListView` (or to a
/// `SliverAtlasList` plus a `CustomScrollView` that uses
/// [scrollController]). Alignment 0 puts the item's leading edge at the
/// viewport's leading edge, 0.5 at the middle, the same meaning as
/// scrollable_positioned_list.
class AtlasController implements AtlasLayoutRegistry, IndexJumper {
  /// Creates a controller. Pass [scrollController] to share one; otherwise
  /// the controller creates its own and disposes it in [dispose].
  AtlasController({ScrollController? scrollController})
      : _ownsScrollController = scrollController == null,
        scrollController = scrollController ?? ScrollController();

  /// The pixel controller of the scroll view that hosts the list.
  final ScrollController scrollController;
  final bool _ownsScrollController;

  AtlasListLayout? _layout;
  ScrollTarget? _pendingTarget;

  /// Whether a list is attached.
  bool get isAttached => _layout != null && scrollController.hasClients;

  @override
  void attachLayout(AtlasListLayout layout) {
    assert(
      _layout == null || identical(_layout, layout),
      'An AtlasController can drive only one Atlas list at a time.',
    );
    _layout = layout;
    final pending = _pendingTarget;
    _pendingTarget = null;
    if (pending != null) layout.anchorNextLayout(pending);
  }

  @override
  void detachLayout(AtlasListLayout layout) {
    if (identical(_layout, layout)) _layout = null;
  }

  /// Moves at once so that item [index] has its leading edge at
  /// [alignment] of the viewport. Lands exactly in the next frame, without
  /// building the items in between.
  ///
  /// An out-of-range [index] fails an assertion in debug builds and is
  /// clamped in release builds. Before a list is attached, the jump is
  /// kept and applied to the first layout.
  void jumpTo({required int index, double alignment = 0}) {
    final layout = _layout;
    if (layout == null || !scrollController.hasClients) {
      assert(index >= 0, 'index must not be negative, got $index.');
      _pendingTarget =
          ScrollTarget(index < 0 ? 0 : index, alignment: alignment);
      return;
    }
    final target = _targetFor(layout, index, alignment);
    final position = scrollController.position;
    if (layout.isBuilt(target.index)) {
      position.jumpTo(_clamp(_pixelsFor(layout, target)));
      return;
    }
    layout.anchorNextLayout(target);
    position.jumpTo(_clamp(_pixelsFor(layout, target)));
  }

  /// Animates to item [index] over [duration] and lands exactly on
  /// [alignment], with no snap at the end, however far the item is
  ///. The future completes when the animation ends or when the
  /// user (or another jump) interrupts it.
  Future<void> animateTo({
    required int index,
    required Duration duration,
    double alignment = 0,
    Curve curve = Curves.easeInOut,
    AtlasLongDistance longDistance = AtlasLongDistance.glide,
  }) async {
    final layout = _layout;
    if (layout == null || !scrollController.hasClients) {
      jumpTo(index: index, alignment: alignment);
      return;
    }
    final target = _targetFor(layout, index, alignment);
    final position = scrollController.position;
    final viewport = position.viewportDimension;
    double aim() => _clamp(_pixelsFor(layout, target));

    if (longDistance == AtlasLongDistance.jumpThenAnimate) {
      final gap = aim() - position.pixels;
      if (gap.abs() > 2 * viewport) {
        position.jumpTo(aim() - gap.sign * viewport);
      }
    }
    if (position is! ScrollActivityDelegate) {
      await position.animateTo(aim(), duration: duration, curve: curve);
      return;
    }
    final activity = GlideScrollActivity(
      position as ScrollActivityDelegate,
      target: aim,
      pixels: () => position.pixels,
      path: GlidePath(
        distance: (aim() - position.pixels).abs(),
        scale: GlidePath.scaleFor(viewport),
      ),
      duration: duration,
      curve: curve,
      vsync: position.context.vsync,
    );
    layout.freezeEstimates(frozen: true);
    position.beginActivity(activity);
    final reached = await activity.done;
    layout.freezeEstimates(frozen: false);
    if (!reached) return;
    // The last frame's layout has not run yet; settle after it.
    await SchedulerBinding.instance.endOfFrame;
    if (identical(_layout, layout) && scrollController.hasClients) {
      _settle(layout, target);
    }
  }

  /// Removes any sub-pixel difference left after an animation, for example
  /// when the last frame's layout measured items above the target.
  void _settle(AtlasListLayout layout, ScrollTarget target) {
    if (!layout.isBuilt(target.index)) return;
    final position = scrollController.position;
    final exact = _clamp(_pixelsFor(layout, target));
    if ((exact - position.pixels).abs() > 0.01) position.jumpTo(exact);
  }

  /// Number of items in the attached list, 0 when none is attached.
  int get itemCount => _layout?.itemCount ?? 0;

  /// The visible items in fractional indexes, or null before layout.
  IndexSpan? get visibleSpan => _layout?.visibleSpan;

  /// Scroll position as a fraction of items, 0 at the start and 1 at the
  /// end. Unlike a pixel fraction it does not jump when estimated
  /// items get measured. Null before layout.
  double? get scrollFraction {
    final layout = _layout;
    final span = layout?.visibleSpan;
    if (layout == null || span == null) return null;
    return IndexFraction.of(span, layout.itemCount);
  }

  /// Jumps so that [scrollFraction] becomes [fraction] (scrollbar drag).
  void jumpToFraction(double fraction) {
    final layout = _layout;
    final span = layout?.visibleSpan;
    final viewport = layout?.viewportExtent;
    if (layout == null || span == null || viewport == null) return;
    if (layout.itemCount == 0 || viewport <= 0) return;
    if (fraction >= 1) {
      // The visible count near the end is unknown here; aiming the last item
      // at the top lets the trailing-gap correction settle on the true end.
      jumpTo(index: layout.itemCount - 1);
      return;
    }
    final leading = IndexFraction.leadingIndexFor(
      fraction,
      itemCount: layout.itemCount,
      visibleItems: span.length,
    );
    final index = leading.floor().clamp(0, layout.itemCount - 1);
    final into = (leading - index) * layout.extentOf(index);
    jumpTo(index: index, alignment: -into / viewport);
  }

  ScrollTarget _targetFor(AtlasListLayout layout, int index, double alignment) {
    final count = layout.itemCount;
    assert(
      index >= 0 && index < count,
      'index $index is out of range for a list of $count items.',
    );
    return ScrollTarget(count == 0 ? 0 : index.clamp(0, count - 1),
        alignment: alignment);
  }

  double _pixelsFor(AtlasListLayout layout, ScrollTarget target) =>
      AlignmentMath.scrollOffsetFor(
        itemLeadingOffset: layout.leadingOffsetOf(target.index),
        alignment: target.alignment,
        viewportExtent: layout.viewportExtent ??
            scrollController.position.viewportDimension,
      );

  double _clamp(double pixels) {
    final position = scrollController.position;
    return pixels.clamp(position.minScrollExtent, position.maxScrollExtent);
  }

  // IndexJumper, so code written against the engine interface works too.

  @override
  void jumpToIndex(int index, {double alignment = 0}) =>
      jumpTo(index: index, alignment: alignment);

  @override
  Future<void> animateToIndex(
    int index, {
    required Duration duration,
    Curve curve = Curves.easeInOut,
    double alignment = 0,
  }) =>
      animateTo(
        index: index,
        duration: duration,
        curve: curve,
        alignment: alignment,
      );

  /// Releases the scroll controller if this controller created it.
  void dispose() {
    if (_ownsScrollController) scrollController.dispose();
  }
}
