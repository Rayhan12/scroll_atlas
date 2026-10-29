# Changelog

## 0.1.1

- README: simpler sections with a screenshot per feature.

## 0.1.0

First release.

### Jump to any item

- `AtlasListView` (`.builder` and `.separated`) and `AtlasController` with `jumpTo`, `animateTo` and `animateBy`. Jumps land on the exact pixel in one frame, and long animations end without a snap, even when item heights are unknown.
- Inserting items above the visible area keeps what you are reading in place.
- `AtlasController.positions` reports the visible items with leading and trailing edges, at most once per frame, with `inSliver`, `firstFullyVisible` and `mostVisible` helpers.

### Slivers and sticky headers

- `AtlasScrollView` and `AtlasScope`: jump to an item, a section or any sliver inside a `CustomScrollView`, including slivers that were never built.
- `SliverAtlasSection`, a section with a sticky header that pushes the previous one and reports how stuck it is.
- `AtlasAnchor` makes any sliver a jump target.
- Targets land below pinned app bars and stuck headers by default. `respectPinned: false` aligns to the viewport edge.
- Works with pinned, floating and stretch `SliverAppBar`, flutter_sticky_header and sliver_tools `MultiSliver`.

### Scroll spy and tabs

- `AtlasScrollSpy` tracks the active section.
- `AtlasTabBar` keeps a `TabBar` in sync with the scroll. A tap moves the indicator once and scrolls to the section; dragging during the animation hands control back to the scroll.

### Linked scrolling

- `LinkedScrollGroup` keeps any number of scroll views at the same offset, vertical or horizontal. Only the view being dragged drives, so there is never a second fling.
- `LinkedTable`, a frozen header row and first column over a lazily built body. The body scrolls diagonally (`diagonalDragBehavior`, free by default) and the headers follow on every frame.

### Drop-in compatibility

- `package:scroll_atlas/compat.dart` provides `ScrollablePositionedList`, `ItemScrollController`, `ItemPositionsListener`, `ScrollOffsetController`, `ScrollOffsetListener` and `LinkedScrollControllerGroup` with the same API as scrollable_positioned_list 0.3.8 and linked_scroll_controller. `shrinkWrap` and `opacityAnimationWeights` are deprecated.

### Testing helpers

- `package:scroll_atlas/fixtures.dart`: seeded fixtures and position assertions for widget tests.

### Example app

- A gallery of five demos (food menu, contacts, chat, table bookings, jump lab). Each one states the problem, what breaks with a plain `ListView` and what scroll_atlas fixes, in light and dark mode.
