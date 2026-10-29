import 'package:flutter/foundation.dart';

import 'food_menu_data.dart';

/// Dishes in the cart and how many of each. Holds data only.
class FoodCart extends ChangeNotifier {
  FoodCart([Map<Dish, int> initial = const <Dish, int>{}])
      : _counts = Map<Dish, int>.of(initial);

  final Map<Dish, int> _counts;

  /// How many of [dish] are in the cart.
  int countOf(Dish dish) => _counts[dish] ?? 0;

  /// Items in the cart.
  int get itemCount => _counts.values.fold(0, (int a, int b) => a + b);

  /// Sum of every item's price.
  double get total => _counts.entries.fold(
      0, (double sum, MapEntry<Dish, int> e) => sum + e.key.price * e.value);

  bool get isEmpty => itemCount == 0;

  /// Adds one [dish].
  void add(Dish dish) {
    _counts[dish] = countOf(dish) + 1;
    notifyListeners();
  }
}
