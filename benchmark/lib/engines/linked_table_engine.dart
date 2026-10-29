import 'package:flutter/widgets.dart';

/// Capability for B5: a table whose header row, first column and body
/// rows scroll together. Engines without linked scrolling do not implement
/// it and B5 skips them (Liskov).
abstract interface class LinkedTableEngine {
  /// A [rows] x [columns] table with a frozen header row of [rowExtent]
  /// and a frozen first column of [columnExtent]. Every cell is
  /// [columnExtent] wide and [rowExtent] high.
  Widget buildLinkedTable({
    required int rows,
    required int columns,
    required double rowExtent,
    required double columnExtent,
  });

  /// Scroll positions that must share the horizontal offset right now.
  Iterable<ScrollPosition> get horizontalMembers;

  /// Scroll positions that must share the vertical offset right now.
  Iterable<ScrollPosition> get verticalMembers;
}
