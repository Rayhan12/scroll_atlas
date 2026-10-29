import 'package:flutter/material.dart';

import '../app/compare_row.dart';
import '../app/demo_theme.dart';
import '../app/food_photo.dart';
import '../demos/demo_catalog.dart';

/// Home screen: a pink header, quick links, then one card per demo with
/// the problem, what goes wrong with a plain ListView, and what
/// scroll_atlas does instead.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          const _Header(),
          const SliverToBoxAdapter(child: _QuickLinks()),
          SliverToBoxAdapter(
            child: _Centered(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Gap.l, Gap.s, Gap.l, Gap.m),
                child: Text('Demos', style: text.titleLarge),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.xl),
            sliver: SliverList.separated(
              itemCount: demoCatalog.length,
              separatorBuilder: (_, __) => const SizedBox(height: Gap.l),
              itemBuilder: (BuildContext context, int index) =>
                  _Centered(child: DemoCard(spec: demoCatalog[index])),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pink header with rounded bottom corners; collapses to a pink bar.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pink = theme.colorScheme.primary;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 168,
      backgroundColor: pink,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding:
            const EdgeInsetsDirectional.only(start: Gap.l, bottom: Gap.l),
        title: Text(
          'scroll_atlas',
          style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
        ),
        background: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, 52),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: Text(
              'Scroll to any item, land below sticky headers and keep linked '
              'views in line.',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ),
      ),
    );
  }
}

/// One pill per demo for a quick jump into it.
class _QuickLinks extends StatelessWidget {
  const _QuickLinks();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(Gap.l, Gap.l, Gap.l, Gap.s),
      child: Row(
        children: <Widget>[
          for (final DemoSpec spec in demoCatalog)
            Padding(
              padding: const EdgeInsets.only(right: Gap.s),
              child: ActionChip(
                avatar: Icon(spec.icon, size: 18, color: scheme.primary),
                label: Text(spec.title),
                onPressed: () =>
                    Navigator.of(context).pushNamed<void>(spec.route),
              ),
            ),
        ],
      ),
    );
  }
}

/// Limits content to a readable width on tablets and the web.
class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: child,
        ),
      );
}

/// A gallery card for [spec]: a photo or icon banner, the problem, and
/// the ListView versus scroll_atlas comparison.
class DemoCard extends StatelessWidget {
  const DemoCard({required this.spec, super.key});

  final DemoSpec spec;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final photo = spec.photo;
    return Card(
      key: ValueKey<String>('demo-card-${spec.slug}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed<void>(spec.route),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: photo == null ? 88 : 150,
              child: photo == null
                  ? _IconBanner(icon: spec.icon)
                  : Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        FoodPhoto(photo, radius: 0),
                        const Positioned(
                          left: Gap.m,
                          top: Gap.m,
                          child: _Badge('Flagship'),
                        ),
                      ],
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(Gap.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(spec.title, style: text.titleMedium),
                      ),
                      Icon(Icons.arrow_forward, color: scheme.primary),
                    ],
                  ),
                  const SizedBox(height: Gap.xs),
                  Text(
                    spec.problem,
                    style: text.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: Gap.m),
                  CompareRow.listView(spec.withListView),
                  const SizedBox(height: Gap.s),
                  CompareRow.atlas(spec.withAtlas),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft pink banner with the demo icon, for demos without a photo.
class _IconBanner extends StatelessWidget {
  const _IconBanner({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.primaryContainer,
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -12,
            bottom: -18,
            child: Icon(
              icon,
              size: 110,
              color: scheme.primary.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            left: Gap.l,
            top: 0,
            bottom: 0,
            child: Center(
              child: CircleAvatar(
                radius: 26,
                backgroundColor: scheme.primary,
                child: Icon(icon, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// White pill label over a photo.
class _Badge extends StatelessWidget {
  const _Badge(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: scheme.primary,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: 4),
        child: Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelMedium
              ?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
