import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scroll_atlas/fixtures.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'engines/engine_catalog.dart';

/// Manual "feel" check: pick an engine, then jump or animate to
/// random items in the same 100k fixture the benchmark measures.
void main() => runApp(const BenchmarkApp());

class BenchmarkApp extends StatelessWidget {
  const BenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'scroll_atlas benchmark',
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    home: const EnginePickerScreen(),
  );
}

class EnginePickerScreen extends StatelessWidget {
  const EnginePickerScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pick an engine')),
    body: ListView(
      children: <Widget>[
        for (final create in engineCatalog)
          ListTile(
            title: Text(_idOf(create)),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => FeelScreen(create: create),
                  ),
                ),
          ),
      ],
    ),
  );

  static String _idOf(EngineFactory create) {
    final engine = create();
    final id = engine.id;
    engine.dispose();
    return id;
  }
}

class FeelScreen extends StatefulWidget {
  const FeelScreen({required this.create, super.key});

  final EngineFactory create;

  @override
  State<FeelScreen> createState() => _FeelScreenState();
}

class _FeelScreenState extends State<FeelScreen> {
  static const int _itemCount = 100000;
  static const double _alignment = 0.5;

  late final ListEngine _engine = widget.create();
  final SeededExtents _extents = SeededExtents(seed: 42, length: _itemCount);
  final Random _random = Random(7);
  int? _target;

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  void _go({required bool animate}) {
    final engine = _engine;
    if (engine is! IndexedScrollEngine) return;
    final target = _random.nextInt(_itemCount);
    setState(() => _target = target);
    if (animate) {
      engine.animateToIndex(
        target,
        duration: const Duration(milliseconds: 600),
        alignment: _alignment,
      );
    } else {
      engine.jumpToIndex(target, alignment: _alignment);
    }
  }

  @override
  Widget build(BuildContext context) {
    final indexed = _engine is IndexedScrollEngine;
    return Scaffold(
      appBar: AppBar(title: Text(_engine.id)),
      body: Stack(
        children: <Widget>[
          _engine.buildList(
            itemCount: _itemCount,
            itemBuilder:
                (context, index) =>
                    FixtureItem(index: index, extent: _extents[index]),
          ),
          const Align(child: Divider(color: Colors.red, height: 1)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  indexed
                      ? 'Target: ${_target ?? '-'} (alignment $_alignment)'
                      : 'No index API: scroll by hand',
                ),
              ),
              FilledButton(
                onPressed: indexed ? () => _go(animate: false) : null,
                child: const Text('Jump'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: indexed ? () => _go(animate: true) : null,
                child: const Text('Animate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
