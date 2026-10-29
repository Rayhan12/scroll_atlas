import 'package:flutter/material.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../../app/demo_theme.dart';

/// Table bookings: 200 restaurant tables by 48 half hour slots on
/// [LinkedTable]. The body scrolls freely in both directions while the
/// time row and the table column stay locked to it.
class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  /// Half hour slots from 00:00 to 23:30.
  static const int slots = 48;

  /// Tables down the frozen first column.
  static const int tables = 200;

  /// Width of a slot, the [LinkedTable] default column extent.
  static const double slotWidth = 96;

  /// Label of [slot], for example `09:30`.
  static String slotLabel(int slot) =>
      '${(slot ~/ 2).toString().padLeft(2, '0')}:${slot.isOdd ? '30' : '00'}';

  /// Label of [table] in the frozen column.
  static String tableLabel(int table) => 'Table $table';

  /// Whether [table] has a booking in [slot]; a fixed pattern, no data.
  static bool isBooked(int table, int slot) => (table * 7 + slot * 3) % 5 == 0;

  /// Guest name of the booking at [table] in [slot].
  static String bookingTitle(int table, int slot) =>
      _guests[(table * 3 + slot) % _guests.length];

  /// Party size of the booking at [table] in [slot].
  static int partySize(int table, int slot) => 2 + (table + slot) % 7;

  static const List<String> _guests = <String>[
    'Rahman',
    'Chowdhury',
    'Birthday',
    'Hossain',
    'Office lunch',
    'Anniversary',
    'Begum',
    'Karim',
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
    final muted = text.labelMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    final line = BorderSide(color: scheme.outlineVariant);
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Table bookings'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: Gap.s),
            child: IconButton.filledTonal(
              tooltip: 'Go to 12:00',
              icon: const Icon(Icons.schedule),
              onPressed: _goToNoon,
            ),
          ),
        ],
      ),
      body: LinkedTable(
        key: const Key('timetable_table'),
        rowCount: TimetableScreen.tables,
        columnCount: TimetableScreen.slots,
        horizontalGroup: _time,
        verticalGroup: _rooms,
        cornerBuilder: (_) => DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(bottom: line, right: line),
          ),
          child: Center(child: Text('Table', style: text.labelLarge)),
        ),
        columnHeaderBuilder: (_, int slot) => DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(bottom: line),
          ),
          child: Center(
            child: Text(TimetableScreen.slotLabel(slot), style: muted),
          ),
        ),
        rowHeaderBuilder: (_, int table) => DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(right: line),
          ),
          child: Center(
            child: Text(
              TimetableScreen.tableLabel(table),
              style: text.labelLarge,
            ),
          ),
        ),
        cellBuilder: (_, int table, int slot) {
          final booked = TimetableScreen.isBooked(table, slot);
          return Padding(
            padding: const EdgeInsets.all(2),
            child: DecoratedBox(
              key: ValueKey<String>('cell-$table-$slot'),
              decoration: BoxDecoration(
                color: booked
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerLow,
                border: booked
                    ? Border(
                        left: BorderSide(color: scheme.primary, width: 3),
                      )
                    : null,
                borderRadius: BorderRadius.circular(Corners.s),
              ),
              child: booked
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            TimetableScreen.bookingTitle(table, slot),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelMedium?.copyWith(
                              color: scheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${TimetableScreen.partySize(table, slot)} guests',
                            maxLines: 1,
                            style: text.labelSmall
                                ?.copyWith(color: scheme.primary),
                          ),
                        ],
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
