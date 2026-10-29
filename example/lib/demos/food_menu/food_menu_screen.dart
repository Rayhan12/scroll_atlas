import 'package:flutter/material.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../../app/demo_theme.dart';
import '../../app/food_photo.dart';
import '../../app/food_photos.dart';
import 'food_cart.dart';
import 'food_menu_data.dart';

/// Restaurant page: a photo hero that collapses into the app bar, an info
/// panel that scrolls away, then a separately pinned [AtlasTabBar] over
/// eight sections. The tabs follow the scroll, a tap scrolls to the
/// section in one move, and a cart bar stays at the bottom.
class FoodMenuScreen extends StatefulWidget {
  const FoodMenuScreen({this.startWithItems = true, super.key});

  /// Starts with two dishes in the cart, so the cart bar shows at once.
  final bool startWithItems;

  /// Height of the hero when fully open.
  static const double heroHeight = 220;

  @override
  State<FoodMenuScreen> createState() => _FoodMenuScreenState();
}

class _FoodMenuScreenState extends State<FoodMenuScreen> {
  final AtlasController _atlas = AtlasController();
  late final FoodCart _cart = FoodCart(<Dish, int>{
    if (widget.startWithItems) menuSections[3].dishes.first: 1,
    if (widget.startWithItems) menuSections.last.dishes.first: 2,
  });

  @override
  void dispose() {
    _atlas.dispose();
    _cart.dispose();
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: AtlasScrollView(
        controller: _atlas,
        slivers: <Widget>[
          const _HeroAppBar(),
          const SliverToBoxAdapter(child: _RestaurantInfo()),
          SliverPersistentHeader(pinned: true, delegate: _TabsHeader(tabs)),
          for (var i = 0; i < menuSections.length; i++)
            SliverAtlasSection(
              id: menuSectionId(i),
              header: (BuildContext context, double stuck) =>
                  _SectionHeader(index: i, stuck: stuck),
              sliver: SliverAtlasList.builder(
                id: 'dishes-$i',
                itemCount: menuSections[i].dishes.length,
                itemBuilder: (BuildContext context, int index) => _DishTile(
                  dish: menuSections[i].dishes[index],
                  photo: FoodPhotos.section(i),
                  cart: _cart,
                ),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: Gap.xl * 2)),
        ],
      ),
      bottomNavigationBar: _CartBar(cart: _cart),
    );
  }
}

