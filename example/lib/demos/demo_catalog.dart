import 'package:flutter/material.dart';

import 'chat/chat_screen.dart';
import 'contacts/contacts_screen.dart';
import 'demo_spec.dart';
import 'food_menu/food_menu_screen.dart';
import 'jump_lab/jump_lab_screen.dart';
import 'timetable/timetable_screen.dart';

export 'demo_spec.dart';

/// Every demo, in gallery order.
final List<DemoSpec> demoCatalog = <DemoSpec>[
  DemoSpec(
    slug: 'menu',
    title: 'Food menu',
    icon: Icons.restaurant_menu,
    problem: 'Tabs that follow a long menu and jump to a section.',
    withListView: 'Tapping a far tab makes the indicator flicker through '
        'every tab, and the section lands under the pinned bar.',
    withAtlas: 'One tap, one indicator move, and the section header lands '
        'right under the tabs.',
    whatToTry: 'Tap Desserts, then Starters. Then scroll slowly and watch '
        'the tabs follow.',
    builder: (BuildContext context) => const FoodMenuScreen(),
  ),
  DemoSpec(
    slug: 'contacts',
    title: 'Contacts',
    icon: Icons.contacts,
    problem: 'Jump to any contact under a pinned bar and sticky letters.',
    withListView: 'Items you have not scrolled past have no context, so you '
        'cannot jump to them, and sticky headers cover the target.',
    withAtlas: 'Jump by id to any section or row, aligned below everything '
        'pinned above it.',
    whatToTry:
        'Scrub the A to Z rail. Turn "Respect pinned headers" off and jump to '
        'K 3 to see what plain alignment hides.',
    builder: (BuildContext context) => const ContactsScreen(),
  ),
  DemoSpec(
    slug: 'chat',
    title: 'Chat',
    icon: Icons.forum,
    problem: 'Open a chat at the first unread message and jump to replies.',
    withListView: 'A reversed ListView opens at the newest message and '
        'cannot scroll to a quoted message far up the history.',
    withAtlas: 'Opens at the first unread, jumps to the original of any '
        'reply, and stays put while new messages arrive.',
    whatToTry: 'Tap a quoted reply, then send a message.',
    builder: (BuildContext context) => const ChatScreen(),
  ),
  DemoSpec(
    slug: 'timetable',
    title: 'Room bookings',
    icon: Icons.table_chart,
    problem: 'A big table with a frozen time row and room column.',
    withListView: 'Nested lists scroll one axis per drag, and the headers '
        'drift away from the cells during a fling.',
    withAtlas: 'Drag or fling diagonally; the header row and room column '
        'stay locked to the cells on every frame.',
    whatToTry: 'Fling diagonally across the grid, then tap the clock to '
        'go to 12:00.',
    builder: (BuildContext context) => const TimetableScreen(),
  ),
  DemoSpec(
    slug: 'jump',
    title: 'Jump lab',
    icon: Icons.bolt,
    problem: 'Jump anywhere in 100,000 items of different heights.',
    withListView: 'scrollTo needs offsets you do not know, and animating far '
        'builds thousands of items or snaps at the end.',
    withAtlas: 'Lands on the exact item in one frame, animates any distance '
        'without a snap, and keeps your place when items load above.',
    whatToTry: 'Jump to 75000, animate back to 10, then tap Insert 20 above '
        'while reading.',
    builder: (BuildContext context) => const JumpLabScreen(),
  ),
];
