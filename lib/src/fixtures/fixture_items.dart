import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Keys for fixture items, so tests and benchmarks find items the same way.
abstract final class FixtureKeys {
  /// Key of the fixture item at [index].
  static Key item(int index) => ValueKey<String>('atlas-item-$index');

  /// Index [item] was created with, or null for any other key.
  static int? idOf(Key key) {
    if (key is! ValueKey<String>) return null;
    const prefix = 'atlas-item-';
    final value = key.value;
    if (!value.startsWith(prefix)) return null;
    return int.tryParse(value.substring(prefix.length));
  }
}

/// A fixed-extent item with a visible label.
class FixtureItem extends StatelessWidget {
  /// Creates an item for [index] with [extent] logical pixels.
  FixtureItem({required this.index, required this.extent})
      : super(key: FixtureKeys.item(index));

  /// Item index.
  final int index;

  /// Main axis extent.
  final double extent;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: extent,
        child: ColoredBox(
          color: Color(index.isEven ? 0xFFF2F4F7 : 0xFFE4E7EC),
          child: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text('Item $index', textDirection: TextDirection.ltr),
            ),
          ),
        ),
      );
}

/// An item whose height comes from wrapping text, for text-scale tests.
class TextWrapFixtureItem extends StatelessWidget {
  /// Creates an item with [words] words of text.
  TextWrapFixtureItem({required this.index, required this.words})
      : super(key: FixtureKeys.item(index));

  /// Item index.
  final int index;

  /// Number of words in the paragraph.
  final int words;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          List<String>.filled(words, 'atlas').join(' '),
          textDirection: TextDirection.ltr,
        ),
      );
}

/// Simulates an image placeholder that resizes once the "image" loads.
/// [loaded] flips it from [initialExtent] to [loadedExtent]. The inner
/// [FixtureItem] carries the [FixtureKeys.item] key, so probes find it.
class GrowingFixtureItem extends StatelessWidget {
  /// Creates the item.
  const GrowingFixtureItem({
    required this.index,
    required this.initialExtent,
    required this.loadedExtent,
    required this.loaded,
    super.key,
  });

  /// Item index.
  final int index;

  /// Extent before the image loads.
  final double initialExtent;

  /// Extent after the image loads.
  final double loadedExtent;

  /// Becomes true when the image has loaded.
  final ValueListenable<bool> loaded;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
        valueListenable: loaded,
        builder: (context, isLoaded, _) => FixtureItem(
          index: index,
          extent: isLoaded ? loadedExtent : initialExtent,
        ),
      );
}

/// Counts item builds, to check that a jump builds only what it shows.
final class BuildCounter {
  final Set<int> _built = <int>{};
  int _builds = 0;

  /// Total builder calls since the last [reset].
  int get builds => _builds;

  /// Distinct indexes built since the last [reset].
  Set<int> get builtIndexes => Set<int>.unmodifiable(_built);

  /// Clears the counts.
  void reset() {
    _built.clear();
    _builds = 0;
  }

  /// Wraps [builder] so every call is counted.
  IndexedWidgetBuilder wrap(IndexedWidgetBuilder builder) => (context, index) {
        _builds++;
        _built.add(index);
        return builder(context, index);
      };
}
