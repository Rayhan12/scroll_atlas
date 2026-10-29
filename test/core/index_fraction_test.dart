import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/src/core/index_fraction.dart';

void main() {
  group('IndexSpan', () {
    test('length is end minus first', () {
      expect(const IndexSpan(2.5, 9).length, 6.5);
    });

    test('value equality and hash', () {
      expect(const IndexSpan(1, 2), const IndexSpan(1, 2));
      expect(const IndexSpan(1, 2).hashCode, const IndexSpan(1, 2).hashCode);
      expect(const IndexSpan(1, 2), isNot(const IndexSpan(1, 3)));
      expect(const IndexSpan(1, 2), isNot(Object()));
    });

    test('toString names both edges', () {
      expect(const IndexSpan(1, 2).toString(), 'IndexSpan(1.0, 2.0)');
    });

    test('asserts on a negative first or an end before first', () {
      expect(() => IndexSpan(-1, 2), throwsAssertionError);
      expect(() => IndexSpan(3, 2), throwsAssertionError);
    });
  });

  group('IndexFraction.of', () {
    test('is 0 at the start and 1 at the end', () {
      expect(IndexFraction.of(const IndexSpan(0, 8), 100), 0);
      expect(IndexFraction.of(const IndexSpan(92, 100), 100), 1);
    });

    test('is 0 when everything fits', () {
      expect(IndexFraction.of(const IndexSpan(0, 5), 5), 0);
    });

    test('ignores a span that runs past the item count', () {
      expect(IndexFraction.of(const IndexSpan(95, 101), 100), 1);
    });

    test(
        'grows strictly while scrolling forward, even when the visible '
        'item count changes', () {
      var previous = -1.0;
      var end = 0.0;
      for (var first = 0.0; first < 990; first += 0.7) {
        // Both edges move forward; the number of visible items varies.
        end = (first + 3 + (first * 13 % 7)).clamp(end, double.infinity);
        final value = IndexFraction.of(IndexSpan(first, end), 1000);
        expect(value, greaterThan(previous));
        previous = value;
      }
    });
  });

  group('IndexFraction.leadingIndexFor', () {
    test('inverts of() for a fixed visible count', () {
      for (final fraction in [0.0, 0.25, 0.5, 0.99, 1.0]) {
        final first = IndexFraction.leadingIndexFor(
          fraction,
          itemCount: 1000,
          visibleItems: 8,
        );
        expect(
          IndexFraction.of(IndexSpan(first, first + 8), 1000),
          closeTo(fraction, 1e-12),
        );
      }
    });

    test('clamps the fraction and the room', () {
      expect(
        IndexFraction.leadingIndexFor(2, itemCount: 10, visibleItems: 4),
        6,
      );
      expect(
        IndexFraction.leadingIndexFor(0.5, itemCount: 3, visibleItems: 4),
        0,
      );
    });
  });
}
