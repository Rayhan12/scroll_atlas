import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:scroll_atlas/scroll_atlas.dart';
import 'package:scrollview_observer/scrollview_observer.dart';

import '../measure/alignment_convention.dart';

/// scrollview_observer 1.27.3 driving a plain ListView with default
/// settings (no fixed height hint, default cacheExtent).
final class ObserverEngine
    implements IndexedScrollEngine, DeclaresAlignmentConvention {
  @override
  AlignmentConvention get alignmentConvention =>
      AlignmentConvention.itemFraction;

  factory ObserverEngine() => ObserverEngine._(ScrollController());

  ObserverEngine._(this._scroll)
    : _observer = ListObserverController(controller: _scroll);

  final ScrollController _scroll;
  final ListObserverController _observer;

  @override
  String get id => 'scrollview_observer';

  @override
  Widget buildList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
  }) => ListViewObserver(
    controller: _observer,
    child: ListView.builder(
      controller: _scroll,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      findChildIndexCallback: findChildIndexCallback,
    ),
  );

  @override
  void jumpToIndex(int index, {double alignment = 0}) =>
      unawaited(_observer.jumpTo(index: index, alignment: alignment));

  @override
  Future<void> animateToIndex(
    int index, {
    required Duration duration,
    Curve curve = Curves.easeInOut,
    double alignment = 0,
  }) => _observer.animateTo(
    index: index,
    duration: duration,
    curve: curve,
    alignment: alignment,
  );

  @override
  void dispose() => _scroll.dispose();
}
