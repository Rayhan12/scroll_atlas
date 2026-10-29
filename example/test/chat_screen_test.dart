import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas_example/demos/chat/chat_screen.dart';
import 'package:scroll_atlas_example/demos/chat/chat_thread.dart';

void main() {
  Future<ChatThread> open(WidgetTester tester) async {
    final thread = ChatThread.seeded();
    await tester.pumpWidget(MaterialApp(home: ChatScreen(thread: thread)));
    return thread;
  }

  Finder bubbleOf(int id) => find.byKey(ValueKey<String>('bubble-$id'));

  Rect listRect(WidgetTester tester) =>
      tester.getRect(find.byType(Scrollable).first);

  testWidgets('the first frame shows the first unread message', (tester) async {
    final thread = await open(tester);
    expect(find.text('First unread'), findsOneWidget);
    final list = listRect(tester);
    // Reversed list: alignment is measured up from the bottom edge.
    final expected = list.bottom - ChatScreen.unreadAlignment * list.height;
    final bottom = tester.getRect(bubbleOf(thread.firstUnreadId)).bottom;
    expect(bottom, moreOrLessEquals(expected, epsilon: 0.5));
    expect(bubbleOf(0), findsNothing);
  });

  testWidgets('tapping a quote animates to it and flashes it', (tester) async {
    final thread = await open(tester);
    // Scroll back to older messages, so a reply is on screen.
    await tester.drag(find.byType(Scrollable).first, const Offset(0, 5000));
    await tester.pumpAndSettle();
    final quote = find.byWidgetPredicate(
      (widget) =>
          widget is InkWell &&
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('quote-'),
    );
    expect(quote, findsWidgets);
    // The cache area builds quotes off screen too: tap one that is visible.
    final list = listRect(tester);
    final visible = quote.evaluate().where((element) {
      final center = tester.getCenter(find.byWidget(element.widget));
      return list.contains(center);
    }).first;
    final key = visible.widget.key! as ValueKey<String>;
    final replyId = int.parse(key.value.substring('quote-'.length));
    final quotedId = thread.atIndex(thread.indexOfId(replyId)).replyTo!;
    expect(bubbleOf(quotedId), findsNothing);

    await tester.tap(find.byKey(key));
    await tester.pumpAndSettle();

    final expected = list.bottom - ChatScreen.quoteAlignment * list.height;
    final bottom = tester.getRect(bubbleOf(quotedId)).bottom;
    expect(bottom, moreOrLessEquals(expected, epsilon: 0.5));
    final scheme =
        Theme.of(tester.element(find.byType(ChatScreen))).colorScheme;
    Color? colorOf(int id) =>
        (tester.widget<Container>(bubbleOf(id)).decoration! as BoxDecoration)
            .color;
    expect(colorOf(quotedId), scheme.tertiaryContainer);

    await tester.pump(ChatScreen.flashDuration);
    expect(colorOf(quotedId), isNot(scheme.tertiaryContainer));
  });

  testWidgets('at the bottom, a sent message shows and stays pinned',
      (tester) async {
    final thread = await open(tester);
    // The first drag reaches the newest message and measures the items
    // estimated on the way; the list keeps the screen still while it
    // fixes their offsets, so a second drag settles on the bottom edge.
    for (var i = 0; i < 2; i++) {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -5000));
      await tester.pumpAndSettle();
    }

    await tester.enterText(find.byKey(const Key('chat_input')), 'hello');
    await tester.tap(find.byKey(const Key('chat_send')));
    await tester.pumpAndSettle();

    final sent = thread.length - 1;
    expect(thread.atIndex(0).text, 'hello');
    final list = listRect(tester);
    final bottom = tester.getRect(bubbleOf(sent)).bottom;
    expect(bottom, moreOrLessEquals(list.bottom, epsilon: 0.5));
  });

  test('keys map back to reversed indexes', () {
    final thread = ChatThread.seeded(count: 10, unread: 2);
    final newest = thread.atIndex(0);
    expect(thread.indexOfKey(ChatThread.keyOf(newest)), 0);
    expect(thread.indexOfKey(const ValueKey<String>('other')), isNull);
    expect(thread.indexOfKey(const ValueKey<int>(3)), isNull);
    thread.send('x');
    expect(thread.indexOfKey(ChatThread.keyOf(newest)), 1);
    expect(thread.firstUnreadId, 8);
  });
}
