# scroll_atlas_benchmark

Benchmark harness for scroll_atlas. Not published.

Engines compared through one `ListEngine` interface (`lib/engines/engine_catalog.dart`): scroll_atlas (`AtlasListView`), the scroll_atlas prototype, super_sliver_list, scrollable_positioned_list, scrollview_observer and a plain `ListView`.

Scenarios (`lib/scenarios/scenario_catalog.dart`): B1 jump storm, B2 long animate and B6 insert while reading are implemented. B3 (10 s fling, p90 frame time within 10% of ListView) needs a profile run on a real device, so it is not measured on the simulator or headless. B4 and B5 come later.

## Run

```
flutter test test/headless_benchmark_test.dart              # headless, debug, deterministic accuracy and builds
dart run run.dart --device <id>                    # real device, profile mode, frame build and raster times
dart run run.dart --device <sim-id> --mode debug   # simulator (debug only, timings not comparable)
dart run compare.dart <baseline.json> <current.json>
flutter run                                        # engine picker for a manual feel check
```

Results go to `results/<name>-<date>.json` and `.md`. Headless runs use the name `flutter_test` unless you pass `--dart-define=SA_RUN_NAME=<name>`, so a new run does not overwrite an older one.

## Prototype before and AtlasListView after (headless, debug)

The prototype is the first engine measured (`results/flutter_test-2026-10-29.md`). `AtlasListView` is (`results/flutter_test-s1-2026-10-29.md`).

| scenario | target | prototype | AtlasListView | met |
|---|---|---|---|---|
| B1 jump storm | settled in 1 frame, error <= 0.5 px, built <= 30 | 100% in 1 frame, 0 px, built p50 12, max 16 | 100% in 1 frame, 0 px, built p50 12, max 16, wall p50 2.22 ms | yes |
| B2 animate 80,000 items | error <= 0.5 px, last frame move < 2 px | error 0, but snaps at the end (last move n/a), fail | error 0, last move 0.11 px, 40 frames | yes |
| B6 insert 20 above while reading | item moves < 0.5 px | not measured for the prototype; the prototype fails (item pushed off screen) | shift 0 px on the first frame and after settling | yes |

Other engines in the headless run: super_sliver_list matches B1 but fails B2 (snap) and B6; scrollable_positioned_list passes B2 (0.44 px) but builds 36 to 44 items per jump (fails B1) and fails B6; scrollview_observer settles only 1% of jumps in 1 frame and fails B2 and B6.

Each engine is measured against its own alignment convention (`lib/measure/alignment_convention.dart`). 
