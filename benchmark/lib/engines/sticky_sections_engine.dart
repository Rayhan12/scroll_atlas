import 'package:flutter/widgets.dart';

/// Builds one item of section [section] at [index].
typedef SectionItemBuilder =
    Widget Function(BuildContext context, int section, int index);

/// Capability for B4: a scroll view with a pinned bar and sticky section
/// headers whose items can be jump targets. Engines without a sticky
/// section API do not implement it and B4 skips them (Liskov).
abstract interface class StickySectionsEngine {
  /// A scroll view with a pinned bar of [barExtent] at the top, then one
  /// section per entry of [itemCounts], each with a sticky header of
  /// [headerExtent].
  Widget buildSections({
    required double barExtent,
    required double headerExtent,
    required List<int> itemCounts,
    required SectionItemBuilder itemBuilder,
  });

  /// Jumps so item [index] of [section] sits at [alignment] of the space
  /// left below the pinned bar and the section's stuck header.
  void jumpToSectionItem(int section, int index, {double alignment = 0});
}
