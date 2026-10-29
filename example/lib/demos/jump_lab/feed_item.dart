import 'package:flutter/material.dart';
import 'package:scroll_atlas/fixtures.dart';

import '../../app/demo_theme.dart';

/// A post card of a fixed [extent], so jumps can be measured exactly. Tall
/// posts get a picture area; short ones are a single line.
class FeedItem extends StatelessWidget {
  FeedItem({required this.index, required this.extent})
      : super(key: FixtureKeys.item(index));

  final int index;
  final double extent;

  static const List<IconData> _pictures = <IconData>[
    Icons.landscape,
    Icons.local_florist,
    Icons.directions_bike,
    Icons.beach_access,
    Icons.architecture,
    Icons.pets,
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hue = (index * 47) % 360;
    final accent = HSLColor.fromAHSL(
      1,
      hue.toDouble(),
      0.55,
      theme.brightness == Brightness.dark ? 0.35 : 0.80,
    ).toColor();
    return SizedBox(
      height: extent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Gap.l, vertical: 4),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: <Widget>[
              Positioned(
                left: Gap.m,
                right: Gap.m,
                top: 4,
                height: 32,
                child: Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 12,
                      backgroundColor: accent,
                      child: Text(
                        String.fromCharCode(65 + index.abs() % 26),
                        style: theme.textTheme.labelSmall,
                      ),
                    ),
                    const SizedBox(width: Gap.s),
                    Text('Item $index', style: theme.textTheme.titleSmall),
                    const Spacer(),
                    Text(
                      '${extent.round()} px',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (extent >= 120)
                Positioned(
                  left: Gap.m,
                  right: Gap.m,
                  top: 40,
                  bottom: Gap.m,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _pictures[index.abs() % _pictures.length],
                      size: 40,
                      color: scheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
