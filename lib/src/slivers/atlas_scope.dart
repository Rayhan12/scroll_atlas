import 'package:flutter/widgets.dart';

import '../list/atlas_controller.dart';
import '../list/atlas_list_layout.dart';

/// Makes [controller] the registry of every Atlas sliver below it, so
/// `SliverAtlasList`, `SliverAtlasSection` and `AtlasAnchor` register by
/// id without being handed the controller.
class AtlasScope extends InheritedWidget {
  /// Creates the scope.
  const AtlasScope({
    required this.controller,
    required super.child,
    super.key,
  });

  /// Controller that the slivers below register with.
  final AtlasController controller;

  /// The controller of the nearest scope, or null.
  static AtlasLayoutRegistry? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AtlasScope>()?.controller;

  @override
  bool updateShouldNotify(AtlasScope oldWidget) =>
      !identical(controller, oldWidget.controller);
}

/// A [CustomScrollView] whose Atlas slivers register with [controller],
/// so `controller.jumpTo(target: ...)` reaches any of them by id.
///
/// ```dart
/// AtlasScrollView(
///   controller: atlas,
///   slivers: [
///     const SliverAppBar(pinned: true, title: Text('Contacts')),
///     for (final s in sections)
///       SliverAtlasSection(
///         id: s.letter,
///         header: (context, stuck) => LetterHeader(s.letter, stuck: stuck),
///         sliver: SliverAtlasList.builder(
///           id: 'people-${s.letter}',
///           itemCount: s.people.length,
///           itemBuilder: (context, i) => PersonTile(s.people[i]),
///         ),
///       ),
///   ],
/// );
/// atlas.jumpTo(target: const AtlasTarget.item('people-K', 3));
/// ```
class AtlasScrollView extends StatelessWidget {
  /// Creates the scroll view.
  const AtlasScrollView({
    required this.controller,
    required this.slivers,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.physics,
    this.cacheExtent,
    super.key,
  });

  /// Jumps and animates to targets in [slivers].
  final AtlasController controller;

  /// The slivers. Atlas slivers among them register by id.
  final List<Widget> slivers;

  /// Scroll axis.
  final Axis scrollDirection;

  /// Whether the scroll view starts at the bottom (or right).
  final bool reverse;

  /// Scroll physics.
  final ScrollPhysics? physics;

  /// Extent built before and after the viewport.
  final double? cacheExtent;

  @override
  Widget build(BuildContext context) => AtlasScope(
        controller: controller,
        child: CustomScrollView(
          controller: controller.scrollController,
          scrollDirection: scrollDirection,
          reverse: reverse,
          physics: physics,
          cacheExtent: cacheExtent,
          slivers: slivers,
        ),
      );
}
