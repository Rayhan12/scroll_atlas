import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// One chat message. [id] is stable and doubles as its position in time.
@immutable
final class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.mine,
    this.replyTo,
  });

  final int id;
  final String text;
  final bool mine;

  /// Id of the quoted message, if this is a reply.
  final int? replyTo;
}

/// Messages of one conversation, oldest first, mapped to the indexes of a
/// reversed list where index 0 is the newest message.
///
/// Holds data only; scrolling lives in the screen (single responsibility).
final class ChatThread {
  ChatThread._(this._messages, this.firstUnreadId);

  /// A deterministic conversation of [count] messages where the last
  /// [unread] are unread. Every seventh message after the first 400 quotes
  /// one far above it.
  factory ChatThread.seeded({int count = 2000, int unread = 12}) {
    const lines = <String>[
      'Morning! Did the build pass?',
      'Yes, all green on the simulator.',
      'Can you check the jump to item 73,210?',
      'It lands on the line marker, no snap at the end.',
      'Nice. What about inserts above?',
      'The message I am reading stays still.',
      'Pushing the notes now.\nTwo more lines here.\nAnd a third.',
    ];
    final messages = <ChatMessage>[
      for (var id = 0; id < count; id++)
        ChatMessage(
          id: id,
          text: '#$id ${lines[id % lines.length]}',
          mine: id % 3 == 0,
          replyTo: id % 7 == 6 && id >= 400 ? id - 400 + (id % 50) : null,
        ),
    ];
    return ChatThread._(messages, count - unread);
  }

  final List<ChatMessage> _messages;

  /// Id of the oldest unread message; the screen opens there.
  final int firstUnreadId;

  int get length => _messages.length;

  /// Message at [index] of the reversed list (0 is the newest).
  ChatMessage atIndex(int index) => _messages[_messages.length - 1 - index];

  /// Reversed-list index of the message with [id].
  int indexOfId(int id) => _messages.length - 1 - id;

  /// Index for a key made by [keyOf], or null if it is unknown. Lets the
  /// list keep its built messages when a new one arrives.
  int? indexOfKey(Key key) {
    if (key is! ValueKey<String> || !key.value.startsWith(_keyPrefix)) {
      return null;
    }
    final id = int.tryParse(key.value.substring(_keyPrefix.length));
    if (id == null || id < 0 || id >= _messages.length) return null;
    return indexOfId(id);
  }

  /// Stable key of a message widget.
  static Key keyOf(ChatMessage message) =>
      ValueKey<String>('$_keyPrefix${message.id}');

  static const String _keyPrefix = 'chat-message-';

  /// Appends a message from me and returns it.
  ChatMessage send(String text) {
    final message = ChatMessage(id: _messages.length, text: text, mine: true);
    _messages.add(message);
    return message;
  }
}
