import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import '../../app/demo_theme.dart';
import 'chat_thread.dart';

/// Chat: a reversed [AtlasListView] that opens at the first unread
/// message, animates to a quoted message and flashes it, and stays pinned
/// to the bottom when a message arrives.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.thread});

  /// Conversation to show; defaults to a seeded one.
  final ChatThread? thread;

  /// Where the first unread message opens. The list is reversed, so its
  /// leading edge is the bottom: the message's bottom edge sits 70 percent
  /// of the way up the viewport.
  static const double unreadAlignment = 0.7;

  /// Where a quoted message lands after a tap.
  static const double quoteAlignment = 0.4;

  /// How long a jumped-to message stays highlighted.
  static const Duration flashDuration = Duration(milliseconds: 1200);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChatThread _thread = widget.thread ?? ChatThread.seeded();
  final AtlasController _atlas = AtlasController();
  final TextEditingController _input = TextEditingController();
  final ValueNotifier<int?> _highlighted = ValueNotifier<int?>(null);
  Timer? _flash;

  @override
  void dispose() {
    _flash?.cancel();
    _highlighted.dispose();
    _input.dispose();
    _atlas.dispose();
    super.dispose();
  }

  Future<void> _jumpToQuote(int id) async {
    await _atlas.animateTo(
      index: _thread.indexOfId(id),
      alignment: ChatScreen.quoteAlignment,
      duration: const Duration(milliseconds: 500),
    );
    if (!mounted) return;
    _highlighted.value = id;
    _flash?.cancel();
    _flash = Timer(ChatScreen.flashDuration, () => _highlighted.value = null);
  }

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _thread.send(text));
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(titleSpacing: 0, title: const _ChatTitle()),
      body: Column(
        children: <Widget>[
          Expanded(
            child: AtlasScrollbar(
              controller: _atlas,
              reverse: true,
              child: AtlasListView.builder(
                controller: _atlas,
                reverse: true,
                itemCount: _thread.length,
                initialIndex: _thread.indexOfId(_thread.firstUnreadId),
                initialAlignment: ChatScreen.unreadAlignment,
                findChildIndexCallback: _thread.indexOfKey,
                itemBuilder: (BuildContext context, int index) {
                  final message = _thread.atIndex(index);
                  return _MessageTile(
                    key: ChatThread.keyOf(message),
                    message: message,
                    quoted: message.replyTo == null
                        ? null
                        : _thread.byId(message.replyTo!),
                    firstUnread: message.id == _thread.firstUnreadId,
                    highlighted: _highlighted,
                    onQuoteTap: _jumpToQuote,
                  );
                },
              ),
            ),
          ),
          _Composer(controller: _input, onSend: _send),
        ],
      ),
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({
    required this.message,
    required this.quoted,
    required this.firstUnread,
    required this.highlighted,
    required this.onQuoteTap,
    super.key,
  });

  final ChatMessage message;

  /// The message this one replies to, if any.
  final ChatMessage? quoted;
  final bool firstUnread;
  final ValueListenable<int?> highlighted;
  final ValueChanged<int> onQuoteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final replyTo = message.replyTo;
    final mine = message.mine;
    const r = Radius.circular(18);
    const tail = Radius.circular(4);
    final bubble = ValueListenableBuilder<int?>(
      valueListenable: highlighted,
      builder: (BuildContext context, int? id, Widget? child) => Container(
        key: ValueKey<String>('bubble-${message.id}'),
        margin: const EdgeInsets.symmetric(horizontal: Gap.m, vertical: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: Gap.m + 2, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: id == message.id
              ? scheme.tertiaryContainer
              : mine
                  ? scheme.primary
                  : scheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: r,
            topRight: r,
            bottomLeft: mine ? r : tail,
            bottomRight: mine ? tail : r,
          ),
          boxShadow: mine
              ? null
              : const <BoxShadow>[
                  BoxShadow(color: Color(0x14000000), blurRadius: 4),
                ],
        ),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            color: id == message.id
                ? scheme.onTertiaryContainer
                : mine
                    ? Colors.white
                    : scheme.onSurface,
          ),
          child: child!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (replyTo != null)
            InkWell(
              key: ValueKey<String>('quote-${message.id}'),
              onTap: () => onQuoteTap(replyTo),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.fromLTRB(Gap.s, 6, Gap.s, 6),
                decoration: BoxDecoration(
                  color: mine
                      ? Colors.white.withValues(alpha: 0.18)
                      : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(Corners.s),
                  border: Border(
                    left: BorderSide(
                      color: mine ? Colors.white : scheme.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      quoted!.mine ? 'You' : 'Nadia',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: mine ? Colors.white : scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      quoted!.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          Text(message.text, style: const TextStyle(height: 1.3)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment:
          mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        if (firstUnread)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Gap.m),
            child: Center(
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: scheme.primaryContainer,
                  shape: const StadiumBorder(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Gap.m,
                    vertical: Gap.xs,
                  ),
                  child: Text(
                    'First unread',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        bubble,
      ],
    );
  }
}

/// Avatar, name and status in the app bar.
class _ChatTitle extends StatelessWidget {
  const _ChatTitle();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: <Widget>[
        CircleAvatar(
          radius: 18,
          backgroundColor: scheme.primaryContainer,
          child: Text(
            'N',
            style: theme.textTheme.titleSmall
                ?.copyWith(color: scheme.onPrimaryContainer),
          ),
        ),
        const SizedBox(width: Gap.m),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Nadia', style: theme.textTheme.titleMedium),
            Text(
              'Online',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: const Color(0xFF1EA362)),
            ),
          ],
        ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(Gap.m, Gap.s, Gap.s, Gap.s),
          child: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  key: const Key('chat_input'),
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Message'),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: Gap.s),
              IconButton.filled(
                key: const Key('chat_send'),
                tooltip: 'Send',
                icon: const Icon(Icons.send_rounded),
                onPressed: onSend,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
