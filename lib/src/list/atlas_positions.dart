import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

import '../core/item_position.dart';

/// Collects the visible items of every attached Atlas list and tells
/// listeners at most once per frame, after layout, and only when something
/// moved.
class AtlasPositionsNotifier extends ChangeNotifier
    implements ValueListenable<List<AtlasItemPosition>> {
  /// Creates a notifier that reads positions with [collect].
  AtlasPositionsNotifier(this._collect);

  final List<AtlasItemPosition> Function() _collect;
  List<AtlasItemPosition> _value = const <AtlasItemPosition>[];
  bool _scheduled = false;
  bool _disposed = false;

  @override
  List<AtlasItemPosition> get value => _value;

  /// Asks for an update after the current frame. Calls within the same
  /// frame are merged into one.
  void schedule() {
    if (_scheduled || _disposed) return;
    _scheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (_disposed) return;
      update();
    });
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  /// Reads the positions now and notifies when they changed.
  void update() {
    final next = List<AtlasItemPosition>.unmodifiable(_collect());
    if (listEquals(next, _value)) return;
    _value = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
