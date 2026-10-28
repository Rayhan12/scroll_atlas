// Coverage gate for CI. Dependency-free; uses dart:io only.
//
// Usage: dart run tool/check_coverage.dart <lcov.info> <path-prefix> <min-percent>
import 'dart:io';

void main(List<String> args) {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/check_coverage.dart <lcov.info> <path-prefix> <min-percent>',
    );
    exit(64);
  }

  final lcovPath = args[0];
  final pathPrefix = args[1];
  final minPercent = double.tryParse(args[2]);
  if (minPercent == null) {
    stderr.writeln('Invalid minimum percent: ${args[2]}');
    exit(64);
  }

  final file = File(lcovPath);
  if (!file.existsSync()) {
    stderr.writeln('LCOV file not found: $lcovPath');
    exit(1);
  }

  var totalLines = 0;
  var hitLines = 0;
  var matchedFiles = 0;
  var currentPath = '';
  var includeCurrent = false;

  for (final line in file.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      currentPath = line.substring(3).trim();
      includeCurrent = currentPath.contains(pathPrefix);
      if (includeCurrent) {
        matchedFiles++;
      }
      continue;
    }
    if (!includeCurrent) {
      continue;
    }
    if (line.startsWith('LF:')) {
      totalLines += int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('LH:')) {
      hitLines += int.tryParse(line.substring(3).trim()) ?? 0;
    }
  }

  if (matchedFiles == 0) {
    stderr.writeln(
      'No LCOV records matched path prefix "$pathPrefix" in $lcovPath',
    );
    exit(1);
  }

  if (totalLines == 0) {
    stderr.writeln('Matched files have LF:0; cannot compute coverage.');
    exit(1);
  }

  final percent = 100.0 * hitLines / totalLines;
  stdout.writeln(
    'Coverage for "$pathPrefix": ${percent.toStringAsFixed(1)}% '
    '($hitLines / $totalLines lines, $matchedFiles files)',
  );

  if (percent + 1e-9 < minPercent) {
    stderr.writeln('Below threshold $minPercent%.');
    exit(1);
  }
}
