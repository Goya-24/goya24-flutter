import 'package:flutter/material.dart';
import 'package:goya24_flutter/goya24_flutter.dart';

void main() => runApp(const ExampleApp());

/// A shop with one support button. The hash would come from your server,
/// beside the session — never computed in the app.
class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  int unread = 0;

  static const options = Goya24Options(
    workspaceKey: 'd24_pk_YOUR_KEY',
    locale: Goya24Locale.fa,
    user: Goya24User(
      id: 'u_1024',
      hash: '<hmac-sha256 of the id, from your server>',
      name: 'سارا',
      email: 'sara@example.com',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('فروشگاه نمونه')),
          body: Center(
            child: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: FilledButton.icon(
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('پشتیبانی'),
                onPressed: () => Goya24Messenger.open(
                  context,
                  options: options,
                  onUnread: (count) => setState(() => unread = count),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
