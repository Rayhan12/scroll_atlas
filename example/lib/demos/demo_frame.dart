import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../app/compare_row.dart';
import '../app/demo_theme.dart';
import 'demo_spec.dart';

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

/// Wraps a demo screen with a bar that says what scroll_atlas fixes, a
/// "How it helps" card and a debug overlay (built items, last jump error,
/// frame time), the same on every screen.
class DemoFrame extends StatefulWidget {
  const DemoFrame({required this.spec, required this.child, super.key});

  final DemoSpec spec;
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
      // The bar sits under the screen, so it never covers the screen's own
      // bottom controls (such as the chat composer); the panels it opens
      // float over the screen.
      child: Column(
        children: <Widget>[
          Expanded(
            child: Stack(
              children: <Widget>[
                // The bar below owns the bottom safe area, so the screen
                // does not pad for the home indicator a second time.
                MediaQuery.removePadding(
                  context: context,
                  removeBottom: true,
                  child: KeyedSubtree(key: _screenKey, child: widget.child),
                ),
                Positioned(
                  left: Gap.s,
                  right: Gap.s,
                  bottom: Gap.s,
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (_showTips) _TipsCard(spec: widget.spec),
                        if (_showTips && _showDebug)
                          const SizedBox(height: Gap.s),
                        if (_showDebug)
                          _DebugPanel(debug: _debug, screenKey: _screenKey),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _WhyBar(
            spec: widget.spec,
            showTips: _showTips,
            showDebug: _showDebug,
            onTips: () => setState(() => _showTips = !_showTips),
            onDebug: () => setState(() => _showDebug = !_showDebug),
          ),
        ],
      ),
    );
  }
}

/// The strip under every demo: what scroll_atlas fixes here, plus the
/// "How it helps" and "Debug" toggles.
class _WhyBar extends StatelessWidget {
  const _WhyBar({
    required this.spec,
    required this.showTips,
    required this.showDebug,
    required this.onTips,
    required this.onDebug,
  });

  final DemoSpec spec;
  final bool showTips;
  final bool showDebug;
  final VoidCallback onTips;
  final VoidCallback onDebug;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(Gap.l, Gap.xs, Gap.s, Gap.xs),
            child: Row(
              children: <Widget>[
                Icon(Icons.check_circle, size: 18, color: scheme.primary),
                const SizedBox(width: Gap.s),
                Expanded(
                  child: Text(
                    spec.withAtlas,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                IconButton(
                  key: const Key('what_to_try_toggle'),
                  tooltip: 'How it helps',
                  isSelected: showTips,
                  color: scheme.onSurfaceVariant,
                  selectedIcon: Icon(Icons.lightbulb, color: scheme.primary),
                  icon: const Icon(Icons.lightbulb_outline),
                  onPressed: onTips,
                ),
                IconButton(
                  key: const Key('debug_toggle'),
                  tooltip: 'Debug',
                  isSelected: showDebug,
                  color: scheme.onSurfaceVariant,
                  selectedIcon: Icon(Icons.speed, color: scheme.primary),
                  icon: const Icon(Icons.speed_outlined),
                  onPressed: onDebug,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The problem, the plain ListView result, the scroll_atlas result and
/// what to try.
class _TipsCard extends StatelessWidget {
  const _TipsCard({required this.spec});

  final DemoSpec spec;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      key: const Key('what_to_try_card'),
      elevation: 6,
      shadowColor: Colors.black26,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(Gap.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(spec.problem, style: theme.textTheme.titleSmall),
            const SizedBox(height: Gap.m),
            CompareRow.listView(spec.withListView),
            const SizedBox(height: Gap.s),
            CompareRow.atlas(spec.withAtlas),
            const SizedBox(height: Gap.m),
            Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  const TextSpan(
                    text: 'Try: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: spec.whatToTry),
                ],
              ),
              style: theme.textTheme.bodySmall,
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
          color: Colors.black.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Corners.m),
          ),
          child: Padding(
            padding: const EdgeInsets.all(Gap.m),
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
