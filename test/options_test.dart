import 'package:flutter_test/flutter_test.dart';
import 'package:goya24_flutter/goya24_flutter.dart';

void main() {
  const key = 'd24_pk_oPJYZVIIFNlTucNtha4LLFdh';

  group('the address the WebView loads', () {
    test('is the messenger in app mode, in the chosen language', () {
      final uri = Goya24Options(workspaceKey: key).uri;

      expect(uri.origin, 'https://goya24.com');
      expect(uri.path, '/fa/widget');
      expect(uri.queryParameters['key'], key);
      expect(uri.queryParameters['app'], '1');
      expect(uri.queryParameters['theme'], 'light');
      expect(uri.queryParameters.containsKey('uid'), isFalse, reason: 'a visitor is nobody');
    });

    test('follows the locale, the theme and a self-hosted origin', () {
      final uri = Goya24Options(
        workspaceKey: key,
        locale: Goya24Locale.en,
        theme: Goya24Theme.dark,
        origin: 'https://staging.example.com/',
      ).uri;

      expect(uri.toString(), startsWith('https://staging.example.com/en/widget?'));
      expect(uri.queryParameters['theme'], 'dark');
    });

    test('carries the signed-in user the way the web loader does', () {
      final uri = Goya24Options(
        workspaceKey: key,
        user: const Goya24User(
          id: 'u_1024',
          hash: 'abc123',
          name: 'سارا محمدی',
          email: 'sara@example.com',
          plan: 'gold',
        ),
      ).uri;

      final q = uri.queryParameters;
      expect(q['uid'], 'u_1024');
      expect(q['uhash'], 'abc123');
      expect(q['uname'], 'سارا محمدی', reason: 'Persian survives the encoding round trip');
      expect(q['uemail'], 'sara@example.com');
      expect(q['uplan'], 'gold');
    });

    test('a user without a hash is sent as a claim, not dropped', () {
      final uri = Goya24Options(
        workspaceKey: key,
        user: const Goya24User(id: '7', email: 'a@b.c'),
      ).uri;

      expect(uri.queryParameters['uid'], '7');
      expect(uri.queryParameters.containsKey('uhash'), isFalse);
    });
  });

  group('Goya24User', () {
    test('knows whether it is proven', () {
      expect(const Goya24User(id: '1').isProven, isFalse);
      expect(const Goya24User(id: '1', hash: '').isProven, isFalse);
      expect(const Goya24User(id: '1', hash: 'ff').isProven, isTrue);
    });

    test('the identify payload carries only what is set', () {
      expect(const Goya24User(id: '1', name: 'Sara').toIdentifyPayload(), {'name': 'Sara'});
    });
  });
}
