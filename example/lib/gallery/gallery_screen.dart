import 'package:flutter/material.dart';

import '../app/compare_row.dart';
import '../app/demo_theme.dart';
import '../demos/demo_catalog.dart';

/// Home screen: one card per demo with the problem, what goes wrong with
/// a plain ListView, and what scroll_atlas does instead.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          const SliverAppBar.large(title: Text('scroll_atlas')),
          SliverToBoxAdapter(
            child: _Centered(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.l),
                child: Text(
                  'Scroll to any item, land below sticky headers, and keep '
                  'linked scroll views in line. Pick a demo to see the '
                  'difference.',
                  style:
                      text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(Gap.l, 0, Gap.l, Gap.xl),
            sliver: SliverList.separated(
              itemCount: demoCatalog.length,
              separatorBuilder: (_, __) => const SizedBox(height: Gap.m),
              itemBuilder: (BuildContext context, int index) =>
                  _Centered(child: DemoCard(spec: demoCatalog[index])),
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

/// A gallery card for [spec].
class DemoCard extends StatelessWidget {
  const DemoCard({required this.spec, super.key});

  final DemoSpec spec;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: ValueKey<String>('demo-card-${spec.slug}'),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed<void>(spec.route),
        child: Padding(
          padding: const EdgeInsets.all(Gap.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(Gap.s + 2),
                      child: Icon(spec.icon, color: scheme.onPrimaryContainer),
                    ),
                  ),
                  const SizedBox(width: Gap.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          spec.title,
                          style: text.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          spec.problem,
                          style: text.bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
                ],
              ),
              const SizedBox(height: Gap.m),
              CompareRow.listView(spec.withListView),
              const SizedBox(height: Gap.s),
              CompareRow.atlas(spec.withAtlas),
            ],
          ),
        ),
      ),
    );
  }
}
