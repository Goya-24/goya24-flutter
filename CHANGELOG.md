## 0.1.0

First release.

- `Goya24Messenger`: the goya24 messenger filling the view, in the mode made for apps — open at once, no launcher, a close button that asks the app to put it away. `Goya24Messenger.open(context, …)` and `Goya24Messenger.route(…)` put it on a page of its own.
- `Goya24Options`: workspace key, Persian or English, light or dark, and the signed-in user.
- `Goya24User`: introduce who is signed in, with proof when `hash` (computed on your server) is set.
- `Goya24MessengerController.identify()` for a user who signs in after the messenger opened.
- Callbacks: `onReady`, `onState`, `onUnread`, `onClose`, `onError`, `onOpenLink`.
- Microphone permission requests from the page (voice messages) are granted; links off goya24 are handed to the app rather than followed.
