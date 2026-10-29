import 'package:flutter/material.dart';

import 'chat/chat_screen.dart';
import 'contacts/contacts_screen.dart';
import 'food_menu/food_menu_screen.dart';
import 'jump_lab/jump_lab_screen.dart';
import 'placeholder_demo_screen.dart';

/// Metadata and navigation for one demo screen in the example app.
final class DemoScreenSpec {
  const DemoScreenSpec({
    required this.id,
    required this.title,
    required this.summary,
    required this.whatToTry,
    required this.tickets,
    required this.builder,
  });

  final String id;
  final String title;
  final String summary;
  final String whatToTry;
  final String tickets;
  final WidgetBuilder builder;
}

/// All demo screens D1 through D6.
final List<DemoScreenSpec> demoCatalog = <DemoScreenSpec>[
  DemoScreenSpec(
    id: 'D1',
    title: 'Jump lab',
    summary:
        '100,000 seeded variable-height items, index field, alignment slider, '
        'Jump and Animate buttons, overlay with built items, last jump error '
        'and frame time',
    whatToTry: 'Jump to random indexes; animate 90,000 items with slow motion; '
        'insert while reading',
    tickets: '',
    builder: (BuildContext context) => const JumpLabScreen(),
  ),
  DemoScreenSpec(
    id: 'D2',
    title: 'Contacts A to Z',
    summary: 'Pinned app bar, 26 sticky letter headers, A to Z index rail, '
        '"Respect pinned headers" toggle, Footer chip',
    whatToTry: 'Scrub the rail; jump to K 3 with the toggle off then on',
    tickets: '',
    builder: (BuildContext context) => const ContactsScreen(),
  ),
  DemoScreenSpec(
    id: 'D3',
    title: 'Timetable',
    summary:
        'Frozen time header row and room column linked to the body, plus a '
        '"synced carousels" variant',
    whatToTry: 'Fling diagonally; scroll down so new rows build',
    tickets: '',
    builder: _placeholderBuilder('D3'),
  ),
  DemoScreenSpec(
    id: 'D4',
    title: 'Food menu',
    summary:
        'Collapsing hero image, sticky tab bar, 8 sections, scroll spy, tap '
        'to scroll',
    whatToTry: 'Tap last tab then first; scroll slowly both ways',
    tickets: '',
    builder: (BuildContext context) => const FoodMenuScreen(),
  ),
  DemoScreenSpec(
    id: 'D5',
    title: 'Migration before and after',
    summary:
        'Same chat list on scrollable_positioned_list and on compat.dart side '
        'by side',
    whatToTry: 'Run both; compare behavior',
    tickets: '',
    builder: _placeholderBuilder('D5'),
  ),
  DemoScreenSpec(
    id: 'D6',
    title: 'Chat',
    summary:
        'Reverse list, opens at first unread, tap a quoted reply to jump to '
        'the original with a highlight flash, stays pinned to bottom on new '
        'messages',
    whatToTry: 'Open; tap a reply; send a message',
    tickets: '',
    builder: (BuildContext context) => const ChatScreen(),
  ),
];

WidgetBuilder _placeholderBuilder(String id) {
  return (BuildContext context) {
    final spec = demoCatalog.firstWhere((DemoScreenSpec s) => s.id == id);
    return PlaceholderDemoScreen(spec: spec);
  };
}
