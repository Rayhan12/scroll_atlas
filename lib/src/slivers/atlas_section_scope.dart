import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Scope for the body of a [SliverAtlasSection]. A single
/// [SliverAtlasList] with no [SliverAtlasList.id] inside it receives the
/// section id as its list id automatically.
class AtlasSectionScope extends InheritedWidget {
  /// Creates the scope.
  const AtlasSectionScope({
    required this.sectionId,
    required super.child,
    super.key,
  });

  /// Id of the enclosing section.
  final String sectionId;

  /// The nearest section scope, or null.
  static AtlasSectionScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AtlasSectionScope>();

  @override
  bool updateShouldNotify(AtlasSectionScope oldWidget) =>
      sectionId != oldWidget.sectionId;
}

/// Tracks how many unnamed lists sit in one section body.
class AtlasSectionListRegistry extends StatefulWidget {
  /// Wraps the [child] of a [SliverAtlasSection].
  const AtlasSectionListRegistry({required this.child, super.key});

  /// The section body sliver.
  final Widget child;

  @override
  State<AtlasSectionListRegistry> createState() =>
      AtlasSectionListRegistryState();
}

/// State of [AtlasSectionListRegistry].
class AtlasSectionListRegistryState extends State<AtlasSectionListRegistry> {
  int _unnamedLists = 0;

  /// Reserves the section id for the first unnamed list in this section.
  String? claimAutoListId() {
    if (_unnamedLists != 0) return null;
    _unnamedLists++;
    return AtlasSectionScope.maybeOf(context)!.sectionId;
  }

  /// Releases a slot when an auto-id list unmounts.
  void releaseAutoListId() {
    if (_unnamedLists == 0) return;
    _unnamedLists = math.max(0, _unnamedLists - 1);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Lets [SliverAtlasList] claim an auto id from [AtlasSectionListRegistry].
abstract final class AtlasSectionListAutoId {
  /// Reserves an auto list id when this list has no explicit id.
  static String? claim(BuildContext context) {
    final registry =
        context.findAncestorStateOfType<AtlasSectionListRegistryState>();
    final scope = AtlasSectionScope.maybeOf(context);
    if (registry == null || scope == null) return null;
    return registry.claimAutoListId();
  }

  /// Releases a previously claimed auto list id.
  static void release(BuildContext context) {
    context
        .findAncestorStateOfType<AtlasSectionListRegistryState>()
        ?.releaseAutoListId();
  }
}
