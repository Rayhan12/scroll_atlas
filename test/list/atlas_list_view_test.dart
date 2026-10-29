import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'list_harness.dart';

void main() {
  testWidgets(
      'initialIndex 300 shows in the first frame without '
      'building item 0', (tester) async {
    final built = <int>{};
    usePhone(tester);
    await tester.pumpWidget(host(AtlasListView.builder(
      itemCount: 100000,
      initialIndex: 300,
      initialAlignment: 0.25,
      itemBuilder: (context, index) {
        built.add(index);
        return item(index);
      },
    )));
    expect(rectOf(tester, 300)!.top, closeTo(alignedTop(0.25), 0.5));
    expect(built, isNot(contains(0)));
    expect(built.length, lessThan(40));
  });

  testWidgets(
      'a reversed chat starts at the newest message and '
      'stays there when one arrives', (tester) async {
    final messages = List<int>.generate(500, (i) => i);
    late StateSetter setState;
    usePhone(tester);
    await tester.pumpWidget(host(StatefulBuilder(builder: (context, set) {
      setState = set;
      return AtlasListView.builder(
        reverse: true,
        itemCount: messages.length,
        findChildIndexCallback: (key) {
          final value = (key as ValueKey<String>).value;
          final index = messages.indexOf(int.parse(value.substring(5)));
          return index < 0 ? null : index;
        },
        itemBuilder: (context, index) => item(messages[index]),
      );
    })));
    // Index 0 is the newest message, drawn at the bottom.
    expect(rectOf(tester, 0)!.bottom, closeTo(844, 0.5));
    setState(() => messages.insert(0, -1));
    await tester.pump();
    expect(rectOf(tester, -1)!.bottom, closeTo(844, 0.5));
    expect(rectOf(tester, 0)!.bottom, closeTo(844 - extentFor(-1), 0.5));
  });

  testWidgets('a reversed list jumps with the same alignment meaning',
      (tester) async {
    final controller = AtlasController();
    addTearDown(controller.dispose);
    usePhone(tester);
    await tester.pumpWidget(host(AtlasListView.builder(
      controller: controller,
      reverse: true,
      itemCount: 100000,
      itemBuilder: (context, index) => item(index),
    )));
    controller.jumpTo(index: 4000);
    await tester.pump();
    // Leading edge of a reversed vertical list is the bottom.
    expect(rectOf(tester, 4000)!.bottom, closeTo(844, 0.5));
  });

  testWidgets('padding wraps the list and jumps still land', (tester) async {
    final controller = AtlasController();
    addTearDown(controller.dispose);
    usePhone(tester);
    await tester.pumpWidget(host(AtlasListView.builder(
      controller: controller,
      padding: const EdgeInsets.only(top: 40),
      itemCount: 100000,
      itemBuilder: (context, index) => item(index),
    )));
    expect(rectOf(tester, 0)!.top, closeTo(40, 0.5));
    controller.jumpTo(index: 777);
    await tester.pump();
    expect(rectOf(tester, 777)!.top, closeTo(0, 0.5));
  });

  testWidgets('an empty list builds nothing and ignores fractions',
      (tester) async {
    final controller = AtlasController();
    addTearDown(controller.dispose);
    usePhone(tester);
    await tester.pumpWidget(host(AtlasListView.builder(
      controller: controller,
      itemCount: 0,
      itemBuilder: (context, index) => item(index),
    )));
    expect(controller.itemCount, 0);
    expect(controller.scrollFraction, isNull);
    controller.jumpToFraction(0.5);
    await tester.pump();
    expect(controller.scrollController.offset, 0);
  });

  testWidgets('a horizontal list jumps along x', (tester) async {
    final controller = AtlasController();
    addTearDown(controller.dispose);
    usePhone(tester);
    await tester.pumpWidget(host(AtlasListView.builder(
      controller: controller,
      scrollDirection: Axis.horizontal,
      itemCount: 10000,
      itemBuilder: (context, index) => SizedBox(
        key: itemKey(index),
        width: extentFor(index),
        child: Text('$index'),
      ),
    )));
    controller.jumpTo(index: 5000, alignment: 0.5);
    await tester.pump();
    expect(rectOf(tester, 5000)!.left, closeTo(195, 0.5));
  });

  testWidgets('swapping in a new controller moves the attachment',
      (tester) async {
    final first = AtlasController();
    final second = AtlasController();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    usePhone(tester);
    Widget list(AtlasController controller) => host(AtlasListView.builder(
          controller: controller,
          itemCount: 1000,
          itemBuilder: (context, index) => item(index),
        ));
    await tester.pumpWidget(list(first));
    expect(first.itemCount, 1000);
    await tester.pumpWidget(list(second));
    expect(second.itemCount, 1000);
    expect(first.itemCount, 0);
    second.jumpTo(index: 500);
    await tester.pump();
    expect(rectOf(tester, 500)!.top, closeTo(0, 0.5));
  });
}
