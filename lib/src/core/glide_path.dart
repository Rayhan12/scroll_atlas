import 'dart:math' as math;

/// How much distance is left at each point of an animated scroll.
///
/// An animation feeds its curve into [remaining] as `u = 1 - curve(t)`, so
/// `u` goes from 1 at the start to 0 at the end. The path is exponential:
/// far targets are crossed quickly, and the last [scale] pixels are covered
/// slowly. That keeps the final frames tiny (no visible snap) for any
/// distance, from one item to millions of pixels.
final class GlidePath {
  /// Creates a path that covers [distance] pixels. [scale] sets where the
  /// path changes from fast to slow; smaller values give a softer landing.
  GlidePath({required this.distance, required this.scale})
      : assert(distance >= 0, 'distance must not be negative'),
        assert(scale > 0, 'scale must be positive'),
        _base = 1 + distance / scale;

  /// Default [scale] for a viewport of [viewportExtent] pixels.
  static double scaleFor(double viewportExtent) =>
      math.max(1, viewportExtent / 16);

  /// Total distance of the path.
  final double distance;

  /// Width of the slow landing zone, in pixels.
  final double scale;

  final double _base;

  /// Distance still to travel at progress [u], where 1 is the start and 0
  /// the end. Values outside 0 to 1 are clamped.
  double remaining(double u) {
    final clamped = u.clamp(0.0, 1.0);
    if (clamped == 1) return distance;
    return scale * (math.pow(_base, clamped) - 1);
  }

  /// Fraction of the distance left at [u] compared with [previousU], so an
  /// animation can shrink whatever gap is left by the same ratio when the
  /// target moves under it (re-aiming). 0 when [previousU] has no distance.
  double shrinkRatio({required double previousU, required double u}) {
    final before = remaining(previousU);
    if (before <= 0) return 0;
    return remaining(u) / before;
  }
}
