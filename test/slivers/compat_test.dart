import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';
import 'package:sliver_tools/sliver_tools.dart';

import 'section_harness.dart';

/// How each letter's header and list are put together.
typedef _SectionBuilder = Widget Function(String letter, Widget list);

Widget _atlasSection(String letter, Widget list) => SliverAtlasSection(
      id: letter,
      header: (context, stuck) => header(letter, stuck),
      sliver: list,
    );

Widget _stickyHeader(String letter, Widget list) => SliverStickyHeader(
      header: header(letter, 0),
      sliver: list,
    );

Widget _multiSliver(String letter, Widget list) => MultiSliver(
      pushPinnedChildren: true,
      children: <Widget>[
        SliverPinnedHeader(child: header(letter, 0)),
        list,
      ],
    );

const _pinned = SliverAppBar(
  pinned: true,
  expandedHeight: 120,
  title: Text('Pinned'),
);
const _floating = SliverAppBar(floating: true, title: Text('Floating'));
const _stretch = SliverAppBar(
  stretch: true,
  expandedHeight: 160,
  title: Text('Stretch'),
);

Widget _app(
  AtlasController controller,
  Widget appBar,
  _SectionBuilder section,
) =>
    MaterialApp(
      home: Scaffold(
        body: AtlasScrollView(
          controller: controller,
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            appBar,
            for (final letter in letters)
              section(
                letter,
                SliverAtlasList.builder(
                  id: 'people-$letter',
                  itemCount: peopleIn(letter),
                  itemBuilder: (context, i) => person(letter, i),
                ),
              ),
          ],
        ),
      ),
    );

/// Bottom of the app bar where it covers the viewport, else its top.
double _appBarBottom(WidgetTester tester) {
  final top = viewportTop(tester);
  final appBar = find.byType(AppBar, skipOffstage: false);
  if (appBar.evaluate().isEmpty) return top;
  return math.max(top, tester.getRect(appBar).bottom);
}

void main() {
  final combinations = <String, (Widget, _SectionBuilder)>{
    'pinned app bar + SliverAtlasSection': (_pinned, _atlasSection),
    'floating app bar + SliverAtlasSection': (_floating, _atlasSection),
    'stretch app bar + SliverAtlasSection': (_stretch, _atlasSection),
    'pinned app bar + flutter_sticky_header': (_pinned, _stickyHeader),
    'pinned app bar + MultiSliver pinned header': (_pinned, _multiSliver),
  };
  for (final MapEntry(key: name, value: (appBar, section))
      in combinations.entries) {
    testWidgets('$name, 50 random targets within 0.5 px', (tester) async {
      usePhone(tester);
      final controller = AtlasController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller, appBar, section));
      final viewport = tester.getSize(find.byType(Viewport)).height;
      final random = math.Random(307);
      var exact = 0;
      for (var n = 0; n < 50; n++) {
        final letter = letters[random.nextInt(letters.length)];
        final i = random.nextInt(peopleIn(letter));
        final alignment = <double>[0, 0, 0.25][random.nextInt(3)];
        controller.jumpTo(
          target: AtlasTarget.item('people-$letter', i),
          alignment: alignment,
        );
        await tester.pump();
        final built = topOf(tester, personKey(letter, i));
        expect(built, isNotNull, reason: 'jump $n to $letter $i not built');
        final y = built!;
        // The target's own header sticks below the app bar.
        final covered = _appBarBottom(tester) + headerExtent;
        final top = viewportTop(tester);
        final want = covered + alignment * (viewport - (covered - top));
        final position = controller.scrollController.position;
        final atEdge = position.pixels >= position.maxScrollExtent - 0.01 ||
            position.pixels <= position.minScrollExtent + 0.01;
        if ((y - want).abs() <= 0.5) {
          exact++;
        } else {
          expect(atEdge, isTrue,
              reason: 'jump $n to $letter $i (alignment $alignment) is at '
                  '${y - top}, want ${want - top}, pixels ${position.pixels}');
        }
        expect(y, greaterThanOrEqualTo(covered - 0.5),
            reason: 'jump $n to $letter $i is covered');
      }
      expect(exact, greaterThanOrEqualTo(40));
    });
  }
}
