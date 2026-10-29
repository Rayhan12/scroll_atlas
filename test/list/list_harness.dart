import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

/// Viewport used by every list test.
const Size phoneSize = Size(390, 844);

/// Deterministic variable item extents between 40 and 300 px.
double extentFor(int id) => 40 + ((id * 7919) % 261).toDouble();

/// Key of the item that shows data id [id].
Key itemKey(int id) => ValueKey<String>('item-$id');

/// Counts item builds.
class Builds {
  int count = 0;
}

/// Sets a phone-sized test view.
void usePhone(WidgetTester tester) {
  tester.view.physicalSize = phoneSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// An item showing data id [id].
Widget item(int id, {double? extent}) => SizedBox(
      key: itemKey(id),
      height: extent ?? extentFor(id),
      child: Text('$id'),
    );

/// Hosts [child] in a minimal app.
Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Rect of the item with data id [id], or null when not built.
Rect? rectOf(WidgetTester tester, int id) {
  final finder = find.byKey(itemKey(id), skipOffstage: false);
  if (finder.evaluate().isEmpty) return null;
  return tester.getRect(finder);
}

/// Where alignment [alignment] puts an item's top in the viewport.
double alignedTop(double alignment) => AlignmentMath.leadingEdgeInViewport(
    alignment: alignment, viewportExtent: phoneSize.height);
