// On-device benchmark run. Same runner and scenarios as the headless
// test; only the binding and the result sink differ.
//
// Run through run.dart, for example:
//   dart run run.dart --device <device-id>            (profile, real device)
//   dart run run.dart --device <sim-id> --mode debug  (simulator)
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:scroll_atlas_benchmark/benchmark_runner.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('benchmark on device', (tester) async {
    final run = await BenchmarkRunner().record(
      tester,
      environment: <String, Object?>{
        'device': defaultTargetPlatform.name,
        'mode': kProfileMode ? 'profile' : (kReleaseMode ? 'release' : 'debug'),
        'viewport_logical':
            '${tester.view.physicalSize.width / tester.view.devicePixelRatio}x'
            '${tester.view.physicalSize.height / tester.view.devicePixelRatio}',
      },
      log: debugPrint,
    );
    binding.reportData = <String, Object?>{'run': run.toJson()};
  }, timeout: const Timeout(Duration(minutes: 20)));
}
