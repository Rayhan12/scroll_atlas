import 'package:flutter/material.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'contacts_data.dart';

/// Contacts A to Z: a pinned app bar, 26 sticky letter headers, an A to
/// Z index rail, a "Respect pinned headers" toggle and jump chips
///
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final AtlasController _atlas = AtlasController();
  bool _respectPinned = true;

  @override
  void dispose() {
    _atlas.dispose();
    super.dispose();
  }

  void _jump(AtlasTarget target) =>
      _atlas.jumpTo(target: target, respectPinned: _respectPinned);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          AtlasScrollView(
            controller: _atlas,
            slivers: <Widget>[
              SliverAppBar(
                pinned: true,
                title: const Text('Contacts'),
                bottom: _JumpBar(
                  respectPinned: _respectPinned,
                  onRespectPinned: (bool value) =>
                      setState(() => _respectPinned = value),
                  onJump: _jump,
                ),
              ),
              for (final String letter in contactLetters)
                SliverAtlasSection(
                  id: letter,
                  header: (BuildContext context, double stuck) =>
                      LetterHeader(letter: letter, stuck: stuck),
                  sliver: SliverAtlasList.builder(
                    id: 'people-$letter',
                    itemCount: contactCount(letter),
                    itemBuilder: (BuildContext context, int index) =>
                        ContactTile(letter: letter, index: index),
                  ),
                ),
              const AtlasAnchor(id: 'footer', sliver: _Footer()),
            ],
          ),
          Positioned(
            right: 0,
            top: MediaQuery.paddingOf(context).top +
                kToolbarHeight +
                _JumpBar.barHeight,
            bottom: 8,
            child: IndexRail(
              onLetter: (String letter) => _jump(AtlasTarget.section(letter)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chips and the toggle under the title.
class _JumpBar extends StatelessWidget implements PreferredSizeWidget {
  const _JumpBar({
    required this.respectPinned,
    required this.onRespectPinned,
    required this.onJump,
  });

  final bool respectPinned;
  final ValueChanged<bool> onRespectPinned;
  final ValueChanged<AtlasTarget> onJump;

  @override
  Size get preferredSize => const Size.fromHeight(barHeight);

  /// Height of the chip row plus the toggle row.
  static const double barHeight = 96;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: barHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                _chip('K, item 3', const AtlasTarget.item('people-K', 3)),
                _chip('Z, item 3', const AtlasTarget.item('people-Z', 3)),
                _chip('Footer', const AtlasTarget.sliver('footer')),
              ],
            ),
            Row(
              children: <Widget>[
                const Expanded(child: Text('Respect pinned headers')),
                Switch(
                  key: const Key('respect_pinned_switch'),
                  value: respectPinned,
                  onChanged: onRespectPinned,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, AtlasTarget target) => Expanded(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ActionChip(
            tooltip: 'Jump to $label',
            visualDensity: VisualDensity.compact,
            label: Text(label),
            onPressed: () => onJump(target),
          ),
        ),
      );
}

/// A letter header with a shadow only while stuck.
class LetterHeader extends StatelessWidget {
  const LetterHeader({required this.letter, required this.stuck, super.key});

  final String letter;

  /// 0 in place, 1 stuck under the app bar.
  final double stuck;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      key: ValueKey<String>('header-$letter'),
      elevation: 4 * stuck,
      color: Color.lerp(scheme.surface, scheme.primaryContainer, stuck),
      child: SizedBox(
        height: 40,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(letter, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
      ),
    );
  }
}

/// One contact row; notes of one to three lines vary its height.
class ContactTile extends StatelessWidget {
  const ContactTile({required this.letter, required this.index, super.key});

  final String letter;
  final int index;

  @override
  Widget build(BuildContext context) {
    final contact = contactAt(letter, index);
    return ListTile(
      key: ValueKey<String>('contact-$letter-$index'),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Text(
          contact.name.split(' ').map((String w) => w[0]).join(),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
      title: Text(contact.name),
      subtitle: Text(contact.note),
      isThreeLine: contact.note.contains('\n'),
    );
  }
}

/// A to Z rail: tap or drag over a letter to jump to its section.
class IndexRail extends StatelessWidget {
  const IndexRail({required this.onLetter, super.key});

  final ValueChanged<String> onLetter;

  void _pick(Offset local, double height) {
    final slot = (local.dy / height * contactLetters.length)
        .floor()
        .clamp(0, contactLetters.length - 1);
    onLetter(contactLetters[slot]);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final height = constraints.maxHeight;
        return GestureDetector(
          key: const Key('index_rail'),
          behavior: HitTestBehavior.opaque,
          onTapDown: (TapDownDetails d) => _pick(d.localPosition, height),
          onVerticalDragUpdate: (DragUpdateDetails d) =>
              _pick(d.localPosition, height),
          child: SizedBox(
            width: 24,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                for (final String letter in contactLetters)
                  Text(letter, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        key: const Key('footer_block'),
        height: 240,
        color: Theme.of(context).colorScheme.secondaryContainer,
        alignment: Alignment.center,
        child: const Text('Footer: 26 sections, sticky headers, any target'),
      ),
    );
  }
}
