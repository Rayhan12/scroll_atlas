import 'dart:typed_data';

import 'extent_estimator.dart';
import 'fenwick_tree.dart';

/// Measured item extents plus an estimate for the unmeasured ones.
///
/// Answers "where does item i start?" and "which item covers offset o?" in
/// O(log n) and O(log^2 n). The cache only stores numbers; it knows nothing
/// about render objects, so it is unit tested on its own.
final class ExtentCache {
  /// Creates a cache for [itemCount] items.
  ExtentCache({int itemCount = 0, ExtentEstimator? estimator})
      : estimator = estimator ?? RunningAverageEstimator() {
    _allocate(itemCount);
  }

  /// Strategy for unmeasured items.
  final ExtentEstimator estimator;

  late Float64List _extents; // NaN marks an unmeasured item.
  late FenwickTree _measuredSum;
  late FenwickTree _measuredCount;

  /// Differences smaller than this are treated as the same extent.
  static const double tolerance = 0.01;

  /// Number of items covered by the cache.
  int get itemCount => _extents.length;

  /// Changes the item count, keeping measurements for indexes that survive.
  set itemCount(int value) {
    if (value == itemCount) return;
    final old = _extents;
    _allocate(value);
    for (var i = 0; i < old.length && i < value; i++) {
      if (!old[i].isNaN) record(i, old[i]);
    }
  }

  void _allocate(int count) {
    RangeError.checkNotNegative(count, 'itemCount');
    _extents = Float64List(count)..fillRange(0, count, double.nan);
    _measuredSum = FenwickTree(count);
    _measuredCount = FenwickTree(count);
    estimator.reset();
  }

  /// Whether item [index] has been measured.
  bool isMeasured(int index) => !_extents[index].isNaN;

  /// Measured extent of [index], or the current estimate.
  double extentOf(int index) {
    final value = _extents[index];
    return value.isNaN ? estimator.estimate : value;
  }

  /// Stores the measured [extent] of item [index].
  void record(int index, double extent) {
    RangeError.checkValueInInterval(index, 0, itemCount - 1, 'index');
    final previous = _extents[index];
    if (!previous.isNaN && (previous - extent).abs() < tolerance) return;
    if (previous.isNaN) {
      _measuredCount.add(index, 1);
      _measuredSum.add(index, extent);
    } else {
      estimator.removeSample(previous);
      _measuredSum.add(index, extent - previous);
    }
    estimator.addSample(extent);
    _extents[index] = extent;
  }

  /// Scroll offset of the leading edge of item [index]. [index] may equal
  /// [itemCount], which gives the total extent.
  double offsetOf(int index) {
    RangeError.checkValueInInterval(index, 0, itemCount, 'index');
    final measured = _measuredCount.prefixSum(index);
    return _measuredSum.prefixSum(index) +
        (index - measured) * estimator.estimate;
  }

  /// Total extent of all items, measured or estimated.
  double get totalExtent => offsetOf(itemCount);

  /// Index of the item that covers [offset], clamped to the valid range.
  int indexAt(double offset) {
    if (itemCount == 0) return 0;
    var low = 0;
    var high = itemCount - 1;
    while (low < high) {
      final mid = (low + high + 1) >> 1;
      if (offsetOf(mid) <= offset) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }
}
