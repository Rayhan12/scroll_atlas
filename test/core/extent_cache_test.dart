import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/experimental.dart';

void main() {
  group('RunningAverageEstimator', () {
    test('uses the fallback, then the average', () {
      final estimator = RunningAverageEstimator(fallback: 40);
      expect(estimator.estimate, 40);
      estimator
        ..addSample(100)
        ..addSample(200);
      expect(estimator.estimate, 150);
      estimator.removeSample(200);
      expect(estimator.estimate, 100);
      estimator.reset();
      expect(estimator.estimate, 40);
    });
  });

  group('ExtentCache', () {
    test('estimates every offset before anything is measured', () {
      final cache = ExtentCache(
          itemCount: 100, estimator: RunningAverageEstimator(fallback: 50));
      expect(cache.offsetOf(0), 0);
      expect(cache.offsetOf(10), 500);
      expect(cache.totalExtent, 5000);
      expect(cache.isMeasured(3), isFalse);
    });

    test('mixes measured extents with the running estimate', () {
      final cache = ExtentCache(
          itemCount: 10, estimator: RunningAverageEstimator(fallback: 50))
        ..record(0, 100)
        ..record(1, 300);
      // Estimate is now 200 for unmeasured items.
      expect(cache.extentOf(2), 200);
      expect(cache.offsetOf(2), 400);
      expect(cache.offsetOf(4), 800);
      expect(cache.totalExtent, 400 + 8 * 200);
    });

    test('re-recording an item replaces its extent', () {
      final cache = ExtentCache(itemCount: 3)
        ..record(0, 100)
        ..record(0, 150);
      expect(cache.extentOf(0), 150);
      expect(cache.offsetOf(1), 150);
      expect(cache.estimator.estimate, 150);
    });

    test('indexAt is the inverse of offsetOf', () {
      final cache = ExtentCache(itemCount: 1000);
      for (var i = 0; i < 1000; i += 3) {
        cache.record(i, 40.0 + i % 7 * 10);
      }
      for (final index in [0, 1, 2, 499, 998, 999]) {
        final start = cache.offsetOf(index);
        expect(cache.indexAt(start), index);
        expect(cache.indexAt(start + cache.extentOf(index) - 0.001), index);
      }
      expect(cache.indexAt(-10), 0);
      expect(cache.indexAt(cache.totalExtent + 10), 999);
    });

    test('changing itemCount keeps surviving measurements', () {
      final cache = ExtentCache(itemCount: 5)
        ..record(1, 70)
        ..record(4, 90);
      cache.itemCount = 3;
      expect(cache.isMeasured(1), isTrue);
      expect(cache.extentOf(1), 70);
      expect(cache.estimator.estimate, 70);
      cache.itemCount = 6;
      expect(cache.isMeasured(4), isFalse);
    });

    test('an empty cache answers safely', () {
      final cache = ExtentCache();
      expect(cache.totalExtent, 0);
      expect(cache.indexAt(100), 0);
    });
  });
}
