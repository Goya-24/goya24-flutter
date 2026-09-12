import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:goya24_flutter/goya24_flutter.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

/// A WebView that records what it was asked to do and can hand messages
/// back over the channel — enough to check the widget's side of the bridge
/// without a platform.
class _FakePlatform extends WebViewPlatform {
  final controllers = <_FakeController>[];

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) {
    final controller = _FakeController(params);
    controllers.add(controller);
    return controller;
  }

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(PlatformWebViewWidgetCreationParams params) =>
      _FakeWidget(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) =>
      _FakeNavigationDelegate(params);
}

class _FakeController extends PlatformWebViewController {
  _FakeController(super.params) : super.implementation();

  final loaded = <Uri>[];
  final scripts = <String>[];
  final channels = <String, JavaScriptChannelParams>{};
  _FakeNavigationDelegate? delegate;
  int reloads = 0;

  @override
  Future<void> loadRequest(LoadRequestParams params) async => loaded.add(params.uri);

  @override
  Future<void> runJavaScript(String javaScript) async => scripts.add(javaScript);

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async =>
      channels[params.name] = params;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setOnPlatformPermissionRequest(
    void Function(PlatformWebViewPermissionRequest request) onPermissionRequest,
  ) async {}

  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async =>
      delegate = handler as _FakeNavigationDelegate;

  @override
  Future<void> reload() async => reloads++;

  /// The page speaks.
  void say(String message) =>
      channels['Goya24Host']!.onMessageReceived(JavaScriptMessage(message: message));
}

class _FakeNavigationDelegate extends PlatformNavigationDelegate {
  _FakeNavigationDelegate(super.params) : super.implementation();

  NavigationRequestCallback? onRequest;

  @override
  Future<void> setOnNavigationRequest(NavigationRequestCallback onNavigationRequest) async =>
      onRequest = onNavigationRequest;

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {}

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {}

  @override
  Future<void> setOnProgress(ProgressCallback onProgress) async {}

  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback onWebResourceError) async {}

  @override
  Future<void> setOnUrlChange(UrlChangeCallback onUrlChange) async {}

  @override
  Future<void> setOnHttpAuthRequest(HttpAuthRequestCallback onHttpAuthRequest) async {}

  @override
  Future<void> setOnHttpError(HttpResponseErrorCallback onHttpError) async {}
}

class _FakeWidget extends PlatformWebViewWidget {
  _FakeWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}

void main() {
  late _FakePlatform platform;
  const options = Goya24Options(workspaceKey: 'd24_pk_oPJYZVIIFNlTucNtha4LLFdh');

  setUp(() {
    platform = _FakePlatform();
    WebViewPlatform.instance = platform;
  });

  Future<_FakeController> pump(
    WidgetTester tester, {
    Goya24Options options = options,
    Goya24MessengerController? controller,
    VoidCallback? onReady,
    ValueChanged<int>? onUnread,
    VoidCallback? onClose,
    ValueChanged<String>? onError,
    ValueChanged<Uri>? onOpenLink,
  }) async {
    await tester.pumpWidget(MaterialApp(
      home: Goya24Messenger(
        options: options,
        controller: controller,
        onReady: onReady,
        onUnread: onUnread,
        onClose: onClose,
        onError: onError,
        onOpenLink: onOpenLink,
      ),
    ));
    return platform.controllers.single;
  }

  testWidgets('loads the messenger in app mode with a channel to talk back on', (tester) async {
    final web = await pump(tester);

    expect(web.loaded.single, options.uri);
    expect(web.channels.keys, ['Goya24Host']);
  });

  testWidgets('what the page says reaches the callbacks', (tester) async {
    var ready = 0;
    final unread = <int>[];
    var closed = 0;
    final errors = <String>[];
    final web = await pump(
      tester,
      onReady: () => ready++,
      onUnread: unread.add,
      onClose: () => closed++,
      onError: errors.add,
    );

    web.say('{"source":"dastyar24","type":"ready"}');
    web.say('{"source":"dastyar24","type":"state","open":true,"unread":0}');
    web.say('{"source":"dastyar24","type":"state","open":true,"unread":2}');
    web.say('{"source":"dastyar24","type":"state","open":false,"unread":2}');
    web.say('{"source":"dastyar24","type":"close"}');
    web.say('{"source":"dastyar24","type":"error","reason":"boot failed"}');
    web.say('garbage');

    expect(ready, 1);
    expect(unread, [0, 2], reason: 'the count, only when it changes');
    expect(closed, 1);
    expect(errors, ['boot failed']);
  });

  testWidgets('identify posts a message the page listens for', (tester) async {
    final controller = Goya24MessengerController();
    final web = await pump(tester, controller: controller);

    await controller.identify(const Goya24User(id: '7', name: 'Sara', email: 's@e.com'));

    expect(controller.isAttached, isTrue);
    expect(web.scripts.single, contains('window.postMessage('));
    expect(web.scripts.single, contains('"source":"dastyar24-host"'));
    expect(web.scripts.single, contains('"type":"identify"'));
    expect(web.scripts.single, contains('"name":"Sara"'));
  });

  testWidgets('links off goya24 are handed to the app, not followed', (tester) async {
    final opened = <Uri>[];
    final web = await pump(tester, onOpenLink: opened.add);
    final onRequest = web.delegate!.onRequest!;

    final inside = await onRequest(
      NavigationRequest(url: 'https://goya24.com/fa/widget?key=x', isMainFrame: true),
    );
    final outside = await onRequest(
      NavigationRequest(url: 'https://shop.example/track/123', isMainFrame: true),
    );

    expect(inside, NavigationDecision.navigate);
    expect(outside, NavigationDecision.prevent);
    expect(opened.single.host, 'shop.example');
  });

  testWidgets('new options load a new address', (tester) async {
    final web = await pump(tester);
    await tester.pumpWidget(MaterialApp(
      home: Goya24Messenger(options: options.copyWith(locale: Goya24Locale.en)),
    ));

    expect(web.loaded.length, 2);
    expect(web.loaded.last.path, '/en/widget');
  });
}
