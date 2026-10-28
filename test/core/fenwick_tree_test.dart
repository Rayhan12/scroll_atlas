import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/experimental.dart';

void main() {
  test('prefix sums match a naive sum', () {
    final tree = FenwickTree(10);
    final values = List<double>.generate(10, (i) => i * 1.5);
    for (var i = 0; i < values.length; i++) {
      tree.add(i, values[i]);
    }
    for (var end = 0; end <= 10; end++) {
      expect(tree.prefixSum(end),
          values.take(end).fold<double>(0, (a, b) => a + b));
    }
  });

  test('rejects out of range indexes', () {
    final tree = FenwickTree(3);
    expect(() => tree.add(3, 1), throwsRangeError);
    expect(() => tree.prefixSum(4), throwsRangeError);
  });
}
