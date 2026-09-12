<p align="center">
  <img src="https://raw.githubusercontent.com/Goya-24/.github/main/profile/goya24-icon.svg" width="72" alt="">
</p>

<h1 align="center">goya24 for Flutter</h1>

<p align="center">
  The <a href="https://goya24.com">goya24</a> AI support messenger in your app: one widget, full screen, Persian and English, with the signed-in user introduced with proof.
</p>

<p align="center">
  <a href="https://github.com/Goya-24/goya24-flutter/actions/workflows/ci.yml"><img src="https://github.com/Goya-24/goya24-flutter/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
  <a href="https://pub.dev/packages/goya24_flutter"><img src="https://img.shields.io/pub/v/goya24_flutter?label=goya24_flutter" alt="pub.dev"></a>
  <img src="https://img.shields.io/badge/platforms-Android%20%7C%20iOS-02569B" alt="Android, iOS">
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-0e7c86" alt="MIT"></a>
</p>

## Install

```sh
flutter pub add goya24_flutter
```

The package is a thin layer over [`webview_flutter`](https://pub.dev/packages/webview_flutter): the messenger is the same one a website shows, served by goya24, in the mode made for apps. Nothing about what it says lives in the app — a fix on the service reaches every app without a release.

For voice messages, declare the microphone: `RECORD_AUDIO` in `AndroidManifest.xml`, `NSMicrophoneUsageDescription` in `Info.plist`. Without them the mic button simply does nothing.

## Open it

```dart
import 'package:goya24_flutter/goya24_flutter.dart';

Goya24Messenger.open(
  context,
  options: Goya24Options(
    workspaceKey: 'd24_pk_…',        // Settings → Install in your workspace
    locale: Goya24Locale.fa,          // or .en
  ),
);
```

That pushes a full-screen page with the messenger on it; its own close button pops the page. To put the messenger somewhere else — a tab, a sheet — use the widget directly and handle `onClose` yourself:

```dart
Goya24Messenger(
  options: options,
  onClose: () => Navigator.of(context).pop(),
  onUnread: (count) => setState(() => unread = count),
)
```

## Who is signed in

```dart
Goya24Options(
  workspaceKey: 'd24_pk_…',
  user: Goya24User(
    id: 'u_1024',
    hash: session.goya24Hash,   // hmac_sha256(identitySecret, id), from YOUR server
    name: 'سارا',
    email: 'sara@example.com',
    plan: 'gold',
  ),
)
```

With `id` and `hash` the identity is **proven**: your server signs the id with the identity secret from _Settings → Install_, and goya24 checks the signature before trusting anything — so the agent greets the customer by name and, with the store connected, looks up their orders. Without `hash` the details are sent as a claim, and the inbox marks it as one.

**Never put the identity secret in the app.** An app bundle is public. Compute the hash on your backend and hand it to the app with the session, like any other credential.

A proven identity has to be there when the messenger opens, because it travels in the boot request. Someone who signs in while it is open can be announced with a `Goya24MessengerController` — that is a claim:

```dart
final controller = Goya24MessengerController();
Goya24Messenger(options: options, controller: controller);
…
await controller.identify(Goya24User(id: 'u_1024', name: 'Sara', email: 'sara@example.com'));
```

## What the app hears

| Callback | When |
| --- | --- |
| `onReady` | The messenger booted and is showing the conversation. |
| `onState(Goya24State)` | The panel's state changed: `open`, `unread`. |
| `onUnread(int)` | The unread count changed — for a badge on your button, once the messenger has been opened. |
| `onClose` | The person pressed the messenger's close button. |
| `onError(String)` | It could not start: a wrong key, a revoked one, no network. |
| `onOpenLink(Uri)` | A link in a conversation leads off goya24. The WebView does not follow it — open it with `url_launcher`. |

## Options

| Option | Default | |
| --- | --- | --- |
| `workspaceKey` | — | Required. `d24_pk_…`, public, safe to ship. |
| `locale` | `Goya24Locale.fa` | Persian or English. |
| `theme` | `Goya24Theme.light` | Light or dark. |
| `user` | none | See above. |
| `origin` | `https://goya24.com` | Only for a self-hosted goya24. |

## Development

```sh
flutter pub get
dart format --set-exit-if-changed lib test example/lib
flutter analyze
flutter test
```

The tests run against a fake WebView platform, so they need no device. See [CONTRIBUTING.md](CONTRIBUTING.md) for how changes ship and [SECURITY.md](SECURITY.md) for reporting vulnerabilities.

## License

[MIT](LICENSE) © Goya24. The JavaScript SDK lives in [goya24-js](https://github.com/Goya-24/goya24-js), React Native in [goya24-react-native](https://github.com/Goya-24/goya24-react-native).
