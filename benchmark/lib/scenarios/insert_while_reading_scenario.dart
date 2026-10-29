import '../results/scenario_result.dart';
import 'scenario.dart';
import 'scenario_context.dart';

/// B6: while reading item [readingId], insert [inserted] keyed items at the
/// top and measure how far the item being read moves on screen.
final class InsertWhileReadingScenario extends JumpScenario {
  InsertWhileReadingScenario({this.readingId = 50000, this.inserted = 20});

  final int readingId;
  final int inserted;

  /// Largest shift that counts as "stays in place".
  static const double tolerance = 0.5;

  @override
  String get id => 'B6';

  @override
  String get title => 'insert $inserted items at top while reading';

  @override
  Future<ScenarioResult> run(ScenarioContext context) async {
    await context.mount();
    jumper(context).jumpToIndex(readingId);
    await context.pumpUntilSettled(readingId, 0);
    final before = context.probe.leadingEdge(readingId);

    await context.mount(insertedAtTop: inserted);
    final firstFrame = _shift(before, context.probe.leadingEdge(readingId));
    await context.nextFrame();
    await context.nextFrame();
    final settled = _shift(before, context.probe.leadingEdge(readingId));

    return ScenarioResult(
      scenarioId: id,
      engineId: context.engine.id,
      metrics: <String, double>{
        'first_frame_shift_px': firstFrame,
        'settled_shift_px': settled,
      },
      passed: firstFrame < tolerance && settled < tolerance,
      notes: 'target: item $readingId moves < $tolerance px',
    );
  }

  /// Movement of the read item; infinity when it is no longer built, which
  /// means it was pushed off screen.
  static double _shift(double? before, double? after) =>
      before == null || after == null
          ? double.infinity
          : (after - before).abs();
}
