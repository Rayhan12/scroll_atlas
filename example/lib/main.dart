import 'package:flutter/material.dart';

import 'demos/demo_catalog.dart';

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
    );
  }
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
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(builder: spec.builder),
          );
        },
      ),
    );
  }
}
