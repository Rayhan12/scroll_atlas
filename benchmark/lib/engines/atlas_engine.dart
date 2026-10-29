import 'package:flutter/widgets.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'sticky_sections_engine.dart';

/// Option (a), decided: the public scroll_atlas engine
/// ([AtlasListView] with an [AtlasController]) behind the same interface.
/// It also builds sticky sections for B4 ([AtlasScrollView] with
/// [SliverAtlasSection]s).
final class AtlasEngine implements IndexedScrollEngine, StickySectionsEngine {
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
  Widget buildSections({
    required double barExtent,
    required double headerExtent,
    required List<int> itemCounts,
    required SectionItemBuilder itemBuilder,
  }) => AtlasScrollView(
    controller: _controller,
    slivers: <Widget>[
      SliverPersistentHeader(pinned: true, delegate: _Bar(barExtent)),
      for (var section = 0; section < itemCounts.length; section++)
        SliverAtlasSection(
          id: 'section-$section',
          header: (context, stuck) => SizedBox(height: headerExtent),
          sliver: SliverAtlasList.builder(
            id: 'items-$section',
            itemCount: itemCounts[section],
            itemBuilder:
                (context, index) => itemBuilder(context, section, index),
          ),
        ),
    ],
  );

  @override
  void jumpToSectionItem(int section, int index, {double alignment = 0}) =>
      _controller.jumpTo(
        target: AtlasTarget.item('items-$section', index),
        alignment: alignment,
      );

  @override
  void dispose() => _controller.dispose();
}

/// A fixed pinned bar, the app bar of B4 without Material.
final class _Bar extends SliverPersistentHeaderDelegate {
  const _Bar(this.extent);

  final double extent;

  @override
  double get minExtent => extent;

  @override
  double get maxExtent => extent;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) =>
      SizedBox(height: extent);

  @override
  bool shouldRebuild(_Bar oldDelegate) => oldDelegate.extent != extent;
}
