import 'dart:collection';

import 'package:flutter/widgets.dart';

import '../core/linked_offset_math.dart';

/// Called with the group's new offset in pixels.
typedef LinkedOffsetListener = void Function(double offset);

/// A group of scroll controllers that share one scroll offset: a frozen
/// header row and a table body, a time column and its rows, or carousels
/// that move together. A maintained replacement for linked_scroll_controller.
///
/// ```dart
/// final group = LinkedScrollGroup();
/// final headerRow = group.createController();
/// final body = group.createController();
/// group.addOffsetListener((offset) => debugPrint('x = $offset'));
/// ```
///
/// The member that the user drags, flings or animates drives; every other
/// member follows in the same frame and drops any motion of its own, so two
/// ballistic simulations never fight. A controller created after
/// the group has scrolled starts at the group's offset, and so does a
/// scroll view that attaches later, for example a table row that builds
/// while the body scrolls. Members may scroll vertically or
/// horizontally; one group should only link scroll views along one axis.
///
/// The group does not own its controllers: dispose each controller where
/// you created it, then [dispose] the group.
class LinkedScrollGroup {
  /// Creates a group that starts at [initialOffset].
  LinkedScrollGroup({double initialOffset = 0}) : _offset = initialOffset;

  double _offset;
  final LinkedHashSet<LinkedScrollPosition> _positions =
      LinkedHashSet<LinkedScrollPosition>();
  final List<LinkedOffsetListener> _listeners = <LinkedOffsetListener>[];
  bool _syncing = false;

  /// The shared offset in pixels: where the driving member last moved to.
  double get offset => _offset;

  /// Whether any member is attached to a scroll view.
  bool get hasClients => _positions.isNotEmpty;

  /// Scroll positions of every attached member, in attach order.
  Iterable<ScrollPosition> get positions =>
      UnmodifiableSetView<LinkedScrollPosition>(_positions);

  /// Creates a controller that belongs to this group. Give it to exactly
  /// the scroll views that should move with the others.
  LinkedScrollController createController({String? debugLabel}) =>
      LinkedScrollController._(this, debugLabel: debugLabel);

  /// Calls [listener] every time the shared offset changes.
  void addOffsetListener(LinkedOffsetListener listener) =>
      _listeners.add(listener);

  /// Stops calling [listener].
  void removeOffsetListener(LinkedOffsetListener listener) =>
      _listeners.remove(listener);

  /// Moves every member to [value] without animation.
  void jumpTo(double value) {
    if (_positions.isEmpty) {
      _setOffset(value);
    } else {
      _positions.first.jumpTo(value);
    }
  }

  /// Animates every member to [value]. The first attached member drives
  /// and the rest follow it frame by frame.
  Future<void> animateTo(
    double value, {
    required Duration duration,
    required Curve curve,
  }) {
    if (_positions.isEmpty) {
      _setOffset(value);
      return Future<void>.value();
    }
    return _positions.first.animateTo(value, duration: duration, curve: curve);
  }

  /// Stops calling listeners. Dispose the controllers first.
  void dispose() => _listeners.clear();

  void _attach(LinkedScrollPosition position) => _positions.add(position);

  void _detach(LinkedScrollPosition position) => _positions.remove(position);

  void _moved(LinkedScrollPosition driver) {
    if (_syncing || !driver.hasContentDimensions) return;
    _syncing = true;
    try {
      for (final follower in _positions.toList()) {
        if (identical(follower, driver)) continue;
        if (!follower.hasPixels || !follower.hasContentDimensions) continue;
        follower._follow(
          LinkedOffsetMath.follow(
            pixels: driver.pixels,
            driverMin: driver.minScrollExtent,
            driverMax: driver.maxScrollExtent,
            followerMin: follower.minScrollExtent,
            followerMax: follower.maxScrollExtent,
          ),
        );
      }
    } finally {
      _syncing = false;
    }
    _setOffset(driver.pixels);
  }

  void _setOffset(double value) {
    if (value == _offset) return;
    _offset = value;
    for (final listener in List<LinkedOffsetListener>.of(_listeners)) {
      listener(value);
    }
  }
}

/// A [ScrollController] made by [LinkedScrollGroup.createController].
class LinkedScrollController extends ScrollController {
  LinkedScrollController._(this.group, {super.debugLabel})
      : super(keepScrollOffset: false);

  /// The group this controller belongs to.
  final LinkedScrollGroup group;

  /// Late joiners start where the group is.
  @override
  double get initialScrollOffset => group.offset;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) =>
      LinkedScrollPosition._(
        group,
        physics: physics,
        context: context,
        initialPixels: group.offset,
        oldPosition: oldPosition,
        debugLabel: debugLabel,
      );

  @override
  void attach(ScrollPosition position) {
    super.attach(position);
    if (position is LinkedScrollPosition) group._attach(position);
  }

  @override
  void detach(ScrollPosition position) {
    if (position is LinkedScrollPosition) group._detach(position);
    super.detach(position);
  }
}

/// The scroll position of one member of a [LinkedScrollGroup].
class LinkedScrollPosition extends ScrollPositionWithSingleContext {
  LinkedScrollPosition._(
    this._group, {
    required super.physics,
    required super.context,
    super.initialPixels,
    super.oldPosition,
    super.debugLabel,
  });

  final LinkedScrollGroup _group;

  @override
  double setPixels(double newPixels) {
    final overscroll = super.setPixels(newPixels);
    _group._moved(this);
    return overscroll;
  }

  @override
  void forcePixels(double value) {
    super.forcePixels(value);
    _group._moved(this);
  }

  @override
  bool applyContentDimensions(double minScrollExtent, double maxScrollExtent) {
    // First layout of a member that joined late or attached before the
    // group moved: start exactly where the others are.
    if (!hasContentDimensions && hasPixels) {
      final start = LinkedOffsetMath.settle(
        _group.offset,
        minScrollExtent,
        maxScrollExtent,
      );
      if (start != pixels) correctPixels(start);
    }
    return super.applyContentDimensions(minScrollExtent, maxScrollExtent);
  }

  /// Moves to [value] because another member drives. Drops any motion of
  /// this member's own so it never runs a second simulation.
  void _follow(double value) {
    if (activity is! IdleScrollActivity) goIdle();
    if (value == pixels) return;
    final before = pixels;
    super.forcePixels(value);
    didStartScroll();
    didUpdateScrollPositionBy(pixels - before);
    didEndScroll();
  }

  @override
  void dispose() {
    _group._detach(this);
    super.dispose();
  }
}
