import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/src/core/item_position.dart';

AtlasItemPosition _p(int i, double lead, double trail, [String? id]) =>
    AtlasItemPosition(
      sliverId: id,
      index: i,
      itemLeadingEdge: lead,
      itemTrailingEdge: trail,
    );

void main() {
  group('AtlasItemPosition', () {
    test('equality, hash and toString', () {
      expect(_p(1, 0, 0.5, 'a'), _p(1, 0, 0.5, 'a'));
      expect(_p(1, 0, 0.5, 'a').hashCode, _p(1, 0, 0.5, 'a').hashCode);
      expect(_p(1, 0, 0.5, 'a'), isNot(_p(1, 0, 0.5, 'b')));
      expect(_p(1, 0, 0.5).toString(), 'AtlasItemPosition(#1, 0.0, 0.5)');
      expect(_p(2, 0, 1, 'x').toString(), contains('x#2'));
    });

    test('isFullyVisible and visibleFraction', () {
      expect(_p(0, 0, 1).isFullyVisible, isTrue);
      expect(_p(0, -0.1, 0.2).isFullyVisible, isFalse);
      expect(_p(0, 0.9, 1.2).isFullyVisible, isFalse);
      expect(_p(0, -0.1, 0.2).visibleFraction, closeTo(0.2, 1e-9));
      expect(_p(0, 0.9, 1.2).visibleFraction, closeTo(0.1, 1e-9));
    });
  });

  group('PositionMath.visible', () {
    test('fractions of the unobstructed viewport', () {
      final p = PositionMath.visible(
        sliverId: 's',
        index: 3,
        leading: 150,
        trailing: 250,
        obstruction: 100,
        viewportExtent: 600,
      )!;
      expect(p.sliverId, 's');
      expect(p.index, 3);
      expect(p.itemLeadingEdge, closeTo(0.1, 1e-12));
      expect(p.itemTrailingEdge, closeTo(0.3, 1e-12));
    });

    test('items under the obstruction or past the end are not visible', () {
      expect(
        PositionMath.visible(
          index: 0,
          leading: 0,
          trailing: 100,
          obstruction: 100,
          viewportExtent: 600,
        ),
        isNull,
      );
      expect(
        PositionMath.visible(
          index: 0,
          leading: 600,
          trailing: 700,
          obstruction: 0,
          viewportExtent: 600,
        ),
        isNull,
      );
      expect(
        PositionMath.visible(
          index: 0,
          leading: 0,
          trailing: 10,
          obstruction: 900,
          viewportExtent: 600,
        ),
        isNull,
      );
    });

    test('partly covered items get a negative leading edge', () {
      final p = PositionMath.visible(
        index: 0,
        leading: 50,
        trailing: 150,
        obstruction: 100,
        viewportExtent: 300,
      )!;
      expect(p.itemLeadingEdge, closeTo(-0.25, 1e-12));
      expect(p.itemTrailingEdge, closeTo(0.25, 1e-12));
    });
  });

  group('AtlasItemPositions helpers', () {
    final positions = [
      _p(4, -0.2, 0.1, 'a'),
      _p(5, 0.1, 0.5, 'a'),
      _p(6, 0.5, 0.9, 'a'),
      _p(7, 0.9, 1.3, 'a'),
      _p(0, 0, 0.2, 'b'),
    ];

    test('inSliver filters by id', () {
      expect(positions.inSliver('b').map((p) => p.index), [0]);
      expect(positions.inSliver(null), isEmpty);
    });

    test('firstFullyVisible picks the fully visible item nearest the top', () {
      expect(positions.inSliver('a').firstFullyVisible!.index, 5);
      expect(positions.firstFullyVisible!.index, 0);
      expect([_p(1, -0.5, 1.5)].firstFullyVisible, isNull);
    });

    test('mostVisible picks the largest share, nearest the top on a tie', () {
      expect(positions.mostVisible!.index, 5);
      expect([_p(2, 0.5, 0.7), _p(1, 0.1, 0.3)].mostVisible!.index, 1);
      expect(<AtlasItemPosition>[].mostVisible, isNull);
    });
  });

  group('ScrollSpyMath.activeIndex', () {
    test('last section whose top reached the pinned bottom', () {
      expect(
        ScrollSpyMath.activeIndex(
          sectionTops: [-500, -10, 100.4, 300, null],
          pinnedBottoms: [100, 100, 100, 100, 100],
          atEnd: false,
        ),
        2,
      );
    });

    test('nothing reached: the first section', () {
      expect(
        ScrollSpyMath.activeIndex(
          sectionTops: [200, 400],
          pinnedBottoms: [100, 100],
          atEnd: false,
        ),
        0,
      );
    });

    test('at the end the last known section is active', () {
      expect(
        ScrollSpyMath.activeIndex(
          sectionTops: [-500, 100, 500, null],
          pinnedBottoms: [100, 100, 100, 100],
          atEnd: true,
        ),
        2,
      );
    });
  });
}
