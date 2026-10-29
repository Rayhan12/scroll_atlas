import 'package:flutter/material.dart';

import 'demos/demo_catalog.dart';
import 'demos/demo_frame.dart';

void main() {
  runApp(const ScrollAtlasDemoApp());
}

/// Portfolio demo shell listing D1 through D6.
class ScrollAtlasDemoApp extends StatelessWidget {
  const ScrollAtlasDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'scroll_atlas demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DemoHomeScreen(),
      onGenerateRoute: demoRoute,
    );
  }
}

/// Route name of a demo, such as `/d4`, so the web build can deep link
/// to one screen (`#/d4`).
String demoRouteName(DemoScreenSpec spec) => '/${spec.id.toLowerCase()}';

/// Builds the route for a demo's [RouteSettings.name], or null when no
/// demo has that name.
Route<void>? demoRoute(RouteSettings settings) {
  for (final DemoScreenSpec spec in demoCatalog) {
    if (demoRouteName(spec) != settings.name) continue;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (BuildContext context) =>
          DemoFrame(spec: spec, child: spec.builder(context)),
    );
  }
  return null;
}

/// Home screen with one tile per planned demo screen.
class DemoHomeScreen extends StatelessWidget {
  const DemoHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('scroll_atlas demo')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: demoCatalog.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int index) {
          final DemoScreenSpec spec = demoCatalog[index];
          return DemoTile(spec: spec);
        },
      ),
    );
  }
}

class DemoTile extends StatelessWidget {
  const DemoTile({required this.spec, super.key});

  final DemoScreenSpec spec;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text('${spec.id} ${spec.title}'),
        subtitle: Text(spec.whatToTry),
        isThreeLine: true,
        onTap: () => Navigator.of(context).pushNamed<void>(demoRouteName(spec)),
      ),
    );
  }
}
