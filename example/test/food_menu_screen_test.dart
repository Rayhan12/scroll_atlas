import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas_example/demos/food_menu/food_menu_data.dart';
import 'package:scroll_atlas_example/demos/food_menu/food_menu_screen.dart';

void main() {
  Finder tab(String title) => find.descendant(
        of: find.byType(TabBar),
        matching: find.text(title),
      );

  TabController tabController(WidgetTester tester) =>
      tester.widget<TabBar>(find.byType(TabBar)).controller!;

  Future<List<int>> tapAndRecord(WidgetTester tester, String title) async {
    final controller = tabController(tester);
    final seen = <int>[];
    void record() => seen.add(controller.index);
    controller.addListener(record);
    // Scroll only the tab strip, the way a user swipes it, so the list
    // itself does not move before the tap.
    final strip = find.byType(TabBar);
    for (var i = 0; i < 10 && tester.getCenter(tab(title)).dx < 0; i++) {
      await tester.drag(strip, const Offset(300, 0));
      await tester.pumpAndSettle();
    }
    final width = tester.getSize(strip).width;
    for (var i = 0; i < 10 && tester.getCenter(tab(title)).dx > width; i++) {
      await tester.drag(strip, const Offset(-300, 0));
      await tester.pumpAndSettle();
    }
    await tester.tap(tab(title));
    await tester.pumpAndSettle();
    controller.removeListener(record);
    return seen.toSet().toList();
  }

  testWidgets('tap the last tab, then the first; one move each',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FoodMenuScreen()));
    expect(tabController(tester).index, 0);

    final last = menuSections.length - 1;
    final toLast = await tapAndRecord(tester, menuSections[last].title);
    expect(toLast, <int>[last]);
    expect(tabController(tester).index, last);

    final toFirst = await tapAndRecord(tester, menuSections.first.title);
    expect(toFirst, <int>[0]);
    expect(find.byKey(const ValueKey<String>('menu-header-0')), findsOneWidget);
  });

  testWidgets('tap Desserts from Starters moves the indicator once',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FoodMenuScreen()));
    final desserts = menuSections.indexWhere((s) => s.title == 'Desserts');
    final seen = await tapAndRecord(tester, 'Desserts');
    expect(seen, <int>[desserts]);
    expect(
      find.byKey(ValueKey<String>('menu-header-$desserts')),
      findsOneWidget,
    );
  });

  testWidgets('scrolling by hand moves the active tab',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: FoodMenuScreen()));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -900));
    await tester.pumpAndSettle();
    final scrolled = tabController(tester).index;
    expect(scrolled, greaterThan(0));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 3000));
    await tester.pumpAndSettle();
    expect(tabController(tester).index, 0);
  });
}
