import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/fixtures.dart';

import 'engines/engine_catalog.dart';
import 'results/scenario_result.dart';
import 'scenarios/scenario.dart';
import 'scenarios/scenario_catalog.dart';
import 'scenarios/scenario_context.dart';

/// Runs every supported (scenario, engine) pair. Shared by the headless
/// headless test and the on-device integration test, so both measure the same
/// way.
final class BenchmarkRunner {
  BenchmarkRunner({
    List<EngineFactory>? engines,
    List<Scenario>? scenarios,
    this.itemCount = 100000,
    this.seed = 42,
  }) : engines = engines ?? engineCatalog,
       scenarios = scenarios ?? scenarioCatalog();

  final List<EngineFactory> engines;
  final List<Scenario> scenarios;
  final int itemCount;
  final int seed;

  /// Runs everything and wraps the results with [environment] plus the
  /// run's own settings, so every entry point records runs the same way.
  Future<BenchmarkRun> record(
    WidgetTester tester, {
    required Map<String, Object?> environment,
    void Function(String)? log,
  }) async {
    final results = await run(tester, log: log);
    return BenchmarkRun(
      environment: <String, Object?>{
        ...environment,
        'date': DateTime.now().toIso8601String().substring(0, 10),
        'item_count': itemCount,
        'seed': seed,
      },
      results: results,
    );
  }

  Future<List<ScenarioResult>> run(
    WidgetTester tester, {
    void Function(String)? log,
  }) async {
    final extents = SeededExtents(seed: seed, length: itemCount);
    final results = <ScenarioResult>[];
    for (final scenario in scenarios) {
      for (final create in engines) {
        final engine = create();
        try {
          if (!scenario.supports(engine)) {
            results.add(
              ScenarioResult(
                scenarioId: scenario.id,
                engineId: engine.id,
                metrics: const <String, double>{},
                notes:
                    scenario is PlannedScenario
                        ? 'planned for ${scenario.segment}'
                        : 'not supported by this API',
              ),
            );
            continue;
          }
          log?.call('${scenario.id} ${engine.id}');
          final context = ScenarioContext(
            tester: tester,
            engine: engine,
            extents: extents,
          );
          final errors = <FlutterErrorDetails>[];
          final result = await _capturingErrors(errors, () async {
            final result = await scenario.run(context);
            await _settle(tester);
            // Unmount before disposing controllers.
            await tester.pumpWidget(const SizedBox.shrink());
            return result;
          });
          results.add(errors.isEmpty ? result : _withErrors(result, errors));
        } finally {
          engine.dispose();
        }
      }
    }
    return results;
  }

  /// Lets engine animations finish so their tickers do not outlive the run.
  static Future<void> _settle(WidgetTester tester) async {
    for (var i = 0; i < 600 && tester.binding.hasScheduledFrame; i++) {
      await tester.pump(ScenarioContext.frame);
    }
  }

  /// Records framework errors thrown by an engine as part of its result
  /// instead of failing the whole run, then restores the test handler.
  static Future<ScenarioResult> _capturingErrors(
    List<FlutterErrorDetails> errors,
    Future<ScenarioResult> Function() body,
  ) async {
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;
    try {
      return await body();
    } finally {
      FlutterError.onError = previous;
    }
  }

  static ScenarioResult _withErrors(
    ScenarioResult result,
    List<FlutterErrorDetails> errors,
  ) {
    final first = errors.first.exceptionAsString().split('\n').first;
    return ScenarioResult(
      scenarioId: result.scenarioId,
      engineId: result.engineId,
      metrics: <String, double>{
        ...result.metrics,
        'framework_errors': errors.length.toDouble(),
      },
      passed: false,
      notes:
          '${result.notes}; ${errors.length} framework error(s), first: $first',
    );
  }
}
