import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/src/core/linked_offset_math.dart';

void main() {
  double follow(double pixels, {double followerMax = 1000}) =>
      LinkedOffsetMath.follow(
        pixels: pixels,
        driverMin: 0,
        driverMax: 1000,
        followerMin: 0,
        followerMax: followerMax,
      );

  group('LinkedOffsetMath.follow', () {
    test('copies the offset inside both ranges', () {
      expect(follow(400), 400);
    });

    test('a shorter follower stops at its end', () {
      expect(follow(900, followerMax: 600), 600);
    });

    test('overscroll past the leading edge is copied', () {
      expect(follow(-30), -30);
    });

    test('overscroll past the trailing edge starts at the follower end', () {
      expect(follow(1040, followerMax: 600), 640);
    });
  });

  test('settle clamps a first layout into range', () {
    expect(LinkedOffsetMath.settle(400, 0, 300), 300);
    expect(LinkedOffsetMath.settle(-5, 0, 300), 0);
    expect(LinkedOffsetMath.settle(120, 0, 300), 120);
  });
}
