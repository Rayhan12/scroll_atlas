# Changelog

## 1.0.0 (unreleased)

- Every example screen has a "What to try" card and a debug overlay with built items, the last jump error and frame build and raster times. The toggles sit in a strip under the screen so they never cover its controls.
- `.github/workflows/pages.yml` builds the example for the web on `v*` tags and deploys it to GitHub Pages. Each demo has a deep link.
- Dartdoc examples on the main public classes; real screenshots of the example app in `assets/screenshots/` and in the pubspec; README status, live demo link and fixed links.
- Example D4: the collapsing title no longer overlaps the tab bar.

## 0.9.0 (unreleased)

- `package:scroll_atlas/compat.dart` with `ScrollablePositionedList` (`.builder` and `.separated`, every 0.3.8 parameter), `ItemScrollController`, `ScrollOffsetController`, `ItemPositionsListener`, `ScrollOffsetListener` and `ItemPosition`, all backed by one `AtlasController`. `shrinkWrap` and `opacityAnimationWeights` are deprecated: the first asserts when true, the second has no effect.
- `LinkedScrollControllerGroup` (`addAndGet`, `offset`, `jumpTo`, `animateTo`, `resetScroll`, offset listeners) on top of `LinkedScrollGroup`.
- `AtlasListView.separated` (indexes unchanged, separators follow `reverse`), `addSemanticIndexes` and `semanticChildCount`; `AtlasController.animateBy`.
- Compat test suite, including the old linked_scroll_controller README example.
- `benchmark/tool/compat_api_diff.dart` compares the public API with both old packages and fails on any difference not listed as known (52 public names checked).
- Example D5 Migration before and after: the same chat list on scrollable_positioned_list and on the compat layer, side by side.

## 0.3.0-dev.1 (unreleased)

- `AtlasController.positions`, a `ValueListenable<List<AtlasItemPosition>>` of the visible items in every attached list, with `itemLeadingEdge` and `itemTrailingEdge` relative to the viewport below pinned headers (same semantics as scrollable_positioned_list's `ItemPosition`).
- Positions notify at most once per frame and only when they change; `inSliver`, `firstFullyVisible` and `mostVisible` helpers.
- `AtlasScrollSpy`, the active section is the last one whose header has reached the bottom of the pinned area; a short last section wins at the end of the scroll.
- `AtlasTabBar`, a `TabBar` kept in sync with the scroll; a tap locks the spy, animates to the section and moves the indicator once; a drag during the animation hands control back to the spy.
- Example D1 shows a "Visible: a to b" readout; D4 Food menu (collapsing hero, pinned tabs over 8 sections).
- `LinkedScrollGroup` with `createController`, `offset`, `jumpTo`, `animateTo`, offset listeners and `positions`. Late joiners start at the group's offset; disposing a member mid-fling leaves the others together; vertical and horizontal.
- Only the member being scrolled drives; the others follow inside the same frame and stop their own activity, so there is never a second ballistic simulation. Overscroll is copied, and a shorter member stops at its own end.
- `LinkedTable`, a frozen header row and first column built from standard `ListView`s and two groups. Benchmark B5: 1,000 x 50 table, two-finger diagonal flings, misalignment and frame time p90 and p99.
- Example D3 Timetable (frozen times and rooms, "Go to 12:00", synced carousels).

## 0.2.0-dev.1 (unreleased)

- `AtlasScrollView` and `AtlasScope`. Atlas slivers register by id, and `AtlasController.jumpTo(target: AtlasTarget.item(id, index))` resolves a target anywhere in a `CustomScrollView`, including slivers that were never built. Duplicate ids fail with a clear error.
- `AtlasTarget.section(id)` and `AtlasTarget.sliver(id)`; `AtlasAnchor` makes any sliver (a grid, a box adapter) a target.
- `SliverAtlasSection`, a section with a sticky header that pushes the previous header and reports how stuck it is (0 to 1).
- Obstruction-aware alignment. Targets land below pinned app bars and stuck headers by default; `respectPinned: false` aligns to the viewport edge.
- Compatibility tests with pinned, floating and stretch `SliverAppBar`, flutter_sticky_header and sliver_tools `MultiSliver`.
- Example D2 Contacts A to Z (pinned app bar, 26 sticky headers, A to Z rail, "Respect pinned headers" toggle, Footer chip).
- Benchmark B4: 500 jumps across 26 sticky sections under a pinned bar.

## 0.1.0-dev.1 (unreleased)

- Package scaffold, strict analysis options, MIT license, example app shell.
- GitHub Actions CI workflow (format, analyze, tests with coverage gate, publish dry run, pana floor).
- Deterministic seeded fixtures (`package:scroll_atlas/fixtures.dart`) and position assertion helpers.
- Benchmark app with scenarios B1 and B2, JSON results and a compare script.
