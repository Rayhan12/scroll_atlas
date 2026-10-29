import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'section_harness.dart';

void main() {
  testWidgets('header stuck amount matches scroll in the same frame',
      (tester) async {
    usePhone(tester);
    stuckAmounts.clear();
    final controller = AtlasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(contacts(controller));
    controller.jumpTo(target: const AtlasTarget.item('people-M', 2));
    await tester.pump();
    expect(stuckAmounts['M'], closeTo(1, 0.05));
  });
}
