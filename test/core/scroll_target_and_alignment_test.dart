import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

void main() {
  test('ScrollTarget is a value object', () {
    expect(ScrollTarget(3, alignment: 0.5), ScrollTarget(3, alignment: 0.5));
    expect(ScrollTarget(3).hashCode, ScrollTarget(3).hashCode);
    expect(ScrollTarget(3), isNot(ScrollTarget(4)));
    expect(() => ScrollTarget(-1), throwsRangeError);
    expect(ScrollTarget(2).toString(), contains('2'));
  });

  test('AlignmentMath places the leading edge inside the unobstructed area',
      () {
    expect(
        AlignmentMath.leadingEdgeInViewport(
            alignment: 0.5, viewportExtent: 800),
        400);
    expect(
      AlignmentMath.leadingEdgeInViewport(
          alignment: 0.5, viewportExtent: 800, leadingObstruction: 100),
      450,
    );
    expect(
      AlignmentMath.scrollOffsetFor(
          itemLeadingOffset: 5000, alignment: 0.25, viewportExtent: 800),
      4800,
    );
  });
}
