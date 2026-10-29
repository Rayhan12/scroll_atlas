import 'package:flutter/widgets.dart';

/// Whether an Atlas list should publish layout side effects while it is
/// laid out.
abstract final class AtlasVisibility {
  /// True when [context] is under an enabled [TickerMode].
  ///
  /// Hidden [IndexedStack] children disable ticker mode through
  /// [Visibility.maintainState], so lists in inactive tabs skip visible-item
  /// notifications until they become active again.
  static bool layoutUpdatesEnabled(BuildContext context) =>
      TickerMode.of(context);
}
