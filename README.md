<!--
  pub.dev may not resolve relative image paths. Before publishing, replace each
  `assets/...` path with its raw.githubusercontent.com URL on the main branch.
-->

<p align="center">
  <img src="assets/hero.png" alt="scroll_atlas: scroll to any index, sticky-aware jumps, linked controllers, scroll-synced tabs" width="100%">
</p>

<h1 align="center">scroll_atlas</h1>

<p align="center">
  Precise scrolling for Flutter. Jump to any index, in any sliver, below any pinned header.
</p>

<p align="center">
  <a href="https://pub.dev/packages/scroll_atlas"><img src="https://img.shields.io/pub/v/scroll_atlas.svg?include_prereleases" alt="pub version"></a>
  <a href="https://pub.dev/packages/scroll_atlas/score"><img src="https://img.shields.io/pub/likes/scroll_atlas" alt="pub likes"></a>
  <a href="https://pub.dev/packages/scroll_atlas/score"><img src="https://img.shields.io/pub/points/scroll_atlas" alt="pub points"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT license"></a>
</p>

> **Status: preview, not published yet.** All features below are built and tested. The pub badges stay empty until the first release.

## Features

- **Scroll to any index.** `jumpTo` and `animateTo` land exactly on items that have never been built, with variable heights, in lists of any length.
- **Works with other slivers.** Put index-addressable lists anywhere in a `CustomScrollView` and target them by id, not by `BuildContext`.
- **Sticky-aware alignment.** Targets land below pinned app bars and stuck section headers by default, so they are never hidden.
- **Sticky sections.** `SliverAtlasSection` gives you sticky headers that know when they are stuck.
- **Visible items.** `positions` reports which items are on screen and how much of each.
- **Scroll-synced tabs.** `AtlasTabBar` follows the scroll and scrolls on tap, without the indicator flickering through every tab.
- **Linked scrollables.** `LinkedScrollGroup` keeps header rows and frozen columns aligned during flings, and `LinkedTable` scrolls diagonally with both headers in line.
- **Stable while content changes.** Inserting items above, or images loading above, does not move what the user is reading.
- **Drop-in migration.** `package:scroll_atlas/compat.dart` keeps the class names of `scrollable_positioned_list` and `linked_scroll_controller`.


| D2 Contacts | D3 Timetable | D4 Food menu | D6 Chat |
|---|---|---|---|
| <img src="assets/screenshots/d2.png" width="200" alt="Contacts with sticky letter headers"> | <img src="assets/screenshots/d3.png" width="200" alt="Timetable with linked headers"> | <img src="assets/screenshots/d4.png" width="200" alt="Food menu with scroll-synced tabs"> | <img src="assets/screenshots/d6.png" width="200" alt="Chat that opens at the first unread message"> |

Run the demo app yourself with `cd example && flutter run`.

## Install

```sh
flutter pub add scroll_atlas
```

Or in `pubspec.yaml`:

```yaml
dependencies:
  scroll_atlas: ^0.2.0-dev.1
```

## Quick start

### A list you can jump around in

```dart
import 'package:flutter/material.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

class Messages extends StatefulWidget {
  const Messages({super.key, required this.items});
  final List<String> items;

  @override
  State<Messages> createState() => _MessagesState();
}

class _MessagesState extends State<Messages> {
  final atlas = AtlasController();

  @override
  void dispose() {
    atlas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.vertical_align_top),
            onPressed: () => atlas.animateTo(
              index: 0,
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
      body: AtlasListView.builder(
        controller: atlas,
        itemCount: widget.items.length,
        itemBuilder: (context, i) => ListTile(title: Text(widget.items[i])),
      ),
    );
  }
}

// Anywhere: atlas.jumpTo(index: 7321, alignment: 0.5);
```

### Sections with sticky headers in a CustomScrollView

```dart
AtlasScrollView(
  controller: atlas,
  slivers: [
    const SliverAppBar(pinned: true, title: Text('Contacts')),
    for (final section in sections)
      SliverAtlasSection(
        id: section.letter,
        header: (context, stuck) => LetterHeader(section.letter, raised: stuck > 0),
        sliver: SliverAtlasList.builder(
          id: 'people-${section.letter}',
          itemCount: section.people.length,
          itemBuilder: (context, i) => PersonTile(section.people[i]),
        ),
      ),
  ],
);

// Lands right below the pinned app bar and the stuck "K" header.
// Pass respectPinned: false to align to the viewport edge instead.
atlas.animateTo(
  target: AtlasTarget.item('people-K', 3),
  duration: const Duration(milliseconds: 400),
);
```

Any other sliver becomes a target when you wrap it in `AtlasAnchor`:

```dart
const AtlasAnchor(id: 'footer', sliver: SliverToBoxAdapter(child: Footer())),
// ...
atlas.jumpTo(target: const AtlasTarget.sliver('footer'));
```

### Tabs that follow the scroll

```dart
AtlasTabBar(
  controller: atlas,
  sectionIds: menu.map((s) => s.id).toList(),
  tabs: [for (final s in menu) Tab(text: s.title)],
);
```

Put it in a pinned `SliverAppBar.bottom`. A tap locks the scroll spy, animates to the section and moves the indicator once; dragging during the animation hands control back to the spy. A short last section becomes active at the end of the scroll. For your own UI, use `AtlasScrollSpy(controller: atlas, sectionIds: ids)`, a `ValueListenable<int>` of the active section.

### Which items are visible

```dart
ValueListenableBuilder<List<AtlasItemPosition>>(
  valueListenable: atlas.positions,
  builder: (context, positions, _) {
    final first = positions.inSliver('messages').firstFullyVisible;
    return Text('First fully visible: ${first?.index}');
  },
);
```

