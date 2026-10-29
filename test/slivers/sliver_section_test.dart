import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'section_harness.dart';

void main() {
  testWidgets('K 3 lands under the app bar and the K header', (tester) async {
    usePhone(tester);
    final controller = AtlasController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(contacts(controller));
    controller.jumpTo(target: const AtlasTarget.item('people-K', 3));
    await tester.pump();
    final top = viewportTop(tester);
    expect(topOf(tester, personKey('K', 3))! - top,
        closeTo(appBarExtent + headerExtent, 0.5));
    expect(topOf(tester, headerKey('K'))! - top, closeTo(appBarExtent, 0.5));
  });
}
