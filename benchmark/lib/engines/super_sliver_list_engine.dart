import 'package:flutter/widgets.dart';
import 'package:scroll_atlas/scroll_atlas.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../measure/alignment_convention.dart';

/// Option (b): super_sliver_list 0.4.1 behind the same interface.
final class SuperSliverListEngine
    implements IndexedScrollEngine, DeclaresAlignmentConvention {
  @override
  AlignmentConvention get alignmentConvention => AlignmentConvention.reveal;

  final ScrollController _scroll = ScrollController();
  final ListController _list = ListController();

  @override
  String get id => 'super_sliver_list';

  @override
  Widget buildList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
  }) => SuperListView.builder(
    controller: _scroll,
    listController: _list,
    itemCount: itemCount,
    itemBuilder: itemBuilder,
    findChildIndexCallback: findChildIndexCallback,
  );

  @override
  void jumpToIndex(int index, {double alignment = 0}) => _list.jumpToItem(
    index: index,
    scrollController: _scroll,
    alignment: alignment,
  );

  @override
  Future<void> animateToIndex(
    int index, {
    required Duration duration,
    Curve curve = Curves.easeInOut,
    double alignment = 0,
  }) {
    _list.animateToItem(
      index: index,
      scrollController: _scroll,
      alignment: alignment,
      duration: (_) => duration,
      curve: (_) => curve,
    );
    return Future<void>.delayed(duration);
  }

  @override
  void dispose() {
    _list.dispose();
    _scroll.dispose();
  }
}
