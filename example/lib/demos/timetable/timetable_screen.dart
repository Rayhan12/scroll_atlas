import 'package:flutter/material.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

/// Room bookings: a 200 room by 48 slot timetable on [LinkedTable]. The
/// body scrolls freely in both directions while the time row and the room
/// column stay locked to it.
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

  /// Title of the booking in [room] at [slot].
  static String bookingTitle(int room, int slot) =>
      _titles[(room * 3 + slot) % _titles.length];

  static const List<String> _titles = <String>[
    'Design review',
    'Standup',
    'Hiring loop',
    'Sprint demo',
    '1:1',
    'Customer call',
    'Workshop',
    'Planning',
  ];

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final LinkedScrollGroup _time = LinkedScrollGroup();
  final LinkedScrollGroup _rooms = LinkedScrollGroup();

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
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = text.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room bookings'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Go to 12:00',
            icon: const Icon(Icons.schedule),
            onPressed: _goToNoon,
          ),
        ],
      ),
      body: LinkedTable(
        key: const Key('timetable_table'),
        rowCount: TimetableScreen.rooms,
        columnCount: TimetableScreen.slots,
        horizontalGroup: _time,
        verticalGroup: _rooms,
        cornerBuilder: (_) => ColoredBox(
          color: scheme.surfaceContainer,
          child: Center(child: Text('Room', style: text.labelLarge)),
        ),
        columnHeaderBuilder: (_, int slot) => ColoredBox(
          color: scheme.surfaceContainer,
          child: Center(
            child: Text(TimetableScreen.slotLabel(slot), style: muted),
          ),
        ),
        rowHeaderBuilder: (_, int room) => ColoredBox(
          color: scheme.surfaceContainerLow,
          child: Center(child: Text('Room $room', style: text.labelLarge)),
        ),
        cellBuilder: (_, int room, int slot) {
          final booked = TimetableScreen.isBooked(room, slot);
          return Padding(
            padding: const EdgeInsets.all(2),
            child: DecoratedBox(
              key: ValueKey<String>('cell-$room-$slot'),
              decoration: BoxDecoration(
                color: booked ? scheme.primaryContainer : null,
                border: booked
                    ? null
                    : Border.all(color: scheme.outlineVariant, width: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: booked
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          TimetableScreen.bookingTitle(room, slot),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelSmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}
