import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../core/sticky_header_math.dart';
import '../list/atlas_list_layout.dart';
import 'atlas_placement.dart';
import 'atlas_scope.dart';
import 'atlas_section_scope.dart';
import 'atlas_target_sliver.dart';

/// Builds a section header. [stuckAmount] goes from 0 (the header scrolls
/// with its section) to 1 (stuck at the top), for shadows and colors.
typedef AtlasHeaderBuilder = Widget Function(
  BuildContext context,
  double stuckAmount,
);

/// Receives the header stuck amount during section layout.
abstract interface class AtlasSectionStuckClient {
  /// Called from layout when [stuckAmount] changes by more than 0.001.
  void updateStuckAmount(double stuckAmount);
}

/// A section whose [header] sticks below whatever is pinned above it while
/// its [sliver] scrolls, and is pushed off by the end of the section, so
/// the next section's header never overlaps it.
///
/// The section is a target for `AtlasTarget.section(id)`, and targets
/// inside [sliver] are aligned below the stuck header.
///
/// ```dart
/// SliverAtlasSection(
///   id: 'K',
///   header: (context, stuckAmount) => LetterHeader('K', elevated: stuckAmount > 0),
///   sliver: SliverAtlasList.builder(
///     id: 'people-K',
///     itemCount: people.length,
///     itemBuilder: (context, index) => PersonTile(people[index]),
///   ),
/// );
/// atlas.jumpTo(target: const AtlasTarget.section('K'));
/// ```
class SliverAtlasSection extends StatefulWidget {
  /// Creates the section.
  const SliverAtlasSection({
    required this.id,
    required this.header,
    required this.sliver,
    this.controller,
    super.key,
  });

  /// Id for `AtlasTarget.section(id)`, unique within one scroll view.
  final String id;

  /// Builds the sticky header from its stuck amount.
  final AtlasHeaderBuilder header;

  /// The section's content.
  final Widget sliver;

  /// Controller to register with. Defaults to the enclosing `AtlasScope`.
  final AtlasLayoutRegistry? controller;

  @override
  State<SliverAtlasSection> createState() => _SliverAtlasSectionState();
}

class _SliverAtlasSectionState extends State<SliverAtlasSection>
    implements AtlasSectionStuckClient {
  double _stuck = 0;

  @override
  void updateStuckAmount(double value) {
    if ((value - _stuck).abs() < 0.001) return;
    _stuck = value;
  }

  @override
  Widget build(BuildContext context) => AtlasSectionScope(
        sectionId: widget.id,
        child: AtlasSectionListRegistry(
          child: _AtlasSectionLayout(
            id: widget.id,
            registry: widget.controller ?? AtlasScope.maybeOf(context),
            stuckClient: this,
            sectionStateElement: context as Element,
            header: widget.header(context, _stuck),
            sliver: widget.sliver,
          ),
        ),
      );
}

/// Children of a [RenderSliverAtlasSection].
enum AtlasSectionSlot {
  /// The sticky header box.
  header,

  /// The content sliver.
  body,
}

class _AtlasSectionLayout extends SlottedMultiChildRenderObjectWidget<
    AtlasSectionSlot, RenderObject> {
  const _AtlasSectionLayout({
    required this.id,
    required this.registry,
    required this.stuckClient,
    required this.sectionStateElement,
    required this.header,
    required this.sliver,
  });

  final String id;
  final AtlasLayoutRegistry? registry;
  final AtlasSectionStuckClient stuckClient;
  final Element sectionStateElement;
  final Widget header;
  final Widget sliver;

  @override
  Iterable<AtlasSectionSlot> get slots => AtlasSectionSlot.values;

  @override
  Widget childForSlot(AtlasSectionSlot slot) => switch (slot) {
        AtlasSectionSlot.header => header,
        AtlasSectionSlot.body => sliver,
      };

  @override
  RenderSliverAtlasSection createRenderObject(BuildContext context) =>
      RenderSliverAtlasSection(
        id: id,
        registry: registry,
        stuckClient: stuckClient,
        sectionStateElement: sectionStateElement,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSliverAtlasSection renderObject,
  ) {
    renderObject
      ..id = id
      ..registry = registry
      ..stuckClient = stuckClient
      ..sectionStateElement = sectionStateElement;
  }
}

