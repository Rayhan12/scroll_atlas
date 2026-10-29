import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:scroll_atlas/scroll_atlas.dart';

import 'chat_thread.dart';

/// D6 Chat: a reversed [AtlasListView] that opens at the first unread
/// message, animates to a quoted message and flashes it, and stays pinned to the bottom when a message arrives.
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
      appBar: AppBar(title: const Text('D6 Chat')),
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
    required this.firstUnread,
    required this.highlighted,
    required this.onQuoteTap,
    super.key,
  });

  final ChatMessage message;
  final bool firstUnread;
  final ValueListenable<int?> highlighted;
  final ValueChanged<int> onQuoteTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final replyTo = message.replyTo;
    final bubble = ValueListenableBuilder<int?>(
      valueListenable: highlighted,
      builder: (BuildContext context, int? id, Widget? child) => Container(
        key: ValueKey<String>('bubble-${message.id}'),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: id == message.id
              ? scheme.tertiaryContainer
              : message.mine
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
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
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: scheme.primary, width: 3),
                  ),
                ),
                child: Text('Reply to #$replyTo (tap to jump)'),
              ),
            ),
          Text(message.text),
        ],
      ),
    );
    return Column(
      crossAxisAlignment:
          message.mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: <Widget>[
        if (firstUnread)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                'First unread',
                style: TextStyle(color: scheme.primary),
              ),
            ),
          ),
        bubble,
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
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                key: const Key('chat_input'),
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(
              key: const Key('chat_send'),
              icon: const Icon(Icons.send),
              onPressed: onSend,
            ),
          ],
        ),
      ),
    );
  }
}
