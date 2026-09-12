# Contributing

Thanks for looking. This repo holds the goya24 Flutter package — the messenger in a WebView, the bridge to it, and the signed identity of the signed-in user.

## Setup

- Flutter stable. `flutter pub get`, then `flutter test` to make sure the tree is green before you change anything.

## Working on it

- `flutter test` — the tests run against a fake WebView platform (see `test/messenger_test.dart`), so they need no device or emulator. The bridge is tested by handing the widget the same JSON the page posts.
- `flutter analyze` and `dart format --set-exit-if-changed lib test example/lib` — what CI runs.
- `example/` is a real app; `flutter run` it against your own workspace key. CI builds it for Android.

## What a change needs

1. **A test.** A bug fix comes with the test that would have caught it. A feature comes with tests for what it does and for what it refuses.
2. **A changelog line** in `CHANGELOG.md`, for anything a user of the package would notice.
3. **The README.** If behaviour changed, the README describes the new behaviour.

## Releasing

Bump `version` in `pubspec.yaml`, add the entry to `CHANGELOG.md`, and tag `vX.Y.Z`. The release workflow makes the GitHub release; publishing to pub.dev runs through pub.dev's own GitHub Actions publishing once it is switched on for the package.

## Things that are already decided

- **The package carries no UI of the messenger.** It loads one page; the messenger is served by goya24. A change to how the messenger looks belongs in goya24, not here.
- **The bridge's names do not change.** The page posts `{source: "dastyar24", …}` and listens for `{source: "dastyar24-host", …}`; those predate the goya24 brand and are a contract with every site and app that embeds the messenger. The channel is `Goya24Host`.
- **The secret never enters the app.** `Goya24User.hash` is computed on the customer's server. A helper that computed it in Dart would be a helper for shipping the secret in an app bundle.
- **The WebView is the messenger, not a browser.** Navigation off goya24's origin is handed to the app, never followed.

## Reporting a bug

Open an issue with the package, Flutter and platform versions, the options you opened it with (no secrets), and what happened.

## Code of conduct

Be kind and be specific. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
