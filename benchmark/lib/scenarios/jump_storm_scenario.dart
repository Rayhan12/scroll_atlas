import 'package:scroll_atlas/fixtures.dart';

import '../results/scenario_result.dart';
import '../results/summary_stats.dart';
import 'scenario.dart';
import 'scenario_context.dart';

/// B1: jump to [jumps] seeded random indexes in a variable-height list.
final class JumpStormScenario extends JumpScenario {
  JumpStormScenario({this.jumps = 200, this.seed = 7});

  final int jumps;
  final int seed;

  static const List<double> alignments = <double>[0, 0.25, 0.5];

  /// Items one viewport plus two default cache extents can hold at the
  /// fixture's minimum extent, plus the two items straddling the edges.
  static int buildBudget(double viewport) =>
      ((viewport + 2 * 250) / SeededExtents.minExtent).floor() + 2;

  @override
  String get id => 'B1';

  @override
  String get title => 'jumpTo $jumps random indexes';

  @override
  Future<ScenarioResult> run(ScenarioContext context) async {
    final targets = seededTargets(
      seed: seed,
      count: jumps,
      itemCount: context.extents.length - 50,
    );
    final errors = <double>[];
    final frames = <double>[];
    final builds = <double>[];
    final wallMs = <double>[];
    var unsettled = 0;
    await context.mount();
    for (var i = 0; i < targets.length; i++) {
      final alignment = alignments[i % alignments.length];
      context.counter.reset();
      final watch = Stopwatch()..start();
      jumper(context).jumpToIndex(targets[i], alignment: alignment);
      final settled = await context.pumpUntilSettled(targets[i], alignment);
      watch.stop();
      wallMs.add(watch.elapsedMicroseconds / 1000);
      builds.add(context.counter.builtIndexes.length.toDouble());
      final settledAt = settled.settledAtFrame;
      if (settledAt == null) {
        unsettled++;
      } else {
        frames.add(settledAt.toDouble());
      }
      errors.add(settled.firstFrameError);
    }
    final budget = buildBudget(context.probe.viewportExtent);
    final framesStats = SummaryStats(frames);
    final buildStats = SummaryStats(builds);
    final settledRatio = (jumps - unsettled) / jumps;
    return ScenarioResult(
      scenarioId: id,
      engineId: context.engine.id,
      metrics: <String, double>{
        'settled_ratio': settledRatio,
        ...framesStats.toMetrics('frames_to_settle'),
        ...SummaryStats(
          errors.where((e) => e.isFinite),
        ).toMetrics('first_frame_error_px'),
        'first_frame_unbuilt':
            errors.where((e) => !e.isFinite).length.toDouble(),
        ...buildStats.toMetrics('items_built'),
        'items_budget': budget.toDouble(),
        ...SummaryStats(wallMs).toMetrics('wall_ms'),
      },
      passed:
          settledRatio == 1 && framesStats.max <= 1 && buildStats.max <= budget,
      notes: 'target: settled in 1 frame, error <= 0.5 px, built <= $budget',
    );
  }
}
