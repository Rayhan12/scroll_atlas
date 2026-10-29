/// Bundled food photos (generated for this demo, no hotlinking).
abstract final class FoodPhotos {
  /// Wide restaurant hero.
  static const String hero = 'assets/food/hero.jpg';

  static const List<String> _sections = <String>[
    'assets/food/starters.jpg',
    'assets/food/soups.jpg',
    'assets/food/salads.jpg',
    'assets/food/mains.jpg',
    'assets/food/grill.jpg',
    'assets/food/sides.jpg',
    'assets/food/desserts.jpg',
    'assets/food/drinks.jpg',
  ];

  /// Every square dish photo.
  static List<String> get all => _sections;

  /// Square photo for menu section [index], wrapping around.
  static String section(int index) => _sections[index % _sections.length];
}
