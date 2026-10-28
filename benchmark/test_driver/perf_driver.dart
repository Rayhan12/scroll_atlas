// Host side of the on-device run: writes the report the app sends back to
// results/<device>-<date>.json and .md. SA_DEVICE names the device file.
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';
import 'package:scroll_atlas_benchmark/results/markdown_report.dart';
import 'package:scroll_atlas_benchmark/results/scenario_result.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    if (data == null) return;
    final run = BenchmarkRun.fromJson(
      (data['run']! as Map).cast<String, Object?>(),
    );
    final device = Platform.environment['SA_DEVICE'] ?? 'device';
    final stem = 'results/$device-${run.environment['date']}';
    Directory('results').createSync(recursive: true);
    File('$stem.json').writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(run.toJson()),
    );
    File('$stem.md').writeAsStringSync(MarkdownReport.tables(run));
    stdout.writeln('Wrote $stem.json and $stem.md');
  },
);
