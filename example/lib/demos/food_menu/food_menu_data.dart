/// A menu section and its dishes.
final class MenuSection {
  const MenuSection(this.title, this.dishes);

  final String title;
  final List<Dish> dishes;
}

/// One dish of the D4 menu.
final class Dish {
  const Dish(this.name, this.description, this.price);

  final String name;
  final String description;
  final double price;
}

/// Section id used by the scroll view, the spy and the tab bar.
String menuSectionId(int index) => 'menu-$index';

/// Eight sections. The last one is short, so it can only become active
/// at the end of the scroll.
final List<MenuSection> menuSections = <MenuSection>[
  for (final (String title, int count) in const <(String, int)>[
    ('Starters', 6),
    ('Soups', 4),
    ('Salads', 5),
    ('Mains', 9),
    ('Grill', 7),
    ('Sides', 5),
    ('Desserts', 6),
    ('Drinks', 2),
  ])
    MenuSection(title, <Dish>[
      for (var i = 0; i < count; i++)
        Dish(
          '$title ${i + 1}',
          i.isEven
              ? 'House favourite with seasonal vegetables.'
              : 'Slow cooked, served with fresh herbs, a squeeze of lemon '
                  'and a side of the chef\'s sauce of the day.',
          4.5 + ((title.length * 7 + i * 3) % 20),
        ),
    ]),
];
