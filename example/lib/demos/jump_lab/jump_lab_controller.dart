import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:scroll_atlas/fixtures.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

/// State and scroll actions for the D1 Jump lab demo, on the public widgets
/// ([AtlasListView], [AtlasController], [AtlasScrollbar]).
///
/// Items keep a stable id: inserted items get ids -1, -2 and so on, so the
/// list can follow them with a keyed `findChildIndexCallback`.
final class JumpLabController {
  JumpLabController({Random? random})
      : _random = random ?? Random(),
        atlas = AtlasController(),
        extents = SeededExtents(seed: 42, length: baseCount),
        buildCounter = BuildCounter();

  /// Seeded items before any insert.
  static const int baseCount = 100000;

  /// Items added by one tap on "Insert 20 at top".
  static const int insertBatch = 20;

  /// Extra extent an item gets when its "image" loads.
  static const double growBy = 300;

  /// Items above the first visible one that grow per tap.
  static const int growCount = 3;

  /// Normal and slow-motion animation lengths.
  static const Duration animateDuration = Duration(milliseconds: 600);
  static const Duration slowDuration = Duration(milliseconds: 3000);

  final Random _random;
  final AtlasController atlas;
  final SeededExtents extents;
  final BuildCounter buildCounter;

  /// Wraps the list, so [lastJumpError] can find the target item.
  final GlobalKey listKey = GlobalKey(debugLabel: 'jump-lab-list');

  double alignment = 0.5;
  bool slowMotion = false;
  int targetIndex = 0;
  int insertedAtTop = 0;
  final Set<int> _grown = <int>{};

  int lastJumpBuilds = 0;
  double? lastJumpError;
  double? lastJumpMs;

  final TextEditingController indexController =
      TextEditingController(text: '0');

  int get itemCount => baseCount + insertedAtTop;

  void dispose() {
    indexController.dispose();
    atlas.dispose();
  }

  int parseIndex() {
    final parsed = int.tryParse(indexController.text.trim()) ?? targetIndex;
    return parsed.clamp(0, itemCount - 1);
  }

  void syncIndexFromField() {
    targetIndex = parseIndex();
    indexController.text = '$targetIndex';
  }

  void pickRandomIndex() {
    targetIndex = _random.nextInt(itemCount);
    indexController.text = '$targetIndex';
  }

  /// Jumps, then records builds, time and landing error of the next frame.
  /// Items build during layout, so these are known once that frame ends.
  Future<void> jump() async {
    syncIndexFromField();
    buildCounter.reset();
    final watch = Stopwatch()..start();
    atlas.jumpTo(index: targetIndex, alignment: alignment);
    await WidgetsBinding.instance.endOfFrame;
    lastJumpMs = watch.elapsedMicroseconds / 1000;
    lastJumpBuilds = buildCounter.builds;
    lastJumpError = measureError(targetIndex);
  }

  /// Animates with re-aiming; slow motion stretches it five times.
  Future<void> animate() async {
    syncIndexFromField();
    buildCounter.reset();
    final watch = Stopwatch()..start();
    await atlas.animateTo(
      index: targetIndex,
      alignment: alignment,
      duration: slowMotion ? slowDuration : animateDuration,
    );
    lastJumpMs = watch.elapsedMicroseconds / 1000;
    lastJumpBuilds = buildCounter.builds;
    lastJumpError = measureError(targetIndex);
  }

  /// Adds [insertBatch] items before item 0, newest first. The item being
  /// read keeps its place on screen.
  void insertAtTop() => insertedAtTop += insertBatch;

  /// Grows the [growCount] items just above the first visible item by
  /// [growBy], like images loading above the reader. Returns false when
  /// nothing is above the viewport.
  bool growAbove() {
    final first = atlas.visibleSpan?.first.floor() ?? 0;
    var grew = false;
    for (var index = first - growCount; index < first; index++) {
      if (index >= 0) grew = _grown.add(idAt(index)) || grew;
    }
    return grew;
  }

  /// Stable id of the item shown at [index].
  int idAt(int index) => index - insertedAtTop;

  /// Current extent of the item with [id].
  double extentOf(int id) {
    final base = extents[id < 0 ? (-id) % baseCount : id];
    return _grown.contains(id) ? base + growBy : base;
  }

  /// Index of a fixture item key, or null if it is gone.
  int? indexOfKey(Key key) {
    final id = FixtureKeys.idOf(key);
    if (id == null) return null;
    final index = id + insertedAtTop;
    return index < 0 || index >= itemCount ? null : index;
  }

  /// Distance in px between the item at [index] and the red marker, or
  /// null when the item is not built.
  double? measureError(int index) {
    final host = listKey.currentContext;
    final viewport = host?.findRenderObject();
    if (host == null || viewport is! RenderBox) return null;
    final id = idAt(index);
    RenderBox? item;
    void visit(Element element) {
      if (item != null) return;
      final widget = element.widget;
      if (widget is FixtureItem && widget.index == id) {
        item = element.findRenderObject() as RenderBox?;
        return;
      }
      element.visitChildElements(visit);
    }

    host.visitChildElements(visit);
    final found = item;
    if (found == null || !found.attached) return null;
    return PositionProbe.alignmentError(
      item: found,
      viewport: viewport,
      alignment: alignment,
    );
  }

  Widget buildList() {
    return KeyedSubtree(
      key: listKey,
      child: AtlasScrollbar(
        controller: atlas,
        child: AtlasListView.builder(
          controller: atlas,
          itemCount: itemCount,
          findChildIndexCallback: indexOfKey,
          itemBuilder: buildCounter.wrap(
            (BuildContext context, int index) {
              final id = idAt(index);
              return FixtureItem(index: id, extent: extentOf(id));
            },
          ),
        ),
      ),
    );
  }
}
