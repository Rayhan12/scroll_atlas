// The engine can read how much of the viewport pinned
// headers cover, which obstruction-aware alignment needs.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/test_app.dart';

void main() {
  testWidgets(
      'pinned header extent is readable from sliver geometry and '
      'only outer pinned headers reach later slivers as overlap',
      (tester) async {
    usePhoneView(tester);
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(
        CustomScrollView(
          controller: controller,
          slivers: <Widget>[
            const PinnedHeaderSliver(
              child: SizedBox(key: Key('header'), height: 56),
            ),
            SliverMainAxisGroup(
              slivers: <Widget>[
                const PinnedHeaderSliver(
                  child: SizedBox(key: Key('section'), height: 32),
                ),
                SliverList.builder(
                  key: const Key('list'),
                  itemCount: 200,
                  itemBuilder: (_, i) =>
                      SizedBox(height: 50, child: Text('$i')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    controller.jumpTo(1000);
    await tester.pump();

    final header = tester.renderObject(find.byType(PinnedHeaderSliver).first)
        as RenderSliver;
    expect(header.geometry!.paintExtent, 56);
    expect(header.geometry!.maxScrollObstructionExtent, 56);

    final list =
        tester.renderObject(find.byKey(const Key('list'))) as RenderSliver;
    // Finding: overlap only carries pinned slivers *outside* the group. A
    // header pinned inside a SliverMainAxisGroup is not added to its
    // siblings' overlap, so the engine must add the group's own pinned
    // geometry itself to get the real obstruction (56 + 32).
    expect(list.constraints.overlap, 56);
    final section = tester.renderObject(find.byType(PinnedHeaderSliver).last)
        as RenderSliver;
    expect(section.geometry!.paintExtent, 32);
    expect(list.constraints.overlap + section.geometry!.paintExtent, 88);
  });
}
