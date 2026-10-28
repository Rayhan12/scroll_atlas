import 'package:flutter/widgets.dart';
import 'package:scroll_atlas/scroll_atlas.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

/// scrollable_positioned_list 0.3.8, the package most apps use today.
final class PositionedListEngine implements IndexedScrollEngine {
  final ItemScrollController _controller = ItemScrollController();

  @override
  String get id => 'scrollable_positioned_list';

  @override
  Widget buildList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) => ScrollablePositionedList.builder(
    itemScrollController: _controller,
    itemCount: itemCount,
    itemBuilder: itemBuilder,
  );

  @override
  void jumpToIndex(int index, {double alignment = 0}) =>
      _controller.jumpTo(index: index, alignment: alignment);

  @override
  Future<void> animateToIndex(
    int index, {
    required Duration duration,
    Curve curve = Curves.easeInOut,
    double alignment = 0,
  }) => _controller.scrollTo(
    index: index,
    duration: duration,
    curve: curve,
    alignment: alignment,
  );

  @override
  void dispose() {}
}
