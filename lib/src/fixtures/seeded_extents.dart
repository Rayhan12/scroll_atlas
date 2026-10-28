import 'dart:collection';
import 'dart:typed_data';

import 'deterministic_random.dart';

/// Deterministic variable item heights for tests, the example app and the
/// benchmark. The same seed gives identical heights everywhere.
///
/// Distribution: mostly 48 to 200 px, about 3 percent 200 to 480 px, and
/// about 1 in 1,000 very tall items of 960 to 1,440 px.
final class SeededExtents extends ListBase<double> {
  /// Generates [length] extents from [seed].
  SeededExtents({required this.seed, required int length})
      : _values = _generate(seed, length);

  /// Seed used to generate the extents.
  final int seed;
  final Float64List _values;

  /// Shortest generated extent.
  static const double minExtent = 48;

  /// Longest extent of a regular item.
  static const double maxRegularExtent = 480;

  static Float64List _generate(int seed, int length) {
    final random = DeterministicRandom(seed);
    final values = Float64List(length);
    for (var i = 0; i < length; i++) {
      final roll = random.nextDouble();
      final double extent;
      if (roll < 0.001) {
        extent = random.nextInRange(960, 1440);
      } else if (roll < 0.031) {
        extent = random.nextInRange(200, maxRegularExtent);
      } else {
        extent = random.nextInRange(minExtent, 200);
      }
      values[i] = extent.roundToDouble();
    }
    return values;
  }

  @override
  int get length => _values.length;

  @override
  set length(int newLength) =>
      throw UnsupportedError('SeededExtents has a fixed length');

  @override
  double operator [](int index) => _values[index];

  @override
  void operator []=(int index, double value) =>
      throw UnsupportedError('SeededExtents is read only');
}

/// Seeded list of jump targets, shared by tests and benchmark scenarios.
List<int> seededTargets(
    {required int seed, required int count, required int itemCount}) {
  final random = DeterministicRandom(seed);
  return List<int>.generate(count, (_) => random.nextInt(itemCount));
}
