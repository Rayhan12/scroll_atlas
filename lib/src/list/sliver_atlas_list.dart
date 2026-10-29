import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/atlas_visibility.dart';
import '../core/extent_cache.dart';
import '../core/extent_estimator.dart';
import '../core/scroll_target.dart';
import '../slivers/atlas_scope.dart';
import '../slivers/atlas_section_scope.dart';
import 'atlas_list_layout.dart';
import 'atlas_options.dart';
import 'render_sliver_atlas_list.dart';

/// A sliver list that can jump to any index in one frame, estimates the
/// extent of items it has not built, and keeps the item you are reading
/// still when items above it change.
///
/// Use it in an `AtlasScrollView` (give it an [id] when there are several
/// lists), in a [CustomScrollView] whose controller is
/// `AtlasController.scrollController` (pass [controller]), or use
/// `AtlasListView`, which does the wiring.
///
/// ```dart
/// AtlasScrollView(
///   controller: atlas,
///   slivers: [
///     const SliverAppBar(pinned: true, title: Text('Inbox')),
///     SliverAtlasList.builder(
///       id: 'mail',
///       itemCount: mails.length,
///       itemBuilder: (context, index) => MailTile(mails[index]),
///     ),
///   ],
/// );
/// atlas.jumpTo(target: const AtlasTarget.item('mail', 420));
/// ```
class SliverAtlasList extends StatefulWidget {
  /// Creates the sliver from a [delegate].
  const SliverAtlasList({
    required this.delegate,
    this.id,
    this.controller,
    this.anchorMode = AtlasAnchorMode.firstVisible,
    this.initialIndex = 0,
    this.initialAlignment = 0,
    this.estimator,
    this.itemExtent,
    super.key,
  })  : assert(itemExtent == null || itemExtent > 0,
            'itemExtent must be positive'),
        assert(
          itemExtent == null || estimator == null,
          'Pass itemExtent or estimator, not both.',
        );

  /// Creates the sliver with a builder, like `SliverList.builder`.
  SliverAtlasList.builder({
    required int itemCount,
    required NullableIndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    this.id,
    this.controller,
    this.anchorMode = AtlasAnchorMode.firstVisible,
    this.initialIndex = 0,
    this.initialAlignment = 0,
    this.estimator,
    this.itemExtent,
    super.key,
  })  : assert(itemExtent == null || itemExtent > 0,
            'itemExtent must be positive'),
        assert(
          itemExtent == null || estimator == null,
          'Pass itemExtent or estimator, not both.',
        ),
        delegate = SliverChildBuilderDelegate(
          itemExtent == null
              ? itemBuilder
              : (context, index) {
                  final child = itemBuilder(context, index);
                  if (child == null) return null;
                  return ConstrainedBox(
                    constraints: BoxConstraints.tightFor(height: itemExtent),
                    child: child,
                  );
                },
          childCount: itemCount,
          findChildIndexCallback: findChildIndexCallback,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
        );

  /// Builds the items. Give it a `findChildIndexCallback` and keyed items
  /// so inserted items keep their identity.
  final SliverChildDelegate delegate;

  /// Id for `AtlasTarget.item(id, index)`. Unique within one
  /// scroll view; null for the only list of a controller.
  final String? id;

  /// Controller that jumps and animates this list. Defaults to the
  /// controller of the enclosing `AtlasScrollView` or `AtlasScope`.
  final AtlasLayoutRegistry? controller;

  /// What stays still when items above the viewport change.
  final AtlasAnchorMode anchorMode;

  /// Item shown at [initialAlignment] in the first frame.
  final int initialIndex;

  /// Alignment of [initialIndex]: 0 is the leading edge, 0.5 the middle.
  final double initialAlignment;

  /// Estimates unmeasured items. Defaults to a running average.
  final ExtentEstimator? estimator;

  /// When set, every item is laid out with this main axis extent and the
  /// estimator is exact. Do not combine with [estimator].
  final double? itemExtent;

  @override
  State<SliverAtlasList> createState() => _SliverAtlasListState();
}

class _SliverAtlasListState extends State<SliverAtlasList> {
  late ExtentCache _cache;
  String? _autoId;
  String? _effectiveId;
  AtlasSectionListRegistryState? _sectionRegistry;
  ValueListenable<bool>? _tickerMode;
  bool _layoutUpdatesEnabled = true;

