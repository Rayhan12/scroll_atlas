import 'dart:typed_data';

/// A Fenwick (binary indexed) tree over doubles.
///
/// Point updates and prefix sums both run in O(log n), which keeps offset
/// lookups cheap for lists with hundreds of thousands of items.
final class FenwickTree {
  /// Creates a tree holding [length] zero values.
  FenwickTree(int length)
      : assert(length >= 0, 'length must not be negative'),
        _tree = Float64List(length + 1);

  final Float64List _tree;

  /// Number of values in the tree.
  int get length => _tree.length - 1;

  /// Adds [delta] to the value at [index].
  void add(int index, double delta) {
    RangeError.checkValueInInterval(index, 0, length - 1, 'index');
    for (var i = index + 1; i <= length; i += i & -i) {
      _tree[i] += delta;
    }
  }

  /// Sum of the values at indexes `0` (inclusive) to [end] (exclusive).
  double prefixSum(int end) {
    RangeError.checkValueInInterval(end, 0, length, 'end');
    var sum = 0.0;
    for (var i = end; i > 0; i -= i & -i) {
      sum += _tree[i];
    }
    return sum;
  }
}
