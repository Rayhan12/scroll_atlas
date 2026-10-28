import 'scenario_result.dart';

/// Renders runs as Markdown tables. Pure Dart, shared by the headless test and
/// `benchmark/compare.dart` so both print the same format.
abstract final class MarkdownReport {
  static String _fmt(double v) => !v.isFinite ? 'n/a' : _fmtFinite(v);

  static String _fmtFinite(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(2);

  /// One table per scenario: rows are engines, columns are metrics.
  static String tables(BenchmarkRun run) {
    final out = StringBuffer();
    final byScenario = <String, List<ScenarioResult>>{};
    for (final r in run.results) {
      byScenario.putIfAbsent(r.scenarioId, () => []).add(r);
    }
    for (final entry in byScenario.entries) {
      final keys =
          <String>{for (final r in entry.value) ...r.metrics.keys}.toList();
      out
        ..writeln('### ${entry.key}')
        ..writeln();
      if (keys.isEmpty) {
        out
          ..writeln('Not measured yet: ${entry.value.first.notes}.')
          ..writeln();
        continue;
      }
      out
        ..writeln('| engine | ${keys.join(' | ')} | target met | notes |')
        ..writeln('|---|${keys.map((_) => '---:').join('|')}|---|---|');
      for (final r in entry.value) {
        final cells = keys.map(
          (k) => r.metrics.containsKey(k) ? _fmt(r.metrics[k]!) : '-',
        );
        final met = switch (r.passed) {
          true => 'yes',
          false => 'no',
          null => '-',
        };
        out.writeln(
          '| ${r.engineId} | ${cells.join(' | ')} | $met | ${r.notes} |',
        );
      }
      out.writeln();
    }
    return out.toString();
  }

  /// Deltas of [current] against [baseline] for matching scenario, engine
  /// and metric. Positive percent means the current value is higher.
  static String compare(BenchmarkRun baseline, BenchmarkRun current) {
    final out =
        StringBuffer()
          ..writeln(
            '| scenario | engine | metric | baseline | current | delta |',
          )
          ..writeln('|---|---|---|---:|---:|---:|');
    for (final now in current.results) {
      final before = baseline.results.where(
        (b) => b.scenarioId == now.scenarioId && b.engineId == now.engineId,
      );
      if (before.isEmpty) continue;
      for (final metric in now.metrics.entries) {
        final old = before.first.metrics[metric.key];
        if (old == null) continue;
        final delta =
            old == 0
                ? '-'
                : '${((metric.value - old) / old * 100).toStringAsFixed(1)}%';
        out.writeln(
          '| ${now.scenarioId} | ${now.engineId} | ${metric.key} | ${_fmt(old)} | ${_fmt(metric.value)} | $delta |',
        );
      }
    }
    return out.toString();
  }
}
