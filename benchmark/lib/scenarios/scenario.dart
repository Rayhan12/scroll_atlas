import 'package:scroll_atlas/scroll_atlas.dart';

import '../results/scenario_result.dart';
import 'scenario_context.dart';

/// One benchmark scenario (B1 to B6).
abstract interface class Scenario {
  String get id;

  String get title;

  /// Whether [engine] has the capability this scenario needs. Engines that
  /// do not are skipped, never faked (Liskov).
  bool supports(ListEngine engine);

  Future<ScenarioResult> run(ScenarioContext context);
}

/// Base for scenarios that need [IndexJumper].
abstract base class JumpScenario implements Scenario {
  @override
  bool supports(ListEngine engine) => engine is IndexJumper;

  IndexJumper jumper(ScenarioContext context) => context.engine as IndexJumper;
}

/// A scenario registered now and implemented later, so result
/// files and tables list it as planned instead of silently omitting it.
final class PlannedScenario implements Scenario {
  const PlannedScenario(this.id, this.title, this.segment);

  @override
  final String id;

  @override
  final String title;

  /// When it is expected, for example `a later version`.
  final String segment;

  @override
  bool supports(ListEngine engine) => false;

  @override
  Future<ScenarioResult> run(ScenarioContext context) =>
      throw UnsupportedError('$id is planned for $segment');
}
