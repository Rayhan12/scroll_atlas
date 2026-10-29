import 'package:flutter/widgets.dart';
import 'package:scroll_atlas/fixtures.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../engines/sticky_sections_engine.dart';
import '../results/scenario_result.dart';
import '../results/summary_stats.dart';
import 'scenario.dart';
import 'scenario_context.dart';

/// B4: [jumps] seeded jumps across 26 sticky sections under a pinned bar.
/// A target is covered when its leading edge lands under the bar or its
/// section's stuck header. Targets near the end that the scroll extent
/// clamps count as exact when they rest below the pinned edge. Pass: 0 covered, every jump settled in 1 frame.
final class StickySectionsScenario implements Scenario {
  StickySectionsScenario({this.jumps = 500, this.seed = 26});

  final int jumps;
  final int seed;

  static const int sections = 26;
  static const double barExtent = 56;
  static const double headerExtent = 40;
  static const List<double> alignments = <double>[0, 0.25, 0.5];

  @override
  String get id => 'B4';

  @override
  String get title => '$jumps jumps across $sections sticky sections';

  @override
  bool supports(ListEngine engine) => engine is StickySectionsEngine;

  static Key itemKey(int section, int index) =>
      ValueKey<String>('b4-$section-$index');

  @override
  Future<ScenarioResult> run(ScenarioContext context) async {
    final engine = context.engine as StickySectionsEngine;
    final random = DeterministicRandom(seed);
    final counts = <int>[
      for (var s = 0; s < sections; s++) 20 + random.nextInt(101),
    ];
    final starts = <int>[0];
    for (final count in counts) {
      starts.add(starts.last + count);
    }
    await context.tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: KeyedSubtree(
          key: context.probe.hostKey,
          child: engine.buildSections(
            barExtent: barExtent,
            headerExtent: headerExtent,
            itemCounts: counts,
            itemBuilder:
                (_, section, index) => SizedBox(
                  key: itemKey(section, index),
                  height: context.extentOf(
                    (starts[section] + index) % context.extents.length,
                  ),
                ),
          ),
        ),
      ),
    );
    final viewport = context.probe.viewportExtent;
    const top = barExtent + headerExtent;
    final errors = <double>[];
    final frames = <double>[];
    var covered = 0;
    var unsettled = 0;
    for (var i = 0; i < jumps; i++) {
      final section = random.nextInt(sections);
      final index = random.nextInt(counts[section]);
      final alignment = alignments[i % alignments.length];
      final expected = top + alignment * (viewport - top);
      engine.jumpToSectionItem(section, index, alignment: alignment);
      double? first;
      int? settledAt;
      double last = double.infinity;
      for (var frame = 1; frame <= 60; frame++) {
        await context.nextFrame();
        last =
            context.probe.leadingEdgeOf(itemKey(section, index)) ??
            double.infinity;
        // At the scroll end the target may rest below its line; that is
        // the closest any engine can get, so it counts as exact.
        final error =
            context.probe.atScrollEnd && last >= expected
                ? 0.0
                : (last - expected).abs();
        first ??= error;
        final ok = error <= 0.5;
        if (ok && settledAt != null) break;
        settledAt = ok ? frame : null;
      }
      errors.add(first!);
      if (!last.isFinite || last < top - 0.5) covered++;
      if (settledAt == null) {
        unsettled++;
      } else {
        frames.add(settledAt.toDouble());
      }
    }
    final framesStats = SummaryStats(frames);
    return ScenarioResult(
      scenarioId: id,
      engineId: context.engine.id,
      metrics: <String, double>{
        'covered_targets': covered.toDouble(),
        'settled_ratio': (jumps - unsettled) / jumps,
        ...SummaryStats(
          errors.where((e) => e.isFinite),
        ).toMetrics('first_frame_error_px'),
        'first_frame_unbuilt':
            errors.where((e) => !e.isFinite).length.toDouble(),
        ...framesStats.toMetrics('frames_to_settle'),
      },
      passed: covered == 0 && unsettled == 0 && framesStats.max <= 1,
      notes: 'target: 0 covered, error <= 0.5 px in 1 frame',
    );
  }
}
