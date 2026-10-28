/// Estimates the main axis extent of items that have not been measured yet.
///
/// The extent cache depends on this abstraction, so the estimation strategy
/// can change (running average, per-type averages, a fixed hint) without
/// touching the cache or the engine.
abstract interface class ExtentEstimator {
  /// The extent to assume for an unmeasured item.
  double get estimate;

  /// Called when an item is measured for the first time.
  void addSample(double extent);

  /// Called when a previously measured extent is replaced or forgotten.
  void removeSample(double extent);

  /// Forgets every sample.
  void reset();
}

/// Uses the average of every measured extent, or [fallback] before the first
/// measurement.
final class RunningAverageEstimator implements ExtentEstimator {
  /// Creates an estimator that starts at [fallback].
  RunningAverageEstimator({this.fallback = 56.0})
      : assert(fallback > 0, 'fallback must be positive');

  /// Extent used until at least one item has been measured.
  final double fallback;

  double _sum = 0;
  int _count = 0;

  @override
  double get estimate => _count == 0 ? fallback : _sum / _count;

  @override
  void addSample(double extent) {
    _sum += extent;
    _count++;
  }

  @override
  void removeSample(double extent) {
    if (_count == 0) return;
    _sum -= extent;
    _count--;
  }

  @override
  void reset() {
    _sum = 0;
    _count = 0;
  }
}
