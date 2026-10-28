import 'package:flutter/foundation.dart';

import '../../core/scroll_target.dart';

/// Hands one pending [ScrollTarget] from an engine to its sliver.
///
/// The engine writes, the render object takes. Listeners are told when a new
/// request arrives so the sliver can mark itself for layout.
final class AnchorRequests extends ChangeNotifier {
  ScrollTarget? _pending;

  /// The target waiting for the next layout, if any.
  ScrollTarget? get pending => _pending;

  /// Queues [target], replacing an older request.
  void request(ScrollTarget target) {
    _pending = target;
    notifyListeners();
  }

  /// Returns and clears the pending target.
  ScrollTarget? take() {
    final target = _pending;
    _pending = null;
    return target;
  }
}
