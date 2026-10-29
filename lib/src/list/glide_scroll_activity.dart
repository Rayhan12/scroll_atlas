import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/glide_path.dart';

/// Animates a scroll position toward a target that may move while the
/// animation runs.
///
/// Each frame shrinks the gap between the position and the latest target by
/// the ratio that [GlidePath] prescribes. When the target is refined from
/// an estimate to an exact offset, the remaining gap absorbs the change, so
/// the list never snaps at the end. The last frame lands exactly on the
/// target.
class GlideScrollActivity extends ScrollActivity {
  /// Starts the animation on [delegate]. [target] and [pixels] (the
  /// current position) are read every frame.
  GlideScrollActivity(
    super.delegate, {
    required ValueGetter<double> target,
    required ValueGetter<double> pixels,
    required GlidePath path,
    required Duration duration,
    required Curve curve,
    required TickerProvider vsync,
  })  : _target = target,
        _pixels = pixels,
        _path = path,
        _curve = curve {
    _controller = AnimationController(duration: duration, vsync: vsync)
      ..addListener(_tick);
    _controller.forward().whenComplete(_end);
  }

  final ValueGetter<double> _target;
  final ValueGetter<double> _pixels;
  final GlidePath _path;
  final Curve _curve;
  late final AnimationController _controller;
  final Completer<bool> _done = Completer<bool>();
  double _previousU = 1;
  bool _finished = false;

  /// Completes with true when the animation reached its target, or false
  /// when something else (a drag, a jump) took over first.
  Future<bool> get done => _done.future;

  void _tick() {
    final u = 1 - _curve.transform(_controller.value);
    final target = _target();
    final ratio = _path.shrinkRatio(previousU: _previousU, u: u);
    _previousU = u;
    final pixels = target - (target - _pixels()) * ratio;
    delegate.setPixels(u <= 0 ? target : pixels);
  }

  void _end() {
    _finished = true;
    delegate.goIdle();
  }

  @override
  void dispatchOverscrollNotification(
    ScrollMetrics metrics,
    BuildContext context,
    double overscroll,
  ) {
    OverscrollNotification(
      metrics: metrics,
      context: context,
      overscroll: overscroll,
      velocity: velocity,
    ).dispatch(context);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  double get velocity => 0;

  @override
  void dispose() {
    _done.complete(_finished);
    _controller.dispose();
    super.dispose();
  }

  @override
  String toString() =>
      '${describeIdentity(this)}(${_controller.value.toStringAsFixed(3)})';
}
