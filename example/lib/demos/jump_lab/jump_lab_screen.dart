import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../../app/demo_theme.dart';
import '../demo_frame.dart';
import 'jump_lab_controller.dart';

/// Jump lab: [AtlasListView] with an alignment marker, a scrollbar and
/// a readout of builds, landing error and time for the last jump.
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

  /// Runs a jump or animation, then shows its result here and in the
  /// debug overlay.
  Future<void> _run(Future<void> Function() move) async {
    await move();
    if (!mounted) return;
    _refresh();
    DemoDebug.maybeOf(context)?.reportJump(_controller.lastJumpError);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Jump lab')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _Controls(
            controller: _controller,
            onChanged: _refresh,
            onJump: () => _run(_controller.jump),
            onAnimate: () => _run(_controller.animate),
            onRandom: () {
              _controller.pickRandomIndex();
              _refresh();
            },
            onInsert: () {
              _controller.insertAtTop();
              _refresh();
            },
            onGrow: () {
              if (_controller.growAbove()) _refresh();
            },
          ),
          _Readout(controller: _controller),
          _VisibleReadout(positions: _controller.atlas.positions),
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
                          color: Theme.of(context).colorScheme.primary,
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
    required this.onInsert,
    required this.onGrow,
  });

  final JumpLabController controller;
  final VoidCallback onChanged;
  final VoidCallback onJump;
  final VoidCallback onAnimate;
  final VoidCallback onRandom;
  final VoidCallback onInsert;
  final VoidCallback onGrow;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.m, Gap.xs),
      child: Padding(
        padding: const EdgeInsets.all(Gap.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              key: const Key('jump_index_field'),
              controller: controller.indexController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Index',
                prefixIcon: Icon(Icons.tag),
              ),
              onSubmitted: (_) => onChanged(),
            ),
            Row(
              children: <Widget>[
                Text('Alignment',
                    style: Theme.of(context).textTheme.labelLarge),
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
              spacing: Gap.s,
              runSpacing: Gap.s,
              children: <Widget>[
                FilledButton(
                  key: const Key('jump_button'),
                  onPressed: onJump,
                  child: const Text('Jump'),
                ),
                FilledButton(
                  onPressed: onAnimate,
                  key: const Key('animate_button'),
                  child: const Text('Animate'),
                ),
                OutlinedButton(
                  onPressed: onRandom,
                  child: const Text('Random'),
                ),
                OutlinedButton(
                  key: const Key('insert_button'),
                  onPressed: onInsert,
                  child: const Text('Insert 20 at top'),
                ),
                OutlinedButton(
                  key: const Key('grow_button'),
                  onPressed: onGrow,
                  child: const Text('Grow images above'),
                ),
                FilterChip(
                  key: const Key('slow_motion_chip'),
                  label: const Text('Slow motion'),
                  selected: controller.slowMotion,
                  onSelected: (bool value) {
                    controller.slowMotion = value;
                    onChanged();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Built items, landing error and time of the last jump or animation.
class _Readout extends StatelessWidget {
  const _Readout({required this.controller});

  final JumpLabController controller;

  @override
  Widget build(BuildContext context) {
    final error = controller.lastJumpError;
    final ms = controller.lastJumpMs;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.xs),
      padding: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: Gap.s),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(Corners.m),
      ),
      child: Text(
        'Builds on last jump: ${controller.lastJumpBuilds}   '
        'Error: ${error == null ? '-' : '${error.toStringAsFixed(2)} px'}   '
        'Time: ${ms == null ? '-' : '${ms.toStringAsFixed(1)} ms'}   '
        'Items: ${controller.itemCount}',
        key: const Key('jump_readout'),
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

/// First and last visible item, from [AtlasController.positions].
class _VisibleReadout extends StatelessWidget {
  const _VisibleReadout({required this.positions});

  final ValueListenable<List<AtlasItemPosition>> positions;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AtlasItemPosition>>(
      valueListenable: positions,
      builder: (BuildContext context, List<AtlasItemPosition> visible, _) {
        final text = visible.isEmpty
            ? 'Visible: -'
            : 'Visible: ${visible.first.index} to ${visible.last.index}';
        return Padding(
          padding: const EdgeInsets.only(bottom: Gap.xs),
          child: Text(
            text,
            key: const Key('visible_readout'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        );
      },
    );
  }
}
