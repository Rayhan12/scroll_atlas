import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../core/alignment_math.dart';
import '../core/atlas_target.dart';
import '../core/glide_path.dart';
import '../core/id_registry.dart';
import '../core/index_fraction.dart';
import '../core/item_position.dart';
import '../core/scroll_target.dart';
import '../engine/list_engine.dart';
import 'atlas_list_layout.dart';
import 'atlas_options.dart';
import 'atlas_positions.dart';
import 'glide_scroll_activity.dart';

/// Jumps and animates Atlas lists and other Atlas targets.
///
/// Give the same controller to an `AtlasListView`, or to an
/// `AtlasScrollView` whose slivers register by id. Alignment 0 puts the
/// target's leading edge at the viewport's leading edge, 0.5 at the
/// middle, the same meaning as scrollable_positioned_list. With
/// `respectPinned` (the default) the alignment is measured below whatever
/// is pinned above the target at its final position.
///
/// ```dart
/// final atlas = AtlasController();
///
/// AtlasListView.builder(
///   controller: atlas,
///   itemCount: 100000,
///   itemBuilder: (context, index) => ListTile(title: Text('Item $index')),
/// );
///
/// atlas.jumpTo(index: 75000, alignment: 0.5);
/// await atlas.animateTo(index: 10, duration: const Duration(milliseconds: 600));
/// atlas.dispose(); // in State.dispose
/// ```
class AtlasController implements AtlasLayoutRegistry, IndexJumper {
  /// Creates a controller. Pass [scrollController] to share one; otherwise
  /// the controller creates its own and disposes it in [dispose].
  AtlasController({ScrollController? scrollController})
      : _ownsScrollController = scrollController == null,
        scrollController = scrollController ?? ScrollController() {
    _positions = AtlasPositionsNotifier(_collectPositions);
  }

  /// The pixel controller of the scroll view that hosts the targets.
  final ScrollController scrollController;
  final bool _ownsScrollController;

  final IdRegistry<AtlasTargetLayout> _layouts =
      IdRegistry<AtlasTargetLayout>();
  _Jump? _pendingJump;
  late final AtlasPositionsNotifier _positions;

  /// Whether a target sliver is attached.
  bool get isAttached =>
      _layouts.values.isNotEmpty && scrollController.hasClients;

  @override
  void attachLayout(AtlasTargetLayout layout) {
    final error = _layouts.add(layout.id, layout);
    assert(error == null, error);
    final pending = _pendingJump;
    final resolved = pending == null ? null : _resolve(pending);
    if (resolved == null) return;
    _pendingJump = null;
    resolved.layout.anchorNextLayout(resolved.target);
  }

  @override
  void detachLayout(AtlasTargetLayout layout) {
    _layouts.remove(layout.id, layout);
    _positions.schedule();
  }

  @override
  void layoutChanged(AtlasTargetLayout layout) => _positions.schedule();

  /// The visible items of every attached Atlas list, each tagged with its
  /// list's id. Fractions are relative to the unobstructed
  /// viewport, as with scrollable_positioned_list's `ItemPosition`.
  /// Listeners are told at most once per frame, after layout.
  /// Use `inSliver`, `firstFullyVisible` and `mostVisible` to query it.
  ValueListenable<List<AtlasItemPosition>> get positions => _positions;

  List<AtlasItemPosition> _collectPositions() => [
        for (final layout in _layouts.values)
          if (layout is AtlasListLayout) ...layout.visiblePositions,
      ];

  /// Distance from the viewport's leading edge to the leading edge of the
  /// sliver with [id] (exact when built, estimated otherwise), or null
  /// when no such sliver is attached or the view has no position yet.
  double? leadingEdgeOf(String id) {
    final layout = _layouts[id];
    if (layout == null || !scrollController.hasClients) return null;
    final position = scrollController.position;
    if (!position.hasPixels) return null;
    return layout.leadingOffsetOf(0) - position.pixels;
  }

  /// What is pinned above the sliver with [id] once it is scrolled, or
  /// null when no such sliver is attached.
  double? obstructionAbove(String id) => _layouts[id]?.pinnedObstruction;

  /// The list that index based calls address: the unnamed list, or the
  /// only list.
  AtlasListLayout? get _primaryList {
    final unnamed = _layouts[null];
    if (unnamed is AtlasListLayout) return unnamed;
    final lists = _layouts.values.whereType<AtlasListLayout>();
    return lists.length == 1 ? lists.first : null;
  }

  /// Moves at once so that the target has its leading edge at [alignment]
  /// of the viewport, below what is pinned above it unless [respectPinned]
  /// is false, plus [padding] pixels. Lands exactly in the next frame,
  /// without building the items in between.
  ///
  /// Pass exactly one of [index] (an item of the only, or unnamed, list)
  /// and [target]. An out-of-range index fails an assertion in debug
  /// builds and is clamped in release builds. Before the target's sliver
  /// is attached, the jump is kept and applied to its first layout.
  void jumpTo({
    int? index,
    AtlasTarget? target,
    double alignment = 0,
    bool respectPinned = true,
    double padding = 0,
  }) {
    final jump = _Jump.of(
      index: index,
      target: target,
      alignment: alignment,
      respectPinned: respectPinned,
      padding: padding,
    );
    final resolved = _resolve(jump);
    if (resolved == null || !scrollController.hasClients) {
      _pendingJump = jump;
      return;
    }
    _pendingJump = null;
    resolved.layout.anchorNextLayout(resolved.target);
    scrollController.position.jumpTo(_clamp(_pixelsFor(resolved)));
    _clampAfterLayout();
  }

