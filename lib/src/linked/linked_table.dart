import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'linked_scroll_group.dart';

/// Builds the cell at [row] and [column] of a [LinkedTable].
typedef LinkedCellBuilder = Widget Function(
  BuildContext context,
  int row,
  int column,
);

/// A table with a frozen header row and a frozen first column, linked by
/// two [LinkedScrollGroup]s.
///
/// The body is one two-dimensional scroll view that builds only the
/// visible cells and scrolls both axes at once, so a diagonal drag or
/// fling moves it freely ([diagonalDragBehavior]). The header row shares
/// the [horizontalGroup] with the body, and the first column shares the
/// [verticalGroup], so both stay in line on every frame.
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
/// selection. Dragging the header row scrolls only the columns, and
/// dragging the first column scrolls only the rows.
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
    this.diagonalDragBehavior = DiagonalDragBehavior.free,
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

  /// How the body handles drags that are not along one axis. The default,
  /// [DiagonalDragBehavior.free], scrolls both axes at once.
  final DiagonalDragBehavior diagonalDragBehavior;

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
  late final ScrollController _bodyColumns = _columns.createController();
  late final ScrollController _bodyRows = _rows.createController();

  @override
  void dispose() {
    _header.dispose();
    _rowHeaders.dispose();
    _bodyColumns.dispose();
    _bodyRows.dispose();
    if (widget.horizontalGroup == null) _columns.dispose();
    if (widget.verticalGroup == null) _rows.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final table = widget;
    return Column(
      children: <Widget>[
        SizedBox(
          height: table.headerExtent,
          child: Row(
            children: <Widget>[
              SizedBox(
                width: table.rowHeaderExtent,
                child: table.cornerBuilder?.call(context),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  controller: _header,
                  physics: table.physics,
                  itemExtent: table.columnExtent,
                  itemCount: table.columnCount,
                  itemBuilder: table.columnHeaderBuilder,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: <Widget>[
              SizedBox(
                width: table.rowHeaderExtent,
                child: ListView.builder(
                  controller: _rowHeaders,
                  physics: table.physics,
                  itemExtent: table.rowExtent,
                  itemCount: table.rowCount,
                  itemBuilder: table.rowHeaderBuilder,
                ),
              ),
              Expanded(
                child: _GridBody(
                  verticalDetails: ScrollableDetails.vertical(
                    controller: _bodyRows,
                    physics: table.physics,
                  ),
                  horizontalDetails: ScrollableDetails.horizontal(
                    controller: _bodyColumns,
                    physics: table.physics,
                  ),
                  diagonalDragBehavior: table.diagonalDragBehavior,
                  rowExtent: table.rowExtent,
                  columnExtent: table.columnExtent,
                  delegate: TwoDimensionalChildBuilderDelegate(
                    maxXIndex: table.columnCount - 1,
                    maxYIndex: table.rowCount - 1,
                    addRepaintBoundaries: false,
                    builder: (BuildContext context, ChildVicinity cell) =>
                        table.cellBuilder(context, cell.yIndex, cell.xIndex),
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

/// The body: a two-dimensional scroll view over a grid of fixed-size
/// cells.
class _GridBody extends TwoDimensionalScrollView {
  const _GridBody({
    required super.verticalDetails,
    required super.horizontalDetails,
    required super.diagonalDragBehavior,
    required TwoDimensionalChildBuilderDelegate super.delegate,
    required this.rowExtent,
    required this.columnExtent,
  });

  final double rowExtent;
  final double columnExtent;

  @override
  Widget buildViewport(
    BuildContext context,
    ViewportOffset verticalOffset,
    ViewportOffset horizontalOffset,
  ) =>
      _GridViewport(
        verticalOffset: verticalOffset,
        verticalAxisDirection: verticalDetails.direction,
        horizontalOffset: horizontalOffset,
        horizontalAxisDirection: horizontalDetails.direction,
        delegate: delegate as TwoDimensionalChildBuilderDelegate,
        mainAxis: mainAxis,
        cacheExtent: cacheExtent,
        clipBehavior: clipBehavior,
        rowExtent: rowExtent,
        columnExtent: columnExtent,
      );
}

class _GridViewport extends TwoDimensionalViewport {
  const _GridViewport({
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required TwoDimensionalChildBuilderDelegate super.delegate,
    required super.mainAxis,
    required this.rowExtent,
    required this.columnExtent,
    super.cacheExtent,
    super.clipBehavior,
  });

  final double rowExtent;
  final double columnExtent;

  @override
  RenderTwoDimensionalViewport createRenderObject(BuildContext context) =>
      _RenderGridViewport(
        horizontalOffset: horizontalOffset,
        horizontalAxisDirection: horizontalAxisDirection,
        verticalOffset: verticalOffset,
        verticalAxisDirection: verticalAxisDirection,
        delegate: delegate as TwoDimensionalChildBuilderDelegate,
        mainAxis: mainAxis,
        childManager: context as TwoDimensionalChildManager,
        cacheExtent: cacheExtent,
        clipBehavior: clipBehavior,
        rowExtent: rowExtent,
        columnExtent: columnExtent,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderGridViewport renderObject,
  ) {
    renderObject
      ..horizontalOffset = horizontalOffset
      ..horizontalAxisDirection = horizontalAxisDirection
      ..verticalOffset = verticalOffset
      ..verticalAxisDirection = verticalAxisDirection
      ..delegate = delegate
      ..mainAxis = mainAxis
      ..cacheExtent = cacheExtent
      ..clipBehavior = clipBehavior
      ..rowExtent = rowExtent
      ..columnExtent = columnExtent;
  }
}

class _RenderGridViewport extends RenderTwoDimensionalViewport {
  _RenderGridViewport({
    required super.horizontalOffset,
    required super.horizontalAxisDirection,
    required super.verticalOffset,
    required super.verticalAxisDirection,
    required TwoDimensionalChildBuilderDelegate super.delegate,
    required super.mainAxis,
    required super.childManager,
    required double rowExtent,
    required double columnExtent,
    super.cacheExtent,
    super.clipBehavior,
  })  : _rowExtent = rowExtent,
        _columnExtent = columnExtent;

  double _rowExtent;
  set rowExtent(double value) {
    if (value == _rowExtent) return;
    _rowExtent = value;
    markNeedsLayout();
  }

  double _columnExtent;
  set columnExtent(double value) {
    if (value == _columnExtent) return;
    _columnExtent = value;
    markNeedsLayout();
  }

  @override
  void layoutChildSequence() {
    final builder = delegate as TwoDimensionalChildBuilderDelegate;
    final columns = builder.maxXIndex! + 1;
    final rows = builder.maxYIndex! + 1;
    final x = horizontalOffset.pixels;
    final y = verticalOffset.pixels;
    final width = viewportDimension.width;
    final height = viewportDimension.height;

    final firstColumn = math.max(0, (x - cacheExtent) ~/ _columnExtent);
    final lastColumn = math.min(
      columns - 1,
      ((x + width + cacheExtent) / _columnExtent).ceil(),
    );
    final firstRow = math.max(0, (y - cacheExtent) ~/ _rowExtent);
    final lastRow = math.min(
      rows - 1,
      ((y + height + cacheExtent) / _rowExtent).ceil(),
    );
    final cellConstraints = BoxConstraints.tightFor(
      width: _columnExtent,
      height: _rowExtent,
    );
    for (var column = firstColumn; column <= lastColumn; column++) {
      for (var row = firstRow; row <= lastRow; row++) {
        final vicinity = ChildVicinity(xIndex: column, yIndex: row);
        final child = buildOrObtainChildFor(vicinity);
        if (child == null) continue;
        child.layout(cellConstraints);
        parentDataOf(child).layoutOffset = Offset(
          column * _columnExtent - x,
          row * _rowExtent - y,
        );
      }
    }
    verticalOffset.applyContentDimensions(
      0,
      math.max(0, rows * _rowExtent - height),
    );
    horizontalOffset.applyContentDimensions(
      0,
      math.max(0, columns * _columnExtent - width),
    );
  }
}
