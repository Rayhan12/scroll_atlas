import 'package:flutter/material.dart';

import 'app/demo_theme.dart';
import 'demos/demo_catalog.dart';
import 'demos/demo_frame.dart';
import 'gallery/gallery_screen.dart';

void main() {
  runApp(const ScrollAtlasDemoApp());
}

/// The scroll_atlas demo app: a gallery of demos, light and dark.
class ScrollAtlasDemoApp extends StatelessWidget {
  const ScrollAtlasDemoApp({this.themeMode = ThemeMode.system, super.key});

  /// Light, dark or follow the system.
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'scroll_atlas demo',
      debugShowCheckedModeBanner: false,
      theme: demoTheme(Brightness.light),
      darkTheme: demoTheme(Brightness.dark),
      themeMode: themeMode,
      home: const GalleryScreen(),
      onGenerateRoute: demoRoute,
    );
  }
}

/// Builds the route for a demo's [RouteSettings.name] (such as `/menu`,
/// so the web build can deep link with `#/menu`), or null when no demo
/// has that name.
Route<void>? demoRoute(RouteSettings settings) {
  for (final DemoSpec spec in demoCatalog) {
    if (spec.route != settings.name) continue;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) =>
          DemoFrame(spec: spec, child: spec.builder(context)),
    );
  }
  return null;
}
