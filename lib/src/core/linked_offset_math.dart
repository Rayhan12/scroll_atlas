/// Pure math for followers in a linked scroll group.
abstract final class LinkedOffsetMath {
  /// Where a follower with the scroll range [followerMin] to [followerMax]
  /// goes when the member that drives sits at [pixels] in its own range
  /// [driverMin] to [driverMax].
  ///
  /// Inside the driver's range this is [pixels] clamped to the follower's
  /// range, so a shorter member stops at its end instead of showing blank
  /// space. Overscroll past the driver's edge is copied past the follower's
  /// same edge, so a bounce looks the same on every member.
  static double follow({
    required double pixels,
    required double driverMin,
    required double driverMax,
    required double followerMin,
    required double followerMax,
  }) {
    final inRange = pixels.clamp(driverMin, driverMax);
    final overscroll = pixels - inRange;
    return inRange.clamp(followerMin, followerMax) + overscroll;
  }

  /// [offset] clamped to a member's range, for a member's first layout.
  static double settle(double offset, double min, double max) =>
      offset.clamp(min, max);
}
