import 'user.dart';

/// The language the messenger opens in. It speaks Persian and English.
enum Goya24Locale {
  /// Persian.
  fa,

  /// English.
  en,
}

/// The messenger's colours.
enum Goya24Theme {
  /// Light.
  light,

  /// Dark.
  dark,
}

/// Everything the messenger needs to open: the workspace, and who is here.
class Goya24Options {
  /// The workspace, and who is here.
  const Goya24Options({
    required this.workspaceKey,
    this.locale = Goya24Locale.fa,
    this.theme = Goya24Theme.light,
    this.user,
    this.origin = defaultOrigin,
  });

  /// Where the messenger is served from. Only for a self-hosted goya24.
  static const defaultOrigin = 'https://goya24.com';

  /// The workspace's public key, from Settings → Install. It looks like
  /// `d24_pk_…` and is safe to ship in the app: it is on every page of the
  /// site too.
  final String workspaceKey;

  /// The language the messenger opens in.
  final Goya24Locale locale;

  /// Light or dark.
  final Goya24Theme theme;

  /// Who is signed in, if anyone. See [Goya24User] for how to prove it.
  final Goya24User? user;

  /// The origin the messenger is loaded from, without a trailing slash.
  final String origin;

  /// The page the WebView loads.
  ///
  /// `/{locale}/widget` with `app=1` — the messenger's own address, in the
  /// mode made for native apps: full screen, open at once, a close button
  /// that asks the app to put it away, and the signed-in user in the query
  /// exactly as the web loader passes them.
  Uri get uri {
    final base = origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
    final query = <String, String>{
      'key': workspaceKey,
      'theme': theme.name,
      'app': '1',
      ...?user?.toQueryParameters(),
    };
    return Uri.parse('$base/${locale.name}/widget').replace(queryParameters: query);
  }

  /// A copy with some fields changed.
  Goya24Options copyWith({
    String? workspaceKey,
    Goya24Locale? locale,
    Goya24Theme? theme,
    Goya24User? user,
    String? origin,
  }) =>
      Goya24Options(
        workspaceKey: workspaceKey ?? this.workspaceKey,
        locale: locale ?? this.locale,
        theme: theme ?? this.theme,
        user: user ?? this.user,
        origin: origin ?? this.origin,
      );
}
