import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/fixtures.dart';

import '../support/position_matchers.dart';
import '../support/test_app.dart';

void main() {
  group('SeededExtents', () {
    test('seed 42 gives identical heights across runs', () {
      final a = SeededExtents(seed: 42, length: 100000);
      final b = SeededExtents(seed: 42, length: 100000);
      expect(a.length, 100000);
      expect(listEquals(a, b), isTrue);
      // Golden values: these must stay the same on every platform.
      expect(a.take(5).toList(), _goldenFirstFive);
    });

    test('heights stay in range and include rare very tall items', () {
      final extents = SeededExtents(seed: 42, length: 100000);
      expect(extents.every((e) => e >= SeededExtents.minExtent && e <= 1440),
          isTrue);
      final tall = extents.where((e) => e >= 960).length;
      expect(tall, inInclusiveRange(30, 200));
      expect(
          extents.where((e) => e > 200 && e <= 480).length, greaterThan(1000));
    });

    test('different seeds differ and the list is read only', () {
      final a = SeededExtents(seed: 1, length: 10);
      expect(listEquals(a, SeededExtents(seed: 2, length: 10)), isFalse);
      expect(() => a[0] = 1, throwsUnsupportedError);
      expect(() => a.length = 1, throwsUnsupportedError);
    });

    test('seededTargets is deterministic and in range', () {
      final t = seededTargets(seed: 7, count: 200, itemCount: 100000);
      expect(t, seededTargets(seed: 7, count: 200, itemCount: 100000));
      expect(t.every((i) => i >= 0 && i < 100000), isTrue);
    });

    test('DeterministicRandom handles a zero seed', () {
      final r = DeterministicRandom(0);
      expect(r.nextUint32(), isNot(0));
      expect(r.nextDouble(), inInclusiveRange(0, 1));
    });
  });

  group('position helpers', () {
    testWidgets('report the corrected offset after an item above grows',
        (tester) async {
      usePhoneView(tester);
      final loaded = ValueNotifier<bool>(false);
      addTearDown(loaded.dispose);
      await tester.pumpWidget(host(ListView.builder(
        itemCount: 20,
        itemBuilder: (context, index) => index == 0
            ? GrowingFixtureItem(
                index: 0, initialExtent: 100, loadedExtent: 260, loaded: loaded)
            : FixtureItem(index: index, extent: 50),
      )));
      expect(itemLeadingEdge(tester, 3), 200);
      expectItemAt(tester, 0);

      loaded.value = true;
      await tester.pump();
      expect(itemLeadingEdge(tester, 3), 360);
      expectNoBuildOf(const [19]);
    });

    testWidgets('expectItemAt checks alignment against the viewport',
        (tester) async {
      usePhoneView(tester);
      await tester.pumpWidget(host(ListView.builder(
        itemCount: 100,
        itemBuilder: (context, index) => FixtureItem(index: index, extent: 211),
      )));
      // Item 2 starts at 422 = 0.5 * 844.
      expectItemAt(tester, 2, alignment: 0.5);
    });

    testWidgets('BuildCounter and TextWrapFixtureItem', (tester) async {
      usePhoneView(tester);
      final counter = BuildCounter();
      await tester.pumpWidget(host(ListView.builder(
        itemCount: 1000,
        itemBuilder: counter.wrap(
            (context, index) => TextWrapFixtureItem(index: index, words: 40)),
      )));
      expect(counter.builds, greaterThan(0));
      expect(counter.builtIndexes, contains(0));
      expect(counter.builtIndexes.length, lessThan(60));
      counter.reset();
      expect(counter.builds, 0);
    });
  });
}

const List<double> _goldenFirstFive = <double>[385, 177, 99, 134, 86];
