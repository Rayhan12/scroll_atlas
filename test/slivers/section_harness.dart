import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

/// App bar and header extents of the contacts harness.
const double appBarExtent = 56;
const double headerExtent = 40;

/// Letters of the sections.
const List<String> letters = <String>[
  'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', //
  'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
];

/// Number of people in section [letter]: between 3 and 40.
int peopleIn(String letter) => 3 + (letter.codeUnitAt(0) * 37) % 38;

/// Deterministic variable extents between 48 and 160 px.
double personExtent(String letter, int i) =>
    48 + ((letter.codeUnitAt(0) * 131 + i * 7919) % 113).toDouble();

/// Key of person [i] in section [letter].
Key personKey(String letter, int i) => ValueKey<String>('p-$letter-$i');

/// Key of the header of section [letter].
Key headerKey(String letter) => ValueKey<String>('h-$letter');

/// Stuck amounts reported to header builders, by letter.
final Map<String, double> stuckAmounts = <String, double>{};

/// A person tile.
Widget person(String letter, int i) => SizedBox(
      key: personKey(letter, i),
      height: personExtent(letter, i),
      child: Text('$letter $i'),
    );

/// A section header.
Widget header(String letter, double stuck) {
  stuckAmounts[letter] = stuck;
  return Container(
    key: headerKey(letter),
    height: headerExtent,
    color: Color.lerp(Colors.white, Colors.blue, stuck),
    child: Text(letter),
  );
}

/// The contacts harness: a pinned app bar (unless [appBar] is false) and
/// one section per letter with an Atlas list of people.
Widget contacts(
  AtlasController controller, {
  bool appBar = true,
  List<Widget> trailing = const <Widget>[],
}) =>
    MaterialApp(
      home: Scaffold(
        body: AtlasScrollView(
          controller: controller,
          slivers: <Widget>[
            if (appBar)
              const SliverAppBar(
                pinned: true,
                title: Text('Contacts'),
              ),
            for (final letter in letters)
              SliverAtlasSection(
                id: letter,
                header: (context, stuck) => header(letter, stuck),
                sliver: SliverAtlasList.builder(
                  id: 'people-$letter',
                  itemCount: peopleIn(letter),
                  itemBuilder: (context, i) => person(letter, i),
                ),
              ),
            ...trailing,
          ],
        ),
      ),
    );

/// Sets a phone-sized test view.
void usePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// Top of the widget with [key] in global coordinates, or null when not
/// built.
double? topOf(WidgetTester tester, Key key) {
  final finder = find.byKey(key, skipOffstage: false);
  if (finder.evaluate().isEmpty) return null;
  return tester.getTopLeft(finder).dy;
}

/// Top of the scroll view's viewport in global coordinates.
double viewportTop(WidgetTester tester) =>
    tester.getTopLeft(find.byType(Viewport)).dy;
