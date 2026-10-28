import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phone-sized logical viewport used by widget tests (390 x 844).
const Size phoneSize = Size(390, 844);

/// Sets a phone-sized view for the current test and restores it afterwards.
void usePhoneView(WidgetTester tester) {
  tester.view
    ..physicalSize = phoneSize * 3
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

/// Minimal host without MaterialApp, so tests depend only on widgets.
Widget host(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(size: phoneSize),
        child: child,
      ),
    );
