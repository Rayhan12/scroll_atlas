import 'insert_while_reading_scenario.dart';
import 'jump_storm_scenario.dart';
import 'long_animate_scenario.dart';
import 'scenario.dart';

/// B1 to B6. B4 and B5 land with the features that add the
/// features they measure. B3 compares frame times with ListView, so it only
/// means something in profile mode on a real device.
List<Scenario> scenarioCatalog() => <Scenario>[
  JumpStormScenario(),
  LongAnimateScenario(),
  const PlannedScenario(
    'B3',
    '10 s scripted fling through 100,000 items',
    'a profile run on a real device',
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
  InsertWhileReadingScenario(),
];
