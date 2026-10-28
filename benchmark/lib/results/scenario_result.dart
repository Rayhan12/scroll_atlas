/// One engine's result for one scenario. Pure Dart (no Flutter imports).
final class ScenarioResult {
  const ScenarioResult({
    required this.scenarioId,
    required this.engineId,
    required this.metrics,
    this.passed,
    this.notes = '',
  });

  factory ScenarioResult.fromJson(Map<String, Object?> json) => ScenarioResult(
    scenarioId: json['scenario'] as String,
    engineId: json['engine'] as String,
    metrics: (json['metrics'] as Map<String, Object?>).map(
      (key, value) =>
          MapEntry(key, (value as num?)?.toDouble() ?? double.infinity),
    ),
    passed: json['passed'] as bool?,
    notes: json['notes'] as String? ?? '',
  );

  final String scenarioId;
  final String engineId;
  final Map<String, double> metrics;

  /// Whether the target for the scenario was met; null when the
  /// scenario has no pass rule for this engine.
  final bool? passed;
  final String notes;

  Map<String, Object?> toJson() => <String, Object?>{
    'scenario': scenarioId,
    'engine': engineId,
    // JSON has no infinity; null means never (for example never built).
    'metrics': metrics.map(
      (key, value) => MapEntry(key, value.isFinite ? value : null),
    ),
    'passed': passed,
    'notes': notes,
  };
}

/// A whole run: environment plus results.
final class BenchmarkRun {
  const BenchmarkRun({required this.environment, required this.results});

  factory BenchmarkRun.fromJson(Map<String, Object?> json) => BenchmarkRun(
    environment:
        (json['environment'] as Map<String, Object?>).cast<String, Object?>(),
    results:
        (json['results'] as List<Object?>)
            .map((r) => ScenarioResult.fromJson(r! as Map<String, Object?>))
            .toList(),
  );

  final Map<String, Object?> environment;
  final List<ScenarioResult> results;

  Map<String, Object?> toJson() => <String, Object?>{
    'environment': environment,
    'results': results.map((r) => r.toJson()).toList(),
  };
}