/// Render object of [SliverAtlasSection]: a box header that sticks and a
/// sliver body. A custom sliver rather than `SliverMainAxisGroup`, because
/// the group drops its children's scroll offset corrections, which Atlas
/// lists need to land jumps exactly.
class RenderSliverAtlasSection extends RenderSliver
    with
        SlottedContainerRenderObjectMixin<AtlasSectionSlot, RenderObject>,
        RenderSliverHelpers,
        AtlasPlacement,
        AtlasTargetSliver
    implements AtlasStickyParent {
  /// Creates the render object.
  RenderSliverAtlasSection({
    required String id,
    required this.stuckClient,
    required Element sectionStateElement,
    AtlasLayoutRegistry? registry,
  }) : _sectionStateElement = sectionStateElement {
    this.id = id;
    this.registry = registry;
  }

  /// Receives the header's stuck amount during layout.
  AtlasSectionStuckClient stuckClient;

  Element _sectionStateElement;
  set sectionStateElement(Element value) => _sectionStateElement = value;

  RenderBox? get _header => childForSlot(AtlasSectionSlot.header) as RenderBox?;
  RenderSliver? get _body =>
      childForSlot(AtlasSectionSlot.body) as RenderSliver?;

  double _headerExtent = 0;
  double _headerPosition = 0;
  double _bodyPosition = 0;

  /// Stuck amount from the latest layout pass, for the header builder.
  double layoutStuck = 0;

  @override
  double stickyExtentAbove(RenderObject child) =>
      identical(child, _body) ? _headerExtent : 0;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) {
      child.parentData = SliverPhysicalParentData();
    }
  }

  void _syncStuckDuringLayout({
    required SliverConstraints c,
    required double headerExtent,
    required double sectionExtent,
  }) {
    final headerPosition = StickyHeaderMath.headerPaintOffset(
      scrollOffset: c.scrollOffset,
      overlap: c.overlap,
      headerExtent: headerExtent,
      sectionExtent: sectionExtent,
    );
    final stuck = StickyHeaderMath.stuckAmount(
      headerPaintOffset: headerPosition,
      scrollOffset: c.scrollOffset,
      headerExtent: headerExtent,
    );
    if ((layoutStuck - stuck).abs() < 0.001) return;
    layoutStuck = stuck;
    invokeLayoutCallback<SliverConstraints>((_) {
      _sectionStateElement.owner!.buildScope(_sectionStateElement, () {
        stuckClient.updateStuckAmount(stuck);
        _sectionStateElement.markNeedsBuild();
      });
    });
  }

  @override
  void performLayout() {
    beginPlacementLayout();
    final c = constraints;
    final header = _header;
    final body = _body;
    var headerExtent = _headerExtent;
    if (header != null) {
      header.layout(c.asBoxConstraints(), parentUsesSize: true);
      headerExtent =
          c.axis == Axis.vertical ? header.size.height : header.size.width;
    }
    _headerExtent = headerExtent;
    final bodyPaintStart = calculatePaintOffset(c, from: 0, to: headerExtent);
    final bodyCacheStart = calculateCacheOffset(c, from: 0, to: headerExtent);
    var bodyScrollExtent = 0.0;
    var bodyMaxPaintExtent = 0.0;
    var bodyOverflows = false;
    if (body != null) {
      body.layout(
        c.copyWith(
          scrollOffset: math.max(0, c.scrollOffset - headerExtent),
          cacheOrigin: math.min(0, c.cacheOrigin + headerExtent),
          overlap: StickyHeaderMath.bodyOverlap(
            scrollOffset: c.scrollOffset,
            overlap: c.overlap,
            headerExtent: headerExtent,
            bodyPaintOffset: bodyPaintStart,
          ),
          remainingPaintExtent: c.remainingPaintExtent - bodyPaintStart,
          remainingCacheExtent: c.remainingCacheExtent - bodyCacheStart,
          precedingScrollExtent: c.precedingScrollExtent + headerExtent,
        ),
        parentUsesSize: true,
      );
      final bodyGeometry = body.geometry!;
      final correction = bodyGeometry.scrollOffsetCorrection;
      if (correction != null) {
        geometry = SliverGeometry(scrollOffsetCorrection: correction);
        return;
      }
      bodyScrollExtent = bodyGeometry.scrollExtent;
      bodyMaxPaintExtent = bodyGeometry.maxPaintExtent;
      bodyOverflows = bodyGeometry.hasVisualOverflow;
    }
    _bodyPosition = bodyPaintStart;
    final total = headerExtent + bodyScrollExtent;
    final paintExtent = calculatePaintOffset(c, from: 0, to: total);
    _headerPosition = StickyHeaderMath.headerPaintOffset(
      scrollOffset: c.scrollOffset,
      overlap: c.overlap,
      headerExtent: headerExtent,
      sectionExtent: total,
    );
    geometry = SliverGeometry(
      scrollExtent: total,
      paintExtent: paintExtent,
      cacheExtent: calculateCacheOffset(c, from: 0, to: total),
      maxPaintExtent: headerExtent + bodyMaxPaintExtent,
      hasVisualOverflow: bodyOverflows || c.scrollOffset > 0,
    );
    if (header != null) {
      _syncStuckDuringLayout(
        c: c,
        headerExtent: headerExtent,
        sectionExtent: total,
      );
      header.layout(c.asBoxConstraints(), parentUsesSize: true);
      final measured =
          c.axis == Axis.vertical ? header.size.height : header.size.width;
      if ((measured - headerExtent).abs() > 0.001) {
        _headerExtent = measured;
      }
    }
    if (placePendingTarget()) return;
  }

  bool get _headerVisible =>
      _header != null &&
      _headerPosition + _headerExtent > 0 &&
      _headerPosition < geometry!.paintExtent;

  Offset _physicalOffset(double position, double extent) {
    final paintExtent = geometry!.paintExtent;
    return switch (applyGrowthDirectionToAxisDirection(
        constraints.axisDirection, constraints.growthDirection)) {
      AxisDirection.down => Offset(0, position),
      AxisDirection.up => Offset(0, paintExtent - position - extent),
      AxisDirection.right => Offset(position, 0),
      AxisDirection.left => Offset(paintExtent - position - extent, 0),
    };
  }

  Offset _offsetOf(RenderObject child) => identical(child, _header)
      ? _physicalOffset(_headerPosition, _headerExtent)
      : _physicalOffset(
          _bodyPosition, (child as RenderSliver).geometry!.paintExtent);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!geometry!.visible) return;
    final body = _body;
    if (body != null && body.geometry!.visible) {
      context.paintChild(body, offset + _offsetOf(body));
    }
    if (_headerVisible) {
      context.paintChild(_header!, offset + _offsetOf(_header!));
    }
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    final offset = _offsetOf(child);
    transform.translate(offset.dx, offset.dy);
  }

  @override
  double childMainAxisPosition(RenderObject child) =>
      identical(child, _header) ? _headerPosition : _bodyPosition;

  @override
  double childCrossAxisPosition(RenderObject child) => 0;

  @override
  double? childScrollOffset(RenderObject child) =>
      identical(child, _header) ? 0 : _headerExtent;

  @override
  bool hitTestChildren(
    SliverHitTestResult result, {
    required double mainAxisPosition,
    required double crossAxisPosition,
  }) {
    final header = _header;
    if (_headerVisible &&
        mainAxisPosition >= _headerPosition &&
        mainAxisPosition < _headerPosition + _headerExtent &&
        hitTestBoxChild(
          BoxHitTestResult.wrap(result),
          header!,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition,
        )) {
      return true;
    }
    final body = _body;
    if (body == null || !body.geometry!.visible) return false;
    return result.addWithAxisOffset(
      paintOffset: _offsetOf(body),
      mainAxisOffset: _bodyPosition,
      crossAxisOffset: 0,
      mainAxisPosition: mainAxisPosition,
      crossAxisPosition: crossAxisPosition,
      hitTest: body.hitTest,
    );
  }
}
