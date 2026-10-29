import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'list_harness.dart';

/// A list of data ids that tests mutate, plus per-id extent overrides.
class _Feed extends ChangeNotifier {
  _Feed(int count) : ids = List<int>.generate(count, (i) => i);

  final List<int> ids;
  final Map<int, double> extents = {};

  void insertAtTop(List<int> newIds) {
    ids.insertAll(0, newIds);
    notifyListeners();
  }

  void resize(int id, double extent) {
    extents[id] = extent;
    notifyListeners();
  }
}

void main() {
  late AtlasController controller;

  setUp(() => controller = AtlasController());
  tearDown(() => controller.dispose());

  Future<_Feed> pump(
    WidgetTester tester, {
    int count = 100000,
    AtlasAnchorMode anchor = AtlasAnchorMode.firstVisible,
  }) async {
    final feed = _Feed(count);
    usePhone(tester);
    await tester.pumpWidget(host(ListenableBuilder(
      listenable: feed,
      builder: (context, _) => AtlasListView.builder(
        controller: controller,
        anchorMode: anchor,
        itemCount: feed.ids.length,
        findChildIndexCallback: (key) {
          final value = (key as ValueKey<String>).value;
          final index = feed.ids.indexOf(int.parse(value.substring(5)));
          return index < 0 ? null : index;
        },
        itemBuilder: (context, index) {
          final id = feed.ids[index];
          return item(id, extent: feed.extents[id]);
        },
      ),
    )));
    return feed;
  }

  testWidgets('20 keyed items inserted above stay out of sight',
      (tester) async {
    final feed = await pump(tester);
    controller.jumpTo(index: 50000, alignment: 0.3);
    await tester.pump();
    final before = rectOf(tester, 50000)!.top;
    feed.insertAtTop(List<int>.generate(20, (i) => -1 - i));
    await tester.pump();
    expect(rectOf(tester, 50000)!.top, closeTo(before, 0.5));
  });

  testWidgets('growth above the viewport keeps the reading position',
      (tester) async {
    final feed = await pump(tester);
    controller.jumpTo(index: 50000);
    await tester.pump();
    // 49999 is in the cache area above the viewport.
    expect(rectOf(tester, 49999)!.bottom, lessThanOrEqualTo(0.5));
    feed.resize(49999, 500);
    await tester.pump();
    expect(rectOf(tester, 50000)!.top, closeTo(0, 0.5));
  });

  testWidgets('AtlasAnchorMode.none lets growth above push content down',
      (tester) async {
    final feed = await pump(tester, anchor: AtlasAnchorMode.none);
    controller.jumpTo(index: 50000, alignment: 0.3);
    await tester.pump();
    final before = rectOf(tester, 50000)!.top;
    final above = rectOf(tester, 49999)!;
    feed.resize(49999, above.height + 300);
    await tester.pump();
    expect(rectOf(tester, 50000)!.top, closeTo(before + 300, 0.5));
  });

  testWidgets('at the very top new items show (chat stays pinned)',
      (tester) async {
    final feed = await pump(tester, count: 100);
    feed.insertAtTop([-1, -2]);
    await tester.pump();
    expect(rectOf(tester, -1)!.top, closeTo(0, 0.5));
    expect(controller.scrollController.offset, 0);
  });

  testWidgets('anchoring survives scrolling and a later insert',
      (tester) async {
    final feed = await pump(tester);
    controller.jumpTo(index: 2000);
    await tester.pump();
    await tester.drag(find.byType(Scrollable), const Offset(0, -500));
    await tester.pumpAndSettle();
    final id = feed.ids[controller.visibleSpan!.first.ceil()];
    final before = rectOf(tester, id)!.top;
    feed.insertAtTop([-7]);
    await tester.pump();
    expect(rectOf(tester, id)!.top, closeTo(before, 0.5));
  });
}
