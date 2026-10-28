// Benchmark measurements, headless under flutter_test.
//
// Run: cd benchmark && flutter test test/headless_benchmark_test.dart
//
// Writes results/flutter_test-<date>.json and results/flutter_test-<date>.md.
// Accuracy, frames to settle and items built are deterministic here. Wall
// times are debug-mode JIT numbers on the host CPU: compare them only with
// each other, never with device profile numbers.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas_benchmark/benchmark_runner.dart';
import 'package:scroll_atlas_benchmark/results/markdown_report.dart';

void main() {
  testWidgets('B1 and B2 for every engine', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final run = await BenchmarkRunner().record(
      tester,
      environment: <String, Object?>{
        'device': 'flutter_test',
        'mode': 'debug (flutter_test, host VM)',
        'host_os': Platform.operatingSystem,
        'dart': Platform.version.split(' ').first,
        'viewport_logical': '390x844',
      },
      log: (m) => debugPrint('running $m'),
    );
    final date = run.environment['date'];
    final results = run.results;
    Directory('results').createSync(recursive: true);
    File('results/flutter_test-$date.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(run.toJson()),
    );
    final table = MarkdownReport.tables(run);
    File('results/flutter_test-$date.md').writeAsStringSync(table);
    debugPrint(table);

    final prototype = results.where(
      (r) => r.engineId == 'scroll_atlas_prototype' && r.scenarioId == 'B1',
    );
    expect(
      prototype.single.passed,
      isTrue,
      reason: 'prototype must meet the B1 target',
    );
  }, timeout: const Timeout(Duration(minutes: 10)));
}
