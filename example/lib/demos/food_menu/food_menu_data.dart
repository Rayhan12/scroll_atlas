/// A menu section and its dishes.
final class MenuSection {
  const MenuSection(this.title, this.dishes);

  final String title;
  final List<Dish> dishes;
}

/// One dish on the menu.
final class Dish {
  const Dish(this.name, this.description, this.price, {this.tag});

  final String name;
  final String description;
  final double price;

  /// Optional label, such as "Spicy" or "Vegan".
  final String? tag;
}

/// Name of the demo restaurant.
const String restaurantName = 'Saffron Kitchen';

/// Section id used by the scroll view, the spy and the tab bar.
String menuSectionId(int index) => 'menu-$index';

/// Eight sections. The last one is short, so it can only become active
/// at the end of the scroll.
const List<MenuSection> menuSections = <MenuSection>[
  MenuSection('Starters', <Dish>[
    Dish(
        'Vegetable samosa',
        'Crisp pastry, spiced potato and peas, '
            'tamarind chutney.',
        5.50,
        tag: 'Vegan'),
    Dish('Chicken pakora', 'Gram flour batter, green chilli, mint yoghurt.',
        6.90),
    Dish('Beguni', 'Aubergine fritters with kasundi mustard.', 5.20,
        tag: 'Vegan'),
    Dish('Fish chop', 'Rohu croquette, panko crust, kasundi.', 7.40),
    Dish('Chotpoti', 'Chickpeas, potato, egg, tamarind and crunchy puri.', 6.10,
        tag: 'Spicy'),
    Dish('Paneer tikka', 'Charred cottage cheese, peppers and onion.', 8.20,
        tag: 'Vegetarian'),
  ]),
  MenuSection('Soups', <Dish>[
    Dish('Red lentil soup', 'Masoor dal, cumin, lemon and coriander.', 4.80,
        tag: 'Vegan'),
    Dish('Thai tom yum', 'Prawns, lemongrass, galangal and lime leaf.', 7.20,
        tag: 'Spicy'),
    Dish('Chicken corn soup', 'Sweetcorn, egg ribbons, white pepper.', 5.60),
    Dish('Mulligatawny', 'Spiced lentil and apple soup with rice.', 5.90),
  ]),
  MenuSection('Salads', <Dish>[
    Dish('Kachumber', 'Cucumber, tomato, red onion, lime and chaat masala.',
        4.90,
        tag: 'Vegan'),
    Dish('Mango and avocado', 'Ripe mango, avocado, chilli and mint.', 7.80,
        tag: 'Vegan'),
    Dish('Grilled chicken Caesar', 'Romaine, parmesan, croutons.', 9.40),
    Dish('Beetroot and feta', 'Roast beetroot, whipped feta, walnuts.', 8.60,
        tag: 'Vegetarian'),
    Dish('Shorshe shrimp salad', 'Mustard prawns over green leaves.', 10.20),
  ]),
  MenuSection('Mains', <Dish>[
    Dish(
        'Kacchi biryani',
        'Mutton and aromatic rice, slow cooked in a '
            'sealed pot, with borhani.',
        16.50,
        tag: 'Chef pick'),
    Dish(
        'Chicken rezala', 'White curry with yoghurt, cashew and kewra.', 13.80),
    Dish('Beef bhuna', 'Dry fried beef, onion, garlic, whole spices.', 14.90,
        tag: 'Spicy'),
    Dish('Ilish bhapa', 'Hilsa steamed in mustard paste and green chilli.',
        18.40),
    Dish('Shorshe ilish', 'Hilsa in a sharp mustard gravy.', 18.90),
    Dish('Chingri malai curry', 'Tiger prawns in coconut milk.', 17.20),
    Dish('Dal makhani', 'Black lentils, butter, cream, slow cooked overnight.',
        11.40,
        tag: 'Vegetarian'),
    Dish('Shahi korma', 'Chicken in a mild almond and saffron sauce.', 13.60),
    Dish('Mixed vegetable curry', 'Seasonal vegetables, five spice.', 10.80,
        tag: 'Vegan'),
  ]),
  MenuSection('Grill', <Dish>[
    Dish('Beef seekh kebab', 'Minced beef skewers, onion salad.', 12.40),
    Dish('Tandoori chicken', 'Half chicken, yoghurt marinade, clay oven.',
        12.90),
    Dish('Lamb chops', 'Four chops, ginger, garlic and garam masala.', 19.80,
        tag: 'Chef pick'),
    Dish('Tikka platter', 'Chicken, lamb and paneer tikka with naan.', 21.50),
    Dish('Grilled pomfret', 'Whole pomfret, chilli lime butter.', 17.60),
    Dish('Malai boti', 'Creamy chicken tikka, cardamom.', 12.70),
    Dish('Charred corn', 'Chilli butter and lime.', 4.90, tag: 'Vegetarian'),
  ]),
  MenuSection('Sides', <Dish>[
    Dish('Garlic naan', 'Clay oven bread, garlic butter.', 3.20),
    Dish('Plain polao', 'Fragrant ghee rice.', 3.80),
    Dish('Aloo bhaji', 'Potato with mustard seed and turmeric.', 4.20,
        tag: 'Vegan'),
    Dish('Raita', 'Yoghurt, cucumber, roasted cumin.', 2.90),
    Dish('Masala fries', 'Fries tossed in chaat masala.', 3.90),
  ]),
  MenuSection('Desserts', <Dish>[
    Dish('Mishti doi', 'Sweet caramelised yoghurt in a clay pot.', 4.50),
    Dish('Rasmalai', 'Soft cheese dumplings in saffron milk.', 5.20),
    Dish('Gulab jamun', 'Warm milk dumplings in rose syrup.', 4.80),
    Dish('Firni', 'Ground rice pudding with pistachio.', 4.60),
    Dish('Mango kulfi', 'Dense frozen milk with Alphonso mango.', 5.40),
    Dish('Chocolate fondant', 'Molten centre, vanilla ice cream.', 6.90),
  ]),
  MenuSection('Drinks', <Dish>[
    Dish('Mango lassi', 'Yoghurt, mango and cardamom.', 3.90),
    Dish('Masala chai', 'Black tea, milk, ginger and spices.', 2.80),
  ]),
];
