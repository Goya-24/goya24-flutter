import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'events.dart';
import 'options.dart';
import 'user.dart';

/// Talks to a mounted [Goya24Messenger]: introduce a user who signed in
/// after it opened, or reload it.
///
/// Pass one to the widget and keep it; the same controller follows the
/// widget across rebuilds.
class Goya24MessengerController {
  WebViewController? _web;

  /// Whether a messenger is currently attached.
  bool get isAttached => _web != null;

  /// Tell the messenger who is signed in, after it has opened.
  ///
  /// This is a claim, the way the web loader's `identify()` is one: a
  /// proven identity has to be in [Goya24Options.user] when the messenger
  /// opens, because it travels in the boot request.
  Future<void> identify(Goya24User user) => _post({
        'source': 'dastyar24-host',
        'type': 'identify',
        'data': user.toIdentifyPayload(),
      });

  /// Load the messenger again — after the network came back, say.
  Future<void> reload() async => _web?.reload();

  Future<void> _post(Map<String, Object?> message) async {
    final web = _web;
    if (web == null) return;
    // The messenger listens for `message` events on its own window; a
    // top-level page's `postMessage` delivers one.
    await web.runJavaScript('window.postMessage(${jsonEncode(message)}, "*");');
  }
}

/// The goya24 messenger, filling whatever it is put in.
///
/// It is the same messenger a website shows, in the mode made for apps: open
/// at once, no launcher, and a close button that fires [onClose] rather
/// than shrinking to a corner. Put it in a page of its own — [route] and
/// [open] do that — or anywhere else a full-height widget fits.
///
/// ```dart
/// Goya24Messenger.open(
///   context,
///   options: Goya24Options(
///     workspaceKey: 'd24_pk_…',
///     locale: Goya24Locale.fa,
///     user: Goya24User(id: 'u_1024', hash: hashFromYourServer, name: 'Sara'),
///   ),
///   onUnread: (count) => setState(() => unread = count),
/// );
/// ```
class Goya24Messenger extends StatefulWidget {
  /// The messenger for [options], reporting to the callbacks.
  const Goya24Messenger({
    super.key,
    required this.options,
    this.controller,
    this.onReady,
    this.onState,
    this.onUnread,
    this.onClose,
    this.onError,
    this.onOpenLink,
    this.backgroundColor,
  });

  /// The workspace, and who is here.
  final Goya24Options options;

  /// To talk to the messenger after it opened: [Goya24MessengerController.identify].
  final Goya24MessengerController? controller;

  /// The messenger booted and is showing the conversation.
  final VoidCallback? onReady;

  /// Whether the panel is open and how many replies are unread — every time
  /// either changes.
  final ValueChanged<Goya24State>? onState;

  /// The unread count, every time it changes. For a badge on your own
  /// button, once the messenger has been opened at least once.
  final ValueChanged<int>? onUnread;

  /// The person pressed the messenger's close button. [route] pops the
  /// page; embedding it yourself, this is where you hide it.
  final VoidCallback? onClose;

  /// The messenger could not start: a wrong key, a revoked one, no network.
  final ValueChanged<String>? onError;

  /// A link inside a conversation that leads off goya24. The WebView does
  /// not follow it — this is the messenger, not a browser. Open it with
  /// `url_launcher` or your own screen; null ignores such links.
  final ValueChanged<Uri>? onOpenLink;

  /// Behind the page while it loads. Defaults to the theme's background,
  /// so the first frame is not a white flash on a dark screen.
  final Color? backgroundColor;

  /// A full-screen page with the messenger on it, closing on its own
  /// close button. `Navigator.of(context).push(Goya24Messenger.route(…))`.
  static Route<void> route({
    required Goya24Options options,
    Goya24MessengerController? controller,
    VoidCallback? onReady,
    ValueChanged<Goya24State>? onState,
    ValueChanged<int>? onUnread,
    ValueChanged<String>? onError,
    ValueChanged<Uri>? onOpenLink,
  }) =>
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          body: SafeArea(
            child: Goya24Messenger(
              options: options,
              controller: controller,
              onReady: onReady,
              onState: onState,
              onUnread: onUnread,
              onError: onError,
              onOpenLink: onOpenLink,
              onClose: () => Navigator.of(context).maybePop(),
            ),
          ),
        ),
      );

  /// Push [route]. Returns when the messenger is closed.
  static Future<void> open(
    BuildContext context, {
    required Goya24Options options,
    Goya24MessengerController? controller,
    VoidCallback? onReady,
    ValueChanged<Goya24State>? onState,
    ValueChanged<int>? onUnread,
    ValueChanged<String>? onError,
    ValueChanged<Uri>? onOpenLink,
  }) =>
      Navigator.of(context).push(route(
        options: options,
        controller: controller,
        onReady: onReady,
        onState: onState,
        onUnread: onUnread,
        onError: onError,
        onOpenLink: onOpenLink,
      ));

  @override
  State<Goya24Messenger> createState() => _Goya24MessengerState();
}

class _Goya24MessengerState extends State<Goya24Messenger> {
  late final WebViewController _web;
  int _unread = -1;

  @override
  void initState() {
    super.initState();
    // Voice messages need the microphone; the page asks, the app grants.
    // (The app still declares the permission in its manifest and Info.plist.)
    _web = WebViewController(onPermissionRequest: (request) => request.grant())
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // The one way back: the page posts to this channel, and the loader's
      // frame on a website posts the same messages to its parent.
      ..addJavaScriptChannel('Goya24Host', onMessageReceived: (m) => _onMessage(m.message))
      ..setNavigationDelegate(NavigationDelegate(onNavigationRequest: _onNavigation))
      ..loadRequest(widget.options.uri);
    widget.controller?._web = _web;
  }

  @override
  void didUpdateWidget(Goya24Messenger old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._web = null;
      widget.controller?._web = _web;
    }
    if (old.options.uri != widget.options.uri) {
      _unread = -1;
      _web.loadRequest(widget.options.uri);
    }
  }

  @override
  void dispose() {
    widget.controller?._web = null;
    super.dispose();
  }

  NavigationDecision _onNavigation(NavigationRequest request) {
    final target = Uri.tryParse(request.url);
    final own = widget.options.uri;
    if (target == null || (target.host == own.host && target.scheme == own.scheme)) {
      return NavigationDecision.navigate;
    }
    widget.onOpenLink?.call(target);
    return NavigationDecision.prevent;
  }

  void _onMessage(String raw) {
    final event = Goya24Event.parse(raw);
    switch (event) {
      case Goya24Ready():
        widget.onReady?.call();
      case Goya24State():
        widget.onState?.call(event);
        if (event.unread != _unread) {
          _unread = event.unread;
          widget.onUnread?.call(event.unread);
        }
      case Goya24CloseRequested():
        widget.onClose?.call();
      case Goya24Error():
        widget.onError?.call(event.reason);
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final background = widget.backgroundColor ?? Theme.of(context).colorScheme.surface;
    return ColoredBox(
      color: background,
      child: WebViewWidget(controller: _web),
    );
  }
}
