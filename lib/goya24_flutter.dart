/// The goya24 AI support messenger for Flutter.
///
/// One widget puts the messenger a website shows into your app — full
/// screen, in Persian or English — and introduces the signed-in user with
/// proof. Everything about what it says lives in your goya24 workspace.
///
/// ```dart
/// Goya24Messenger.open(
///   context,
///   options: Goya24Options(workspaceKey: 'd24_pk_…', locale: Goya24Locale.fa),
/// );
/// ```
library;

export 'src/events.dart' show Goya24CloseRequested, Goya24Error, Goya24Event, Goya24Ready, Goya24State;
export 'src/messenger.dart' show Goya24Messenger, Goya24MessengerController;
export 'src/options.dart' show Goya24Locale, Goya24Options, Goya24Theme;
export 'src/user.dart' show Goya24User;
