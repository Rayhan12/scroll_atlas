import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'section_harness.dart';

/// Where alignment [alignment] puts a target's top, below [obstruction].
double alignedTop(double alignment, double obstruction, double viewport) =>
    obstruction + alignment * (viewport - obstruction);

void main() {
  testWidgets('500 random targets land exactly and uncovered', (tester) async {
    usePhone(tester);
    final controller = AtlasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(contacts(controller));
    final random = math.Random(306);
    final viewport = tester.getSize(find.byType(Viewport)).height;
    final top = viewportTop(tester);
    var exact = 0;
    var clamped = 0;
    for (var n = 0; n < 500; n++) {
      final letter = letters[random.nextInt(letters.length)];
      final section = random.nextInt(5) == 0;
      final i = random.nextInt(peopleIn(letter));
      final alignment = <double>[0, 0, 0.25, 0.5][random.nextInt(4)];
      final padding = random.nextBool() ? 0.0 : 8.0;
      controller.jumpTo(
        target: section
            ? AtlasTarget.section(letter)
            : AtlasTarget.item('people-$letter', i),
        alignment: alignment,
        padding: padding,
      );
      await tester.pump();
      final key = section ? headerKey(letter) : personKey(letter, i);
      final y = topOf(tester, key);
      expect(y, isNotNull, reason: 'jump $n to $letter $i not built');
      final itemTop = y! - top;
      final obstruction = appBarExtent + (section ? 0 : headerExtent) + padding;
      final want = alignedTop(alignment, obstruction, viewport);
      final position = controller.scrollController.position;
      final atEdge = position.pixels >= position.maxScrollExtent - 0.01 ||
          position.pixels <= position.minScrollExtent + 0.01;
      if ((itemTop - want).abs() <= 0.5) {
        exact++;
      } else {
        expect(atEdge, isTrue,
            reason: 'jump $n to ${section ? letter : '$letter $i'} '
                '(alignment $alignment, padding $padding) is at $itemTop, '
                'want $want');
        clamped++;
      }
      // No pixel of the target is under the app bar or a stuck header.
      expect(itemTop, greaterThanOrEqualTo(obstruction - padding - 0.5),
          reason: 'jump $n: target is covered');
    }
    expect(exact, greaterThan(400));
    debugPrint('$exact exact, $clamped clamped at an edge');
  });

  testWidgets('respectPinned false aligns to the viewport edge',
      (tester) async {
    usePhone(tester);
    final controller = AtlasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(contacts(controller));
    controller.jumpTo(
      target: const AtlasTarget.item('people-M', 2),
      respectPinned: false,
    );
    await tester.pump();
    expect(topOf(tester, personKey('M', 2))! - viewportTop(tester),
        closeTo(0, 0.5));
  });

  testWidgets('header sticks, is pushed, never overlaps the next',
      (tester) async {
    usePhone(tester);
    final controller = AtlasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(contacts(controller));
    final top = viewportTop(tester);
    controller.jumpTo(target: const AtlasTarget.section('C'));
    await tester.pump();
    await tester.pump();
    final position = controller.scrollController.position;
    final cStart = position.pixels;
    final cExtent = <double>[
      for (var i = 0; i < peopleIn('C'); i++) personExtent('C', i),
    ].fold<double>(headerExtent, (a, b) => a + b);
    // Five offsets: natural place, stuck, partly stuck, pushed, gone.
    final offsets = <double>[
      cStart - 100,
      cStart + 10,
      cStart + cExtent / 2,
      cStart + cExtent - headerExtent / 2,
      cStart + cExtent + 5,
    ];
    for (final offset in offsets) {
      position.jumpTo(offset);
      await tester.pump();
      await tester.pump();
      final c = topOf(tester, headerKey('C'));
      final d = topOf(tester, headerKey('D'));
      if (c != null && d != null) {
        expect(c + headerExtent, lessThanOrEqualTo(d + 0.5),
            reason: 'C overlaps D at $offset');
      }
      // While its section fills the top, the header stays under the app
      // bar: it is never scrolled away before the section ends.
      if (offset > cStart && offset <= cStart + cExtent - headerExtent) {
        expect(c, isNotNull);
        expect(c! - top, closeTo(appBarExtent, 0.5),
            reason: 'C not stuck at $offset');
      }
    }
    position.jumpTo(cStart + 10);
    await tester.pump();
    await tester.pump();
    expect(topOf(tester, headerKey('C'))! - top, closeTo(appBarExtent, 0.5));
    expect(stuckAmounts['C'], 1.0);
    // Pushed: D's header half a header below the app bar. Measured from D
    // itself, because the lists above can be measured again while
    // scrolling, which moves where C ends.
    controller.jumpTo(target: const AtlasTarget.section('D'));
    await tester.pump();
    await tester.pump();
    position.jumpTo(position.pixels - headerExtent / 2);
    await tester.pump();
    await tester.pump();
    expect(topOf(tester, headerKey('C'))! - top,
        closeTo(appBarExtent - headerExtent / 2, 0.5));
    expect(topOf(tester, headerKey('D'))! - top,
        closeTo(appBarExtent + headerExtent / 2, 0.5));
  });

  testWidgets('tapping a stuck header hits the header', (tester) async {
    usePhone(tester);
    final controller = AtlasController();
    addTearDown(controller.dispose);
    var tapped = '';
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AtlasScrollView(
          controller: controller,
          slivers: <Widget>[
            for (final letter in <String>['A', 'B'])
              SliverAtlasSection(
                id: letter,
                header: (context, stuck) => GestureDetector(
                  onTap: () => tapped = 'header $letter',
                  child: header(letter, stuck),
                ),
                sliver: SliverList.builder(
                  itemCount: 30,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => tapped = '$letter $i',
                    child: person(letter, i),
                  ),
                ),
              ),
          ],
        ),
      ),
    ));
    controller.scrollController.jumpTo(300);
    await tester.pump();
    await tester
        .tapAt(tester.getTopLeft(find.byType(Viewport)) + const Offset(20, 10));
    expect(tapped, 'header A');
    await tester.tapAt(tester.getTopLeft(find.byType(Viewport)) +
        const Offset(20, headerExtent + 30));
    expect(tapped, startsWith('A '));
  });
}
