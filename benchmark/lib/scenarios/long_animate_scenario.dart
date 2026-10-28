import 'dart:async';

import '../measure/frame_stats_recorder.dart';
import '../results/scenario_result.dart';
import '../results/summary_stats.dart';
import 'scenario.dart';
import 'scenario_context.dart';

/// B2: animate [distance] items away over [duration] to alignment 0.5.
final class LongAnimateScenario extends JumpScenario {
  LongAnimateScenario({
    this.start = 1000,
    this.distance = 80000,
    this.duration = const Duration(milliseconds: 600),
  });

  final int start;
  final int distance;
  final Duration duration;

  static const double alignment = 0.5;

  @override
  String get id => 'B2';

  @override
  String get title =>
      'animateTo $distance items away, ${duration.inMilliseconds} ms';

  @override
  Future<ScenarioResult> run(ScenarioContext context) async {
    final target = start + distance;
    await context.mount();
    jumper(context).jumpToIndex(start);
    await context.pumpUntilSettled(start, 0);

    final recorder = FrameStatsRecorder()..start();
    final watch = Stopwatch()..start();
    var done = false;
    final frameWallMs = <double>[];
    final edges = <double?>[];
    unawaited(
      jumper(context)
          .animateToIndex(target, duration: duration, alignment: alignment)
          .whenComplete(() => done = true),
    );
    final maxFrames =
        duration.inMilliseconds ~/ ScenarioContext.frame.inMilliseconds * 4;
    var frames = 0;
    while (frames < maxFrames) {
      final frameWatch = Stopwatch()..start();
      await context.nextFrame();
      frameWallMs.add(frameWatch.elapsedMicroseconds / 1000);
      frames++;
      edges.add(context.probe.leadingEdge(target));
      if (done && _isStable(edges)) {
        break;
      }
    }
    watch.stop();
    recorder.stop();

    final settled = context.probe.alignmentError(target, alignment);
    final lastMove = _lastFrameMovement(edges);
    return ScenarioResult(
      scenarioId: id,
      engineId: context.engine.id,
      metrics: <String, double>{
        'final_error_px': settled,
        'last_frame_move_px': lastMove,
        'frames': frames.toDouble(),
        'completed': done ? 1 : 0,
        ...SummaryStats(frameWallMs).toMetrics('frame_wall_ms'),
        ...recorder.toMetrics(),
      },
      passed: done && settled <= 0.5 && lastMove < 2,
      notes: 'target: error <= 0.5 px, last frame move < 2 px',
    );
  }

  /// True when the target is built and did not move in the last frame.
  static bool _isStable(List<double?> edges) =>
      edges.length >= 2 &&
      edges.last != null &&
      edges.last == edges[edges.length - 2];

  /// Distance the target moved in the last frame that moved it: the visible
  /// final "snap". Infinity when it appeared from unbuilt in that frame.
  static double _lastFrameMovement(List<double?> edges) {
    for (var i = edges.length - 1; i > 0; i--) {
      final now = edges[i];
      final before = edges[i - 1];
      if (now == before) {
        continue;
      }
      if (now == null || before == null) return double.infinity;
      return (now - before).abs();
    }
    return 0;
  }
}
