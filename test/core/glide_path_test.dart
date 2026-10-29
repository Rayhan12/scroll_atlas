import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/src/core/glide_path.dart';

void main() {
  group('GlidePath', () {
    test('starts at the full distance and ends at 0', () {
      final path = GlidePath(distance: 5000, scale: 50);
      expect(path.remaining(1), 5000);
      expect(path.remaining(0), 0);
    });

    test('is continuous at the start', () {
      final path = GlidePath(distance: 5000, scale: 50);
      expect(path.remaining(0.999999), closeTo(5000, 0.1));
    });

    test('clamps progress outside 0 to 1', () {
      final path = GlidePath(distance: 100, scale: 10);
      expect(path.remaining(2), 100);
      expect(path.remaining(-1), 0);
    });

    test('remaining distance shrinks as progress goes to 0', () {
      final path = GlidePath(distance: 1e6, scale: 50);
      var previous = double.infinity;
      for (var u = 1.0; u >= 0; u -= 0.01) {
        final value = path.remaining(u);
        expect(value, lessThanOrEqualTo(previous));
        previous = value;
      }
    });

    test(
        'the last 16 ms of a 600 ms easeInOut move under 2 px for any '
        'distance (B2)', () {
      const curve = Curves.easeInOut;
      for (final distance in [10.0, 1e3, 8e4 * 150, 7.5e6, 1e9]) {
        final path = GlidePath(
          distance: distance,
          scale: GlidePath.scaleFor(844),
        );
        final u = 1 - curve.transform(1 - 16 / 600);
        expect(path.remaining(u), lessThan(2), reason: 'distance $distance');
      }
    });

    test('a zero distance stays at zero', () {
      final path = GlidePath(distance: 0, scale: 1);
      expect(path.remaining(0.5), 0);
      expect(path.shrinkRatio(previousU: 1, u: 0.5), 0);
    });

    test('shrinkRatio is the ratio of remaining distances', () {
      final path = GlidePath(distance: 1000, scale: 20);
      expect(
        path.shrinkRatio(previousU: 0.8, u: 0.4),
        closeTo(path.remaining(0.4) / path.remaining(0.8), 1e-12),
      );
      expect(path.shrinkRatio(previousU: 0.5, u: 0), 0);
    });

    test('scaleFor is a sixteenth of the viewport, at least 1', () {
      expect(GlidePath.scaleFor(800), 50);
      expect(GlidePath.scaleFor(8), 1);
    });

    test('asserts on a negative distance or a non-positive scale', () {
      expect(() => GlidePath(distance: -1, scale: 1), throwsAssertionError);
      expect(() => GlidePath(distance: 1, scale: 0), throwsAssertionError);
    });
  });
}
