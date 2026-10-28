import 'package:flutter/widgets.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

/// Plain ListView.builder: the frame time baseline. It implements only
/// [ListEngine] because it cannot jump to an index, so jump scenarios skip it
/// instead of faking a result.
final class PlainListViewEngine implements ListEngine {
  final ScrollController controller = ScrollController();

  @override
  String get id => 'plain_listview';

  @override
  Widget buildList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
  }) => ListView.builder(
    controller: controller,
    itemCount: itemCount,
    itemBuilder: itemBuilder,
  );

  @override
  void dispose() => controller.dispose();
}
