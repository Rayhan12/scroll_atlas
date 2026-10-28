import 'package:scroll_atlas/scroll_atlas.dart';

/// What "alignment" means to an engine. The three packages disagree, so the
/// benchmark checks each against its own documented meaning instead of
/// counting a different convention as an error.
enum AlignmentConvention {
  /// Leading edge at `alignment * viewport` (scroll_atlas and
  /// scrollable_positioned_list).
  leadingEdge,

  /// Leading edge at `alignment * (viewport - itemExtent)`, like
  /// `RenderAbstractViewport.getOffsetToReveal` (super_sliver_list).
  reveal,

  /// The point at `alignment * itemExtent` inside the item sits at the
  /// viewport's leading edge (scrollview_observer).
  itemFraction;

  /// Expected leading edge of an item of [itemExtent] in [viewport].
  double expectedLeadingEdge({
    required double alignment,
    required double viewport,
    required double itemExtent,
  }) => switch (this) {
    leadingEdge => AlignmentMath.leadingEdgeInViewport(
      alignment: alignment,
      viewportExtent: viewport,
    ),
    reveal => alignment * (viewport - itemExtent),
    itemFraction => -alignment * itemExtent,
  };

  /// The convention [engine] declares, or [leadingEdge].
  static AlignmentConvention of(ListEngine engine) => switch (engine) {
    DeclaresAlignmentConvention(:final alignmentConvention) =>
      alignmentConvention,
    _ => leadingEdge,
  };
}

/// Implemented by benchmark adapters whose package uses another convention.
abstract interface class DeclaresAlignmentConvention {
  AlignmentConvention get alignmentConvention;
}
