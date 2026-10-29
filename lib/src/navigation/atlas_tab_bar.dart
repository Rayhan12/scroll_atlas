import 'package:flutter/material.dart';

import '../core/atlas_target.dart';
import '../list/atlas_controller.dart';
import 'atlas_scroll_spy.dart';

/// A [TabBar] that follows an `AtlasScrollView`'s sections and jumps to
/// them.
///
/// Tapping a tab animates [controller] to the section with the matching
/// id in [sectionIds]. While that animation runs the indicator does not
/// follow the sections it passes, so it moves exactly once. Dragging the
/// view stops the animation, and the tab bar follows the scroll again.
/// Scrolling by hand moves the indicator to the active section of an
/// [AtlasScrollSpy], and a scrollable tab strip scrolls to show it.
///
/// Use it as a pinned `SliverAppBar`'s `bottom`. Targets land below
/// everything pinned, including this tab bar.
class AtlasTabBar extends StatefulWidget implements PreferredSizeWidget {
  /// Creates a tab bar with one tab per section.
  const AtlasTabBar({
    required this.controller,
    required this.sectionIds,
    required this.tabs,
    this.isScrollable = true,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeInOut,
    this.onSectionChanged,
    super.key,
  }) : assert(
          sectionIds.length == tabs.length,
          'sectionIds and tabs must have the same length',
        );

  /// Controller of the scroll view that holds the sections.
  final AtlasController controller;

  /// Ids of the sections, in scroll order, one per tab.
  final List<String> sectionIds;

  /// The tabs, usually [Tab] widgets.
  final List<Widget> tabs;

  /// Whether the tab strip scrolls horizontally (see [TabBar.isScrollable]).
  final bool isScrollable;

  /// Duration of the animation to a tapped section.
  final Duration duration;

  /// Curve of the animation to a tapped section.
  final Curve curve;

  /// Called with the new index whenever the selected tab changes.
  final ValueChanged<int>? onSectionChanged;

  @override
  Size get preferredSize =>
      TabBar(tabs: tabs, isScrollable: isScrollable).preferredSize;

  @override
  State<AtlasTabBar> createState() => _AtlasTabBarState();
}

class _AtlasTabBarState extends State<AtlasTabBar>
    with TickerProviderStateMixin {
  late TabController _tabs;
  late AtlasScrollSpy _spy;
  int _reported = 0;

  @override
  void initState() {
    super.initState();
    _create();
  }

  void _create() {
    _tabs = TabController(length: widget.tabs.length, vsync: this)
      ..addListener(_report);
    _reported = 0;
    _spy = AtlasScrollSpy(
      controller: widget.controller,
      sectionIds: widget.sectionIds,
    )..addListener(_follow);
  }

  void _destroy() {
    _spy
      ..removeListener(_follow)
      ..dispose();
    _tabs.dispose();
  }

  @override
  void didUpdateWidget(AtlasTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller ||
        !_sameIds(oldWidget.sectionIds, widget.sectionIds)) {
      _destroy();
      _create();
    }
  }

  static bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _follow() => _select(_spy.value);

  void _select(int index) {
    if (_tabs.index != index) _tabs.animateTo(index);
  }

  void _report() {
    if (_tabs.index == _reported) return;
    _reported = _tabs.index;
    widget.onSectionChanged?.call(_reported);
  }

  // TabBar has already selected the tapped tab.
  Future<void> _onTap(int index) async {
    final spy = _spy..lock();
    final scroll = widget.controller.scrollController;
    try {
      await widget.controller.animateTo(
        target: AtlasTarget.section(widget.sectionIds[index]),
        duration: widget.duration,
        curve: widget.curve,
      );
    } finally {
      // Still moving means the user took over; otherwise the tapped section
      // has landed, even if it is too short to reach the pinned area.
      final landed =
          scroll.hasClients && !scroll.position.isScrollingNotifier.value;
      if (landed) spy.hold(index);
      spy.unlock();
      if (mounted && identical(spy, _spy)) _select(spy.value);
    }
  }

  @override
  void dispose() {
    _destroy();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TabBar(
        controller: _tabs,
        tabs: widget.tabs,
        isScrollable: widget.isScrollable,
        onTap: _onTap,
      );
}
