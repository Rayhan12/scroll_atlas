import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas_example/demos/migration/migration_screen.dart';

void main() {
  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: MigrationScreen()));
  }

  double top(WidgetTester tester, String side, int index) =>
      tester.getTopLeft(find.byKey(ValueKey<String>('$side-$index'))).dy;

  testWidgets('both panes land on the same message', (tester) async {
    await open(tester);
    for (final (label, index, _) in MigrationScreen.moves) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(top(tester, 'new', index), top(tester, 'old', index),
          reason: label);
    }
  });

  testWidgets('both readouts agree', (tester) async {
    await open(tester);
    await tester.tap(find.text('Jump to 1500'));
    await tester.pumpAndSettle();
    expect(find.text('First visible: 1500 at 0.000'), findsNWidgets(2));
  });
}
