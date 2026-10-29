<p align="center">
  <img src="https://raw.githubusercontent.com/Rayhan12/scroll_atlas/main/assets/hero.png" alt="scroll_atlas: scroll to any item, land below sticky headers, tabs that follow the scroll" width="100%">
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

> **Status: 0.1.0, the first release.** All features below are built and tested.

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


| Food menu | Contacts | Table bookings | Chat |
|---|---|---|---|
| <img src="https://raw.githubusercontent.com/Rayhan12/scroll_atlas/main/assets/screenshots/food_menu.png" width="200" alt="Restaurant menu with category tabs that follow the sections"> | <img src="https://raw.githubusercontent.com/Rayhan12/scroll_atlas/main/assets/screenshots/contacts.png" width="200" alt="Contacts with sticky letter headers and an index rail"> | <img src="https://raw.githubusercontent.com/Rayhan12/scroll_atlas/main/assets/screenshots/table_bookings.png" width="200" alt="Table booking grid with a frozen time row and table column"> | <img src="https://raw.githubusercontent.com/Rayhan12/scroll_atlas/main/assets/screenshots/chat.png" width="200" alt="Chat that opens at the first unread message"> |

Run the demo app yourself with `cd example && flutter run`.

## Install

```sh
flutter pub add scroll_atlas
```

Or in `pubspec.yaml`:

```yaml
dependencies:
  scroll_atlas: ^0.1.0
```

## Quick start

### A list you can jump around in

<p align="center">
  <img src="https://raw.githubusercontent.com/Rayhan12/scroll_atlas/main/assets/screenshots/jump_lab.png" width="280" alt="Jump lab: jump to any of 100,000 items in one frame">
</p>

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

<p align="center">
  <img src="https://raw.githubusercontent.com/Rayhan12/scroll_atlas/main/assets/screenshots/contacts.png" width="280" alt="Contacts with sticky letter headers and an index rail">
</p>

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

<p align="center">
  <img src="https://raw.githubusercontent.com/Rayhan12/scroll_atlas/main/assets/screenshots/food_menu.png" width="280" alt="Restaurant menu with category tabs that follow the sections">
</p>

```dart
AtlasTabBar(
  controller: atlas,
  sectionIds: menu.map((s) => s.id).toList(),
  tabs: [for (final s in menu) Tab(text: s.title)],
);
```

Put it in a pinned `SliverAppBar.bottom`. A tap locks the scroll spy, animates to the section and moves the indicator once; dragging during the animation hands control back to the spy. A short last section becomes active at the end of the scroll. For your own UI, use `AtlasScrollSpy(controller: atlas, sectionIds: ids)`, a `ValueListenable<int>` of the active section.

### Which items are visible

<p align="center">
  <img src="https://raw.githubusercontent.com/Rayhan12/scroll_atlas/main/assets/screenshots/chat.png" width="280" alt="Chat that opens at the first unread message and tracks what is on screen">
</p>

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

<p align="center">
  <img src="https://raw.githubusercontent.com/Rayhan12/scroll_atlas/main/assets/screenshots/table_bookings.png" width="280" alt="Table booking grid with a frozen time row and table column">
</p>

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

## Example app

<p align="center">
  <img src="https://raw.githubusercontent.com/Rayhan12/scroll_atlas/main/assets/screenshots/gallery.png" width="280" alt="The example app gallery of five demos">
</p>

The `example/` app opens on a gallery of five demos: a food menu with tabs that follow the sections, contacts A to Z with sticky headers, a chat that opens at the first unread message, a restaurant table booking grid with a frozen time row and table column, and a jump lab with 100,000 items. Each demo says what breaks with a plain `ListView` and what scroll_atlas fixes.

## License

MIT. See [LICENSE](LICENSE). Copyright (c) 2026 Rayhanul Islam.

scroll_atlas is an independent implementation. It shares no code with google/flutter.widgets; the compat layer only mirrors public class and method names to ease migration.
