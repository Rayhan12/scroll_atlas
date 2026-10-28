// Prints metric deltas between two saved runs.
//
// Usage: dart run compare.dart <baseline.json> <current.json>
import 'dart:convert';
import 'dart:io';

import 'package:scroll_atlas_benchmark/results/markdown_report.dart';
import 'package:scroll_atlas_benchmark/results/scenario_result.dart';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln(
      'Usage: dart run compare.dart <baseline.json> <current.json>',
    );
    exit(64);
  }
  BenchmarkRun load(String path) => BenchmarkRun.fromJson(
    (jsonDecode(File(path).readAsStringSync()) as Map).cast<String, Object?>(),
  );
  stdout.write(MarkdownReport.compare(load(args[0]), load(args[1])));
}
