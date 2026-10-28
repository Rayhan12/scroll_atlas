import 'package:flutter/material.dart';

import 'demo_catalog.dart';

/// Shared placeholder for demo screens not yet implemented (D2 to D6).
class PlaceholderDemoScreen extends StatelessWidget {
  const PlaceholderDemoScreen({required this.spec, super.key});

  final DemoScreenSpec spec;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${spec.id} ${spec.title}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'What to try',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(spec.whatToTry),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Coming in a later version',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
