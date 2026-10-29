import 'package:flutter/material.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../../app/demo_theme.dart';
import 'food_menu_data.dart';

/// Food menu: a pinned app bar, a restaurant card that scrolls away, then
/// a separately pinned [AtlasTabBar] over eight sections. The tabs follow
/// the scroll, and a tap scrolls to the section in one move.
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
    final tabs = AtlasTabBar(
      key: const Key('menu_tabs'),
      controller: _atlas,
      sectionIds: <String>[
        for (var i = 0; i < menuSections.length; i++) menuSectionId(i),
      ],
      tabs: <Widget>[
        for (final MenuSection section in menuSections)
          Tab(text: section.title),
      ],
    );
    return Scaffold(
      body: AtlasScrollView(
        controller: _atlas,
        slivers: <Widget>[
          const SliverAppBar(
            pinned: true,
            title: Text('Saffron Kitchen'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Search',
                onPressed: null,
                icon: Icon(Icons.search),
              ),
            ],
          ),
          const SliverToBoxAdapter(child: _RestaurantCard()),
          SliverPersistentHeader(pinned: true, delegate: _TabsHeader(tabs)),
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
          const SliverToBoxAdapter(child: SizedBox(height: Gap.xl)),
        ],
      ),
    );
  }
}

/// Pins the tab bar under the app bar, on its own, so nothing overlaps it.
class _TabsHeader extends SliverPersistentHeaderDelegate {
  _TabsHeader(this.tabs);

  final AtlasTabBar tabs;

  @override
  double get minExtent => tabs.preferredSize.height;

  @override
  double get maxExtent => tabs.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrink, bool overlaps) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      elevation: overlaps ? 2 : 0,
      surfaceTintColor: scheme.surfaceTint,
      child: tabs,
    );
  }

  @override
  bool shouldRebuild(_TabsHeader old) => old.tabs != tabs;
}

/// Restaurant summary that scrolls away above the tabs.
class _RestaurantCard extends StatelessWidget {
  const _RestaurantCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    scheme.primaryContainer,
                    scheme.tertiaryContainer,
                  ],
                ),
              ),
              child: SizedBox(
                height: 120,
                width: double.infinity,
                child: Icon(
                  Icons.ramen_dining,
                  size: 64,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),
          const SizedBox(height: Gap.m),
          Text(
            'Bengali and North Indian kitchen',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: Gap.xs),
          const Wrap(
            spacing: Gap.l,
            children: <Widget>[
              _Fact(Icons.star_rounded, '4.7 (2.1k)', color: Colors.amber),
              _Fact(Icons.schedule, '25 to 35 min'),
              _Fact(Icons.delivery_dining, 'Free over \$20'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.icon, this.label, {this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon,
            size: 16, color: color ?? theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: Gap.xs),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.index, required this.stuck});

  final int index;
  final double stuck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final section = menuSections[index];
    return Material(
      key: ValueKey<String>('menu-header-$index'),
      elevation: stuck,
      color: Color.lerp(scheme.surface, scheme.surfaceContainer, stuck),
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: Gap.l),
          child: Row(
            children: <Widget>[
              Text(
                section.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: Gap.s),
              Text(
                '${section.dishes.length} dishes',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tag = dish.tag;
    return Padding(
      key: ValueKey<String>('dish-${dish.name}'),
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.s),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(dish.name, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(
                  dish.description,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: Gap.xs),
                Row(
                  children: <Widget>[
                    Text(
                      '\$${dish.price.toStringAsFixed(2)}',
                      style: theme.textTheme.labelLarge,
                    ),
                    if (tag != null) ...<Widget>[
                      const SizedBox(width: Gap.s),
                      _Tag(tag),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Gap.m),
          _Thumb(seed: dish.name.length),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: scheme.onSecondaryContainer),
        ),
      ),
    );
  }
}

/// Stand-in for a dish photo.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.seed});

  final int seed;

  static const List<IconData> _icons = <IconData>[
    Icons.rice_bowl,
    Icons.lunch_dining,
    Icons.local_dining,
    Icons.soup_kitchen,
    Icons.icecream,
    Icons.local_cafe,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        _icons[seed % _icons.length],
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
