import 'package:flutter/scheduler.dart';

import '../results/summary_stats.dart';

/// Collects engine frame timings while a scenario runs. Only real devices
/// report timings; under flutter_test the lists stay empty.
final class FrameStatsRecorder {
  FrameStatsRecorder({this.budget = const Duration(microseconds: 16667)});

  /// Frame budget; a frame whose build or raster time exceeds it is jank.
  final Duration budget;

  final List<double> _buildMs = <double>[];
  final List<double> _rasterMs = <double>[];

  void _onTimings(List<FrameTiming> timings) {
    for (final t in timings) {
      _buildMs.add(t.buildDuration.inMicroseconds / 1000);
      _rasterMs.add(t.rasterDuration.inMicroseconds / 1000);
    }
  }

  void start() => SchedulerBinding.instance.addTimingsCallback(_onTimings);

  void stop() => SchedulerBinding.instance.removeTimingsCallback(_onTimings);

  int get frameCount => _buildMs.length;

  int get jankFrames {
    final limit = budget.inMicroseconds / 1000;
    var count = 0;
    for (var i = 0; i < _buildMs.length; i++) {
      if (_buildMs[i] > limit || _rasterMs[i] > limit) count++;
    }
    return count;
  }

  /// Build and raster p50/p90/p99/max plus frame and jank counts.
  Map<String, double> toMetrics() => <String, double>{
    if (frameCount > 0) ...SummaryStats(_buildMs).toMetrics('build_ms'),
    if (frameCount > 0) ...SummaryStats(_rasterMs).toMetrics('raster_ms'),
    if (frameCount > 0) 'frames': frameCount.toDouble(),
    if (frameCount > 0) 'jank_frames': jankFrames.toDouble(),
  };
}