Each `AtlasItemPosition` has the sliver id, the index and `itemLeadingEdge` and `itemTrailingEdge` as fractions of the viewport below pinned headers, like `ItemPosition` in scrollable_positioned_list. The list updates at most once per frame. `firstFullyVisible` and `mostVisible` cover the usual needs.

### Linked scrollables

```dart
final group = LinkedScrollGroup();
final headerRow = group.createController();
final body = group.createController();
// Give headerRow and body to two horizontal scroll views; they now move together.
```

Only the scroll view under the finger drives; the others follow in the same frame, so flings never fight and nobody overshoots. A controller created after the group has moved starts at the group's offset, and disposing one member leaves the others scrolling. `group.jumpTo`, `group.animateTo` and `group.addOffsetListener` work on all members at once. Call `group.dispose()` after the controllers.

`LinkedTable` is built on two groups: a frozen header row and first column over a lazily built body that scrolls in both directions at once. Pass `diagonalDragBehavior: DiagonalDragBehavior.none` to lock each drag to one axis.

```dart
LinkedTable(
  rowCount: 1000,
  columnCount: 50,
  cellBuilder: (context, row, column) => Text('$row:$column'),
  columnHeaderBuilder: (context, column) => Text('C$column'),
  rowHeaderBuilder: (context, row) => Text('R$row'),
)
```

## Migrating from scrollable_positioned_list

Swap the dependency and the import. The class names stay the same:

```diff
-  scrollable_positioned_list: ^0.3.8
+  scroll_atlas: ^0.2.0-dev.1

-import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
+import 'package:scroll_atlas/compat.dart';
```

`LinkedScrollControllerGroup` from linked_scroll_controller is in `compat.dart` too. Two differences: `scrollTo` glides to the target instead of cross fading, and `shrinkWrap: true` is not supported.

## How it compares

Facts read from the pub.dev and GitHub APIs on 2026-10-28.

| Package | Latest version | Last published | Downloads (30 days) | Likes | Repository |
|---|---|---|---|---|---|
| [scrollable_positioned_list](https://pub.dev/packages/scrollable_positioned_list) | 0.3.8 | 2023-05-08 | 679,109 | 1,995 | google/flutter.widgets, archived, BSD-3-Clause |
| [linked_scroll_controller](https://pub.dev/packages/linked_scroll_controller) | 0.2.0 | 2021-05-05 | 158,099 | 335 | google/flutter.widgets, archived |
| [scroll_to_index](https://pub.dev/packages/scroll_to_index) | 3.0.1 | 2022-05-18 | 474,878 | 821 | quire-io/scroll-to-index |
| [scrollview_observer](https://pub.dev/packages/scrollview_observer) | 1.27.3 | 2026-09-14 | 137,517 | 325 | fluttercandies/flutter_scrollview_observer, MIT |
| [super_sliver_list](https://pub.dev/packages/super_sliver_list) | 0.4.1 | 2024-03-26 | 112,647 | 301 | superlistapp/super_sliver_list, MIT |
| scroll_atlas | not published | | | | MIT |

What the other packages' own docs say:

- scrollview_observer is actively maintained and covers ListView, SliverList, GridView and mixed CustomScrollViews. For items with dynamic heights it recommends a large `cacheExtent` to reduce "page turning" during a jump, in a CustomScrollView each target sliver is identified by its `BuildContext`, and the height of a pinned `SliverAppBar` at the target is returned from a callback you provide ([wiki](https://github.com/fluttercandies/flutter_scrollview_observer/wiki)).
- super_sliver_list jumps to items that are not built yet, inside slivers, and its README notes that scrollable_positioned_list cannot be combined with other slivers ([README](https://github.com/superlistapp/super_sliver_list)).

scroll_atlas aims to combine id-based targets, sticky-aware alignment, scroll-synced tabs, linked controllers and a drop-in layer for the two archived Google packages in one maintained package. Speed comparisons will appear here only after they are measured with the benchmark app on real devices, with links to the raw results.

Measured so far (headless test runs and an iOS simulator in debug mode, not real devices yet): `AtlasListView` lands every jump in one frame within 0.5 px while building at most 16 items, animates across 80,000 items without a snap at the end (last frame move 0.11 px headless, 1.73 px on the iOS simulator), and keeps the item you are reading still when 20 items are inserted above it. Across 26 sticky sections under a pinned bar, 500 of 500 jumps land in one frame with no target hidden under a header. A 1,000 x 50 `LinkedTable` keeps its headers and body within 0 px of each other on every frame of 24 two-finger diagonal flings. Details: [`benchmark/README.md`](benchmark/README.md).

## Example app

The `example/` app opens on a gallery of five demos: a food menu with tabs that follow the sections, contacts A to Z with sticky headers, a chat that opens at the first unread message, a room booking table with a frozen header row and column, and a jump lab with 100,000 items. Each demo says what breaks with a plain `ListView` and what scroll_atlas fixes.

## Contributing

Contributions are welcome.

1. Open an issue first for anything larger than a small fix, so we can agree on the API.
2. Fork, then create a branch from `main`.
3. Run the checks before you push:
   ```sh
   dart format --set-exit-if-changed .
   flutter analyze
   flutter test
   ```
4. Add tests for new behavior. Scroll positions are checked to within 0.5 px.
5. Open a pull request and describe how you tested it (device, Flutter version).

Bug reports are most useful with your Flutter version, the device, and a minimal reproduction.

## License

MIT. See [LICENSE](LICENSE). Copyright (c) 2026 Rayhanul Islam.

scroll_atlas is an independent implementation. It shares no code with google/flutter.widgets; the compat layer only mirrors public class and method names to ease migration.
