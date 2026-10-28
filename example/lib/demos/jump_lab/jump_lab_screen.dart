import 'package:flutter/material.dart';

import 'jump_lab_controller.dart';

/// D1 Jump lab: prototype engine with alignment marker and build counter.
class JumpLabScreen extends StatefulWidget {
  const JumpLabScreen({super.key});

  @override
  State<JumpLabScreen> createState() => _JumpLabScreenState();
}

class _JumpLabScreenState extends State<JumpLabScreen> {
  late final JumpLabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = JumpLabController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('D1 Jump lab')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Controls(
            controller: _controller,
            onChanged: _refresh,
            onJump: () async {
              await _controller.jump();
              if (mounted) {
                _refresh();
              }
            },
            onAnimate: () async {
              await _controller.animate();
              if (mounted) {
                _refresh();
              }
            },
            onRandom: () {
              _controller.pickRandomIndex();
              _refresh();
            },
          ),
          Text(
            'Builds on last jump: ${_controller.lastJumpBuilds}',
            textAlign: TextAlign.center,
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final markerY = _controller.alignment * constraints.maxHeight;
                return Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    _controller.buildList(),
                    Positioned(
                      left: 0,
                      right: 0,
                      top: markerY,
                      child: IgnorePointer(
                        child: Container(
                          height: 2,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.controller,
    required this.onChanged,
    required this.onJump,
    required this.onAnimate,
    required this.onRandom,
  });

  final JumpLabController controller;
  final VoidCallback onChanged;
  final VoidCallback onJump;
  final VoidCallback onAnimate;
  final VoidCallback onRandom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            key: const Key('jump_index_field'),
            controller: controller.indexController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Index',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => onChanged(),
          ),
          Row(
            children: <Widget>[
              const Text('Alignment'),
              Expanded(
                child: Slider(
                  value: controller.alignment,
                  divisions: 4,
                  onChanged: (double value) {
                    controller.alignment = value;
                    onChanged();
                  },
                ),
              ),
              Text(controller.alignment.toStringAsFixed(2)),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton(
                key: const Key('jump_button'),
                onPressed: onJump,
                child: const Text('Jump'),
              ),
              FilledButton(
                onPressed: onAnimate,
                child: const Text('Animate (600 ms)'),
              ),
              OutlinedButton(
                onPressed: onRandom,
                child: const Text('Random'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
