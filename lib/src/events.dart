import 'dart:convert';

/// What the messenger tells the app, over the `Goya24Host` channel.
///
/// The messages are the ones the web loader receives from its frame —
/// `{source: "dastyar24", type: …}` — as JSON strings. `dastyar24` is the
/// loader's original name and is a contract with every site that embeds
/// it; it is not going to change.
sealed class Goya24Event {
  const Goya24Event();

  /// The event a channel message carries, or null for anything that is
  /// not one of ours — a page can post other things.
  static Goya24Event? parse(String message) {
    Object? decoded;
    try {
      decoded = jsonDecode(message);
    } on FormatException {
      return null;
    }
    if (decoded is! Map || decoded['source'] != 'dastyar24') return null;
    switch (decoded['type']) {
      case 'ready':
        return const Goya24Ready();
      case 'state':
        return Goya24State(
          open: decoded['open'] == true,
          unread: switch (decoded['unread']) {
            final int n => n,
            final num n => n.toInt(),
            _ => 0,
          },
        );
      case 'close':
        return const Goya24CloseRequested();
      case 'error':
        return Goya24Error(reason: decoded['reason']?.toString() ?? 'unknown');
      default:
        return null;
    }
  }
}

/// The messenger has booted and is showing the conversation.
class Goya24Ready extends Goya24Event {
  /// See [Goya24Ready].
  const Goya24Ready();
}

/// Whether the panel is open, and how many replies are unread.
class Goya24State extends Goya24Event {
  /// See [Goya24State].
  const Goya24State({required this.open, required this.unread});

  /// Whether the conversation panel is open. Inside an app it always is.
  final bool open;

  /// Replies that landed while nobody was looking.
  final int unread;
}

/// The person pressed the messenger's close button: pop the screen.
class Goya24CloseRequested extends Goya24Event {
  /// See [Goya24CloseRequested].
  const Goya24CloseRequested();
}

/// The messenger could not start — a wrong key, a revoked one, no network.
class Goya24Error extends Goya24Event {
  /// See [Goya24Error].
  const Goya24Error({required this.reason});

  /// What went wrong, in the messenger's words.
  final String reason;
}