/// Pinned app bar whose photo fades into a plain title bar as it collapses.
class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canPop = Navigator.of(context).canPop();
    return SliverAppBar(
      pinned: true,
      expandedHeight: FoodMenuScreen.heroHeight,
      automaticallyImplyLeading: false,
      backgroundColor: scheme.surface,
      leading: canPop
          ? _RoundButton(
              icon: Icons.arrow_back,
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: const <Widget>[
        _RoundButton(icon: Icons.favorite_border, tooltip: 'Save'),
        _RoundButton(icon: Icons.ios_share, tooltip: 'Share'),
        _RoundButton(icon: Icons.search, tooltip: 'Search'),
        SizedBox(width: Gap.s),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final top = MediaQuery.paddingOf(context).top;
          final collapsed = kToolbarHeight + top;
          final open = FoodMenuScreen.heroHeight + top;
          final t = ((constraints.maxHeight - collapsed) / (open - collapsed))
              .clamp(0.0, 1.0);
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Opacity(
                opacity: t,
                child: const FoodPhoto(FoodPhotos.hero, radius: 0),
              ),
              Opacity(
                opacity: t,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.center,
                      colors: <Color>[Colors.black38, Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: canPop ? 64 : Gap.l,
                right: 160,
                bottom: 0,
                height: kToolbarHeight,
                child: Opacity(
                  opacity: 1 - t,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      restaurantName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// White circle button that reads on the photo and on the plain bar.
class _RoundButton extends StatelessWidget {
  const _RoundButton(
      {required this.icon, required this.tooltip, this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(Gap.xs + 2),
      child: Material(
        color: scheme.surface,
        shape: const CircleBorder(),
        elevation: 1,
        child: IconButton(
          tooltip: tooltip,
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          color: scheme.onSurface,
          onPressed: onPressed ?? () {},
          icon: Icon(icon),
        ),
      ),
    );
  }
}

/// Name, cuisine, rating, delivery and deals; scrolls away above the tabs.
class _RestaurantInfo extends StatelessWidget {
  const _RestaurantInfo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted =
        theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.l, Gap.l, Gap.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(restaurantName, style: theme.textTheme.headlineSmall),
          const SizedBox(height: Gap.xs),
          Text('Bengali  ·  North Indian  ·  Biryani', style: muted),
          const SizedBox(height: Gap.m),
          Row(
            children: <Widget>[
              Icon(Icons.star_rounded, size: 20, color: scheme.primary),
              const SizedBox(width: Gap.xs),
              Text('4.7', style: theme.textTheme.titleSmall),
              Text('  (2,000+ ratings)', style: muted),
              const Spacer(),
              Text(
                'Reviews',
                style:
                    theme.textTheme.labelLarge?.copyWith(color: scheme.primary),
              ),
            ],
          ),
          const SizedBox(height: Gap.s),
          Row(
            children: <Widget>[
              Icon(Icons.delivery_dining,
                  size: 20, color: scheme.onSurfaceVariant),
              const SizedBox(width: Gap.xs),
              Text('Delivery 25 to 35 min', style: muted),
              Text('  ·  ', style: muted),
              Text('Free over \$20', style: muted),
            ],
          ),
          const SizedBox(height: Gap.m),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _Deal(Icons.local_offer, '15% off, min. order \$15'),
                SizedBox(width: Gap.s),
                _Deal(Icons.card_giftcard, 'Free drink over \$30'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A pink deal pill.
class _Deal extends StatelessWidget {
  const _Deal(this.icon, this.label);

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.primaryContainer,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: Gap.s - 2),
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ],
        ),
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
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: overlaps ? 2 : 0,
      shadowColor: Colors.black26,
      child: tabs,
    );
  }

  @override
  bool shouldRebuild(_TabsHeader old) => old.tabs != tabs;
}

/// Bold section title that sticks under the tabs while its section shows.
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
      color: scheme.surface,
      elevation: stuck,
      shadowColor: Colors.black26,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.l, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(section.title, style: theme.textTheme.titleLarge),
              const SizedBox(width: Gap.s),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${section.dishes.length} items',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A dish: name, description and price on the left, photo with an add
/// button on the right.
class _DishTile extends StatelessWidget {
  const _DishTile(
      {required this.dish, required this.photo, required this.cart});

  final Dish dish;
  final String photo;
  final FoodCart cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tag = dish.tag;
    return Padding(
      key: ValueKey<String>('dish-${dish.name}'),
      padding: const EdgeInsets.symmetric(horizontal: Gap.l),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: Gap.l),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(dish.name, style: theme.textTheme.titleSmall),
                    const SizedBox(height: Gap.xs),
                    Text(
                      dish.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: Gap.s),
                    Row(
                      children: <Widget>[
                        Text(
                          '\$${dish.price.toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall,
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
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    FoodPhoto(photo, width: 96, height: 96),
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: _AddButton(dish: dish, cart: cart),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White round "+" over the photo; shows the count once added.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.dish, required this.cart});

  final Dish dish;
  final FoodCart cart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: cart,
      builder: (BuildContext context, _) {
        final count = cart.countOf(dish);
        return Material(
          key: ValueKey<String>('add-${dish.name}'),
          color: count > 0 ? scheme.primary : scheme.surface,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: Colors.black38,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => cart.add(dish),
            child: SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: count > 0
                    ? Text(
                        '$count',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(color: scheme.onPrimary),
                      )
                    : Icon(Icons.add, color: scheme.primary, size: 22),
              ),
            ),
          ),
        );
      },
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
      decoration: ShapeDecoration(
        color: scheme.surfaceContainer,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.s, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall
              ?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

/// Pink bar pinned to the bottom with the item count and total.
class _CartBar extends StatelessWidget {
  const _CartBar({required this.cart});

  final FoodCart cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final onPink = theme.textTheme.titleSmall?.copyWith(color: Colors.white);
    return ListenableBuilder(
      listenable: cart,
      builder: (BuildContext context, _) {
        if (cart.isEmpty) return const SizedBox.shrink();
        return Material(
          color: scheme.surface,
          elevation: 8,
          shadowColor: Colors.black26,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(Gap.l, Gap.m, Gap.l, Gap.m),
              child: Material(
                key: const Key('cart_bar'),
                color: scheme.primary,
                borderRadius: BorderRadius.circular(Corners.m),
                child: InkWell(
                  borderRadius: BorderRadius.circular(Corners.m),
                  onTap: () {},
                  child: SizedBox(
                    height: 52,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: Gap.l),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.white, width: 1.5),
                            ),
                            child: Text('${cart.itemCount}', style: onPink),
                          ),
                          const SizedBox(width: Gap.m),
                          Expanded(
                              child: Text('View your cart', style: onPink)),
                          Text('\$${cart.total.toStringAsFixed(2)}',
                              style: onPink),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
