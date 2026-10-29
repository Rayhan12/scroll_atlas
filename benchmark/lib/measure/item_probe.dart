import 'package:flutter/widgets.dart';
import 'package:scroll_atlas/fixtures.dart';

import 'alignment_convention.dart';

/// Measures fixture items against the box that hosts the list, so it works
/// for engines that stack more than one viewport (scrollable_positioned_list).
final class ItemProbe {
  ItemProbe(this.hostKey, {this.convention = AlignmentConvention.leadingEdge});

  final GlobalKey hostKey;

  /// The engine's own meaning of alignment.
  final AlignmentConvention convention;

  RenderBox get _host =>
      hostKey.currentContext!.findRenderObject()! as RenderBox;

  double get viewportExtent => _host.size.height;

  RenderBox? _itemBox(int index) => _boxWithKey(FixtureKeys.item(index));

  RenderBox? _boxWithKey(Key key) =>
      _contextWithKey(key)?.findRenderObject() as RenderBox?;

  BuildContext? _contextWithKey(Key key) {
    BuildContext? found;
    void visit(Element element) {
      if (found != null) return;
      if (element.widget.key == key) {
        found = element;
        return;
      }
      element.visitChildElements(visit);
    }

    hostKey.currentContext?.visitChildElements(visit);
    return found;
  }

  /// Whether the first scroll view in the host rests at its end, where a
  /// target near the end cannot reach its alignment line.
  bool get atScrollEnd {
    ScrollPosition? position;
    void visit(Element element) {
      if (position != null) return;
      if (element is StatefulElement && element.state is ScrollableState) {
        position = (element.state as ScrollableState).position;
        return;
      }
      element.visitChildElements(visit);
    }

    hostKey.currentContext?.visitChildElements(visit);
    final p = position;
    return p != null && p.pixels >= p.maxScrollExtent - 0.5;
  }

  /// True when item [index] is built and laid out.
  bool isBuilt(int index) => _itemBox(index)?.hasSize ?? false;

  /// Leading edge of [index] from the host's top, or null if not built.
  double? leadingEdge(int index) => leadingEdgeOf(FixtureKeys.item(index));

  /// Leading edge of the widget with [key] from the host's top, or null if
  /// it is not built.
  double? leadingEdgeOf(Key key) {
    final box = _boxWithKey(key);
    if (box == null || !box.hasSize) return null;
    return PositionProbe.leadingEdgeInViewport(box, _host);
  }

  /// Pixels between [index]'s leading edge and where [convention] says it
  /// belongs for [alignment], or infinity when the item is not built.
  double alignmentError(int index, double alignment) {
    final box = _itemBox(index);
    if (box == null || !box.hasSize) return double.infinity;
    final expected = convention.expectedLeadingEdge(
      alignment: alignment,
      viewport: viewportExtent,
      itemExtent: box.size.height,
    );
    return (PositionProbe.leadingEdgeInViewport(box, _host) - expected).abs();
  }
}
