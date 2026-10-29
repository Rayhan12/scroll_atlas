import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../core/item_position.dart';
import '../list/atlas_controller.dart';

/// Tracks which section of an `AtlasScrollView` is active.
///
/// The active section is the last one in [sectionIds] whose leading edge
/// (its header) has reached the bottom of what is pinned above it, such as
/// a pinned app bar with a tab bar. At the end of the scroll the last
/// section is active, even when it is too short to reach the pinned area.
///
/// While [locked] (a tab tap is animating), [value] keeps its last value;
/// [unlock] catches up with the current scroll position.
class AtlasScrollSpy extends ChangeNotifier implements ValueListenable<int> {
  /// Creates a spy over [sectionIds], in scroll order, of the sections
  /// registered with [controller].
  AtlasScrollSpy({
    required this.controller,
    required List<String> sectionIds,
  }) : sectionIds = List.unmodifiable(sectionIds) {
    controller.scrollController.addListener(_scheduleUpdate);
    controller.positions.addListener(update);
  }

  /// The controller whose sections are tracked.
  final AtlasController controller;

  /// Ids of the tracked sections, in scroll order.
  final List<String> sectionIds;

  int _value = 0;
  int _locks = 0;
  double? _heldAt;
  bool _scheduled = false;
  bool _disposed = false;

  @override
  int get value => _value;

  /// Whether updates are paused.
  bool get locked => _locks > 0;

  /// Pauses updates, for example while a tapped tab animates the view.
  /// Calls nest: each [lock] needs an [unlock].
  void lock() => _locks++;

  /// Resumes updates and catches up with the scroll position.
  void unlock() {
    if (_locks == 0) return;
    _locks--;
    update();
  }

  /// Makes section [index] active until the view scrolls. A tab bar calls
  /// it when a tapped section has landed but could not reach the pinned
  /// area, such as a short section near the end.
  void hold(int index) {
    assert(index >= 0 && index < sectionIds.length, 'index out of range');
    final scroll = controller.scrollController;
    _heldAt = scroll.hasClients ? scroll.position.pixels : null;
    if (index == _value) return;
    _value = index;
    notifyListeners();
  }

  /// Computes the active section from the last layout.
  void update() {
    if (locked || _disposed || !controller.scrollController.hasClients) {
      return;
    }
    final position = controller.scrollController.position;
    if (!position.hasContentDimensions || !position.hasPixels) return;
    final held = _heldAt;
    if (held != null) {
      if ((position.pixels - held).abs() <= ScrollSpyMath.tolerance) return;
      _heldAt = null;
    }
    final next = ScrollSpyMath.activeIndex(
      sectionTops: [for (final id in sectionIds) controller.leadingEdgeOf(id)],
      pinnedBottoms: [
        for (final id in sectionIds) controller.obstructionAbove(id) ?? 0,
      ],
      atEnd:
          position.pixels >= position.maxScrollExtent - ScrollSpyMath.tolerance,
    );
    if (next == _value) return;
    _value = next;
    notifyListeners();
  }

  // The scroll controller notifies before layout: read after it.
  void _scheduleUpdate() {
    if (_scheduled) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      update();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _disposed = true;
    controller.scrollController.removeListener(_scheduleUpdate);
    controller.positions.removeListener(update);
    super.dispose();
  }
}
