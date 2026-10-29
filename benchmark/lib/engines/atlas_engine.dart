import 'package:flutter/widgets.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

/// Option (a), decided: the public scroll_atlas engine
/// ([AtlasListView] with an [AtlasController]) behind the same interface.
final class AtlasEngine implements IndexedScrollEngine {
  final AtlasController _controller = AtlasController();

  @override
  String get id => 'scroll_atlas';

  @override
  Widget buildList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
  }) => AtlasListView.builder(
    controller: _controller,
    itemCount: itemCount,
    itemBuilder: itemBuilder,
    findChildIndexCallback: findChildIndexCallback,
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
  }) => _controller.animateTo(
    index: index,
    duration: duration,
    curve: curve,
    alignment: alignment,
  );

  @override
  void dispose() => _controller.dispose();
}
