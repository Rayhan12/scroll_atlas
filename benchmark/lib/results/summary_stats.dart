/// Percentiles and means over a list of samples. Pure Dart, so the
/// comparison script can use it without Flutter.
final class SummaryStats {
  SummaryStats(Iterable<num> samples)
    : _sorted = samples.map((s) => s.toDouble()).toList()..sort();

  final List<double> _sorted;

  int get count => _sorted.length;

  double get max => _sorted.isEmpty ? 0 : _sorted.last;

  double get mean =>
      _sorted.isEmpty ? 0 : _sorted.reduce((a, b) => a + b) / _sorted.length;

  /// Nearest-rank percentile, [p] in 0..100.
  double percentile(double p) {
    if (_sorted.isEmpty) return 0;
    final rank = (p / 100 * _sorted.length).ceil().clamp(1, _sorted.length);
    return _sorted[rank - 1];
  }

  /// Standard keys used in every result file.
  Map<String, double> toMetrics(String prefix) => <String, double>{
    '${prefix}_p50': percentile(50),
    '${prefix}_p90': percentile(90),
    '${prefix}_p99': percentile(99),
    '${prefix}_max': max,
  };
}
