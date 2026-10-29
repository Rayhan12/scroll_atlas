import 'package:flutter/material.dart';
import 'package:scroll_atlas/fixtures.dart';

import '../../app/demo_theme.dart';
import '../../app/food_photo.dart';
import '../../app/food_photos.dart';

/// A post card of a fixed [extent], so jumps can be measured exactly. Tall
/// posts get a food photo; short ones are a single line.
class FeedItem extends StatelessWidget {
  FeedItem({required this.index, required this.extent})
      : super(key: FixtureKeys.item(index));

  final int index;
  final double extent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        String.fromCharCode(65 + index.abs() % 26),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: scheme.onPrimaryContainer),
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
                  child: FoodPhoto(FoodPhotos.section(index.abs())),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
