import 'package:flutter/material.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

/// Extent of the pinned bar above the sections.
const double barExtent = 100;

/// Extent of a section header.
const double headerExtent = 40;

/// Extent of an item.
const double itemExtent = 50;

/// Items per section: the last section is short.
const List<int> sectionSizes = <int>[10, 6, 12, 8, 2];

/// Id of section [i].
String sectionId(int i) => 'section-$i';

/// A pinned box of [barExtent].
class PinnedBar extends SliverPersistentHeaderDelegate {
  const PinnedBar({this.child});

  final Widget? child;

  @override
  double get minExtent => barExtent;

  @override
  double get maxExtent => barExtent;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) =>
      SizedBox.expand(child: child ?? const ColoredBox(color: Colors.blue));

  @override
  bool shouldRebuild(PinnedBar oldDelegate) => oldDelegate.child != child;
}

/// Sections with sticky headers under a pinned bar.
List<Widget> sections() => <Widget>[
      for (var s = 0; s < sectionSizes.length; s++)
        SliverAtlasSection(
          id: sectionId(s),
          header: (context, stuck) => SizedBox(
            key: ValueKey<String>('header-$s'),
            height: headerExtent,
            child: Text('Header $s'),
          ),
          sliver: SliverAtlasList.builder(
            id: 'items-$s',
            itemCount: sectionSizes[s],
            itemBuilder: (context, i) => SizedBox(
              key: ValueKey<String>('item-$s-$i'),
              height: itemExtent,
              child: Text('$s.$i'),
            ),
          ),
        ),
    ];
