import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'section_harness.dart';

Key _rowKey(String list, int i) => ValueKey<String>('$list-$i');

double _rowExtent(String list, int i) =>
    40 + ((list.codeUnitAt(0) * 53 + i * 977) % 90);

Widget _list(String id, int count) => SliverAtlasList.builder(
      id: id,
      itemCount: count,
      itemBuilder: (context, i) => SizedBox(
        key: _rowKey(id, i),
        height: _rowExtent(id, i),
        child: Text('$id $i'),
      ),
    );

Widget _app(AtlasController controller, List<Widget> slivers) => MaterialApp(
      home: Scaffold(
        body: AtlasScrollView(controller: controller, slivers: slivers),
      ),
    );

void main() {
  group('global targets by sliver id', () {
    testWidgets('c 10 lands exactly while a and b are unbuilt', (tester) async {
      usePhone(tester);
      final controller = AtlasController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller, <Widget>[
        _list('a', 2000),
        _list('b', 2000),
        _list('c', 50),
      ]));
      // Like any sliver list, b keeps at most its first child before it is
      // ever scrolled to; nothing of it is measured or shown.
      expect(find.byKey(_rowKey('b', 1), skipOffstage: false), findsNothing,
          reason: 'b is unbuilt below the viewport');
      expect(find.byKey(_rowKey('c', 1), skipOffstage: false), findsNothing);
      for (final (alignment, padding) in <(double, double)>[
        (0, 0),
        (0.5, 0),
        (0, 12),
      ]) {
        controller.jumpTo(
          target: const AtlasTarget.item('c', 10),
          alignment: alignment,
          padding: padding,
        );
        await tester.pump();
        final top = viewportTop(tester);
        final viewport = tester.getSize(find.byType(Viewport)).height;
        expect(topOf(tester, _rowKey('c', 10))! - top,
            closeTo(alignment * viewport + padding, 0.5),
            reason: 'alignment $alignment padding $padding');
        controller.scrollController.jumpTo(0);
        await tester.pump();
      }
    });

    testWidgets('lists after c stay where they are', (tester) async {
      usePhone(tester);
      final controller = AtlasController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller, <Widget>[
        _list('c', 50),
        _list('a', 2000),
        _list('b', 2000),
      ]));
      controller.jumpTo(target: const AtlasTarget.item('b', 1500));
      await tester.pump();
      controller.jumpTo(target: const AtlasTarget.item('c', 10));
      await tester.pump();
      expect(topOf(tester, _rowKey('c', 10))! - viewportTop(tester),
          closeTo(0, 0.5));
    });

    testWidgets('two slivers with one id assert and name the id',
        (tester) async {
      final controller = AtlasController();
      addTearDown(controller.dispose);
      final errors = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) => errors.add('${details.exception}');
      try {
        await tester.pumpWidget(_app(controller, <Widget>[
          _list('dup', 5),
          _list('dup', 5),
        ]));
        await tester.pumpWidget(const SizedBox());
      } finally {
        FlutterError.onError = previous;
      }
      expect(errors.first, contains("Two Atlas slivers use the id 'dup'"));
    });
  });

  group('AtlasAnchor makes any sliver a target', () {
    Widget grid() => AtlasAnchor(
          id: 'reviews',
          sliver: SliverGrid.count(
            crossAxisCount: 3,
            children: <Widget>[
              for (var i = 0; i < 30; i++) Text('review $i'),
            ],
          ),
        );

    for (final alignment in <double>[0, 0.25, 0.5]) {
      testWidgets('the grid leading edge is at alignment $alignment',
          (tester) async {
        usePhone(tester);
        final controller = AtlasController();
        addTearDown(controller.dispose);
        await tester.pumpWidget(_app(controller, <Widget>[
          _list('a', 3000),
          grid(),
          _list('b', 3000),
        ]));
        controller.jumpTo(
          target: const AtlasTarget.sliver('reviews'),
          alignment: alignment,
        );
        await tester.pump();
        final viewport = tester.getSize(find.byType(Viewport)).height;
        expect(
          tester.getTopLeft(find.text('review 0')).dy - viewportTop(tester),
          closeTo(alignment * viewport, 0.5),
        );
      });
    }

    testWidgets('a SliverToBoxAdapter footer lands at the top', (tester) async {
      usePhone(tester);
      final controller = AtlasController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_app(controller, <Widget>[
        _list('a', 3000),
        const AtlasAnchor(
          id: 'footer',
          sliver: SliverToBoxAdapter(
            child: SizedBox(height: 1200, child: Text('footer')),
          ),
        ),
      ]));
      controller.jumpTo(target: const AtlasTarget.sliver('footer'));
      await tester.pump();
      expect(tester.getTopLeft(find.text('footer')).dy - viewportTop(tester),
          closeTo(0, 0.5));
    });
  });
}