  /// Animates to the target over [duration] and lands exactly on
  /// [alignment], with no snap at the end, however far it is.
  /// Takes the same target arguments as [jumpTo]. The future completes
  /// when the animation ends or when the user (or another jump)
  /// interrupts it.
  Future<void> animateTo({
    required Duration duration,
    int? index,
    AtlasTarget? target,
    double alignment = 0,
    bool respectPinned = true,
    double padding = 0,
    Curve curve = Curves.easeInOut,
    AtlasLongDistance longDistance = AtlasLongDistance.glide,
  }) async {
    final jump = _Jump.of(
      index: index,
      target: target,
      alignment: alignment,
      respectPinned: respectPinned,
      padding: padding,
    );
    final resolved = _resolve(jump);
    if (resolved == null || !scrollController.hasClients) {
      jumpTo(
        index: index,
        target: target,
        alignment: alignment,
        respectPinned: respectPinned,
        padding: padding,
      );
      return;
    }
    final layout = resolved.layout;
    final position = scrollController.position;
    final viewport = position.viewportDimension;
    double aim() => _clamp(_pixelsFor(resolved));

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
    final list = layout is AtlasListLayout ? layout : null;
    list?.freezeEstimates(frozen: true);
    position.beginActivity(activity);
    final reached = await activity.done;
    list?.freezeEstimates(frozen: false);
    if (!reached) return;
    // The last frame's layout has not run yet; settle after it.
    await SchedulerBinding.instance.endOfFrame;
    if (identical(_layouts[layout.id], layout) && scrollController.hasClients) {
      _settle(resolved);
    }
  }

  /// Animates the scroll offset by [offset] pixels from where it is now,
  /// positive towards the end. Unlike [animateTo] it targets no item.
  Future<void> animateBy({
    required double offset,
    required Duration duration,
    Curve curve = Curves.linear,
  }) {
    final position = scrollController.position;
    return position.animateTo(
      position.pixels + offset,
      duration: duration,
      curve: curve,
    );
  }

  /// Removes any sub-pixel difference left after an animation, for example
  /// when the last frame's layout measured items above the target.
  void _settle(_Resolved resolved) {
    if (!resolved.layout.isBuilt(resolved.target.index)) return;
    final position = scrollController.position;
    final exact = _clamp(_pixelsFor(resolved));
    if ((exact - position.pixels).abs() <= 0.01) return;
    resolved.layout.anchorNextLayout(resolved.target);
    position.jumpTo(exact);
    _clampAfterLayout();
  }

  /// A placement correction can move past the end of the scroll view when
  /// the target is near its end and the targeted sliver is not the last
  /// one. Pulls the offset back in range right after that layout, before
  /// the physics animate it back.
  void _clampAfterLayout() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      final position = scrollController.position;
      final clamped = _clamp(position.pixels);
      if (clamped != position.pixels) position.jumpTo(clamped);
    });
  }

  /// Number of items in the only (or unnamed) list, 0 when none is
  /// attached.
  int get itemCount => _primaryList?.itemCount ?? 0;

  /// The visible items of the only (or unnamed) list in fractional
  /// indexes, or null before layout.
  IndexSpan? get visibleSpan => _primaryList?.visibleSpan;

  /// Scroll position as a fraction of items, 0 at the start and 1 at the
  /// end. Unlike a pixel fraction it does not jump when estimated
  /// items get measured. Null before layout.
  double? get scrollFraction {
    final layout = _primaryList;
    final span = layout?.visibleSpan;
    if (layout == null || span == null) return null;
    return IndexFraction.of(span, layout.itemCount);
  }

  /// Jumps so that [scrollFraction] becomes [fraction] (scrollbar drag).
  void jumpToFraction(double fraction) {
    final layout = _primaryList;
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

  _Resolved? _resolve(_Jump jump) {
    final layout = jump.target is AtlasIndexTarget
        ? _primaryList
        : _layouts[jump.target.sliverId];
    if (layout == null) return null;
    final count = layout.itemCount;
    final index = jump.target.index;
    assert(
      index >= 0 && index < count,
      'index $index is out of range for ${jump.target} with $count items.',
    );
    return _Resolved(
      layout,
      ScrollTarget(
        count == 0 ? 0 : index.clamp(0, count - 1),
        alignment: jump.alignment,
        respectPinned: jump.respectPinned,
        padding: jump.padding,
      ),
    );
  }

  double _pixelsFor(_Resolved resolved) {
    final layout = resolved.layout;
    final target = resolved.target;
    return AlignmentMath.scrollOffsetFor(
      itemLeadingOffset: layout.leadingOffsetOf(target.index),
      alignment: target.alignment,
      viewportExtent:
          layout.viewportExtent ?? scrollController.position.viewportDimension,
      leadingObstruction:
          (target.respectPinned ? layout.pinnedObstruction : 0) +
              target.padding,
    );
  }

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
    _positions.dispose();
    if (_ownsScrollController) scrollController.dispose();
  }
}

/// A requested jump, before it is resolved to a sliver.
final class _Jump {
  _Jump.of({
    required int? index,
    required AtlasTarget? target,
    required this.alignment,
    required this.respectPinned,
    required this.padding,
  })  : assert(
          (index == null) != (target == null),
          'Pass exactly one of index or target.',
        ),
        target = target ?? AtlasTarget.index(math.max(0, index ?? 0)) {
    assert(index == null || index >= 0, 'index must not be negative.');
  }

  final AtlasTarget target;
  final double alignment;
  final bool respectPinned;
  final double padding;
}

/// A jump resolved to the sliver that holds its target.
final class _Resolved {
  const _Resolved(this.layout, this.target);

  final AtlasTargetLayout layout;
  final ScrollTarget target;
}
