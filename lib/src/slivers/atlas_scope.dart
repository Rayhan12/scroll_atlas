import 'package:flutter/widgets.dart';

import '../list/atlas_controller.dart';
import '../list/atlas_list_layout.dart';

/// Makes [controller] the registry of every Atlas sliver below it, so
/// `SliverAtlasList`, `SliverAtlasSection` and `AtlasAnchor` register by
/// id without being handed the controller.
class AtlasScope extends StatefulWidget {
  /// Creates the scope.
  const AtlasScope({
    required this.controller,
    required this.child,
    this.pinnedInset = 0,
    super.key,
  });

  /// Controller that the slivers below register with.
  final AtlasController controller;

  /// Extra pinned obstruction for [controller.pinnedInset] while this scope
  /// is mounted.
  final double pinnedInset;

  /// The child subtree whose Atlas slivers register with [controller].
  final Widget child;

  /// The controller of the nearest scope, or null.
  static AtlasLayoutRegistry? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_AtlasScopeData>()?.controller;

  @override
  State<AtlasScope> createState() => _AtlasScopeState();
}

class _AtlasScopeState extends State<AtlasScope> {
  @override
  void initState() {
    super.initState();
    widget.controller.pinnedInset = widget.pinnedInset;
  }

  @override
  void didUpdateWidget(AtlasScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pinnedInset != widget.pinnedInset ||
        !identical(oldWidget.controller, widget.controller)) {
      widget.controller.pinnedInset = widget.pinnedInset;
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AtlasScopeData(
      controller: widget.controller,
      pinnedInset: widget.pinnedInset,
      child: widget.child,
    );
  }
}

class _AtlasScopeData extends InheritedWidget {
  const _AtlasScopeData({
    required this.controller,
    required this.pinnedInset,
    required super.child,
  });

  final AtlasController controller;
  final double pinnedInset;

  @override
  bool updateShouldNotify(_AtlasScopeData oldWidget) =>
      !identical(controller, oldWidget.controller) ||
      pinnedInset != oldWidget.pinnedInset;
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
    this.pinnedInset = 0,
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

  /// Added to [AtlasController.pinnedInset] while this view is mounted.
  final double pinnedInset;

  @override
  Widget build(BuildContext context) {
    return AtlasScope(
      controller: controller,
      pinnedInset: pinnedInset,
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
}
