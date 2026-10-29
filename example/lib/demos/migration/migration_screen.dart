import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scroll_atlas/compat.dart' as atlas;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart'
    as old;

/// D5: the same chat list on scrollable_positioned_list 0.3.8 and on
/// `package:scroll_atlas/compat.dart`, side by side.
///
/// Both panes are the same code; only the import prefix differs.
class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  /// Messages in each list.
  static const int messages = 2000;

  /// Height of message [index]; varied so jumps cross unmeasured items.
  static double heightOf(int index) => 44 + (index * 37 % 5) * 22;

  /// The buttons: label, target index and whether it animates.
  static const List<(String, int, bool)> moves = [
    ('Jump to 1500', 1500, false),
    ('Scroll to 300', 300, true),
    ('Scroll to 1999', 1999, true),
  ];

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  final old.ItemScrollController _oldScroll = old.ItemScrollController();
  final old.ItemPositionsListener _oldPositions =
      old.ItemPositionsListener.create();
  final atlas.ItemScrollController _newScroll = atlas.ItemScrollController();
  final atlas.ItemPositionsListener _newPositions =
      atlas.ItemPositionsListener.create();

  static const Duration _duration = Duration(milliseconds: 800);

  void _go(int index, {required bool animate}) {
    if (animate) {
      _oldScroll.scrollTo(index: index, duration: _duration);
      _newScroll.scrollTo(index: index, duration: _duration);
    } else {
      _oldScroll.jumpTo(index: index);
      _newScroll.jumpTo(index: index);
    }
  }

  Widget _bubble(String side, int index) => Container(
        key: ValueKey<String>('$side-$index'),
        height: MigrationScreen.heightOf(index),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.all(8),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: index.isEven ? Colors.blue.shade50 : Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text('Message $index'),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('D5 Migration before and after')),
      body: Column(
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final (label, index, animate) in MigrationScreen.moves)
                OutlinedButton(
                  onPressed: () => _go(index, animate: animate),
                  child: Text(label),
                ),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _Pane(
                    title: 'Before: scrollable_positioned_list',
                    positions: _oldPositions.itemPositions,
                    indexOf: (p) => p.index,
                    edgeOf: (p) => p.itemLeadingEdge,
                    list: old.ScrollablePositionedList.builder(
                      itemCount: MigrationScreen.messages,
                      itemBuilder: (context, index) => _bubble('old', index),
                      itemScrollController: _oldScroll,
                      itemPositionsListener: _oldPositions,
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _Pane(
                    title: 'After: scroll_atlas compat.dart',
                    positions: _newPositions.itemPositions,
                    indexOf: (p) => p.index,
                    edgeOf: (p) => p.itemLeadingEdge,
                    list: atlas.ScrollablePositionedList.builder(
                      itemCount: MigrationScreen.messages,
                      itemBuilder: (context, index) => _bubble('new', index),
                      itemScrollController: _newScroll,
                      itemPositionsListener: _newPositions,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One side: a title, a readout of the first visible item and the list.
class _Pane<P> extends StatelessWidget {
  const _Pane({
    required this.title,
    required this.positions,
    required this.indexOf,
    required this.edgeOf,
    required this.list,
  });

  final String title;
  final ValueListenable<Iterable<P>> positions;
  final int Function(P position) indexOf;
  final double Function(P position) edgeOf;
  final Widget list;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        ValueListenableBuilder<Iterable<P>>(
          valueListenable: positions,
          builder: (context, value, _) {
            final visible = value.where((p) => edgeOf(p) < 1).toList()
              ..sort((a, b) => indexOf(a).compareTo(indexOf(b)));
            final first = visible.where((p) => edgeOf(p) >= -1e-6).firstOrNull;
            return Text(
              first == null
                  ? 'First visible: none'
                  : 'First visible: ${indexOf(first)} at '
                      '${edgeOf(first).toStringAsFixed(3)}',
            );
          },
        ),
        Expanded(child: list),
      ],
    );
  }
}
