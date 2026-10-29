# Changelog

## 0.3.0-dev.1 (unreleased)

- `AtlasController.positions`, a `ValueListenable<List<AtlasItemPosition>>` of the visible items in every attached list, with `itemLeadingEdge` and `itemTrailingEdge` relative to the viewport below pinned headers (same semantics as scrollable_positioned_list's `ItemPosition`).
- Positions notify at most once per frame and only when they change; `inSliver`, `firstFullyVisible` and `mostVisible` helpers.
- `AtlasScrollSpy`, the active section is the last one whose header has reached the bottom of the pinned area; a short last section wins at the end of the scroll.
- `AtlasTabBar`, a `TabBar` kept in sync with the scroll; a tap locks the spy, animates to the section and moves the indicator once; a drag during the animation hands control back to the spy.
- Example D1 shows a "Visible: a to b" readout; D4 Food menu (collapsing hero, pinned tabs over 8 sections).

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