  @override
  void initState() {
    super.initState();
    _cache = _cacheFor(widget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sectionRegistry =
        context.findAncestorStateOfType<AtlasSectionListRegistryState>();
    _syncAutoId();
    final next = TickerMode.getNotifier(context);
    if (!identical(next, _tickerMode)) {
      _tickerMode?.removeListener(_onTickerModeChanged);
      _tickerMode = next;
      _tickerMode!.addListener(_onTickerModeChanged);
    }
    _onTickerModeChanged();
  }

  void _onTickerModeChanged() {
    final enabled = AtlasVisibility.layoutUpdatesEnabled(context);
    if (enabled == _layoutUpdatesEnabled) return;
    setState(() => _layoutUpdatesEnabled = enabled);
  }

  @override
  void didUpdateWidget(SliverAtlasList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.estimator != oldWidget.estimator ||
        widget.itemExtent != oldWidget.itemExtent) {
      _cache = _cacheFor(widget);
    }
    if (widget.id != oldWidget.id) {
      _syncAutoId();
    }
  }

  @override
  void dispose() {
    _tickerMode?.removeListener(_onTickerModeChanged);
    if (_autoId != null) {
      _sectionRegistry?.releaseAutoListId();
    }
    super.dispose();
  }

  void _syncAutoId() {
    if (widget.id != null) {
      if (_autoId != null) {
        _sectionRegistry?.releaseAutoListId();
        _autoId = null;
      }
      _effectiveId = widget.id;
      return;
    }
    if (_autoId == null && _sectionRegistry != null) {
      _autoId = _sectionRegistry!.claimAutoListId();
    }
    _effectiveId = widget.id ?? _autoId;
  }

  ExtentCache _cacheFor(SliverAtlasList widget) => ExtentCache(
        estimator: widget.itemExtent != null
            ? FixedExtentEstimator(widget.itemExtent!)
            : widget.estimator,
      );

  @override
  Widget build(BuildContext context) {
    _syncAutoId();
    var delegate = widget.delegate;
    final extent = widget.itemExtent;
    if (extent != null && delegate is SliverChildBuilderDelegate) {
      final inner = delegate;
      delegate = SliverChildBuilderDelegate(
        (context, index) {
          final child = inner.builder(context, index);
          if (child == null) return null;
          return ConstrainedBox(
            constraints: BoxConstraints.tightFor(height: extent),
            child: child,
          );
        },
        childCount: delegate.childCount,
        findChildIndexCallback: delegate.findChildIndexCallback,
        addAutomaticKeepAlives: delegate.addAutomaticKeepAlives,
        addRepaintBoundaries: delegate.addRepaintBoundaries,
        addSemanticIndexes: delegate.addSemanticIndexes,
      );
    }
    return _SliverAtlasListAdaptor(
      delegate: delegate,
      cache: _cache,
      id: _effectiveId,
      registry: widget.controller ?? AtlasScope.maybeOf(context),
      anchorMode: widget.anchorMode,
      layoutUpdatesEnabled: _layoutUpdatesEnabled,
      initialTarget: widget.initialIndex == 0 && widget.initialAlignment == 0
          ? null
          : ScrollTarget(widget.initialIndex,
              alignment: widget.initialAlignment),
    );
  }
}

class _SliverAtlasListAdaptor extends SliverMultiBoxAdaptorWidget {
  const _SliverAtlasListAdaptor({
    required super.delegate,
    required this.cache,
    required this.id,
    required this.registry,
    required this.anchorMode,
    required this.layoutUpdatesEnabled,
    required this.initialTarget,
  });

  final ExtentCache cache;
  final String? id;
  final AtlasLayoutRegistry? registry;
  final AtlasAnchorMode anchorMode;
  final bool layoutUpdatesEnabled;
  final ScrollTarget? initialTarget;

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  RenderSliverAtlasList createRenderObject(BuildContext context) =>
      RenderSliverAtlasList(
        childManager: context as SliverMultiBoxAdaptorElement,
        cache: cache,
        id: id,
        registry: registry,
        anchorMode: anchorMode,
        layoutUpdatesEnabled: layoutUpdatesEnabled,
        initialTarget: initialTarget,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverAtlasList renderObject,
  ) {
    renderObject
      ..cache = cache
      ..id = id
      ..registry = registry
      ..anchorMode = anchorMode
      ..layoutUpdatesEnabled = layoutUpdatesEnabled;
  }
}
