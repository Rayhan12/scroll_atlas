import 'jump_storm_scenario.dart';
import 'long_animate_scenario.dart';
import 'scenario.dart';

/// B1 to B6. B3 to B6 land with the features that add the
/// features they measure.
List<Scenario> scenarioCatalog() => <Scenario>[
  JumpStormScenario(),
  LongAnimateScenario(),
  const PlannedScenario(
    'B3',
    '10 s scripted fling through 100,000 items',
    'S1',
  ),
  const PlannedScenario(
    'B4',
    '500 jumps across 26 sticky sections',
    'a later version',
  ),
  const PlannedScenario(
    'B5',
    'linked 1,000 x 50 table, diagonal flings',
    'a later version',
  ),
  const PlannedScenario('B6', 'insert 20 items at top while reading', 'S1'),
];
