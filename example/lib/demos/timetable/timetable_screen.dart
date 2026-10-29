import 'package:flutter/material.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

/// D3: a room timetable built on [LinkedTable], plus a synced carousels
/// variant built on one [LinkedScrollGroup].
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  /// Half hour slots from 00:00 to 23:30.
  static const int slots = 48;

  /// Rooms down the frozen first column.
  static const int rooms = 200;

  /// Width of a slot, the [LinkedTable] default column extent.
  static const double slotWidth = 96;

  /// Label of [slot], for example `09:30`.
  static String slotLabel(int slot) =>
      '${(slot ~/ 2).toString().padLeft(2, '0')}:${slot.isOdd ? '30' : '00'}';

  /// Whether [room] has a booking in [slot]; a fixed pattern, no data.
  static bool isBooked(int room, int slot) => (room * 7 + slot * 3) % 5 == 0;

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

enum _View { table, carousels }

class _TimetableScreenState extends State<TimetableScreen> {
  final LinkedScrollGroup _time = LinkedScrollGroup();
  final LinkedScrollGroup _rooms = LinkedScrollGroup();
  _View _view = _View.table;

  @override
  void dispose() {
    _time.dispose();
    _rooms.dispose();
    super.dispose();
  }

  Future<void> _goToNoon() => _time.animateTo(
        24 * TimetableScreen.slotWidth,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('D3 Timetable'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Go to 12:00',
            icon: const Icon(Icons.schedule),
            onPressed: _goToNoon,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: SegmentedButton<_View>(
              segments: const <ButtonSegment<_View>>[
                ButtonSegment<_View>(
                  value: _View.table,
                  label: Text('Table'),
                ),
                ButtonSegment<_View>(
                  value: _View.carousels,
                  label: Text('Synced carousels'),
                ),
              ],
              selected: <_View>{_view},
              onSelectionChanged: (Set<_View> v) =>
                  setState(() => _view = v.single),
            ),
          ),
        ),
      ),
      body: switch (_view) {
        _View.table => _Table(time: _time, rooms: _rooms),
        _View.carousels => _Carousels(time: _time),
      },
    );
  }
}

class _Table extends StatelessWidget {
  const _Table({required this.time, required this.rooms});

  final LinkedScrollGroup time;
  final LinkedScrollGroup rooms;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LinkedTable(
      key: const Key('timetable_table'),
      rowCount: TimetableScreen.rooms,
      columnCount: TimetableScreen.slots,
      horizontalGroup: time,
      verticalGroup: rooms,
      cornerBuilder: (_) => const Center(child: Text('Room')),
      columnHeaderBuilder: (_, int slot) => Center(
        child: Text(TimetableScreen.slotLabel(slot)),
      ),
      rowHeaderBuilder: (_, int room) => Center(child: Text('Room $room')),
      cellBuilder: (_, int room, int slot) => Padding(
        padding: const EdgeInsets.all(2),
        child: DecoratedBox(
          key: ValueKey<String>('cell-$room-$slot'),
          decoration: BoxDecoration(
            color: TimetableScreen.isBooked(room, slot)
                ? scheme.primaryContainer
                : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

class _Carousels extends StatefulWidget {
  const _Carousels({required this.time});

  final LinkedScrollGroup time;

  @override
  State<_Carousels> createState() => _CarouselsState();
}

class _CarouselsState extends State<_Carousels> {
  static const List<String> _tracks = <String>['Main hall', 'Studio', 'Lab'];

  late final List<ScrollController> _controllers = <ScrollController>[
    for (final _ in _tracks) widget.time.createController(),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: <Widget>[
        for (var t = 0; t < _tracks.length; t++) ...<Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              _tracks[t],
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SizedBox(
            height: 120,
            child: ListView.builder(
              key: ValueKey<String>('carousel-$t'),
              scrollDirection: Axis.horizontal,
              controller: _controllers[t],
              itemExtent: TimetableScreen.slotWidth,
              itemCount: TimetableScreen.slots,
              itemBuilder: (_, int slot) => Card(
                key: ValueKey<String>('slide-$t-$slot'),
                child: Center(child: Text(TimetableScreen.slotLabel(slot))),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
