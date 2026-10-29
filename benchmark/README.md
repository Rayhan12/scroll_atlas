# scroll_atlas benchmarks

A benchmark app that runs the same scenarios against scroll_atlas and the packages it replaces: super_sliver_list, scrollable_positioned_list, scrollview_observer and a plain `ListView`.

## Scenarios

| Id | Scenario | Target |
|---|---|---|
| B1 | Jump storm: 200 seeded random jumps in a list of variable-height items | settled in 1 frame, error <= 0.5 px, <= 30 items built |
| B2 | 600 ms `animateToIndex` from item 1,000 to item 81,000 | error <= 0.5 px, last frame moves < 2 px (no snap) |
| B3 | 10 s fling | p90 frame time within 10% of `ListView` (needs a profile run on a real device) |
| B4 | 500 jumps across 26 sticky sections under a pinned app bar | no target hidden under a header, settled in 1 frame |
| B5 | 1,000 x 50 linked table, 24 two-finger diagonal flings | members of an axis within 0.5 px on every frame |
| B6 | Insert 20 items above the item being read | the item moves < 0.5 px |

Scenarios live in `lib/scenarios/scenario_catalog.dart`.

## Run

```
flutter test test/headless_benchmark_test.dart              # headless, debug, deterministic accuracy and builds
dart run run.dart --device <id>                    # real device, profile mode, frame build and raster times
dart run run.dart --device <sim-id> --mode debug   # simulator (debug only, timings not comparable)
dart run compare.dart <baseline.json> <current.json>
flutter run                                        # engine picker for a manual feel check
```

Results are written to `results/<name>-<date>.json` and `.md` (not committed). Pass `--dart-define=SA_RUN_NAME=<name>` so a new run does not overwrite an older one.

## Latest headless results (debug, host VM)

| Scenario | scroll_atlas | Target met |
|---|---|---|
| B1 | 100% of jumps settled in 1 frame, error 0 px, 12 items built (p50), 16 max | yes |
| B2 | final error 0 px, last frame move 0.11 px over 40 frames | yes |
| B4 | 0 targets covered, 500 of 500 settled in 1 frame | yes |
| B5 | misalignment 0.00 px over 2,448 frames, 0 unsettled flings | yes |
| B6 | item shift 0 px | yes |

For comparison, scrollable_positioned_list builds 36 to 44 items per jump in B1, and super_sliver_list snaps at the end of B2. Neither keeps the reading position in B6.

On the iPhone 17 Pro simulator (debug), B2 ends 1.73 px from the target over 23 frames with no janky frames.

Wall times in a debug run say nothing about a device. B3 and frame build and raster times need a profile build on a real device.

## compat API check

```
dart run tool/compat_api_diff.dart
```

Compares the public API of `package:scroll_atlas/compat.dart` with scrollable_positioned_list and linked_scroll_controller, and fails on any difference that is not listed as known.
