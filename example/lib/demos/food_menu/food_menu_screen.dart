import 'package:flutter/material.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'food_menu_data.dart';

/// D4 Food menu: a collapsing hero image, a pinned [AtlasTabBar] over
/// eight sections, a scroll spy and tap to scroll.
class FoodMenuScreen extends StatefulWidget {
  const FoodMenuScreen({super.key});

  @override
  State<FoodMenuScreen> createState() => _FoodMenuScreenState();
}

class _FoodMenuScreenState extends State<FoodMenuScreen> {
  final AtlasController _atlas = AtlasController();

  @override
  void dispose() {
    _atlas.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AtlasScrollView(
        controller: _atlas,
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            flexibleSpace: const FlexibleSpaceBar(
              // Keep the title above the tab bar, which sits at the bottom
              // of the flexible space.
              titlePadding: EdgeInsetsDirectional.only(
                start: 56,
                bottom: 16 + kTextTabBarHeight,
              ),
              title: Text('D4 Food menu'),
              background: _Hero(),
            ),
            bottom: AtlasTabBar(
              key: const Key('menu_tabs'),
              controller: _atlas,
              sectionIds: <String>[
                for (var i = 0; i < menuSections.length; i++) menuSectionId(i),
              ],
              tabs: <Widget>[
                for (final MenuSection section in menuSections)
                  Tab(text: section.title),
              ],
            ),
          ),
          for (var i = 0; i < menuSections.length; i++)
            SliverAtlasSection(
              id: menuSectionId(i),
              header: (BuildContext context, double stuck) =>
                  _SectionHeader(index: i, stuck: stuck),
              sliver: SliverAtlasList.builder(
                id: 'dishes-$i',
                itemCount: menuSections[i].dishes.length,
                itemBuilder: (BuildContext context, int index) =>
                    _DishTile(dish: menuSections[i].dishes[index]),
              ),
            ),
        ],
      ),
    );
  }
}

/// Stand-in for a hero photo: a gradient with an icon.
class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[scheme.primary, scheme.tertiary],
        ),
      ),
      child: Icon(Icons.restaurant, size: 96, color: scheme.onPrimary),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.index, required this.stuck});

  final int index;
  final double stuck;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: ValueKey<String>('menu-header-$index'),
      elevation: 2 * stuck,
      color: Color.lerp(scheme.surface, scheme.secondaryContainer, stuck),
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              menuSections[index].title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}

class _DishTile extends StatelessWidget {
  const _DishTile({required this.dish});

  final Dish dish;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: ValueKey<String>('dish-${dish.name}'),
      title: Text(dish.name),
      subtitle: Text(dish.description),
      trailing: Text('\$${dish.price.toStringAsFixed(2)}'),
    );
  }
}
