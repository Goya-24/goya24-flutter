import 'package:flutter_test/flutter_test.dart';
import 'package:goya24_flutter/goya24_flutter.dart';

void main() {
  group('what the messenger posts over the channel', () {
    test('ready', () {
      expect(Goya24Event.parse('{"source":"dastyar24","type":"ready","fallbackKey":"v_1"}'), isA<Goya24Ready>());
    });

    test('state, with the unread count', () {
      final event = Goya24Event.parse('{"source":"dastyar24","type":"state","open":true,"unread":3}');
      expect(event, isA<Goya24State>());
      expect((event! as Goya24State).open, isTrue);
      expect((event as Goya24State).unread, 3);
    });

    test('close and error', () {
      expect(Goya24Event.parse('{"source":"dastyar24","type":"close"}'), isA<Goya24CloseRequested>());
      final error = Goya24Event.parse('{"source":"dastyar24","type":"error","reason":"boot failed"}');
      expect((error! as Goya24Error).reason, 'boot failed');
    });

    test('anything else is nothing', () {
      expect(Goya24Event.parse('not json'), isNull);
      expect(Goya24Event.parse('{"source":"other","type":"state"}'), isNull);
      expect(Goya24Event.parse('{"source":"dastyar24","type":"resize","width":"96px"}'), isNull);
      expect(Goya24Event.parse('[1,2]'), isNull);
    });
  });
}
