import 'package:flutter/material.dart';

import 'demo_theme.dart';

/// A bundled food photo with rounded corners. Falls back to a tinted box
/// with an icon if the asset cannot load.
class FoodPhoto extends StatelessWidget {
  const FoodPhoto(
    this.asset, {
    this.width,
    this.height,
    this.radius = Corners.m,
    super.key,
  });

  final String asset;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (BuildContext context, Object error, StackTrace? st) =>
            Container(
          width: width,
          height: height,
          color: scheme.primaryContainer,
          child: Icon(Icons.restaurant, color: scheme.onPrimaryContainer),
        ),
      ),
    );
  }
}
