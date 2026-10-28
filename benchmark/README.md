# scroll_atlas_benchmark

Benchmark harness for scroll_atlas. Not published.

Engines compared through one `ListEngine` interface (`lib/engines/engine_catalog.dart`): the scroll_atlas prototype, super_sliver_list, scrollable_positioned_list, scrollview_observer and a plain `ListView`.

Scenarios (`lib/scenarios/scenario_catalog.dart`): B1 jump storm and B2 long animate are implemented; B3 to B6 are listed as planned.

## Run

```
flutter test test/headless_benchmark_test.dart              # headless, debug, deterministic accuracy and builds
dart run run.dart --device <id>                    # real device, profile mode, frame build and raster times
dart run run.dart --device <sim-id> --mode debug   # simulator (debug only, timings not comparable)
dart run compare.dart <baseline.json> <current.json>
flutter run                                        # engine picker for a manual feel check
```

Results go to `results/<device>-<date>.json` and `.md`.

Each engine is measured against its own alignment convention (`lib/measure/alignment_convention.dart`). 
