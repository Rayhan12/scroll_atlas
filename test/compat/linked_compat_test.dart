import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/compat.dart';

/// The README example of linked_scroll_controller 0.2.0, ported to null
/// safety. Only the import changes.
class _LinkedScrollables extends StatefulWidget {
  const _LinkedScrollables(this.group);

  final LinkedScrollControllerGroup group;

  @override
  State<_LinkedScrollables> createState() => _LinkedScrollablesState();
}

class _LinkedScrollablesState extends State<_LinkedScrollables> {
  late final ScrollController _letters = widget.group.addAndGet();
  late final ScrollController _numbers = widget.group.addAndGet();

  @override
  void dispose() {
    _letters.dispose();
    _numbers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Expanded(
              child: ListView(
                controller: _letters,
                children: [
                  for (var i = 0; i < 40; i++) _Tile('Hello $i A'),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _numbers,
                children: [
                  for (var i = 0; i < 40; i++) _Tile('Hello $i 1'),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile(this.label);

  final String label;

  @override
  Widget build(BuildContext context) =>
      SizedBox(height: 100, child: Text(label));
}

void main() {
  testWidgets('the old README example stays in sync', (tester) async {
    final group = LinkedScrollControllerGroup();
    var changes = 0;
    void onChanged() => changes++;
    group.addOffsetChangedListener(onChanged);
    // Adding the same callback twice still calls it once per change.
    group.addOffsetChangedListener(onChanged);

    await tester.pumpWidget(_LinkedScrollables(group));
    await tester.drag(find.text('Hello 3 A'), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(group.offset, greaterThan(0));
    expect(
      tester.getTopLeft(find.text('Hello 5 1')).dy,
      tester.getTopLeft(find.text('Hello 5 A')).dy,
    );
    expect(changes, greaterThan(0));

    final animation = group.animateTo(
      700,
      curve: Curves.easeOut,
      duration: const Duration(milliseconds: 200),
    );
    await tester.pumpAndSettle();
    await animation;
    expect(group.offset, 700);
    expect(tester.getTopLeft(find.text('Hello 7 1')).dy, 0);

    group.removeOffsetChangedListener(onChanged);
    final seen = changes;
    group.resetScroll();
    await tester.pump();
    expect(group.offset, 0);
    expect(tester.getTopLeft(find.text('Hello 0 A')).dy, 0);
    expect(tester.getTopLeft(find.text('Hello 0 1')).dy, 0);
    expect(changes, seen);
    // Removing an unknown callback is a no-op.
    group.removeOffsetChangedListener(() {});
  });

  testWidgets('addAndGet starts late joiners at the group offset',
      (tester) async {
    final group = LinkedScrollControllerGroup()..jumpTo(400);
    final controller = group.addAndGet();
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: ListView(
        controller: controller,
        children: [for (var i = 0; i < 40; i++) _Tile('Hello $i')],
      ),
    ));
    expect(controller.offset, 400);
    expect(tester.getTopLeft(find.text('Hello 4')).dy, 0);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
