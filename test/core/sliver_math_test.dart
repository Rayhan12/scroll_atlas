import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';
import 'package:scroll_atlas/src/core/id_registry.dart';
import 'package:scroll_atlas/src/core/placement_math.dart';
import 'package:scroll_atlas/src/core/sticky_header_math.dart';

void main() {
  group('AtlasTarget', () {
    test('index target addresses the unnamed list', () {
      const t = AtlasTarget.index(4);
      expect(t, isA<AtlasIndexTarget>());
      expect(t.sliverId, isNull);
      expect(t.index, 4);
      expect(t, const AtlasTarget.index(4));
      expect(t, isNot(const AtlasTarget.index(5)));
      expect(t.hashCode, const AtlasTarget.index(4).hashCode);
      expect(t.toString(), 'AtlasTarget.index(4)');
    });

    test('item target names its list', () {
      const t = AtlasTarget.item('people-K', 3);
      expect(t.sliverId, 'people-K');
      expect(t.index, 3);
      expect(t, const AtlasTarget.item('people-K', 3));
      expect(t, isNot(const AtlasTarget.item('people-K', 4)));
      expect(t, isNot(const AtlasTarget.item('people-L', 3)));
      expect(t.hashCode, const AtlasTarget.item('people-K', 3).hashCode);
      expect(t.toString(), "AtlasTarget.item('people-K', 3)");
    });

    test('section and sliver targets are the leading edge of a sliver', () {
      const s = AtlasTarget.section('K');
      expect(s.sliverId, 'K');
      expect(s.index, 0);
      expect(s, const AtlasTarget.sliver('K'));
      expect(s, isNot(const AtlasTarget.sliver('L')));
      expect(s.hashCode, const AtlasTarget.sliver('K').hashCode);
      expect(s.toString(), "AtlasTarget.sliver('K')");
      expect(s, isNot(const AtlasTarget.item('K', 0)));
    });
  });

  group('IdRegistry', () {
    test('registers, finds and removes values by id', () {
      final registry = IdRegistry<Object>();
      final a = Object();
      final b = Object();
      expect(registry.add('a', a), isNull);
      expect(registry.add('a', a), isNull, reason: 're-adding is fine');
      expect(registry.add(null, b), isNull);
      expect(registry['a'], same(a));
      expect(registry[null], same(b));
      expect(registry.ids, unorderedEquals(<String?>['a', null]));
      expect(registry.values, unorderedEquals(<Object>[a, b]));
      registry.remove('a', b);
      expect(registry['a'], same(a), reason: 'only the owner removes');
      registry.remove('a', a);
      expect(registry['a'], isNull);
    });

    test('a duplicate id is an error that names the id', () {
      final registry = IdRegistry<Object>();
      final first = Object();
      registry.add('people-K', first);
      final error = registry.add('people-K', Object());
      expect(error, contains("'people-K'"));
      expect(registry['people-K'], same(first));
      registry.add(null, first);
      expect(registry.add(null, Object()), contains('unnamed'));
    });
  });

  group('StickyHeaderMath', () {
    double paint(double so, {double overlap = 0, double section = 500}) =>
        StickyHeaderMath.headerPaintOffset(
          scrollOffset: so,
          overlap: overlap,
          headerExtent: 50,
          sectionExtent: section,
        );

    test('the header scrolls, sticks, then is pushed off', () {
      expect(paint(0), 0);
      expect(paint(100), 0, reason: 'stuck at the top');
      expect(paint(100, overlap: 56), 56, reason: 'stuck below the app bar');
      expect(paint(470), -20, reason: 'pushed by the section end');
      expect(paint(440, overlap: 56), 10);
    });

    test('stuck amount goes from 0 to 1', () {
      double stuck(double so, {double overlap = 0}) =>
          StickyHeaderMath.stuckAmount(
            headerPaintOffset: paint(so, overlap: overlap),
            scrollOffset: so,
            headerExtent: 50,
          );
      expect(stuck(0), 0);
      expect(stuck(25), 0.5);
      expect(stuck(200), 1);
      expect(
        StickyHeaderMath.stuckAmount(
            headerPaintOffset: 0, scrollOffset: 10, headerExtent: 0),
        0,
      );
    });

    test('body overlap covers the stuck header and the pinned bar', () {
      double overlap(double so, double bodyPaint, {double pinned = 0}) =>
          StickyHeaderMath.bodyOverlap(
            scrollOffset: so,
            overlap: pinned,
            headerExtent: 50,
            bodyPaintOffset: bodyPaint,
          );
      expect(overlap(0, 50), 0, reason: 'header above the body');
      expect(overlap(100, 0), 50, reason: 'stuck header covers the body');
      expect(overlap(100, 0, pinned: 56), 106);
      expect(overlap(-200, 250), 0, reason: 'section below the leading edge');
    });
  });

  group('PlacementMath', () {
    test('returns the correction that aligns a leading edge', () {
      expect(
        PlacementMath.correction(
            leading: 1000,
            aligned: 100,
            virtualOffset: 850,
            minVirtualOffset: -2000),
        50,
      );
      expect(
        PlacementMath.correction(
            leading: 1000,
            aligned: 100,
            virtualOffset: 900.005,
            minVirtualOffset: -2000),
        isNull,
      );
    });

    test('never scrolls before the start of the scroll view', () {
      expect(
        PlacementMath.correction(
            leading: 0,
            aligned: 400,
            virtualOffset: -100,
            minVirtualOffset: -300),
        -200,
      );
      expect(
        PlacementMath.correction(
            leading: 0,
            aligned: 400,
            virtualOffset: -300,
            minVirtualOffset: -300),
        isNull,
      );
    });
  });

  test('ScrollTarget carries respectPinned and padding', () {
    final t = ScrollTarget(3, alignment: 0.5, respectPinned: false, padding: 8);
    expect(t.withIndex(7),
        ScrollTarget(7, alignment: 0.5, respectPinned: false, padding: 8));
    expect(t, isNot(ScrollTarget(3, alignment: 0.5, padding: 8)));
    expect(t, isNot(ScrollTarget(3, alignment: 0.5, respectPinned: false)));
    expect(t.toString(), contains('padding: 8.0'));
  });
}
