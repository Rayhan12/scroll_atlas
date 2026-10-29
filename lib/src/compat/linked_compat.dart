import 'package:flutter/widgets.dart';

import '../linked/linked_scroll_group.dart';

/// Drop-in for linked_scroll_controller 0.2.0's
/// `LinkedScrollControllerGroup`, built on [LinkedScrollGroup].
///
/// New code should use [LinkedScrollGroup] directly.
///
/// ```dart
/// final group = LinkedScrollControllerGroup();
/// final header = group.addAndGet();
/// final body = group.addAndGet();
/// group.addOffsetChangedListener(() => debugPrint('x = ${group.offset}'));
/// ```
class LinkedScrollControllerGroup extends LinkedScrollGroup {
  final Map<VoidCallback, LinkedOffsetListener> _changed = {};

  /// Creates a controller linked to the others, starting at [offset].
  /// Dispose it when its scroll view goes away.
  ScrollController addAndGet() => createController();

  /// Calls [onChanged] every time [offset] changes.
  void addOffsetChangedListener(VoidCallback onChanged) {
    void listener(double _) => onChanged();
    removeOffsetChangedListener(onChanged);
    _changed[onChanged] = listener;
    addOffsetListener(listener);
  }

  /// Stops calling [listener].
  void removeOffsetChangedListener(VoidCallback listener) {
    final mapped = _changed.remove(listener);
    if (mapped != null) removeOffsetListener(mapped);
  }

  /// Jumps every member back to 0.
  void resetScroll() => jumpTo(0);
}
