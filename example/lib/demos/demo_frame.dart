import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'demo_catalog.dart';

/// Debug values a demo screen can report to its [DemoFrame].
class DemoDebug extends ChangeNotifier {
  double? _lastJumpError;

  /// Landing error in px of the last jump, or null if not measured.
  double? get lastJumpError => _lastJumpError;

  /// Records the landing error of a jump the screen measured.
  void reportJump(double? errorPx) {
    _lastJumpError = errorPx;
    notifyListeners();
  }

  /// The [DemoDebug] of the enclosing [DemoFrame], if any.
  static DemoDebug? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DemoDebugScope>()?.notifier;
}

class _DemoDebugScope extends InheritedNotifier<DemoDebug> {
  const _DemoDebugScope({required DemoDebug debug, required super.child})
      : super(notifier: debug);
}

/// Wraps a demo screen with a "What to try" card and a debug overlay
/// toggle (built items, last jump error, frame time), the same on every
/// screen.
class DemoFrame extends StatefulWidget {
  const DemoFrame({required this.spec, required this.child, super.key});

  final DemoScreenSpec spec;
  final Widget child;

  @override
  State<DemoFrame> createState() => _DemoFrameState();
}

class _DemoFrameState extends State<DemoFrame> {
  final DemoDebug _debug = DemoDebug();
  final GlobalKey _screenKey = GlobalKey(debugLabel: 'demo-screen');
  bool _showTips = false;
  bool _showDebug = false;

  @override
  void dispose() {
    _debug.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _DemoDebugScope(
      debug: _debug,
      // The chips sit in a strip under the screen, so they never cover its
      // own bottom controls (such as the D6 composer); the panels they open
      // float over the screen.
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                KeyedSubtree(key: _screenKey, child: widget.child),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_showTips) _TipsCard(spec: widget.spec),
                        if (_showDebug)
                          _DebugPanel(debug: _debug, screenKey: _screenKey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Material(
            elevation: 4,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FilterChip(
                      key: const Key('what_to_try_toggle'),
                      label: const Text('What to try'),
                      selected: _showTips,
                      onSelected: (on) => setState(() => _showTips = on),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      key: const Key('debug_toggle'),
                      label: const Text('Debug'),
                      selected: _showDebug,
                      onSelected: (on) => setState(() => _showDebug = on),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.spec});

  final DemoScreenSpec spec;

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const Key('what_to_try_card'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What to try', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(spec.whatToTry),
            const SizedBox(height: 4),
            Text(
              'Coming in a later version',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Live debug values: items built in every list on screen, the last jump
/// error the screen reported, and build and raster time of the last frame.
class _DebugPanel extends StatefulWidget {
  const _DebugPanel({required this.debug, required this.screenKey});

  final DemoDebug debug;
  final GlobalKey screenKey;

  @override
  State<_DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<_DebugPanel> {
  int _built = 0;
  FrameTiming? _timing;

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _sample();
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_onTimings);
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (mounted && timings.isNotEmpty) setState(() => _timing = timings.last);
  }

  /// Counts built items after each frame; only rebuilds on a change, so it
  /// never schedules frames by itself.
  void _sample() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final built =
          countBuiltItems(widget.screenKey.currentContext?.findRenderObject());
      if (built != _built) setState(() => _built = built);
      _sample();
    });
  }

  static String _ms(Duration d) => (d.inMicroseconds / 1000).toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final timing = _timing;
    return ListenableBuilder(
      listenable: widget.debug,
      builder: (context, _) {
        final error = widget.debug.lastJumpError;
        return Card(
          key: const Key('debug_overlay'),
          color: Colors.black87,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: DefaultTextStyle(
              style: const TextStyle(color: Colors.white, fontSize: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Built items: $_built'),
                  Text('Last jump error: '
                      '${error == null ? '-' : '${error.toStringAsFixed(2)} px'}'),
                  Text(timing == null
                      ? 'Frame: -'
                      : 'Frame: build ${_ms(timing.buildDuration)} ms, '
                          'raster ${_ms(timing.rasterDuration)} ms'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Items currently built in every lazy list or grid under [root].
int countBuiltItems(RenderObject? root) {
  var count = 0;
  void visit(RenderObject node) {
    if (node is RenderSliverMultiBoxAdaptor) {
      var child = node.firstChild;
      while (child != null) {
        count++;
        child = node.childAfter(child);
      }
    }
    node.visitChildren(visit);
  }

  if (root != null) visit(root);
  return count;
}
