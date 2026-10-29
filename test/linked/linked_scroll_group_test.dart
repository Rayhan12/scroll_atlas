import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

/// Lists side by side, one per controller, each [itemCount] items of 50 px.
Widget lists(
  List<ScrollController> controllers, {
  Axis axis = Axis.vertical,
  ScrollPhysics physics = const ClampingScrollPhysics(),
  List<int>? itemCounts,
}) {
  final children = <Widget>[
    for (var i = 0; i < controllers.length; i++)
      Expanded(
        child: ListView.builder(
          key: ValueKey<int>(i),
          scrollDirection: axis,
          controller: controllers[i],
          physics: physics,
          itemExtent: 50,
          itemCount: itemCounts?[i] ?? 200,
          itemBuilder: (_, int index) => Text('$i:$index'),
        ),
      ),
  ];
  return Directionality(
    textDirection: TextDirection.ltr,
    child: axis == Axis.vertical
        ? Row(children: children)
        : Column(children: children),
  );
}

void main() {
  late LinkedScrollGroup group;
  late List<LinkedScrollController> controllers;

  setUp(() {
    group = LinkedScrollGroup();
    controllers = <LinkedScrollController>[
      group.createController(debugLabel: 'a'),
      group.createController(debugLabel: 'b'),
      group.createController(debugLabel: 'c'),
    ];
  });

  tearDown(() {
    for (final c in controllers) {
      c.dispose();
    }
    group.dispose();
  });

  List<double> offsets() => <double>[
        for (final c in controllers)
          if (c.hasClients) c.offset,
      ];

  void expectAligned() {
    final all = offsets();
    for (final o in all) {
      expect(o, moreOrLessEquals(all.first, epsilon: 0.5));
    }
  }

  testWidgets('a drag on one member moves the others in the same frame',
      (tester) async {
    await tester.pumpWidget(lists(controllers));
    await tester.drag(
        find.byKey(const ValueKey<int>(1)), const Offset(0, -300));
    await tester.pump();
    expect(offsets(), <double>[300, 300, 300]);
    expect(group.offset, 300);
    expect(group.hasClients, isTrue);
    expect(group.positions.length, 3);
  });

  testWidgets('a controller that joins at 400 px starts at 400 px',
      (tester) async {
    await tester.pumpWidget(lists(controllers.sublist(0, 2)));
    group.jumpTo(400);
    await tester.pump();
    expect(offsets(), <double>[400, 400]);

    final late = group.createController();
    controllers.add(late);
    expect(late.initialScrollOffset, 400);
    await tester.pumpWidget(lists(<ScrollController>[...controllers]));
    // The first frame the new list is laid out, it is already at 400.
    expect(late.offset, 400);
    expect(find.text('3:8'), findsOneWidget);
  });

  testWidgets('a member laid out after the group moved starts in line',
      (tester) async {
    await tester.pumpWidget(lists(controllers.sublist(0, 1)));
    group.jumpTo(250);
    await tester.pump();
    // Created before the jump but attached after it.
    await tester.pumpWidget(lists(controllers));
    expect(offsets(), <double>[250, 250, 250]);
  });

  testWidgets('a short member stops at its end and joins at its end',
      (tester) async {
    await tester.pumpWidget(
      lists(controllers, itemCounts: <int>[200, 200, 20]),
    );
    final shortMax = controllers[2].position.maxScrollExtent;
    group.jumpTo(shortMax + 500);
    await tester.pump();
    expect(controllers[0].offset, shortMax + 500);
    expect(controllers[2].offset, shortMax);
  });

  testWidgets(
      'a fling decelerates with every member equal on every frame '
      'and nobody overshoots', (tester) async {
    await tester.pumpWidget(lists(controllers));
    await tester.fling(
      find.byKey(const ValueKey<int>(0)),
      const Offset(0, -400),
      3000,
    );
    var last = 0.0;
    var frames = 0;
    while (tester.binding.hasScheduledFrame && frames < 600) {
      await tester.pump(const Duration(milliseconds: 16));
      expectAligned();
      final now = controllers.first.offset;
      expect(now, greaterThanOrEqualTo(last - 0.001), reason: 'no bounce');
      last = now;
      frames++;
    }
    expect(frames, greaterThan(5));
    expect(offsets(), everyElement(last));
    for (final c in controllers) {
      expect(c.position.activity, isA<IdleScrollActivity>());
    }
  });

  testWidgets('disposing a member mid-fling keeps the rest together',
      (tester) async {
    await tester.pumpWidget(lists(controllers));
    await tester.fling(
      find.byKey(const ValueKey<int>(0)),
      const Offset(0, -400),
      3000,
    );
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    final before = controllers.first.offset;

    final removed = controllers.removeLast();
    await tester.pumpWidget(lists(controllers));
    removed.dispose();
    expect(group.positions.length, 2);

    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expectAligned();
    }
    expect(controllers.first.offset, greaterThan(before));
    await tester.pumpAndSettle();
    expectAligned();
  });

  testWidgets('a drag on a follower takes over from a fling', (tester) async {
    await tester.pumpWidget(lists(controllers));
    await tester.fling(
      find.byKey(const ValueKey<int>(0)),
      const Offset(0, -300),
      3000,
    );
    await tester.pump(const Duration(milliseconds: 50));
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey<int>(2))),
    );
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump(const Duration(milliseconds: 16));
    final held = controllers[2].offset;
    // The first member's fling has stopped: only the finger drives now.
    await tester.pump(const Duration(milliseconds: 200));
    expect(controllers[0].offset, held);
    expectAligned();
    await gesture.up();
    await tester.pumpAndSettle();
    expectAligned();
  });

  testWidgets('bounce overscroll is copied to every member', (tester) async {
    await tester.pumpWidget(
      lists(controllers, physics: const BouncingScrollPhysics()),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey<int>(0))),
    );
    await gesture.moveBy(const Offset(0, 120));
    await tester.pump();
    expect(controllers[0].offset, lessThan(0));
    expectAligned();
    await gesture.up();
    var frames = 0;
    while (tester.binding.hasScheduledFrame && frames < 300) {
      await tester.pump(const Duration(milliseconds: 16));
      expectAligned();
      frames++;
    }
    expect(offsets(), everyElement(moreOrLessEquals(0, epsilon: 0.01)));
  });

  testWidgets('animateTo moves every member and tells listeners',
      (tester) async {
    final heard = <double>[];
    void listener(double offset) => heard.add(offset);
    group.addOffsetListener(listener);
    await tester.pumpWidget(lists(controllers, axis: Axis.horizontal));
    final done = group.animateTo(
      600,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expectAligned();
    }
    await done;
    expect(offsets(), <double>[600, 600, 600]);
    expect(heard.last, 600);
    expect(heard.length, greaterThan(3));

    group.removeOffsetListener(listener);
    final count = heard.length;
    group.jumpTo(0);
    await tester.pump();
    expect(heard.length, count);
    expect(offsets(), <double>[0, 0, 0]);
  });

  test('without members, jumpTo and animateTo only set the offset', () async {
    final heard = <double>[];
    group
      ..addOffsetListener(heard.add)
      ..jumpTo(120);
    expect(group.offset, 120);
    await group.animateTo(
      80,
      duration: const Duration(milliseconds: 100),
      curve: Curves.linear,
    );
    expect(group.offset, 80);
    group.jumpTo(80);
    expect(heard, <double>[120, 80]);
    expect(group.hasClients, isFalse);
    expect(LinkedScrollGroup(initialOffset: 30).offset, 30);
  });

  testWidgets(
      'a controller moved to another scroll view leaves the group '
      'once', (tester) async {
    await tester.pumpWidget(lists(controllers));
    expect(group.positions.length, 3);
    // Same controllers, new physics: Flutter replaces each position.
    await tester.pumpWidget(
      lists(controllers, physics: const BouncingScrollPhysics()),
    );
    expect(group.positions.length, 3);
    await tester.pumpWidget(const SizedBox());
    expect(group.positions, isEmpty);
  });
}
