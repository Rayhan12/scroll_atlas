import 'package:flutter/material.dart';

/// Brand pink of the demo app, in the style of food delivery apps.
const Color brandPink = Color(0xFFD70F64);

/// Soft pink for chips, booked cells and highlights in light mode.
const Color brandPinkSoft = Color(0xFFFCE6EF);

/// Material 3 theme of the demo app for [brightness]: pink primary, white
/// rounded cards on a light grey page, pill chips and bold headers.
ThemeData demoTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final page = dark ? const Color(0xFF101012) : const Color(0xFFF4F4F6);
  final card = dark ? const Color(0xFF1C1C1F) : Colors.white;
  final scheme = ColorScheme.fromSeed(
    seedColor: brandPink,
    brightness: brightness,
  ).copyWith(
    primary: dark ? const Color(0xFFFF4F93) : brandPink,
    onPrimary: Colors.white,
    primaryContainer: dark ? const Color(0xFF4A1530) : brandPinkSoft,
    onPrimaryContainer:
        dark ? const Color(0xFFFFD9E6) : const Color(0xFF8A0A40),
    surface: card,
    surfaceContainerLowest: card,
    surfaceContainerLow: page,
    surfaceContainer: dark ? const Color(0xFF242428) : const Color(0xFFF0F0F3),
    surfaceContainerHigh:
        dark ? const Color(0xFF2C2C31) : const Color(0xFFE9E9EE),
    surfaceContainerHighest:
        dark ? const Color(0xFF34343A) : const Color(0xFFE2E2E8),
    onSurfaceVariant: dark ? const Color(0xFFB4B4BC) : const Color(0xFF6B6B76),
    outlineVariant: dark ? const Color(0xFF3A3A40) : const Color(0xFFE6E6EB),
  );
  final base = ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: page,
    visualDensity: VisualDensity.standard,
  );
  final text = base.textTheme.copyWith(
    headlineSmall: base.textTheme.headlineSmall
        ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3),
    titleLarge: base.textTheme.titleLarge
        ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
    titleMedium:
        base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    titleSmall:
        base.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    labelLarge:
        base.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
  );
  const pill = StadiumBorder();
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: card,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: Colors.black26,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: card,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: pill,
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: card,
      selectedColor: scheme.primaryContainer,
      labelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(shape: pill),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: pill,
        foregroundColor: scheme.primary,
        side: BorderSide(color: scheme.primary),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainer,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: Gap.l, vertical: Gap.m),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: BorderSide.none,
      ),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: scheme.primary,
      thumbColor: scheme.primary,
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (Set<WidgetState> states) =>
            states.contains(WidgetState.selected) ? scheme.primary : null,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: scheme.outlineVariant,
      thickness: 1,
      space: 1,
    ),
    tabBarTheme: TabBarTheme(
      labelColor: scheme.primary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: text.titleSmall,
      unselectedLabelStyle:
          text.titleSmall?.copyWith(fontWeight: FontWeight.w500),
      indicatorColor: scheme.primary,
      indicatorSize: TabBarIndicatorSize.label,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: scheme.primary, width: 3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
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

/// Corner radii used by every demo screen.
abstract final class Corners {
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
}
