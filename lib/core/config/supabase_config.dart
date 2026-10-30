import 'dart:convert';

/// Paramètres publics du client, injectés à la compilation.
/// La validation locale ne remplace ni la vérification serveur ni les RLS.
class SupabaseConfig {
  const SupabaseConfig({required this.url, required this.publicKey});

  const SupabaseConfig.fromEnvironment()
    : url = const String.fromEnvironment('SUPABASE_URL'),
      publicKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

  final String url;
  final String publicKey;

  String? get validationError {
    if (url.isEmpty || publicKey.isEmpty) {
      return 'La configuration Supabase est absente ou incomplète. '
          'Renseignez SUPABASE_URL et SUPABASE_ANON_KEY au lancement.';
    }
    final uri = Uri.tryParse(url);
    if (url != url.trim() ||
        uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      return 'SUPABASE_URL doit être une URL de projet HTTPS valide.';
    }
    if (!_isPublicKey(publicKey)) {
      return 'SUPABASE_ANON_KEY doit être une clé publique publishable '
          'ou une ancienne clé anon. Les clés privilégiées sont interdites.';
    }
    return null;
  }

  static bool _isPublicKey(String key) {
    if (RegExp(r'^sb_publishable_[A-Za-z0-9_-]+$').hasMatch(key)) {
      return true;
    }
    // Ancien format JWT : on accepte exclusivement le rôle client anon.
    // Il ne s’agit pas d’une validation cryptographique du jeton.
    final parts = key.split('.');
    if (parts.length != 3 ||
        parts.any((part) => !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(part))) {
      return false;
    }
    try {
      final header = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[0]))),
      );
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      return header is Map &&
          header['alg'] == 'HS256' &&
          payload is Map &&
          payload['role'] == 'anon';
    } on FormatException {
      return false;
    }
  }
}
