import 'package:flutter/foundation.dart';

/// What `AtlasController.jumpTo(target: ...)` should bring into view
///.
///
/// * [AtlasTarget.index]: an item of the controller's only (or unnamed)
///   list, the same as `jumpTo(index: ...)`.
/// * [AtlasTarget.item]: item [index] of the Atlas list registered as
///   [sliverId] in an `AtlasScrollView`.
/// * [AtlasTarget.section] and [AtlasTarget.sliver]: the leading edge of a
///   `SliverAtlasSection` or of any sliver wrapped in an `AtlasAnchor`.
@immutable
sealed class AtlasTarget {
  const AtlasTarget._();

  /// Item [index] of the controller's only (or unnamed) Atlas list.
  const factory AtlasTarget.index(int index) = AtlasIndexTarget;

  /// Item [index] of the Atlas list whose id is [sliverId].
  const factory AtlasTarget.item(String sliverId, int index) = AtlasItemTarget;

  /// The leading edge of the `SliverAtlasSection` whose id is [id]: its
  /// header lands at the alignment line.
  const factory AtlasTarget.section(String id) = AtlasSliverTarget;

  /// The leading edge of the sliver registered as [id], for example a
  /// sliver wrapped in an `AtlasAnchor`.
  const factory AtlasTarget.sliver(String id) = AtlasSliverTarget;

  /// Id of the sliver that holds the target, or null for the controller's
  /// only (or unnamed) list.
  String? get sliverId;

  /// Item index inside that sliver; 0 for the leading edge of a sliver.
  int get index;
}

/// See [AtlasTarget.index].
final class AtlasIndexTarget extends AtlasTarget {
  /// Creates the target.
  const AtlasIndexTarget(this.index) : super._();

  @override
  final int index;

  @override
  String? get sliverId => null;

  @override
  bool operator ==(Object other) =>
      other is AtlasIndexTarget && other.index == index;

  @override
  int get hashCode => index.hashCode;

  @override
  String toString() => 'AtlasTarget.index($index)';
}

/// See [AtlasTarget.item].
final class AtlasItemTarget extends AtlasTarget {
  /// Creates the target.
  const AtlasItemTarget(this.sliverId, this.index) : super._();

  @override
  final String sliverId;

  @override
  final int index;

  @override
  bool operator ==(Object other) =>
      other is AtlasItemTarget &&
      other.sliverId == sliverId &&
      other.index == index;

  @override
  int get hashCode => Object.hash(sliverId, index);

  @override
  String toString() => "AtlasTarget.item('$sliverId', $index)";
}

/// See [AtlasTarget.sliver] and [AtlasTarget.section].
final class AtlasSliverTarget extends AtlasTarget {
  /// Creates the target.
  const AtlasSliverTarget(this.sliverId) : super._();

  @override
  final String sliverId;

  @override
  int get index => 0;

  @override
  bool operator ==(Object other) =>
      other is AtlasSliverTarget && other.sliverId == sliverId;

  @override
  int get hashCode => sliverId.hashCode;

  @override
  String toString() => "AtlasTarget.sliver('$sliverId')";
}
