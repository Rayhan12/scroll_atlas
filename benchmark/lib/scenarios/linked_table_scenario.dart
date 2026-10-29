import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../engines/linked_table_engine.dart';
import '../measure/frame_stats_recorder.dart';
import '../results/scenario_result.dart';
import '../results/summary_stats.dart';
import 'scenario.dart';
import 'scenario_context.dart';

/// B5: [flings] diagonal flings over a [rows] x [columns] linked table.
///
/// Each fling is two fingers at once, one on the header row (horizontal)
/// and one on the body (vertical), so both axes fling together; with
/// separate scroll views per row, one finger locks to one axis. Every
/// frame until both axes rest, misalignment is the largest gap between
/// two members of the same axis. Pass: under 0.5 px on every frame.
final class LinkedTableScenario implements Scenario {
  LinkedTableScenario({this.flings = 24, this.rows = 1000, this.columns = 50});

  final int flings;
  final int rows;
  final int columns;

  static const double rowExtent = 48;
  static const double columnExtent = 96;

  @override
  String get id => 'B5';

  @override
  String get title => 'linked $rows x $columns table, $flings diagonal flings';

  @override
  bool supports(ListEngine engine) => engine is LinkedTableEngine;

  @override
  Future<ScenarioResult> run(ScenarioContext context) async {
    final engine = context.engine as LinkedTableEngine;
    final tester = context.tester;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: KeyedSubtree(
          key: context.probe.hostKey,
          child: engine.buildLinkedTable(
            rows: rows,
            columns: columns,
            rowExtent: rowExtent,
            columnExtent: columnExtent,
          ),
        ),
      ),
    );
    final host = tester.getRect(find.byKey(context.probe.hostKey));
    final headerPoint = Offset(host.center.dx, host.top + rowExtent / 2);
    final bodyPoint = Offset(host.center.dx, host.center.dy);

    final recorder = FrameStatsRecorder()..start();
    final misalignment = <double>[];
    final frameWallMs = <double>[];
    var maxMembers = 0;
    var unsettled = 0;
    var clock = Duration.zero;

    Future<void> frame() async {
      final watch = Stopwatch()..start();
      await context.nextFrame();
      frameWallMs.add(watch.elapsedMicroseconds / 1000);
      misalignment.add(
        math.max(
          _spread(engine.horizontalMembers),
          _spread(engine.verticalMembers),
        ),
      );
      maxMembers = math.max(
        maxMembers,
        engine.horizontalMembers.length + engine.verticalMembers.length,
      );
    }

    for (var i = 0; i < flings; i++) {
      // Three flings forward, one back, so the table travels far.
      final sign = i % 4 == 3 ? 1.0 : -1.0;
      final across = await tester.startGesture(headerPoint, pointer: 51);
      final down = await tester.startGesture(bodyPoint, pointer: 52);
      for (var step = 0; step < 6; step++) {
        clock += const Duration(milliseconds: 8);
        await across.moveBy(Offset(sign * 30, 0), timeStamp: clock);
        await down.moveBy(Offset(0, sign * 40), timeStamp: clock);
        await frame();
      }
      clock += const Duration(milliseconds: 8);
      await across.up(timeStamp: clock);
      await down.up(timeStamp: clock);
      var rest = 0;
      while (tester.binding.hasScheduledFrame && rest < 600) {
        await frame();
        rest++;
      }
      if (rest == 600) unsettled++;
      clock += const Duration(seconds: 1);
    }
    recorder.stop();
    final worst = SummaryStats(misalignment);
    return ScenarioResult(
      scenarioId: id,
      engineId: context.engine.id,
      metrics: <String, double>{
        ...worst.toMetrics('misalignment_px'),
        ...SummaryStats(frameWallMs).toMetrics('frame_wall_ms'),
        'measured_frames': misalignment.length.toDouble(),
        'max_members': maxMembers.toDouble(),
        'unsettled_flings': unsettled.toDouble(),
        'final_x_px': _first(engine.horizontalMembers),
        'final_y_px': _first(engine.verticalMembers),
        ...recorder.toMetrics(),
      },
      passed: worst.max < 0.5 && unsettled == 0,
      notes: 'target: members of an axis within 0.5 px on every frame',
    );
  }

  static double _spread(Iterable<ScrollPosition> members) {
    var low = double.infinity;
    var high = double.negativeInfinity;
    for (final p in members) {
      if (!p.hasPixels) continue;
      low = math.min(low, p.pixels);
      high = math.max(high, p.pixels);
    }
    return high >= low ? high - low : 0;
  }

  static double _first(Iterable<ScrollPosition> members) =>
      members.isEmpty ? 0 : members.first.pixels;
}
