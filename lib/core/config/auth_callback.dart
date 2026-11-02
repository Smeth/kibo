/// Adresse publique Android ; ne contient ni configuration ni jeton réel.
abstract final class KiboAuthCallback {
  static const redirectUrl = 'com.kibo.kibo://auth/confirm';

  /// Seuls les retours PKCE (ou leurs erreurs) sont confiés au SDK.
  /// Les fragments de session du flux implicite ne sont pas acceptés.
  static bool accepts(Uri uri) {
    if (uri.scheme != 'com.kibo.kibo' ||
        uri.host != 'auth' ||
        uri.path != '/confirm' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort) {
      return false;
    }
    Map<String, List<String>> parameters;
    try {
      parameters = uri.hasFragment
          ? Uri(query: uri.fragment).queryParametersAll
          : uri.queryParametersAll;
    } on FormatException {
      return false;
    }
    // Supabase peut renvoyer les erreurs dans le fragment, jamais une session.
    if (uri.hasFragment &&
        (uri.hasQuery ||
            parameters.keys.any(
              (key) => !const {
                'error',
                'error_code',
                'error_description',
              }.contains(key),
            ))) {
      return false;
    }
    if (parameters.containsKey('access_token') ||
        parameters.containsKey('refresh_token')) {
      return false;
    }
    bool singleValue(String key) =>
        parameters[key]?.length == 1 && parameters[key]!.single.isNotEmpty;
    return (!uri.hasFragment && singleValue('code')) ||
        singleValue('error') ||
        singleValue('error_code');
  }
}
