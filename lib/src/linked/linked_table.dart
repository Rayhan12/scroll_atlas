import 'package:flutter/widgets.dart';

import 'linked_scroll_group.dart';

/// Builds the cell at [row] and [column] of a [LinkedTable].
typedef LinkedCellBuilder = Widget Function(
  BuildContext context,
  int row,
  int column,
);

/// A table with a frozen header row and a frozen first column, built from
/// standard [ListView]s and two [LinkedScrollGroup]s.
///
/// The header row and every body row share the [horizontalGroup]; the row
/// header column and the body share the [verticalGroup]. Rows build lazily
/// and each new row starts at the group's offset, so it already lines up
/// with the header when it appears.
///
/// ```dart
/// LinkedTable(
///   rowCount: 1000,
///   columnCount: 50,
///   cellBuilder: (context, row, column) => Text('$row:$column'),
///   columnHeaderBuilder: (context, column) => Text('C$column'),
///   rowHeaderBuilder: (context, row) => Text('R$row'),
/// )
/// ```
///
/// This is a recipe, not a data grid: there is no sorting, editing or
/// selection. Each gesture scrolls one axis, because the body rows are
/// separate scroll views; two fingers, one on the header row and one on
/// the body, scroll both at once.
class LinkedTable extends StatefulWidget {
  /// Creates a table of [rowCount] rows and [columnCount] columns.
  const LinkedTable({
    required this.rowCount,
    required this.columnCount,
    required this.cellBuilder,
    required this.columnHeaderBuilder,
    required this.rowHeaderBuilder,
    this.cornerBuilder,
    this.rowExtent = 48,
    this.columnExtent = 96,
    this.headerExtent = 48,
    this.rowHeaderExtent = 96,
    this.horizontalGroup,
    this.verticalGroup,
    this.physics,
    super.key,
  });

  /// Number of body rows.
  final int rowCount;

  /// Number of body columns.
  final int columnCount;

  /// Builds one body cell.
  final LinkedCellBuilder cellBuilder;

  /// Builds the frozen header cell of a column.
  final IndexedWidgetBuilder columnHeaderBuilder;

  /// Builds the frozen first-column cell of a row.
  final IndexedWidgetBuilder rowHeaderBuilder;

  /// Builds the top left corner; empty when null.
  final WidgetBuilder? cornerBuilder;

  /// Height of every row.
  final double rowExtent;

  /// Width of every column.
  final double columnExtent;

  /// Height of the header row.
  final double headerExtent;

  /// Width of the row header column.
  final double rowHeaderExtent;

  /// Group for the columns. When null the table makes and disposes its
  /// own. Read once, when the table is first built.
  final LinkedScrollGroup? horizontalGroup;

  /// Group for the rows. When null the table makes and disposes its own.
  /// Read once, when the table is first built.
  final LinkedScrollGroup? verticalGroup;

  /// Physics of every scroll view in the table.
  final ScrollPhysics? physics;

  @override
  State<LinkedTable> createState() => _LinkedTableState();
}

class _LinkedTableState extends State<LinkedTable> {
  late final LinkedScrollGroup _columns =
      widget.horizontalGroup ?? LinkedScrollGroup();
  late final LinkedScrollGroup _rows =
      widget.verticalGroup ?? LinkedScrollGroup();
  late final ScrollController _header = _columns.createController();
  late final ScrollController _rowHeaders = _rows.createController();
  late final ScrollController _body = _rows.createController();

  @override
  void dispose() {
    _header.dispose();
    _rowHeaders.dispose();
    _body.dispose();
    if (widget.horizontalGroup == null) _columns.dispose();
    if (widget.verticalGroup == null) _rows.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          height: widget.headerExtent,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: widget.rowHeaderExtent,
                child: widget.cornerBuilder?.call(context),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  controller: _header,
                  physics: widget.physics,
                  itemExtent: widget.columnExtent,
                  itemCount: widget.columnCount,
                  itemBuilder: widget.columnHeaderBuilder,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              SizedBox(
                width: widget.rowHeaderExtent,
                child: ListView.builder(
                  controller: _rowHeaders,
                  physics: widget.physics,
                  itemExtent: widget.rowExtent,
                  itemCount: widget.rowCount,
                  itemBuilder: widget.rowHeaderBuilder,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: _body,
                  physics: widget.physics,
                  itemExtent: widget.rowExtent,
                  itemCount: widget.rowCount,
                  itemBuilder: (BuildContext context, int row) => _LinkedRow(
                    key: ValueKey<int>(row),
                    group: _columns,
                    row: row,
                    table: widget,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One body row: a horizontal list that joins the column group while it
/// is built and leaves it when it scrolls away.
class _LinkedRow extends StatefulWidget {
  const _LinkedRow({
    required this.group,
    required this.row,
    required this.table,
    super.key,
  });

  final LinkedScrollGroup group;
  final int row;
  final LinkedTable table;

  @override
  State<_LinkedRow> createState() => _LinkedRowState();
}

class _LinkedRowState extends State<_LinkedRow> {
  late final ScrollController _controller = widget.group.createController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.table;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      controller: _controller,
      physics: table.physics,
      itemExtent: table.columnExtent,
      itemCount: table.columnCount,
      itemBuilder: (BuildContext context, int column) =>
          table.cellBuilder(context, widget.row, column),
    );
  }
}
