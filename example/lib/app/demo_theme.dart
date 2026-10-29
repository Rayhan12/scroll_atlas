import 'package:flutter/material.dart';

/// Seed color of the demo app.
const Color demoSeed = Color(0xFF3355D1);

/// Material 3 theme of the demo app for [brightness].
ThemeData demoTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: demoSeed,
    brightness: brightness,
  );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
  );
  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      surfaceTintColor: scheme.surfaceTint,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ),
    tabBarTheme: TabBarTheme(
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      indicatorColor: scheme.primary,
      dividerColor: scheme.outlineVariant,
      tabAlignment: TabAlignment.start,
    ),
  );
}

/// Spacing scale used by every demo screen.
abstract final class Gap {
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
}
