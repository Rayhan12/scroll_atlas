import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/fixtures.dart';

/// Render box of the fixture item [index]. Fails if it is not built.
RenderBox itemBox(WidgetTester tester, int index) =>
    tester.renderObject<RenderBox>(find.byKey(FixtureKeys.item(index)));

/// Render box of the only viewport in the tree.
RenderBox viewportBox(WidgetTester tester) =>
    tester.renderObject<RenderBox>(find.byType(Viewport));

/// Leading edge of item [index] measured from the viewport's leading edge.
double itemLeadingEdge(WidgetTester tester, int index) =>
    PositionProbe.leadingEdgeInViewport(
        itemBox(tester, index), viewportBox(tester));

/// Expects item [index] to have its leading edge at [alignment] of the
/// viewport, within [tolerance] logical pixels.
void expectItemAt(
  WidgetTester tester,
  int index, {
  double alignment = 0,
  double tolerance = 0.5,
  double leadingObstruction = 0,
}) {
  final finder = find.byKey(FixtureKeys.item(index));
  expect(finder, findsOneWidget, reason: 'item $index is not built');
  final error = PositionProbe.alignmentError(
    item: itemBox(tester, index),
    viewport: viewportBox(tester),
    alignment: alignment,
    leadingObstruction: leadingObstruction,
  );
  expect(
    error,
    lessThanOrEqualTo(tolerance),
    reason: 'item $index is $error px away from alignment $alignment',
  );
}

/// Expects none of [indexes] to be built.
void expectNoBuildOf(Iterable<int> indexes) {
  for (final index in indexes) {
    expect(
      find.byKey(FixtureKeys.item(index), skipOffstage: false),
      findsNothing,
      reason: 'item $index should not be built',
    );
  }
}
