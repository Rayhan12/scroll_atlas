// Runs the benchmark on a device and saves results/<device>-<date>.*.
//
// Usage: dart run run.dart --device <id> [--mode profile|debug] [--name <n>]
// Profile mode needs a physical device; simulators only run debug, whose
// timings are not comparable with device numbers.
import 'dart:io';

Future<void> main(List<String> args) async {
  String? option(String name) {
    final i = args.indexOf('--$name');
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final device = option('device');
  if (device == null) {
    stderr.writeln(
      'Usage: dart run run.dart --device <id> [--mode profile|debug] '
      '[--name <file-name>]',
    );
    exit(64);
  }
  final mode = option('mode') ?? 'profile';
  final process = await Process.start(
    'flutter',
    <String>[
      'drive',
      '--$mode',
      '--driver=test_driver/perf_driver.dart',
      '--target=integration_test/benchmark_test.dart',
      '-d',
      device,
    ],
    environment: <String, String>{'SA_DEVICE': option('name') ?? device},
    mode: ProcessStartMode.inheritStdio,
  );
  exit(await process.exitCode);
}
